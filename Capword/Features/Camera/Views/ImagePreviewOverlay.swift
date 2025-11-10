//
//  ImagePreviewOverlay.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//
import SwiftUI
import Vision
import CoreGraphics
#if canImport(VisionKit)
import VisionKit
#endif

struct ImagePreviewOverlay: View {
    let image: UIImage
    let onRetake: () -> Void
    let onUse: () -> Void
    
    @State private var stickerImage: UIImage?
    @State private var isExtracting = false
    @State private var stickerPath: Path?
    @State private var stickerPoints: [CGPoint]? // normalized points (0..1) around contour
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: AppTheme.Constants.contentSpacing) {
                Text(currentDateString())
                    .font(AppTheme.TextStyles.header())
                    .foregroundColor(AppTheme.primary)
                
                Spacer()
                
                GeometryReader { geo in
                    HStack {
                        Spacer(minLength: 0)
                        Group {
                            if let stickerImage = stickerImage {
                                Image(uiImage: stickerImage)
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.92)
                                    .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 8)
                                    .accessibilityIdentifier("stickerImage")
                            } else {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.92)
                                    .overlay(
                                        isExtracting ? ProgressView().scaleEffect(2) : nil
                                    )
                                    .accessibilityIdentifier("sourceImage")
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
                
                HStack(alignment: .center, spacing: 80) {
                    Button(action: {
                        Vibration.fire(.impact(.soft))
                        onRetake()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.35))
                                .frame(width: 55, height: 55)
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Button(action: {
                        Vibration.fire(.impact(.medium))
                        onUse()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 66, height: 66)
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color(hex: 0x8B7FED))
                        }
                    }
                    
                    Button(action: {
                        Vibration.fire(.impact(.soft))
                        extractSticker(from: image)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.35))
                                .frame(width: 55, height: 55)
                            Image(systemName: "crop")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .paddingContent()
        }
        .transition(.opacity)
        .onAppear {
            if stickerImage == nil {
                extractSticker(from: image)
            }
        }
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: Date())
    }
    
    private func extractSticker(from image: UIImage) {
        isExtracting = true
        // Run heavy vision + mask work off the main actor to avoid UI stalls
        Task.detached {
            // Try Apple's VisionKit subject lifting (iOS 16+) - same as Photos app
            if let lifted = await self.liftWithVisionKit(image) {
                await MainActor.run {
                    self.stickerImage = lifted
                    self.isExtracting = false
                }
                return
            }
            
            // Fallback to Vision framework
            if let (lifted, path, points) = await self.maskWithVision(image) {
                await MainActor.run {
                    self.stickerImage = lifted
                    self.stickerPath = path
                    self.stickerPoints = points
                    self.isExtracting = false
                }
                return
            }
            
            await MainActor.run { self.isExtracting = false }
        }
    }
    
    private func liftWithVisionKit(_ uiImage: UIImage) async -> UIImage? {
        // VisionKit subject lifting is complex and not always available
        // Skip it and use Vision framework directly for reliable results
        return nil
    }
    
    // Fallback for iOS 16 or when VisionKit isn't supported
    private func maskWithVision(_ image: UIImage) -> (UIImage, Path, [CGPoint])? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let orientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
        do {
            try handler.perform([request])
            guard let obs = request.results?.first as? VNInstanceMaskObservation else { return nil }
            // Generate mask for all instances
            guard let maskBuffer = try? obs.generateScaledMaskForImage(forInstances: obs.allInstances, from: handler) else { return nil }
            
            // Extract contour path and points from the mask
            let (path, points) = extractContourPath(from: maskBuffer, imageSize: image.size)
            
            guard let resultImage = compositeWithMask(image: image, mask: maskBuffer) else { return nil }
            return (resultImage, path, points)
        } catch { return nil }
    }
    
    // Extract contour path from mask for animation
    private func extractContourPath(from mask: CVPixelBuffer, imageSize: CGSize) -> (Path, [CGPoint]) {
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        
        let width = CVPixelBufferGetWidth(mask)
        let height = CVPixelBufferGetHeight(mask)
        // Try to handle both contiguous and planar pixel buffers. Some pixel buffers
        // may not expose a base address directly (nil) but will have plane base addresses.
        var bytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        var baseAddress = CVPixelBufferGetBaseAddress(mask)
        
        if baseAddress == nil {
            let planes = CVPixelBufferGetPlaneCount(mask)
            print("⚠️ mask has no base address; planeCount=\(planes)")
            if planes > 0 {
                baseAddress = CVPixelBufferGetBaseAddressOfPlane(mask, 0)
                bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(mask, 0)
            }
        }
        
        guard let base = baseAddress else {
            // Diagnostic: print pixel format for debugging
            let fmt = CVPixelBufferGetPixelFormatType(mask)
            print("❌ No base address for mask (pixelFormat=\(fmt))")
            return (Path(), [])
        }
        
        let buffer = base.assumingMemoryBound(to: UInt8.self)
        var edgePoints: [CGPoint] = []
        
        // Sample edge pixels with a reasonable step for performance
        let step = max(1, min(width, height) / 200) // Sample ~200 points
        
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x
                if offset < bytesPerRow * height && buffer[offset] > 128 {
                    // Check if this pixel is on the edge
                    let hasTransparentNeighbor =
                    (x == 0 || buffer[y * bytesPerRow + max(0, x - step)] <= 128) ||
                    (x >= width - step || buffer[y * bytesPerRow + min(width - 1, x + step)] <= 128) ||
                    (y == 0 || buffer[max(0, y - step) * bytesPerRow + x] <= 128) ||
                    (y >= height - step || buffer[min(height - 1, y + step) * bytesPerRow + x] <= 128)
                    
                    if hasTransparentNeighbor {
                        let normalizedX = CGFloat(x) / CGFloat(width)
                        let normalizedY = CGFloat(y) / CGFloat(height)
                        edgePoints.append(CGPoint(x: normalizedX, y: normalizedY))
                    }
                }
            }
        }
        
        print("📍 Found \(edgePoints.count) edge points")
        
        guard !edgePoints.isEmpty else {
            print("❌ No edge points found")
            return (Path(), [])
        }
        
        // Sort points by angle from center to create a smooth contour
        let centerX = edgePoints.map { $0.x }.reduce(0, +) / CGFloat(edgePoints.count)
        let centerY = edgePoints.map { $0.y }.reduce(0, +) / CGFloat(edgePoints.count)
        
        let sortedPoints = edgePoints.sorted { p1, p2 in
            let angle1 = atan2(p1.y - centerY, p1.x - centerX)
            let angle2 = atan2(p2.y - centerY, p2.x - centerX)
            return angle1 < angle2
        }
        
        // Create path from sorted points
        var path = Path()
        if !sortedPoints.isEmpty {
            path.move(to: sortedPoints[0])
            for i in 1..<sortedPoints.count {
                path.addLine(to: sortedPoints[i])
            }
            path.closeSubpath()
            print("✅ Created path with \(sortedPoints.count) points")
        }
        
        return (path, sortedPoints)
    }
    
    // Same composite helper you used (preserves color, removes background)
    fileprivate func compositeWithMask(image: UIImage, mask: CVPixelBuffer) -> UIImage? {
        // Create a CIImage from the UIImage and apply its orientation so the CI pipeline
        // works in the same visual coordinate space as the original image. The final
        // CGImage we get back from the context will already be upright, so we return
        // a UIImage with orientation `.up` to avoid double-rotation.
        guard let input = CIImage(image: image) else { return nil }
        let imgOrientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        // Apply orientation to the input so `extent` and pixel coordinates match what
        // Vision produced when we asked with the same orientation earlier.
        let orientedInput = input.oriented(forExifOrientation: Int32(imgOrientation.rawValue))
        
        var maskCI = CIImage(cvPixelBuffer: mask)
        // If the mask and the input sizes differ, scale the mask into the oriented input space
        if maskCI.extent.size != orientedInput.extent.size {
            let sx = orientedInput.extent.width / max(maskCI.extent.width, 1)
            let sy = orientedInput.extent.height / max(maskCI.extent.height, 1)
            maskCI = maskCI.transformed(by: .init(scaleX: sx, y: sy))
        }
        
        let clearBG = CIImage(color: .clear).cropped(to: orientedInput.extent)
        let composed = orientedInput.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: clearBG,
            kCIInputMaskImageKey: maskCI
        ])
        
        // Reuse a shared CIContext to avoid repeated heavy context creation
        let ctx = ImageProcessing.sharedCIContext
        guard let out = ctx.createCGImage(composed, from: orientedInput.extent) else { return nil }
        // `out` is already rendered in the correct (upright) orientation. Return as `.up`.
        return UIImage(cgImage: out, scale: image.scale, orientation: .up)
    }
    
    // Your existing 200×200 renderer is fine
    fileprivate func renderToSquare(_ image: UIImage, side: CGFloat) -> UIImage {
        let canvas = CGSize(width: side, height: side)
        let scale = min(side / image.size.width, side / image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (canvas.width - drawSize.width) * 0.5, y: (canvas.height - drawSize.height) * 0.5)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = image.scale
        fmt.opaque = false
        return UIGraphicsImageRenderer(size: canvas, format: fmt).image { _ in
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }

    /// Render a new `UIImage` clipped to `path` with an optional border drawn on top.
    /// - Parameters:
    ///   - image: source image to draw
    ///   - size: target output size in points
    ///   - path: a `UIBezierPath` describing the shape (in output coordinates)
    ///   - borderColor: color for the border stroke
    ///   - borderWidth: stroke width in points
    ///   - contentMode: how the image is placed into the shape (defaults to scaleAspectFill)
    fileprivate func renderShapedImage(_ image: UIImage,
                                      size: CGSize,
                                      path: UIBezierPath,
                                      borderColor: UIColor = .white,
                                      borderWidth: CGFloat = 3,
                                      contentMode: UIView.ContentMode = .scaleAspectFill) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)

            // Save context state
            ctx.cgContext.saveGState()

            // Clip to the provided path
            path.addClip()

            // Compute image drawing rect based on contentMode
            let imgRect: CGRect = {
                switch contentMode {
                case .scaleAspectFill:
                    let i = image.size
                    let s = max(rect.width / max(1, i.width), rect.height / max(1, i.height))
                    let w = i.width * s, h = i.height * s
                    return CGRect(x: rect.midX - w/2, y: rect.midY - h/2, width: w, height: h)
                case .scaleAspectFit:
                    let i = image.size
                    let s = min(rect.width / max(1, i.width), rect.height / max(1, i.height))
                    let w = i.width * s, h = i.height * s
                    return CGRect(x: rect.midX - w/2, y: rect.midY - h/2, width: w, height: h)
                default:
                    return rect
                }
            }()

            // Draw image into clipped area
            image.draw(in: imgRect)

            // Restore before stroking (stroke should not be clipped by fill)
            ctx.cgContext.restoreGState()

            // Stroke the path on top
            borderColor.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
        }
    }
}

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

