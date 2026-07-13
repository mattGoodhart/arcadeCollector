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

    static var databaseErrorView: some View {
        ContentUnavailableView(
            "Unable to Load Database",
            systemImage: "exclamationmark.triangle",
            description: Text("ArcadeCollector could not open its data store. Try restarting the app. If the problem persists, reinstalling may help.")
        )
    }
}

#Preview {
    let container = PreviewSupport.container
    let context = container.mainContext

    let games: [(String, String, String, String, String, ScreenOrientation, OwnershipStatus)] = [
        ("pacman", "Pac-Man", "Namco", "1980", "1-2", .vertical, .owned),
        ("dkong", "Donkey Kong", "Nintendo", "1981", "1-2", .vertical, .owned),
        ("galaga", "Galaga", "Namco", "1981", "1-2", .vertical, .wanted),
        ("sf2", "Street Fighter II", "Capcom", "1991", "1-2", .horizontal, .owned),
        ("mslug", "Metal Slug", "SNK", "1996", "1-2", .horizontal, .wanted),
        ("1942", "1942", "Capcom", "1984", "1-2", .vertical, .none),
        ("defender", "Defender", "Williams", "1981", "1-2", .horizontal, .owned),
        ("asteroids", "Asteroids", "Atari", "1979", "1-2", .vertical, .none),
    ]

    for (rom, title, mfr, year, players, orient, ownership) in games {
        let game = Game(
            romSetName: rom,
            title: title,
            manufacturer: mfr,
            year: year,
            players: players,
            orientation: orient,
            ownership: ownership
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
