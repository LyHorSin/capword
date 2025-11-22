//
//  ProfileView.swift
//  Capword
//
//  Placeholder profile/settings view for the Profile feature.
//

import SwiftUI

struct ProfileView: View {
    // State for interactive settings

    @State private var reviewReminderEnabled: Bool = true
    @State private var showLanguageView: Bool = false
    @ObservedObject private var settings = UserSettings.shared
    @Environment(\.presentationMode) private var presentationMode

    
    @State private var showHeader: Bool = false
    @State private var showPremium: Bool = false
    @State private var showSettings: Bool = false
    @State private var showSupport: Bool = false
    @State private var showAbout: Bool = false
    @State private var showFooter: Bool = false
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
                .navigationBarHidden(true)
            
            VStack {
                GlassNavigationBar("", backAction: {
                    presentationMode.wrappedValue.dismiss()
                })
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: AppTheme.Constants.contentSpacing) {
                        avatarSection
                        premiumCard
                        settingsSection
                        supportSection
                        aboutSection
                        footer
                    }
                    .paddingContent()
                    .onAppear {
                        showHeader = true
                        showPremium = true
                        showSettings = true
                        showSupport = true
                        showAbout = true
                        showFooter = true
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    private var avatarSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.onTertiary)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 4)
                    )
                Image(systemName: "person")
                    .font(AppTheme.TextStyles.title())
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 32, height: 32)
            }
            Text("Edit Profile")
                .font(AppTheme.TextStyles.subtitle())
                .foregroundColor(AppTheme.primary)
                .bold()
            languagePill
        }
        .opacity(showHeader ? 1 : 0)
        .offset(y: showHeader ? 0 : 30)
        .animation(.easeOut(duration: 0.5), value: showHeader)
    }
    
    private var languagePill: some View {
        Button(action: {
            showLanguageView = true
        }) {
            HStack(spacing: 12) {
                Text(settings.getFlagForLanguage(settings.selectedLanguage))
                    .font(AppTheme.TextStyles.subtitle())
                Text(settings.selectedLanguage)
                    .font(AppTheme.TextStyles.subtitle())
                    .foregroundColor(AppTheme.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 18)
            .background(Color.white)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showLanguageView) {
            LanguageView(selectedLanguage: $settings.selectedLanguage)
        }
    }
    
    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 26))
                    .foregroundColor(AppTheme.primary)
                
                Text("Upgrade to Premium")
                    .font(AppTheme.TextStyles.caption())
                    .bold()
                    .foregroundColor(AppTheme.primary)
            }
            Text("Go Premium Learn more ...")
                .font(AppTheme.TextStyles.title())
                .foregroundColor(AppTheme.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Button(action: {}) {
                Text("Start Free Trial")
                    .font(AppTheme.TextStyles.subtitle())
                    .foregroundColor(AppTheme.primary)
                    .paddingContent()
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
        .appPremiumCardStyle()
        .opacity(showPremium ? 1 : 0)
        .offset(y: showPremium ? 0 : 30)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: showPremium)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Settings")
            settingsCard(
                VStack(spacing: 0) {
                    navigationRow(icon: "globe", title: "System Language", detail: systemLanguageDisplayName)
                    divider
                    navigationRow(icon: "flag", title: "Preferred Language", detail: settings.selectedLanguage, action: {
                        showLanguageView = true
                    })
                    divider
                    navigationRow(icon: "waveform", title: "Change Voice", detail: "")
                    divider
                    navigationRow(icon: "trash", title: "Clear Cache", detail: "366 KB")
                    divider
                    navigationRow(icon: "star", title: "Subscription", detail: "Free")
                }
            )
        }
        .opacity(showSettings ? 1 : 0)
        .offset(y: showSettings ? 0 : 30)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: showSettings)
    }
    
    private var systemLanguageDisplayName: String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let locale = Locale.current
        return locale.localizedString(forIdentifier: preferredLanguage) ?? "English"
    }
    
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Support")
            settingsCard(
                VStack(spacing: 0) {
                    navigationRow(icon: "envelope", title: "Contact & Support")
                    divider
                    navigationRow(icon: "questionmark.circle", title: "FAQs")
                    divider
                    navigationRow(icon: "doc.text", title: "Terms of Use")
                }
            )
        }
        .opacity(showSupport ? 1 : 0)
        .offset(y: showSupport ? 0 : 30)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: showSupport)
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsCard(
                VStack(spacing: 0) {
                    navigationRow(icon: "lock", title: "Privacy Policy")
                }
            )
            sectionHeader("About")
            settingsCard(
                VStack(spacing: 0) {
                    navigationRow(icon: "globe", title: "Our Story")
                    divider
                    navigationRow(icon: "megaphone", title: "KOL partnership")
                    divider
                    navigationRow(icon: "sparkles", title: "Suggest a Feature")
                }
            )
        }
        .opacity(showAbout ? 1 : 0)
        .offset(y: showAbout ? 0 : 30)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: showAbout)
    }
    
    private var footer: some View {
        VStack(spacing: 16) {
            Image(systemName: "circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(AppTheme.primary)
                .overlay(
                    Circle().stroke(Color.black.opacity(0.1), lineWidth: 2)
                )
            Text("Made with ❤ from\nCapWords")
                .multilineTextAlignment(.center)
                .font(AppTheme.TextStyles.body())
                .foregroundColor(AppTheme.secondary)
            Text("Copyright © 2025 CapWords")
                .font(AppTheme.TextStyles.caption())
                .foregroundColor(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .opacity(showFooter ? 1 : 0)
        .offset(y: showFooter ? 0 : 30)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: showFooter)
    }
    
    // MARK: - Row Components
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.TextStyles.body())
            .foregroundColor(AppTheme.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 48)
    }
    
    private func settingsCard<Content: View>(_ content: Content) -> some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Constants.cornerRadius))
    }
    
    private func navigationRow(icon: String, title: String, detail: String = "", action: (() -> Void)? = nil) -> some View {
        Button(action: {
            if let action = action {
                action()
            } else {
                // Open iOS Settings app
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }) {
            HStack(spacing: 16) {
                iconCircle(icon)
                Text(title)
                    .font(AppTheme.TextStyles.body())
                    .foregroundColor(AppTheme.primary)

                Spacer()
                if !detail.isEmpty {
                    Text(detail)
                        .font(AppTheme.TextStyles.caption())
                        .foregroundColor(AppTheme.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.secondary)
            }
            .paddingContent()
        }
        .buttonStyle(.plain)
    }
    
    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            iconCircle(icon)
            Text(title)
                .font(AppTheme.TextStyles.body())
                .foregroundColor(AppTheme.primary)
                .bold()
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private func iconCircle(_ system: String) -> some View {
        ZStack {
            Circle().fill(AppTheme.primary.opacity(0.08))
            Image(systemName: system)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.primary)
        }
        .frame(width: 40, height: 40)
    }
}

#Preview {
    ProfileView()
}
