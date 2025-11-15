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
    
    // Object detection and translation
    @State private var detectedObject: String?
    @State private var translations: [String: String] = [:]
    @State private var isDetecting = false
    
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
                                VStack(spacing: 16) {
                                    Image(uiImage: stickerImage)
                                        .resizable()
                                        .interpolation(.high)
                                        .antialiased(true)
                                        .scaledToFit()
                                        .frame(width: geo.size.width * 0.92)
                                        .shadow(color: .black.opacity(0.42), radius: 18, x: 0, y: 8)
                                        .accessibilityIdentifier("stickerImage")
                                    
                                    // Object detection results
                                    if isDetecting {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Detecting object...")
                                                .font(AppTheme.TextStyles.body())
                                                .foregroundColor(AppTheme.secondary)
                                        }
                                    } else if let objectName = detectedObject {
                                        VStack(spacing: 12) {
                                            // English object name
                                            Text(objectName.capitalized)
                                                .font(AppTheme.TextStyles.title())
                                                .foregroundColor(AppTheme.primary)
                                                .multilineTextAlignment(.center)
                                                .bold()
                                        }
                                    }
                                }
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
    
    // MARK: - Object Detection and Translation
    
    private func detectAndTranslateObject(_ image: UIImage) async {
        await MainActor.run {
            self.isDetecting = true
            self.detectedObject = nil
            self.translations = [:]
        }
        
        do {
            let targetLanguages = ["zh"] // Spanish, French, Japanese, Chinese
            let results = try await ObjectDetectorAndTranslator.detectAndTranslateWithModel(
                named: "MobileNetV2",
                image: image,
                targetLanguageCodes: targetLanguages
            )
            
            // Get the first detected object with highest confidence
            if let firstObject = results.keys.first {
                let objectTranslations = results[firstObject] ?? [:]
                
                await MainActor.run {
                    self.detectedObject = firstObject
                    self.translations = objectTranslations
                    self.isDetecting = false
                }
            } else {
                await MainActor.run {
                    self.isDetecting = false
                }
            }
        } catch {
            print("❌ Object detection failed: \(error)")
            await MainActor.run {
                self.isDetecting = false
            }
        }
    }
    
    private func extractSticker(from image: UIImage) {
        isExtracting = true
        // Run heavy vision + mask work off the main actor to avoid UI stalls
        Task.detached {
            // Fallback to Vision framework
            if let (lifted, path, points) = await self.maskWithVision(image) {
                await MainActor.run {
                    self.stickerImage = lifted
                    self.stickerPath = path
                    self.stickerPoints = points
                    self.isExtracting = false
                }
                
                // Start object detection after sticker extraction
                await self.detectAndTranslateObject(lifted)
                return
            }
            
            await MainActor.run { self.isExtracting = false }
        }
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
    
    /// Returns a sticker (foreground cut-out) with an outline border.
    /// - Parameters:
    ///   - image: Source image
    ///   - mask: 1-channel mask (foreground=white), same orientation used when produced
    ///   - borderWidth: outline thickness in points
    ///   - borderColor: outline color
    ///   - edgeSoftness: small blur (points) to slightly soften the edge; set 0 for crisp
    fileprivate func compositeWithMask(
        image: UIImage,
        mask: CVPixelBuffer,
        borderWidth: CGFloat = 32,
        borderColor: UIColor = .white,
        edgeSoftness: CGFloat = 2
    ) -> UIImage? {

        // 1) Oriented input CIImage (so CI extent/coords match what Vision used)
        guard let input = CIImage(image: image) else { return nil }
        let imgOrientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        let orientedInput = input.oriented(forExifOrientation: Int32(imgOrientation.rawValue))

        // 2) Bring mask into the same oriented/scale space as the input
        var maskCI = CIImage(cvPixelBuffer: mask)
        if maskCI.extent.size != orientedInput.extent.size {
            let sx = orientedInput.extent.width / max(maskCI.extent.width, 1)
            let sy = orientedInput.extent.height / max(maskCI.extent.height, 1)
            maskCI = maskCI.transformed(by: .init(scaleX: sx, y: sy))
        }
        maskCI = maskCI.cropped(to: orientedInput.extent)

        // 3) Build the cut-out sticker (transparent background, foreground from image by mask)
        let clearBG = CIImage(color: .clear).cropped(to: orientedInput.extent)
        let cutout = orientedInput.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: clearBG,
            kCIInputMaskImageKey: maskCI
        ])

        // 4) Create a **thick halo mask** by dilating the original mask.
        //    borderWidth is in points; convert to pixels.
        let pxScale = max(image.scale, 1)
        let borderPx = max(1, borderWidth * pxScale)

        guard let dilate = CIFilter(name: "CIMorphologyMaximum") else { return nil }
        dilate.setValue(maskCI, forKey: kCIInputImageKey)
        dilate.setValue(borderPx, forKey: kCIInputRadiusKey)
        var haloMask = dilate.outputImage?.cropped(to: orientedInput.extent) ?? maskCI

        // Optional: soften the outer edge of the halo
        if edgeSoftness > 0 {
            let blurPx = edgeSoftness * pxScale
            let blurred = haloMask.applyingFilter("CIBoxBlur", parameters: [kCIInputRadiusKey: blurPx])
            haloMask = blurred.cropped(to: orientedInput.extent)
        }

        // 5) Paint the border color into the halo mask
        let borderCIColor = CIColor(color: borderColor)
        let borderColorImage = CIImage(color: borderCIColor).cropped(to: orientedInput.extent)
        let borderLayer = borderColorImage.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: clearBG,
            kCIInputMaskImageKey: haloMask
        ])

        // 6) Composite final: sticker (original mask) on top of thick colored halo
        let final = cutout.composited(over: borderLayer)

        // 7) Render with your shared CIContext
        let ctx = ImageProcessing.sharedCIContext
        guard let cg = ctx.createCGImage(final, from: orientedInput.extent) else { return nil }
        return UIImage(cgImage: cg, scale: image.scale, orientation: .up)
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

