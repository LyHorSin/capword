//
//  HeaderView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI

struct HeaderView: View {
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: Date())
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(currentDate)
                .font(AppTheme.TextStyles.caption())
                .foregroundColor(AppTheme.secondary)
            
            Text(greeting)
                .font(AppTheme.TextStyles.header())
                .foregroundColor(AppTheme.primary)
            
            Text("Start your day with a new word!")
                .font(AppTheme.TextStyles.subtitle())
                .foregroundColor(AppTheme.secondary)
        }
    }
}
