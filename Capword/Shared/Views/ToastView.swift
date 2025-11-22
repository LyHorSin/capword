//
//  ToastView.swift
//  Capword
//
//  Created by Ly Hor Sin on 22/11/25.
//
import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sticker saved to Photos!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Text("+1")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

