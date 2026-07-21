import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Lets the user drag the four corners of a quad over the scanned image,
/// then applies a perspective correction so the result looks flat/rectangular
/// — the same interaction Microsoft Lens uses for manual re-cropping.
struct CropView: View {
    let image: UIImage
    var onCancel: () -> Void
    var onDone: (UIImage) -> Void

    @State private var corners: [CGPoint] = []
    @State private var containerSize: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack {
                    Color.black
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .overlay(CropOverlay(corners: $corners, containerSize: geo.size))
                }
                .onAppear {
                    containerSize = geo.size
                    if corners.isEmpty {
                        corners = Self.defaultCorners(imageSize: image.size, containerSize: geo.size)
                    }
                }
            }

            HStack {
                Button("Cancel", role: .cancel) { onCancel() }
                Spacer()
                Button("Reset") {
                    corners = Self.defaultCorners(imageSize: image.size, containerSize: containerSize)
                }
                Spacer()
                Button("Done") {
                    let cropped = Self.applyCrop(to: image, corners: corners, containerSize: containerSize)
                    onDone(cropped ?? image)
                }
                .fontWeight(.bold)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }

    private static func imageDisplayRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else { return .zero }
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2
        )
        return CGRect(origin: origin, size: size)
    }

    private static func defaultCorners(imageSize: CGSize, containerSize: CGSize) -> [CGPoint] {
        let rect = imageDisplayRect(imageSize: imageSize, containerSize: containerSize)
        guard rect.width > 0, rect.height > 0 else { return [] }
        let dx = rect.width * 0.04
        let dy = rect.height * 0.04
        return [
            CGPoint(x: rect.minX + dx, y: rect.minY + dy), // top-left
            CGPoint(x: rect.maxX - dx, y: rect.minY + dy), // top-right
            CGPoint(x: rect.maxX - dx, y: rect.maxY - dy), // bottom-right
            CGPoint(x: rect.minX + dx, y: rect.maxY - dy)  // bottom-left
        ]
    }

    private static func applyCrop(to image: UIImage, corners: [CGPoint], containerSize: CGSize) -> UIImage? {
        guard corners.count == 4, let cgImage = image.cgImage else { return nil }
        let displayRect = imageDisplayRect(imageSize: image.size, containerSize: containerSize)
        guard displayRect.width > 0, displayRect.height > 0 else { return nil }

        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)

        // Core Image's coordinate space has its origin at the bottom-left,
        // the opposite of UIKit's top-left — flip Y when converting.
        func toPixelPoint(_ p: CGPoint) -> CGPoint {
            let nx = min(max((p.x - displayRect.minX) / displayRect.width, 0), 1)
            let ny = min(max((p.y - displayRect.minY) / displayRect.height, 0), 1)
            return CGPoint(x: nx * pixelWidth, y: (1 - ny) * pixelHeight)
        }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = CIImage(cgImage: cgImage)
        filter.topLeft = toPixelPoint(corners[0])
        filter.topRight = toPixelPoint(corners[1])
        filter.bottomRight = toPixelPoint(corners[2])
        filter.bottomLeft = toPixelPoint(corners[3])

        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        guard let outputCG = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: outputCG)
    }
}
