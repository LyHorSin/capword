//
//  CapwordApp.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI
import SwiftData

@main
struct CapwordApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(WordStorage.shared.modelContainer)
    }
}
