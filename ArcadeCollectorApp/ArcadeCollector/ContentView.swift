//
//  ContentView.swift
//  ArcadeCollector
//
//  Created by Matthew Goodhart on 7/5/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var sort: GameSort = .title
    @State private var filter = GameListFilter()
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            GameListView(sort: sort.descriptor, filter: filter)
                .navigationTitle("Games")
                .searchable(text: $filter.search, prompt: "Search title")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingAbout = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        listMenu
                    }
                }
                .sheet(isPresented: $showingAbout) {
                    NavigationStack {
                        AboutView()
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { showingAbout = false }
                                }
                            }
                    }
                }
                .navigationDestination(for: Game.self) { game in
                    GameDetailView(game: game)
                }
        }
    }

    private var listMenu: some View {
        Menu {
            Section("Sort by") {
                Picker(selection: $sort) {
                    ForEach(GameSort.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                } label: {
                    Text("Sort")
                }
                .pickerStyle(.inline)
            }

            Section("Ownership") {
                Picker(selection: $filter.ownership) {
                    Text("All").tag(OwnershipStatus?.none)
                    ForEach(OwnershipStatus.allCases) { status in
                        Text(status.displayName).tag(Optional(status))
                    }
                } label: {
                    Text("Ownership")
                }
                .pickerStyle(.inline)
            }

            Section("Orientation") {
                Picker(selection: $filter.orientation) {
                    Text("All").tag(ScreenOrientation?.none)
                    ForEach(ScreenOrientation.allCases) { value in
                        Text(value.displayName).tag(Optional(value))
                    }
                } label: {
                    Text("Orientation")
                }
                .pickerStyle(.inline)
            }

            if filter.isActive {
                Section {
                    Button("Clear Filters", role: .destructive) {
                        filter = GameListFilter()
                    }
                }
            }
        } label: {
            Image(systemName: filter.isActive
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
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
