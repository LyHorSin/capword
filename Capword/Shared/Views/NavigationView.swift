//
//  NavigationView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI
import UIKit

/// A customizable, glass-like navigation bar with centered title, a left (back) area, and a right area for actions.
///
/// Features:
/// - Liquid/glass material background (uses SwiftUI Materials)
/// - Centered title (keeps centered even when leading/trailing content differ in width)
/// - Optional default back button (uses `dismiss()` from environment) or a custom back action
/// - Accepts any custom leading/title/trailing views via `@ViewBuilder`.
///
/// Usage examples are shown in the preview at bottom.
public struct GlassNavigationBar<Leading: View, Title: View, Trailing: View>: View {
	private let leading: Leading
	private let title: Title
	private let trailing: Trailing

	private let height: CGFloat
	private let showSeparator: Bool

	// Stored back button configuration (used by the convenience initializer).
	// We store these so we don't capture `self` in escaping closures during init.
	private let hideBackButtonStored: Bool
	private let backActionStored: (() -> Void)?

	@Environment(\.dismiss) private var dismiss

	/// Generic initializer with custom leading/title/trailing content
	public init(
		height: CGFloat = 44,
		showSeparator: Bool = false,
		@ViewBuilder leading: () -> Leading,
		@ViewBuilder title: () -> Title,
		@ViewBuilder trailing: () -> Trailing
	) {
		self.height = height
		self.showSeparator = showSeparator
		self.leading = leading()
		self.title = title()
		self.trailing = trailing()
		// When using the full custom initializer, assume the caller provided leading content
		self.hideBackButtonStored = true
		self.backActionStored = nil
	}

	/// Convenience initializer for a simple string title and optional back action
	public init(
		_ titleText: String,
		height: CGFloat = 44,
		showSeparator: Bool = false,
		hideBackButton: Bool = false,
		backAction: (() -> Void)? = nil,
		@ViewBuilder trailing: () -> Trailing = { EmptyView() }
	) where Leading == AnyView, Title == Text {
		self.height = height
		self.showSeparator = showSeparator
		// We can't capture `dismiss` or `self` inside an escaping closure during init,
		// so store the backAction and hide flag and build the actual back button inside `body`.
		self.leading = AnyView(EmptyView())
		self.hideBackButtonStored = hideBackButton
		self.backActionStored = backAction
		self.title = Text(titleText)
            .font(AppTheme.TextStyles.title())
            .foregroundColor(AppTheme.primary)
		self.trailing = trailing()
	}

	public var body: some View {
		ZStack {
			// Simple background color from AppTheme
            AppTheme.background
				.edgesIgnoringSafeArea(.all)
			
            Rectangle()
                .fill(AppTheme.pastelYellow)
                .frame(width: 120, height: topSafeArea, alignment: .top)
                .cornerRadius(10)
                .offset(y: -topSafeArea)

			HStack {
				// Leading region - fixed width to avoid shifting title
				Group {
					if hideBackButtonStored {
						HStack { leading }
					} else {
						// Build the default back button here so we can use `dismiss` safely
                        
                        CircleButtonView(systemNameIcon: "chevron.left") {
                            backActionStored?()
                        }
						.accessibilityLabel("Back")
					}
				}
				.frame(minWidth: 44, maxWidth: 120, alignment: .leading)

				Spacer()

				// Center title - placed in its own container to remain centered
				HStack { title }
					.frame(maxWidth: .infinity)
					.multilineTextAlignment(.center)

				Spacer()

				// Trailing region - fixed width to match leading area
				HStack { trailing }
					.frame(minWidth: 44, maxWidth: 120, alignment: .trailing)
			}
            .padding(.horizontal, AppTheme.Constants.horizontalPadding)
		}
		.frame(height: height)
	}

	// Read top safe area inset from the active window scene. Falls back to 0 when unavailable.
	private var topSafeArea: CGFloat {
		guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			  let window = scene.windows.first else { return 0 }
		return window.safeAreaInsets.top
	}
}
