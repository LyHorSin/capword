//
//  Extensions.swift
//  Capword
//
//  Small handy extensions used across the app.
//

import Foundation
import SwiftUI

extension String {
    var trimmed: String { self.trimmingCharacters(in: .whitespacesAndNewlines) }
}

extension View {
    func hidden(_ hidden: Bool) -> some View {
        modifier(HiddenModifier(isHidden: hidden))
    }
}

private struct HiddenModifier: ViewModifier {
    let isHidden: Bool
    func body(content: Content) -> some View {
        Group {
            if isHidden { content.hidden() } else { content }
        }
    }
}
