//
//  GameListTab.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData

struct GameListTab: View {
    let mode: GameListMode

    @Environment(\.modelContext) private var modelContext
    @State private var sort: GameSort = .title
    @State private var filter = GameListFilter()
    @State private var showingAbout = false
    @State private var availableGenres: [String] = []
    @State private var availableNplayers: [String] = []

    private var showsSearch: Bool { mode == .allGames }

    var body: some View {
        NavigationStack {
            gameList
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
                .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .sheet(isPresented: $showingAbout) {
                    NavigationStack {
                        AboutView()
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") { showingAbout = false }
                                }
                            }
                            .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                            .toolbarColorScheme(.dark, for: .navigationBar)
                    }
                }
                .navigationDestination(for: Game.self) { game in
                    if mode == .repairLogs {
                        RepairLogListView(game: game)
                    } else {
                        GameDetailView(game: game)
                    }
                }
                .task {
                    if availableGenres.isEmpty {
                        loadFilterOptions()
                    }
                }
        }
    }

    /// Populates the Genre and Players picker options with distinct values
    /// from the store. Uses `propertiesToFetch` so SwiftData only reads the
    /// two columns we need instead of materializing full `Game` rows. Runs
    /// once per view lifetime — the seed and API back-fill don't churn these
    /// values often enough to warrant continuous `@Query` observation over
    /// the full 3,855-row table.
    private func loadFilterOptions() {
        var descriptor = FetchDescriptor<Game>()
        descriptor.propertiesToFetch = [\.genre, \.nplayers]
        guard let games = try? modelContext.fetch(descriptor) else { return }
        availableGenres = Array(Set(games.map(\.genre)).subtracting([""])).sorted()
        availableNplayers = Array(Set(games.map(\.nplayers)).subtracting([""])).sorted()
    }

    @ViewBuilder
    private var gameList: some View {
        let list = GameListView(sort: sort.descriptor, filter: activeFilter)
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
        if showsSearch {
            list.searchable(text: $filter.search, prompt: "Search title")
        } else {
            list
        }
    }

    private var activeFilter: GameListFilter {
        var f = filter
        f.mode = mode
        return f
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

            if mode.showsOwnershipFilter {
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

            Section("Genre") {
                Picker(selection: $filter.genre) {
                    Text("All").tag(String?.none)
                    ForEach(availableGenres, id: \.self) { genre in
                        Text(genre).tag(Optional(genre))
                    }
                } label: {
                    Text("Genre")
                }
                .pickerStyle(.inline)
            }

            Section("Players") {
                Picker(selection: $filter.nplayers) {
                    Text("All").tag(String?.none)
                    ForEach(availableNplayers, id: \.self) { value in
                        Text(value).tag(Optional(value))
                    }
                } label: {
                    Text("Players")
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
