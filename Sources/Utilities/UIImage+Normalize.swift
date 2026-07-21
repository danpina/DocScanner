import UIKit

extension UIImage {
    /// Redraws the image with orientation baked in as `.up`, so downstream
    /// pixel-space math (crop, filters) doesn't have to account for EXIF rotation.
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
