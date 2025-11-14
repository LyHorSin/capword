//
//  ObjectDetectorAndTranslator.swift
//  Capword
//
//  Created by Ly Hor Sin on 14/11/25.
//

import Foundation
import Vision
import UIKit

/// A robust module for detecting objects and translating their labels.
class ObjectDetectorAndTranslator {
    
    enum DetectionError: Error {
        case invalidImage
        case detectionFailed(Error)
        case translationFailed(Error)
        case noObjectsDetected
    }
    
    /// Detects objects in a UIImage and translates labels into specified languages.
    ///
    /// - Parameters:
    ///   - image: The input image (UIImage).
    ///   - targetLanguageCodes: Array of standard language codes (e.g., ["es", "fr", "ja"]).
    /// - Returns: A dictionary of English labels mapping to a dictionary of translations.
    static func detectAndTranslate(
        image: UIImage,
        targetLanguageCodes: [String]
    ) async throws -> [String: [String: String]] {
        
        guard let ciImage = CIImage(image: image) else {
            throw DetectionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Use VNCoreMLModel for a specific, pre-trained model (e.g., MobileNetV2-SSD)
            // For general objects, we rely on the built-in VNImageBasedRequest subclasses.
            
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: DetectionError.detectionFailed(error))
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: DetectionError.noObjectsDetected)
                    return
                }
                
                // Process results asynchronously after detection finishes
                Task {
                    do {
                        let uniqueLabels = Set(results.map { $0.identifier.split(separator: ",").first!.trimmingCharacters(in: .whitespaces) })
                        var finalResults: [String: [String: String]] = [:]
                        
                        for label in uniqueLabels {
                            finalResults[label] = try await translateLabel(label, to: targetLanguageCodes)
                        }
                        continuation.resume(returning: finalResults)
                    } catch {
                        continuation.resume(throwing: error) // Forward translation errors
                    }
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DetectionError.detectionFailed(error))
            }
        }
    }
    
    /// Helper function to handle translations using Apple's built-in NLP services.
    private static func translateLabel(
        _ label: String,
        to targetLanguageCodes: [String]
    ) async throws -> [String: String] {
        
        var translations: [String: String] = [:]
        
        // This leverages the system's translation service. It requires an internet connection
        // and may fail if the device is offline or the service is unavailable.
        for langCode in targetLanguageCodes {
            // NSLinguisticTagger can detect languages, but we need translation service here
            // For a robust app, you would integrate a cloud API (like Google Translate API via a URLSession)
            // but this placeholder demonstrates the async structure.
            
            // NOTE: A real translation API call goes here.
            // We simulate it for modularity demonstration:
            // let translatedText = try await performAPITranslation(text: label, target: langCode)
            let translatedText = "Translated \(label) in \(langCode)" // Placeholder
            translations[langCode] = translatedText
        }
        return translations
    }
}
