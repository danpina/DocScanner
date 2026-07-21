import UIKit

enum PageFilter: String, CaseIterable, Identifiable {
    case original = "Original"
    case grayscale = "Grayscale"
    case blackAndWhite = "Black & White"

    var id: String { rawValue }
}

struct ScanPage: Identifiable {
    let id: UUID
    var originalImage: UIImage
    var filter: PageFilter

    init(id: UUID = UUID(), originalImage: UIImage, filter: PageFilter = .original) {
        self.id = id
        self.originalImage = originalImage
        self.filter = filter
    }

    var filteredImage: UIImage {
        ImageFilterService.apply(filter, to: originalImage)
    }
}
