//
//  WordsView.swift
//  Capword
//
//  Placeholder words/word-list view for the Words feature.
//

import SwiftUI

struct WordsView: View {
    var body: some View {
        VStack {
            Text("Words")
                .font(.title2)
            Text("List or grid of words will be shown here.")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    WordsView()
}
