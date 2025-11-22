//
//  SubscriptionView.swift
//  Capword
//
//  Subscription offer view with pricing and features.
//

import SwiftUI

struct SubscriptionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            Color(hex: 0xF5E6D3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(AppTheme.TextStyles.caption())
                            .foregroundColor(.gray)
                    }
                }
                .paddingContent()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Title section
                        VStack(spacing: 12) {
                            Text("WELCOME OFFER")
                                .font(AppTheme.TextStyles.caption())
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            Text("Save 40% on\nYour First Year")
                                .font(AppTheme.TextStyles.title())
                                .foregroundColor(Color(hex: 0x2C2C2E))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.top, 20)
                        
                        // Features card
                        VStack(alignment: .leading, spacing: 0) {
                            Text("40%\nOFF")
                                .font(AppTheme.TextStyles.header())
                                .foregroundColor(Color(hex: 0x2C2C2E))
                                .lineSpacing(-6)
                                .padding(.bottom, 16)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                featureRow("Scan words, no limits")
                                featureRow("Learn with context")
                                featureRow("Unlock all features")
                                featureRow("No Ads")
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: 0xFFB84D))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .rotationEffect(.degrees(-2))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 32)
                        
                        // Pricing
                        VStack(spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("$9.99")
                                    .font(AppTheme.TextStyles.header())
                                    .foregroundColor(Color(hex: 0x2C2C2E))
                                
                                Text("USD 14.99")
                                    .font(AppTheme.TextStyles.title())
                                    .foregroundColor(.gray.opacity(0.5))
                                    .strikethrough(true, color: .gray.opacity(0.5))
                            }
                            
                            Text("First-year price is $9.99. After that,\nit renews at USD 14.99 per year. Cancel anytime")
                                .font(AppTheme.TextStyles.caption())
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // Bottom section
                VStack(spacing: 16) {
                    // Claim Offer Button
                    Button(action: {
                        claimOffer()
                    }) {
                        Text(isProcessing ? "Processing..." : "Claim Offer")
                            .font(AppTheme.TextStyles.subtitle())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: 0xFF6B6B), Color(hex: 0xFF4757)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal, 20)
                    
                    // Footer links
                    HStack(spacing: 16) {
                        Button(action: {
                            // Restore purchases
                        }) {
                            Text("Restore Purchase")
                                .font(AppTheme.TextStyles.caption())
                                .foregroundColor(.gray)
                        }
                        
                        Text("|")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Button(action: {
                            // Show terms
                        }) {
                            Text("Terms")
                                .font(AppTheme.TextStyles.caption())
                                .foregroundColor(.gray)
                        }
                        
                        Text("|")
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Button(action: {
                            // Show privacy
                        }) {
                            Text("Privacy")
                                .font(AppTheme.TextStyles.caption())
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: 0x2C2C2E))
            
            Text(text)
                .font(AppTheme.TextStyles.subtitle())
                .foregroundColor(Color(hex: 0x2C2C2E))
        }
    }
    
    private func claimOffer() {
        isProcessing = true
        
        // Simulate purchase process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            // Handle successful purchase
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

#Preview {
    SubscriptionView()
}
