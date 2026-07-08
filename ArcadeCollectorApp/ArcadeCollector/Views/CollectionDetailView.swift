//
//  CollectionDetailView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @Bindable var collection: GameCollection
    @Environment(\.modelContext) private var modelContext
    @State private var isRenaming = false
    @State private var renameText = ""

    private var sortedGames: [Game] {
        collection.games.sorted { $0.title < $1.title }
    }

    var body: some View {
        List {
            ForEach(Array(sortedGames.enumerated()), id: \.element.id) { index, game in
                NavigationLink(value: game) {
                    GameRow(game: game, isDarkRow: !index.isMultiple(of: 2))
                }
                .listRowBackground(index.isMultiple(of: 2) ? Color.arcadeRowEven : Color.arcadeRowOdd)
            }
            .onDelete(perform: removeGames)
        }
        .listStyle(.plain)
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        renameText = collection.name
                        isRenaming = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .navigationDestination(for: Game.self) { game in
            GameDetailView(game: game)
        }
        .overlay {
            if collection.games.isEmpty {
                ContentUnavailableView(
                    "Empty Collection",
                    systemImage: "folder",
                    description: Text("Add games from the game detail view.")
                )
            }
        }
        .alert("Rename Collection", isPresented: $isRenaming) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                let name = renameText.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    collection.name = name
                }
            }
        }
    }

    private func removeGames(at offsets: IndexSet) {
        let sorted = sortedGames
        for index in offsets {
            collection.games.removeAll { $0.id == sorted[index].id }
        }
    }
}
