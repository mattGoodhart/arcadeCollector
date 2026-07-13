//
//  ArcadeCollectorApp.swift
//  ArcadeCollector
//
//  Created by Matthew Goodhart on 7/5/26.
//

import SwiftUI
import SwiftData

@main
struct ArcadeCollectorApp: App {
    let sharedModelContainer: ModelContainer?

    init() {
        let schema = Schema([
            Game.self,
            GameArtwork.self,
            RepairLog.self,
            RepairLogPhoto.self,
            GameCollection.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            sharedModelContainer = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let sharedModelContainer {
                ContentView()
                    .task {
                        do {
                            let seeder = GameSeeder(modelContainer: sharedModelContainer)
                            try await seeder.seedIfNeeded()
                        } catch {
                            assertionFailure("Seeding failed: \(error)")
                        }
                    }
                    .modelContainer(sharedModelContainer)
            } else {
                ContentView.databaseErrorView
            }
        }
    }
}
