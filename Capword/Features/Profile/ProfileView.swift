//
//  ProfileView.swift
//  Capword
//
//  Placeholder profile/settings view for the Profile feature.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile")
                .font(.title2)
            Text("User profile and settings go here.")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
