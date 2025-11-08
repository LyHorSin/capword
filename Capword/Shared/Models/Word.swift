//
//  Word.swift
//  Capword
//
//  Domain model for a word record.
//

import Foundation

struct Word: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var dateAdded: Date = Date()
}
