//
//  CapturedWord.swift
//  Capword
//
//  SwiftData model for captured words with images and translations.
//

import Foundation
import SwiftData

@Model
final class CapturedWord {
    var id: UUID
    var detectedText: String
    var translation: String
    var targetLanguage: String
    var capturedDate: Date
    
    // Store image as Data
    @Attribute(.externalStorage)
    var imageData: Data?
    
    // Optional: user notes or context
    var notes: String?
    
    // Track if user has reviewed/studied this word
    var isReviewed: Bool
    var reviewCount: Int
    var lastReviewedDate: Date?
    
    init(
        id: UUID = UUID(),
        detectedText: String,
        translation: String,
        targetLanguage: String,
        capturedDate: Date = Date(),
        imageData: Data? = nil,
        notes: String? = nil,
        isReviewed: Bool = false,
        reviewCount: Int = 0,
        lastReviewedDate: Date? = nil
    ) {
        self.id = id
        self.detectedText = detectedText
        self.translation = translation
        self.targetLanguage = targetLanguage
        self.capturedDate = capturedDate
        self.imageData = imageData
        self.notes = notes
        self.isReviewed = isReviewed
        self.reviewCount = reviewCount
        self.lastReviewedDate = lastReviewedDate
    }
}
