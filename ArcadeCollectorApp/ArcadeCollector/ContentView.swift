//
//  ContentView.swift
//  ArcadeCollector
//
//  Created by Matthew Goodhart on 7/5/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            SummaryView()
                .tabItem { Label("Summary", systemImage: "chart.pie") }

            GameListTab(mode: .allGames)
                .tabItem { Label("All Games", systemImage: "list.bullet") }

            GameListTab(mode: .myCollection)
                .tabItem { Label("My Collection", systemImage: "star.circle") }

            GameListTab(mode: .wanted)
                .tabItem { Label("Wanted", systemImage: "heart.circle") }

            GameListTab(mode: .repairLogs)
                .tabItem { Label("Repair Logs", systemImage: "list.clipboard") }
        }
        .tint(.accentColor)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Schema([Game.self, GameArtwork.self, RepairLog.self, RepairLogPhoto.self, GameCollection.self]),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let games: [(String, String, String, String, String, ScreenOrientation, OwnershipStatus, Bool)] = [
        ("pacman", "Pac-Man", "Namco", "1980", "1-2", .vertical, .owned, true),
        ("dkong", "Donkey Kong", "Nintendo", "1981", "1-2", .vertical, .owned, true),
        ("galaga", "Galaga", "Namco", "1981", "1-2", .vertical, .wanted, false),
        ("sf2", "Street Fighter II", "Capcom", "1991", "1-2", .horizontal, .owned, true),
        ("mslug", "Metal Slug", "SNK", "1996", "1-2", .horizontal, .wanted, false),
        ("1942", "1942", "Capcom", "1984", "1-2", .vertical, .none, false),
        ("defender", "Defender", "Williams", "1981", "1-2", .horizontal, .owned, true),
        ("asteroids", "Asteroids", "Atari", "1979", "1-2", .vertical, .none, false),
    ]

    for (rom, title, mfr, year, players, orient, ownership, board) in games {
        let game = Game(
            romSetName: rom,
            title: title,
            manufacturer: mfr,
            year: year,
            players: players,
            orientation: orient,
            ownership: ownership,
            hasBoard: board
        )
        switch rom {
        case "pacman":
            game.bootStatus = .working
            game.audioStatus = .working
            game.videoStatus = .working
            game.controlsStatus = .working
        case "dkong":
            game.bootStatus = .working
            game.audioStatus = .working
            game.videoStatus = .issues
            game.controlsStatus = .working
        case "sf2":
            game.bootStatus = .broken
        case "defender":
            break
        default:
            break
        }
        context.insert(game)
    }
    try! context.save()

    return ContentView()
        .modelContainer(container)
}
