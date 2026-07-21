import SwiftUI
import VisionKit

struct ScanReviewView: View {
    @State var pages: [ScanPage]
    @ObservedObject var store: DocumentStore

    @State private var isShowingScanner = false
    @State private var showsUnsupportedAlert = false
    @State private var croppingPage: ScanPage?
    @State private var shareItem: IdentifiableURL?
    @State private var documentName = ""
    @State private var isShowingNamePrompt = false

    var body: some View {
        List {
            ForEach(pages) { page in
                HStack(alignment: .top, spacing: 12) {
                    Image(uiImage: page.filteredImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.secondary.opacity(0.3)))

                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Filter", selection: binding(for: page)) {
                            ForEach(PageFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)

                        Button("Crop") {
                            croppingPage = page
                        }
                        .font(.footnote)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                pages.remove(atOffsets: indexSet)
            }
            .onMove { source, destination in
                pages.move(fromOffsets: source, toOffset: destination)
            }
        }
        .navigationTitle("Review Pages")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    startScanning()
                } label: {
                    Label("Add Page", systemImage: "plus.viewfinder")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    isShowingNamePrompt = true
                } label: {
                    Label("Save as PDF", systemImage: "doc.badge.plus")
                }
                .disabled(pages.isEmpty)
            }
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            DocumentCameraView(
                onFinish: { images in
                    pages.append(contentsOf: images.map { ScanPage(originalImage: $0.normalizedOrientation()) })
                    isShowingScanner = false
                },
                onCancel: { isShowingScanner = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $croppingPage) { page in
            CropView(
                image: page.originalImage,
                onCancel: { croppingPage = nil },
                onDone: { cropped in
                    if let index = pages.firstIndex(where: { $0.id == page.id }) {
                        pages[index].originalImage = cropped
                    }
                    croppingPage = nil
                }
            )
        }
        .alert("Name this document", isPresented: $isShowingNamePrompt) {
            TextField("Document name", text: $documentName)
            Button("Save") { savePDF() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Scanning Not Available", isPresented: $showsUnsupportedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Document scanning needs a physical iPhone with a camera — it isn't available in the Simulator.")
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    private func startScanning() {
        guard VNDocumentCameraViewController.isSupported else {
            showsUnsupportedAlert = true
            return
        }
        isShowingScanner = true
    }

    private func binding(for page: ScanPage) -> Binding<PageFilter> {
        Binding(
            get: { page.filter },
            set: { newValue in
                if let index = pages.firstIndex(where: { $0.id == page.id }) {
                    pages[index].filter = newValue
                }
            }
        )
    }

    private func savePDF() {
        let data = PDFGenerator.makePDF(from: pages)
        let url = store.save(pdfData: data, name: documentName)
        shareItem = IdentifiableURL(url: url)
        documentName = ""
    }
}
