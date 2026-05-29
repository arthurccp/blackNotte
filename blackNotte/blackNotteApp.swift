//
//  blackNotteApp.swift
//  blackNotte
//
//  Created by Arthur Silva on 06/05/26.
//

import SwiftUI
import SwiftData

@main
struct blackNotteApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            ThoughtNote.self,
            ThoughtAnalysis.self
        ])
    }
}
