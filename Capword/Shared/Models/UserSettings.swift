//
//  UserSettings.swift
//  Capword
//
//  Manages user preferences and settings across the app.
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        }
    }
    
    /// Available languages with their flag emoji
    let availableLanguages: [(name: String, flag: String)] = [
        ("Chinese", "🇨🇳"),
        ("French", "🇫🇷"),
        ("Spanish", "🇪🇸"),
        ("Japanese", "🇯🇵")
    ]
    
    private init() {
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "Chinese"
    }
    
    /// Get the flag emoji for a language name
    func getFlagForLanguage(_ language: String) -> String {
        return availableLanguages.first(where: { $0.name == language })?.flag ?? "🇨🇳"
    }
    
    /// Get the ISO language code for translation API
    func getLanguageCode() -> String {
        switch selectedLanguage {
        case "Chinese": return "zh"
        case "English", "English (British)": return "en"
        case "French": return "fr"
        case "Spanish": return "es"
        case "Japanese": return "ja"
        default: return "zh"
        }
    }
    
    /// Get the speech language code with locale (for TextToSpeech)
    func getSpeechLanguageCode() -> String {
        switch selectedLanguage {
        case "Chinese": return "zh-CN"
        case "English": return "en-US"
        case "English (British)": return "en-GB"
        case "French": return "fr-FR"
        case "Spanish": return "es-ES"
        case "Japanese": return "ja-JP"
        default: return "zh-CN"
        }
    }
}
