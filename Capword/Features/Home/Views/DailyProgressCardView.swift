//
//  DailyProgressCardView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI
import SwiftData

struct DailyProgressCardView: View {
    
    @Query(sort: \CapturedWord.capturedDate, order: .reverse, animation: .spring(response: 0.4, dampingFraction: 0.75))
    private var allWords: [CapturedWord]
    
    // Get today's words
    private var todayWords: [CapturedWord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allWords.filter { word in
            calendar.isDate(word.capturedDate, inSameDayAs: today)
        }
    }
    
    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentMonth)
                .font(AppTheme.TextStyles.title())
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if todayWords.isEmpty {
                // Empty state - same as before
                VStack(alignment: .leading, spacing: 6) {
                    Text(currentDateFormatted)
                        .font(AppTheme.TextStyles.subtitle())
                        .foregroundColor(AppTheme.primary)
                    
                    Text("Can you snap 5 words today?")
                        .font(AppTheme.TextStyles.caption())
                        .foregroundColor(AppTheme.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle()
            } else {
                // Show today's captured words with images
                VStack(alignment: .leading, spacing: 12) {
                    Text(currentDateFormatted)
                        .font(AppTheme.TextStyles.subtitle())
                        .foregroundColor(AppTheme.primary)
                    
                    Text("\(todayWords.count) Words")
                        .font(AppTheme.TextStyles.caption())
                        .foregroundColor(AppTheme.secondary)
                    
                    // Display word stickers
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(todayWords.prefix(10)) { word in
                                if let imageData = word.imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 80)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(AppTheme.onTertiary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Constants.cornerRadius))
            }
        }
    }
}
