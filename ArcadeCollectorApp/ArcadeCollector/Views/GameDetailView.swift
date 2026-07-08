//
//  GameDetailView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var modelContext

    @State private var isFetchingArtwork = false
    @State private var fetchError: Error?

    var body: some View {
        List {
            metadataSection
            hardwareLinkSection
            ownershipSection
            componentStatusSection
            artworkSection
            repairLogSection
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(
            "Couldn't fetch artwork",
            isPresented: Binding(
                get: { fetchError != nil },
                set: { if !$0 { fetchError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let fetchError {
                Text(fetchError.localizedDescription)
            }
        }
    }

    private var metadataSection: some View {
        Section("Overview") {
            LabeledContent("ROM Set", value: game.romSetName)
            if !game.manufacturer.isEmpty {
                LabeledContent("Manufacturer", value: game.manufacturer)
            }
            if !game.year.isEmpty {
                LabeledContent("Year", value: game.year)
            }
            if !game.players.isEmpty {
                LabeledContent("Players", value: game.players)
            }
            LabeledContent("Orientation", value: game.orientation.displayName)
            if !game.genre.isEmpty {
                LabeledContent("Genre", value: game.genre)
            }
        }
    }

    private var hardwareLinkSection: some View {
        Section {
            NavigationLink {
                HardwareDetailView(game: game)
            } label: {
                Label("Hardware", systemImage: "cpu")
            }
        }
    }

    private var ownershipSection: some View {
        Section("Ownership") {
            Picker("Status", selection: $game.ownership) {
                ForEach(OwnershipStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Have the PCB", isOn: $game.hasBoard)
        }
    }

    private var componentStatusSection: some View {
        Section("Component Status") {
            StatusPickerRow(label: "Overall",       selection: $game.functionalCondition)
            StatusPickerRow(label: "Boot",          selection: $game.bootStatus)
            StatusPickerRow(label: "Audio",         selection: $game.audioStatus)
            StatusPickerRow(label: "Video",         selection: $game.videoStatus)
            StatusPickerRow(label: "Controls",      selection: $game.controlsStatus)
            StatusPickerRow(label: "Extended Play", selection: $game.extendedPlayStatus)
        }
    }

    private var artworkSection: some View {
        Section("Artwork") {
            if !game.artwork.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(sortedArtwork) { art in
                            VStack(spacing: 4) {
                                ArtworkThumbnailView(artwork: art)
                                Text(art.kind.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } else if !isFetchingArtwork {
                Text("No artwork saved yet")
                    .foregroundStyle(.secondary)
            }

            Button(action: fetchArtwork) {
                HStack {
                    if isFetchingArtwork {
                        ProgressView()
                            .controlSize(.small)
                        Text("Fetching…")
                    } else {
                        Label(
                            game.artwork.isEmpty ? "Fetch Artwork" : "Fetch Missing",
                            systemImage: "arrow.down.circle"
                        )
                    }
                }
            }
            .disabled(isFetchingArtwork)
        }
    }

    private var repairLogSection: some View {
        Section("Repair Log") {
            NavigationLink {
                RepairLogListView(game: game)
            } label: {
                HStack {
                    Label("Entries", systemImage: "wrench.and.screwdriver")
                    Spacer()
                    Text("\(game.repairLogs.count)")
                        .foregroundStyle(.secondary)
                }
            }
            if let lastDate = game.lastRepairLogDate {
                LabeledContent("Last Entry", value: lastDate, format: .dateTime.month(.abbreviated).day().year())
            }
        }
    }

    private var sortedArtwork: [GameArtwork] {
        let order: [ArtworkKind] = [.marquee, .title, .inGame, .flyer, .cabinet, .pcb, .userPCB]
        return game.artwork.sorted { lhs, rhs in
            (order.firstIndex(of: lhs.kind) ?? Int.max)
                < (order.firstIndex(of: rhs.kind) ?? Int.max)
        }
    }

    private func fetchArtwork() {
        isFetchingArtwork = true
        let gameID = game.persistentModelID
        let container = modelContext.container
        Task {
            do {
                let fetcher = ArtworkFetcher(modelContainer: container)
                try await fetcher.fetch(for: gameID)
            } catch {
                fetchError = error
            }
            isFetchingArtwork = false
        }
    }
}

private struct StatusPickerRow: View {
    let label: String
    @Binding var selection: ComponentStatus

    var body: some View {
        Picker(selection: $selection) {
            ForEach(ComponentStatus.allCases) { status in
                Label(status.displayName, systemImage: status.symbolName)
                    .tag(status)
            }
        } label: {
            HStack {
                Image(systemName: selection.symbolName)
                    .foregroundStyle(selection.color)
                    .accessibilityHidden(true)
                Text(label)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Schema([Game.self, GameArtwork.self, RepairLog.self, RepairLogPhoto.self, GameCollection.self]),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let game = Game(
        romSetName: "pacman",
        title: "Pac-Man",
        manufacturer: "Namco",
        year: "1980",
        players: "1",
        orientation: .vertical,
        ownership: .owned,
        hasBoard: true
    )
    game.bootStatus = .working
    game.videoStatus = .issues
    container.mainContext.insert(game)

    return NavigationStack {
        GameDetailView(game: game)
    }
    .modelContainer(container)
}
