//
//  WordStorage.swift
//  Capword
//
//  Manages SwiftData storage for captured words.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class WordStorage {
    static let shared = WordStorage()
    
    private(set) var modelContainer: ModelContainer
    private var modelContext: ModelContext
    
    private init() {
        do {
            let schema = Schema([CapturedWord.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    // MARK: - Save
    
    func saveWord(
        detectedText: String,
        translation: String,
        targetLanguage: String,
        image: UIImage?
    ) throws {
        let imageData = image?.pngData()
        
        let word = CapturedWord(
            detectedText: detectedText,
            translation: translation,
            targetLanguage: targetLanguage,
            imageData: imageData
        )
        
        modelContext.insert(word)
        try modelContext.save()
    }
    
    // MARK: - Fetch
    
    func fetchAllWords() throws -> [CapturedWord] {
        let descriptor = FetchDescriptor<CapturedWord>(
            sortBy: [SortDescriptor(\.capturedDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchWordsByLanguage(_ language: String) throws -> [CapturedWord] {
        let predicate = #Predicate<CapturedWord> { word in
            word.targetLanguage == language
        }
        let descriptor = FetchDescriptor<CapturedWord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.capturedDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchRecentWords(limit: Int = 10) throws -> [CapturedWord] {
        var descriptor = FetchDescriptor<CapturedWord>(
            sortBy: [SortDescriptor(\.capturedDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Update
    
    func markAsReviewed(_ word: CapturedWord) throws {
        word.isReviewed = true
        word.reviewCount += 1
        word.lastReviewedDate = Date()
        try modelContext.save()
    }
    
    func updateNotes(for word: CapturedWord, notes: String) throws {
        word.notes = notes
        try modelContext.save()
    }
    
    // MARK: - Delete
    
    func deleteWord(_ word: CapturedWord) throws {
        modelContext.delete(word)
        try modelContext.save()
    }
    
    func deleteAllWords() throws {
        let words = try fetchAllWords()
        for word in words {
            modelContext.delete(word)
        }
        try modelContext.save()
    }
    
    // MARK: - Statistics
    
    func getWordCount() throws -> Int {
        let descriptor = FetchDescriptor<CapturedWord>()
        return try modelContext.fetchCount(descriptor)
    }
    
    func getWordCountByLanguage(_ language: String) throws -> Int {
        let predicate = #Predicate<CapturedWord> { word in
            word.targetLanguage == language
        }
        let descriptor = FetchDescriptor<CapturedWord>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
}
