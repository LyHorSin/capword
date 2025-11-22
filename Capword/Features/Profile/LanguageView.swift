//
//  LanguageView.swift
//  Capword
//
//  Language selection view for changing the learning language.
//

import SwiftUI

struct LanguageView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedLanguage: String
    @State private var tempSelectedLanguage: String
    
    private let languages = UserSettings.shared.availableLanguages.sorted { $0.name < $1.name }
    
    init(selectedLanguage: Binding<String>) {
        self._selectedLanguage = selectedLanguage
        self._tempSelectedLanguage = State(initialValue: selectedLanguage.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        CircleButtonView(systemNameIcon: "xmark") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .accessibilityLabel("Back")
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Constants.horizontalPadding)
                }
                .frame(height: 60)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title and subtitle
                        VStack(spacing: 16) {
                            Text("Change the language\nyou want to learn")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("After switching languages, your previous\nlearning data will remain")
                                .font(AppTheme.TextStyles.body())
                                .foregroundColor(AppTheme.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Language grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(languages, id: \.name) { language in
                                languageCard(
                                    language: language.name,
                                    flag: language.flag,
                                    isSelected: tempSelectedLanguage == language.name
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Done button
                Button(action: {
                    selectedLanguage = tempSelectedLanguage
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(AppTheme.TextStyles.subtitle())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func languageCard(language: String, flag: String, isSelected: Bool) -> some View {
        Button(action: {
            tempSelectedLanguage = language
        }) {
            VStack(spacing: 12) {
                Text(flag)
                    .font(.system(size: 48))
                
                Text(language)
                    .font(AppTheme.TextStyles.subtitle())
                    .foregroundColor(AppTheme.primary)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(.vertical, 32)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    LanguageView(selectedLanguage: .constant("Chinese"))
}
