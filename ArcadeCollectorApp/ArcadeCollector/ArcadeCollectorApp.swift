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
        let schema = AppSchema.schema
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
                RootView(container: sharedModelContainer)
                    .modelContainer(sharedModelContainer)
            } else {
                ContentView.databaseErrorView
            }
        }
    }
}

/// Owns seed-failure state so a first-launch seed error surfaces as a real
/// user-facing screen instead of a silently-empty game list (which is what
/// `assertionFailure` used to produce in release builds).
private struct RootView: View {
    let container: ModelContainer
    @State private var seedFailure: String?

    var body: some View {
        Group {
            if let seedFailure {
                ContentView.seedFailureView(message: seedFailure)
            } else {
                ContentView()
            }
        }
        .task {
            do {
                let seeder = GameSeeder(modelContainer: container)
                try await seeder.seedIfNeeded()
            } catch {
                seedFailure = error.localizedDescription
            }
        }
    }
}
