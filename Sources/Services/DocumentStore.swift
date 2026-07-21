import Foundation

struct SavedDocument: Identifiable {
    let id: URL
    let url: URL
    let name: String
    let createdAt: Date

    init(url: URL, createdAt: Date) {
        self.id = url
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.createdAt = createdAt
    }
}

final class DocumentStore: ObservableObject {
    @Published private(set) var documents: [SavedDocument] = []

    private var scansDirectory: URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let scansDir = documentsDir.appendingPathComponent("Scans", isDirectory: true)
        if !FileManager.default.fileExists(atPath: scansDir.path) {
            try? FileManager.default.createDirectory(at: scansDir, withIntermediateDirectories: true)
        }
        return scansDir
    }

    init() {
        refresh()
    }

    func refresh() {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(at: scansDirectory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        documents = urls
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .map { url in
                let created = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
                return SavedDocument(url: url, createdAt: created)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func save(pdfData: Data, name: String) -> URL {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Scan \(Date().formatted(date: .abbreviated, time: .shortened))" : trimmed
        let safeBase = base.replacingOccurrences(of: "/", with: "-")
        let fileURL = scansDirectory.appendingPathComponent("\(safeBase)-\(UUID().uuidString.prefix(6)).pdf")
        try? pdfData.write(to: fileURL)
        refresh()
        return fileURL
    }

    func delete(_ document: SavedDocument) {
        try? FileManager.default.removeItem(at: document.url)
        refresh()
    }
}
