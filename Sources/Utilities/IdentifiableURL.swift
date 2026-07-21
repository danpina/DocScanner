import Foundation

struct IdentifiableURL: Identifiable {
    let url: URL
    var id: URL { url }
}
