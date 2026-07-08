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
