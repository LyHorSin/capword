//
//  DailyProgressCardView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI
import SwiftData

struct DailyProgressCardView: View {
    
    // Query only today's words directly from SwiftData for better performance
    @Query private var todayWords: [CapturedWord]
    
    init() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
        
        let predicate = #Predicate<CapturedWord> { word in
            word.capturedDate >= startOfToday && word.capturedDate < endOfToday
        }
        
        _todayWords = Query(
            filter: predicate,
            sort: \CapturedWord.capturedDate,
            order: .reverse
        )
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
            Text("Image to your language")
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
                        LazyHStack(spacing: 12) {
                            ForEach(todayWords.prefix(10)) { word in
                                ThumbnailImageView(imageData: word.imageData)
                            }
                        }
                        .padding(.horizontal, 1) // Small padding to prevent clipping
                    }
                    .frame(height: 80)
                }
                .padding(20)
                .background(AppTheme.onTertiary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Constants.cornerRadius))
            }
        }
    }
}

// Optimized thumbnail view with cached image loading
private struct ThumbnailImageView: View {
    let imageData: Data?
    @State private var cachedImage: UIImage?
    
    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: 60, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let imageData = imageData else { return }
        
        // Load image on background thread
        let image = await Task.detached(priority: .userInitiated) {
            // Create thumbnail instead of full resolution
            guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
                  let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                      kCGImageSourceCreateThumbnailFromImageAlways: true,
                      kCGImageSourceCreateThumbnailWithTransform: true,
                      kCGImageSourceThumbnailMaxPixelSize: 160
                  ] as CFDictionary) else {
                return UIImage(data: imageData)
            }
            return UIImage(cgImage: cgImage)
        }.value
        
        await MainActor.run {
            self.cachedImage = image
        }
    }
}
