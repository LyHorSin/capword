//
//  ImageProcessing.swift
//  Capword
//
//  Created by Ly Hor Sin on 15/11/25.
//

import UIKit

enum ImageProcessing {
    static let sharedCIContext: CIContext = {
        let opts: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,
            .cacheIntermediates: true
        ]
        return CIContext(options: opts)
    }()
}


extension CGImagePropertyOrientation {
    init(uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

extension UIImage {
    /// Crops the image to the bounding box of non-transparent pixels.
    /// - parameter paddingPoints: extra padding around content, in points.
    func croppedToNonTransparent(paddingPoints: CGFloat = 0) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: Int(height * bytesPerRow))

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0

        // Find bounding box where alpha > 0
        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + x * bytesPerPixel
                let alpha = pixelData[index + 3]
                if alpha > 0 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        // If nothing non-transparent found, just return self
        if minX > maxX || minY > maxY {
            return self
        }

        // Add padding (in pixels)
        let paddingPx = Int(paddingPoints * self.scale)
        minX = max(minX - paddingPx, 0)
        minY = max(minY - paddingPx, 0)
        maxX = min(maxX + paddingPx, width - 1)
        maxY = min(maxY + paddingPx, height - 1)

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        guard let croppedCG = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedCG, scale: self.scale, orientation: self.imageOrientation)
    }
}
