import SwiftUI
import VisionKit

struct ContentView: View {
    @StateObject private var store = DocumentStore()
    @State private var isShowingScanner = false
    @State private var showsUnsupportedAlert = false
    @State private var capturedPages: [ScanPage] = []
    @State private var isShowingReview = false
    @State private var shareItem: IdentifiableURL?

    var body: some View {
        NavigationStack {
            Group {
                if store.documents.isEmpty {
                    ContentUnavailableView(
                        "No Scans Yet",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Tap the camera button to scan your first document.")
                    )
                } else {
                    List {
                        ForEach(store.documents) { document in
                            Button {
                                shareItem = IdentifiableURL(url: document.url)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.name).font(.headline)
                                    Text(document.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.primary)
                        }
                        .onDelete { indexSet in
                            indexSet.map { store.documents[$0] }.forEach(store.delete)
                        }
                    }
                }
            }
            .navigationTitle("My Scans")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        startScanning()
                    } label: {
                        Label("New Scan", systemImage: "camera.fill")
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingScanner) {
                DocumentCameraView(
                    onFinish: { images in
                        capturedPages = images.map { ScanPage(originalImage: $0.normalizedOrientation()) }
                        isShowingScanner = false
                        isShowingReview = true
                    },
                    onCancel: { isShowingScanner = false }
                )
                .ignoresSafeArea()
            }
            .navigationDestination(isPresented: $isShowingReview) {
                ScanReviewView(pages: capturedPages, store: store)
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
            .alert("Scanning Not Available", isPresented: $showsUnsupportedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Document scanning needs a physical iPhone with a camera — it isn't available in the Simulator.")
            }
        }
    }

    private func startScanning() {
        guard VNDocumentCameraViewController.isSupported else {
            showsUnsupportedAlert = true
            return
        }
        capturedPages = []
        isShowingScanner = true
    }
}
