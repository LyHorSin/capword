//
//  AnalyticsManager.swift
//  Capword
//
//  Analytics / telemetry integration point.
//

import Foundation

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {}

    func track(event: String, properties: [String: Any]? = nil) {
        // Integrate with analytics SDKs here
    }
}
