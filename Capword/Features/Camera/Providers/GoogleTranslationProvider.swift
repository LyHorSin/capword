//
//  GoogleTranslationProvider.swift
//  Capword
//
//  Created by Ly Hor Sin on 15/11/25.
//

import UIKit

/// Google Translate provider (uses v2 REST API with API key)
class GoogleTranslationProvider: ObjectDetectorAndTranslator.TranslationProvider {
    private let apiKey: String

    init(apiKey: String = License.googleTranslateApiKey) {
        self.apiKey = apiKey
    }

    func translate(_ text: String, to targetLang: String, from sourceLang: String?) async throws -> String {
        guard var comps = URLComponents(string: "https://translation.googleapis.com/language/translate/v2") else {
            throw ObjectDetectorAndTranslator.DetectionError.translationFailed(NSError(domain: "TranslateError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Google Translate URL"]))
        }
        comps.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = comps.url else {
            throw ObjectDetectorAndTranslator.DetectionError.translationFailed(NSError(domain: "TranslateError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Google Translate URL components"]))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Include bundle id header when the API key is restricted to iOS apps
        if let bundleId = Bundle.main.bundleIdentifier {
            request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }

        let body: [String: Any] = [
            "q": [text],
            "target": targetLang,
            "format": "text"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 200 {
            // OK
        } else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("❌ Google Translate API error — status: \(status), body: \(body)")
            throw ObjectDetectorAndTranslator.DetectionError.translationFailed(NSError(domain: "TranslateError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Translate API error (status: \(status))"]))
        }

        struct GoogleData: Decodable {
            struct Trans: Decodable { let translatedText: String }
            struct Root: Decodable { let translations: [Trans] }
            let data: Root
        }

        let parsed = try JSONDecoder().decode(GoogleData.self, from: data)
        if let first = parsed.data.translations.first {
            return first.translatedText
        }

        throw ObjectDetectorAndTranslator.DetectionError.translationFailed(NSError(domain: "TranslateError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google translate parsing failed"]))
    }
}
