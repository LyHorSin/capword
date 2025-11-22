//
//  ObjectDetectorAndTranslator.swift
//  Capword
//
//  Created by Ly Hor Sin on 14/11/25.
//

import Foundation
import Vision
import UIKit
import CoreML
import NaturalLanguage


class ObjectDetectorAndTranslator {

    enum DetectionError: Error {
        case invalidImage
        case detectionFailed(Error)
        case translationFailed(Error)
        case noObjectsDetected
    }
    
    /// Get the device's system language code (e.g., "en", "zh", "es")
    private static func getSystemLanguageCode() -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? "en"
        return languageCode
    }
    
    /// Pluggable translation provider protocol. Implement this to integrate any translation backend
    protocol TranslationProvider {
        /// Translate a single piece of text from source (if known) to target language code (ISO)
        func translate(_ text: String, to targetLang: String, from sourceLang: String?) async throws -> String
    }

    /// Default provider — currently an empty Azure provider placeholder. Swap this out at app startup with a network provider or an on-device provider when available.
    static var translationProvider: TranslationProvider = GoogleTranslationProvider()

    // MARK: - Google Translate provider

    /// Configure Google Translate provider using an API key (v2 REST API)
    /// NOTE: For production, do not hardcode API keys in your app binary. Prefer fetching keys/tokens from a secure server.
    static func configureGoogleProvider(apiKey: String) {
        translationProvider = GoogleTranslationProvider(apiKey: apiKey)
    }
    
    // MARK: - Google Cloud Vision API for Object Detection
    
    /// Detect objects using Google Cloud Vision API and translate
    static func detectAndTranslateWithGoogleVision(
        image: UIImage,
        targetLanguageCodes: [String]
    ) async throws -> [String: [String: String]] {
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw DetectionError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()
        
        // Call Google Cloud Vision API
        let labels = try await detectWithGoogleVision(base64Image: base64Image)
        
        guard let firstLabel = labels.first else {
            throw DetectionError.noObjectsDetected
        }
        
        // Translate the detected object
        var finalResults: [String: [String: String]] = [:]
        finalResults[firstLabel] = try await translateLabel(firstLabel, to: targetLanguageCodes)
        
        return finalResults
    }
    
    /// Call Google Cloud Vision API for label detection
    private static func detectWithGoogleVision(base64Image: String) async throws -> [String] {
        let apiKey = License.googleCloudVisionApiKey // Reuse the same API key
        let systemLanguage = getSystemLanguageCode()
        
        guard let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)") else {
            throw DetectionError.detectionFailed(NSError(domain: "VisionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Google Vision URL"]))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let bundleId = Bundle.main.bundleIdentifier {
            request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        
        let body: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [
                        ["type": "LABEL_DETECTION", "maxResults": 5]
                    ],
                    "imageContext": [
                        "languageHints": [systemLanguage]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let status = http.statusCode
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("❌ Google Vision API error — status: \(status), body: \(body)")
            throw DetectionError.detectionFailed(NSError(domain: "VisionError", code: status, userInfo: [NSLocalizedDescriptionKey: "Google Vision API error (status: \(status))"]))
        }
        
        struct VisionResponse: Decodable {
            struct Response: Decodable {
                struct LabelAnnotation: Decodable {
                    let description: String
                    let score: Double
                }
                let labelAnnotations: [LabelAnnotation]?
            }
            let responses: [Response]
        }
        
        let parsed = try JSONDecoder().decode(VisionResponse.self, from: data)
        
        guard let labels = parsed.responses.first?.labelAnnotations, !labels.isEmpty else {
            throw DetectionError.noObjectsDetected
        }
        
        // Return top labels with confidence > 0.7
        let topLabels = labels
            .filter { $0.score > 0.7 }
            .sorted(by: { $0.score > $1.score })
            .prefix(3)
            .map { $0.description.lowercased() }
        
        print("✅ Google Vision detected (lang: \(systemLanguage)): \(topLabels)")
        
        return Array(topLabels)
    }

    /// Advanced translateLabel: detects source language, then translates concurrently using the configured provider.
    private static func translateLabel(
        _ label: String,
        to targetLanguageCodes: [String]
    ) async throws -> [String: String] {

        var translations: [String: String] = [:]

        // Detect probable source language (may be weak for single words)
        var detectedLang: String? = nil
        if #available(iOS 12.0, *) {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(label)
            if let lang = recognizer.dominantLanguage?.rawValue {
                detectedLang = lang
                // Convert to ISO short codes if necessary (e.g., "en" stays "en")
            }
        }

        // Translate concurrently to all target languages
        try await withThrowingTaskGroup(of: (String, String).self) { group in
            for langCode in targetLanguageCodes {
                group.addTask {
                    do {
                        let translated = try await translationProvider.translate(label, to: langCode, from: detectedLang)
                        return (langCode, translated)
                    } catch {
                        // Rethrow to be handled by outer catch
                        throw error
                    }
                }
            }

            for try await (lang, translated) in group {
                translations[lang] = translated
                print("✅ Translated '\(label)' to '\(translated)' (\(lang))")
            }
        }

        return translations
    }

    // MARK: - Generic model support

    /// Detect and translate using a specific model resource name (without extension)
    /// Example: `detectAndTranslateWithModel(named: "yolov8n", image: img, targetLanguageCodes: ["es"])`
    static func detectAndTranslateWithModel(
        named modelName: String,
        image: UIImage,
        targetLanguageCodes: [String]
    ) async throws -> [String: [String: String]] {

        guard let cgImage = image.cgImage else {
            throw DetectionError.invalidImage
        }

        // Load the requested model
        let mlModel = try loadMLModel(named: modelName)

        // Run Vision detection and get label strings
        let labels = try await runVisionDetection(with: mlModel, cgImage: cgImage)
        
        var finalResults: [String: [String: String]] = [:]
        if let first = labels.first {
            finalResults[first] = try await translateLabel(first, to: targetLanguageCodes)
        }
        return finalResults
    }

    /// Load an MLModel from bundle by trying common resource forms for the given base name
    private static func loadMLModel(named modelName: String) throws -> MLModel {
        var loadedModel: MLModel?

        // 1) plain mlmodel (many users add .mlmodel files directly)
        if let simpleURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
            loadedModel = try? MLModel(contentsOf: simpleURL)
            if loadedModel != nil {
                print("✅ Loaded .mlmodel at: \(simpleURL.path)")
            }
        }

        // 2) mlpackage inner model
        if loadedModel == nil, let packageURL = Bundle.main.url(forResource: modelName, withExtension: "mlpackage") {
            let innerModelURL = packageURL.appendingPathComponent("Data/com.apple.CoreML/model.mlmodel")
            if FileManager.default.fileExists(atPath: innerModelURL.path) {
                loadedModel = try? MLModel(contentsOf: innerModelURL)
                if loadedModel != nil {
                    print("✅ Loaded model from mlpackage inner path: \(innerModelURL.path)")
                }
            }

            if loadedModel == nil {
                loadedModel = try? MLModel(contentsOf: packageURL)
                if loadedModel != nil {
                    print("✅ Loaded MLModel directly from mlpackage at: \(packageURL.path)")
                }
            }
        }

        // 3) compiled model (.mlmodelc)
        if loadedModel == nil, let compiledURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
            loadedModel = try? MLModel(contentsOf: compiledURL)
            if loadedModel != nil {
                print("✅ Loaded compiled model (.mlmodelc) at: \(compiledURL.path)")
            }
        }

        if let mlModel = loadedModel {
            return mlModel
        }

        throw DetectionError.detectionFailed(NSError(domain: "ModelError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model \(modelName) not found in bundle"]))
    }

    /// Run Vision object detection and return up to 3 unique label strings
    private static func runVisionDetection(with mlModel: MLModel, cgImage: CGImage) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let vnModel = try VNCoreMLModel(for: mlModel)
                let request = VNCoreMLRequest(model: vnModel) { request, error in
                    if let error = error {
                        continuation.resume(throwing: DetectionError.detectionFailed(error))
                        return
                    }

                    // Handle object-detection-style results first — return only the single highest-confidence label
                    if let objResults = request.results as? [VNRecognizedObjectObservation], !objResults.isEmpty {
                        // Sort by confidence descending
                        let sorted = objResults.sorted(by: { $0.confidence > $1.confidence })

                        if let topObs = sorted.first, topObs.confidence > 0.3, let topLabel = topObs.labels.first {
                            let cleanLabel = topLabel.identifier.lowercased()
                            continuation.resume(returning: [cleanLabel])
                            return
                        }
                        // If top observation below threshold, treat as no useful detection and fall through
                    }

                    // If not object detections, handle classification results (common for MobileNet-style models)
                    if let classResults = request.results as? [VNClassificationObservation], !classResults.isEmpty {
                        // Lower threshold for classifiers and take top 3
                        let filtered = classResults
                            .filter { $0.confidence > 0.05 }
                            .sorted(by: { $0.confidence > $1.confidence })

                        var uniqueResults: [String] = []
                        var seen: Set<String> = []
                        for c in filtered {
                            let cleanLabel = c.identifier.lowercased()
                            if !seen.contains(cleanLabel) {
                                seen.insert(cleanLabel)
                                uniqueResults.append(cleanLabel)
                            }
                            if uniqueResults.count >= 3 { break }
                        }

                        continuation.resume(returning: uniqueResults)
                        return
                    }

                    // No recognized results we can use
                    continuation.resume(throwing: DetectionError.noObjectsDetected)
                }
                request.imageCropAndScaleOption = .centerCrop
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DetectionError.detectionFailed(error))
            }
        }
    }
}

