//
//  ContentView.swift
//  ArcadeCollector
//
//  Created by Matthew Goodhart on 7/5/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Game.title) private var games: [Game]

    var body: some View {
        NavigationStack {
            List(games) { game in
                NavigationLink(value: game) {
                    GameRow(game: game)
                }
            }
            .navigationTitle("Games")
            .navigationDestination(for: Game.self) { game in
                GameDetailView(game: game)
            }
            .overlay {
                if games.isEmpty {
                    ContentUnavailableView(
                        "No Games Yet",
                        systemImage: "gamecontroller",
                        description: Text("Seed data has not been loaded.")
                    )
                }
            }
        }
    }
}

private struct GameRow: View {
    let game: Game

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: game.functionalCondition.symbolName)
                .foregroundStyle(game.functionalCondition.color)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(game.title)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(game.romSetName)
                    if !game.year.isEmpty {
                        Text("·")
                        Text(game.year)
                    }
                    if !game.manufacturer.isEmpty {
                        Text("·")
                        Text(game.manufacturer)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                Game.self,
                GameArtwork.self,
                RepairLog.self,
                RepairLogPhoto.self,
                GameCollection.self,
            ],
            inMemory: true
        )
}
