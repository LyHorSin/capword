//
//  OnboardingView.swift
//  Capword
//
//  Placeholder onboarding flow for the Onboarding feature.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Welcome to Capword")
                .font(.title)
            Text("Quick onboarding screens and permissions prompts.")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
