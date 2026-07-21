import UIKit

enum PDFGenerator {
    // US Letter at 72pt/inch — a reasonable default for exported scans.
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 24

    static func makePDF(from pages: [ScanPage]) -> Data {
        let pageRect = CGRect(origin: .zero, size: pageSize)

        var metadata = [String: Any]()
        metadata[kCGPDFContextCreator as String] = "DocScanner"
        metadata[kCGPDFContextTitle as String] = "Scanned Document"

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = metadata

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            for page in pages {
                context.beginPage()
                let image = page.filteredImage
                let bounds = pageRect.insetBy(dx: margin, dy: margin)
                let imageRect = aspectFitRect(for: image.size, in: bounds)
                image.draw(in: imageRect)
            }
        }
    }

    private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: bounds.minX + (bounds.width - size.width) / 2,
            y: bounds.minY + (bounds.height - size.height) / 2
        )
        return CGRect(origin: origin, size: size)
    }
}
