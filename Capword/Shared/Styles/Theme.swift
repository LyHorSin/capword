//
//  Theme.swift
//  Capword
//
//  Created by assistant on 8/11/25.
//

import SwiftUI
import UIKit

extension Color {
    /// Init with hex integer, e.g. Color(hex: 0xFF0000)
    init(hex: UInt, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

enum AppTheme {
    // Backgrounds
    static let background = Color(hex: 0xF4F4F4) // very light gray
    static let card = Color(hex: 0xE8E8E8) // slightly darker card

    // Primary text
    static let primary = Color(hex: 0x222222) // deep navy/ink
    static let secondary = Color(hex: 0x767676) // muted gray

    // Accent / brand
    static let accent = Color(hex: 0xF7B500) // warm mustard/yellow
    static let accentMuted = Color(hex: 0xCDA88A) // warm beige/tan

    // Pastel ring colors (used for the circular ring)
    static let pastelBlue = Color(hex: 0xB8E1FF)
    static let pastelPurple = Color(hex: 0xFEC6EB)
    static let pastelPink = Color(hex: 0xEBF51A)
    static let pastelGreen = Color(hex: 0x9ADBB9)
    static let pastelYellow = Color(hex: 0xB4B1E8)

    // Constants for spacing, font family names and sizes
    struct Constants {
        // Spacing / padding
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 24
        static let contentSpacing: CGFloat = 24

        // Font families (update with actual bundled font names if available)
        static let primarySerifFontName: String = "Georgia"
        static let primarySansFontName: String = "HelveticaNeue"

        // Standard sizes
        struct FontSize {
            static let largeTitle: CGFloat = 44
            static let title: CGFloat = 28
            static let subtitle: CGFloat = 20
            static let body: CGFloat = 16
            static let caption: CGFloat = 13
        }
    }

    // Named text styles for consistent typography usage across the app
    struct TextStyles {

        static func header() -> SwiftUI.Font {
            // Prefer custom serif family if available, otherwise system serif
            if UIFont(name: Constants.primarySerifFontName, size: Constants.FontSize.largeTitle) != nil {
                return SwiftUI.Font.custom(Constants.primarySerifFontName, size: Constants.FontSize.largeTitle)
            }
            return SwiftUI.Font.system(size: Constants.FontSize.largeTitle, weight: SwiftUI.Font.Weight.semibold, design: .serif)
        }

        static func title() -> SwiftUI.Font {
            if UIFont(name: Constants.primarySerifFontName, size: Constants.FontSize.title) != nil {
                return SwiftUI.Font.custom(Constants.primarySerifFontName, size: Constants.FontSize.title)
            }
            return SwiftUI.Font.system(size: Constants.FontSize.title, weight: SwiftUI.Font.Weight.semibold, design: .serif)
        }

        static func subtitle() -> SwiftUI.Font {
            if UIFont(name: Constants.primarySerifFontName, size: Constants.FontSize.subtitle) != nil {
                return SwiftUI.Font.custom(Constants.primarySerifFontName, size: Constants.FontSize.subtitle)
            }
            return SwiftUI.Font.system(size: Constants.FontSize.subtitle, weight: SwiftUI.Font.Weight.regular, design: .serif)
        }

        static func body() -> SwiftUI.Font {
            if UIFont(name: Constants.primarySansFontName, size: Constants.FontSize.body) != nil {
                return SwiftUI.Font.custom(Constants.primarySansFontName, size: Constants.FontSize.body)
            }
            return SwiftUI.Font.system(size: Constants.FontSize.body, weight: SwiftUI.Font.Weight.regular, design: .default)
        }

        static func caption() -> SwiftUI.Font {
            if UIFont(name: Constants.primarySansFontName, size: Constants.FontSize.caption) != nil {
                return SwiftUI.Font.custom(Constants.primarySansFontName, size: Constants.FontSize.caption)
            }
            return SwiftUI.Font.system(size: Constants.FontSize.caption, weight: SwiftUI.Font.Weight.regular, design: .default)
        }
    }

    // Card style view modifier
    struct CardStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, AppTheme.Constants.horizontalPadding)
                .padding(.vertical, AppTheme.Constants.verticalPadding)
                .background(AppTheme.card)
                .cornerRadius(AppTheme.Constants.cornerRadius)
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
        }
    }

    // Accent pill style
    struct AccentPill: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, AppTheme.Constants.horizontalPadding)
                .padding(.vertical, AppTheme.Constants.verticalPadding)
                .background(AppTheme.accent)
                .cornerRadius(AppTheme.Constants.cornerRadius)
                .foregroundColor(.white)
        }
    }
    
    struct ContentView: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, AppTheme.Constants.horizontalPadding)
                .padding(.vertical, AppTheme.Constants.verticalPadding)
        }
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppTheme.CardStyle())
    }

    func accentPillStyle() -> some View {
        modifier(AppTheme.AccentPill())
    }
    
    func paddingContent() -> some View {
        modifier(AppTheme.ContentView())
    }
}
