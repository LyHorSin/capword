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
        ("Spanish", "🇪🇸"),
        ("French", "🇫🇷"),
        ("German", "🇩🇪"),
        ("Italian", "🇮🇹"),
        ("Japanese", "🇯🇵"),
        ("Korean", "🇰🇷"),
        ("Portuguese", "🇵🇹"),
        ("Russian", "🇷🇺"),
        ("Arabic", "🇸🇦"),
        ("Hindi", "🇮🇳"),
        ("Dutch", "🇳🇱"),
        ("Turkish", "🇹🇷"),
        ("Polish", "🇵🇱"),
        ("Vietnamese", "🇻🇳")
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
        case "Spanish": return "es"
        case "French": return "fr"
        case "German": return "de"
        case "Italian": return "it"
        case "Japanese": return "ja"
        case "Korean": return "ko"
        case "Portuguese": return "pt"
        case "Russian": return "ru"
        case "Arabic": return "ar"
        case "Hindi": return "hi"
        case "Dutch": return "nl"
        case "Turkish": return "tr"
        case "Polish": return "pl"
        case "Vietnamese": return "vi"
        default: return "zh"
        }
    }
    
    /// Get the speech language code with locale (for TextToSpeech)
    func getSpeechLanguageCode() -> String {
        switch selectedLanguage {
        case "Chinese": return "zh-CN"
        case "Spanish": return "es-ES"
        case "French": return "fr-FR"
        case "German": return "de-DE"
        case "Italian": return "it-IT"
        case "Japanese": return "ja-JP"
        case "Korean": return "ko-KR"
        case "Portuguese": return "pt-PT"
        case "Russian": return "ru-RU"
        case "Arabic": return "ar-SA"
        case "Hindi": return "hi-IN"
        case "Dutch": return "nl-NL"
        case "Turkish": return "tr-TR"
        case "Polish": return "pl-PL"
        case "Vietnamese": return "vi-VN"
        default: return "zh-CN"
        }
    }
}
