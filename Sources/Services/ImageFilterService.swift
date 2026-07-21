import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum ImageFilterService {
    private static let context = CIContext()

    static func apply(_ filter: PageFilter, to image: UIImage) -> UIImage {
        guard filter != .original, let ciImage = CIImage(image: image) else { return image }

        let output: CIImage?
        switch filter {
        case .original:
            return image

        case .grayscale:
            let desaturate = CIFilter.colorControls()
            desaturate.inputImage = ciImage
            desaturate.saturation = 0
            desaturate.contrast = 1.05
            output = desaturate.outputImage

        case .blackAndWhite:
            let mono = CIFilter.colorMonochrome()
            mono.inputImage = ciImage
            mono.color = CIColor(red: 1, green: 1, blue: 1)
            mono.intensity = 1
            let boosted = CIFilter.colorControls()
            boosted.inputImage = mono.outputImage
            boosted.contrast = 1.8
            boosted.brightness = 0.05
            output = boosted.outputImage
        }

        guard let output, let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage)
    }
}
