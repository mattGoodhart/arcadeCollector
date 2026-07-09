//
//  GameDetailView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var isFetchingArtwork = false
    @State private var fetchError: Error?
    @State private var selectedArtwork: GameArtwork?
    @State private var mainImageKind: ArtworkKind = .inGame

    /// Kinds surfaced in the main-image segmented picker, in order.
    /// Matches the five segments of the legacy `DetailViewController`.
    private static let mainKinds: [ArtworkKind] = [.title, .inGame, .cabinet, .flyer, .pcb]

    var body: some View {
        List {
            heroSection
            metadataSection
            hardwareLinkSection
            if hasExternalLinks {
                externalLinksSection
            }
            pcbSection
            componentStatusSection
            repairLogSection
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !game.hasBoard {
                    Button {
                        let isWanted = game.ownership == .wanted
                        game.ownership = isWanted ? .none : .wanted
                    } label: {
                        Image(systemName: game.ownership == .wanted ? "heart.fill" : "heart")
                    }
                    .accessibilityLabel(game.ownership == .wanted ? "Remove from wanted" : "Add to wanted")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await fetchArtwork(force: true) }
                } label: {
                    if isFetchingArtwork {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isFetchingArtwork)
                .accessibilityLabel("Refresh artwork")
            }
        }
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
        .fullScreenCover(item: $selectedArtwork) { art in
            if let uiImage = art.imageData.flatMap(UIImage.init(data:)) {
                ZoomableImageView(image: uiImage, title: art.kind.displayName)
            }
        }
        .task {
            await fetchArtwork(force: false)
        }
    }

    // MARK: - Hero (marquee + main image + segmented picker)

    private var heroSection: some View {
        Section {
            VStack(spacing: 12) {
                marqueeBanner
                mainImageWithPicker
            }
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var marqueeBanner: some View {
        Group {
            if let art = game.artwork(.marquee),
               let uiImage = art.imageData.flatMap(UIImage.init(data:)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .onTapGesture { selectedArtwork = art }
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel("Marquee")
            } else {
                // Legacy fallback graphic — a 576×144 (4:1) placeholder that
                // preserves the marquee's silhouette while artwork is loading
                // or unavailable from the Arcade Database.
                Image("missing_marquee")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .overlay {
                        if isFetchingArtwork {
                            ProgressView()
                        }
                    }
                    .accessibilityLabel("Missing marquee")
            }
        }
    }

    private var mainImageWithPicker: some View {
        VStack(spacing: 10) {
            mainImage
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 300)

            Picker("Artwork", selection: $mainImageKind) {
                ForEach(Self.mainKinds) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    private var mainImage: some View {
        Group {
            if let art = game.artwork(mainImageKind),
               let uiImage = art.imageData.flatMap(UIImage.init(data:)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .onTapGesture { selectedArtwork = art }
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel(mainImageKind.displayName)
            } else if isFetchingArtwork {
                ProgressView()
                    .controlSize(.large)
                    .frame(height: 200)
            } else {
                ContentUnavailableView(
                    "No \(mainImageKind.displayName) Image",
                    systemImage: "photo",
                    description: Text("The Arcade Database may not have this artwork for \(game.romSetName).")
                )
                .frame(maxHeight: 240)
            }
        }
    }

    // MARK: - Overview / metadata

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

    // MARK: - External links

    private var hasExternalLinks: Bool {
        youtubeURL != nil || game.shortPlayURL != nil || game.manualURL != nil
    }

    /// Builds a YouTube watch URL from the video ID via `URLComponents`
    /// so any special characters in the ID are properly escaped (raw
    /// interpolation into a string + `URL(string:)!` was crash-prone).
    private var youtubeURL: URL? {
        let id = game.youtubeVideoID
        guard !id.isEmpty else { return nil }
        var components = URLComponents(string: "https://www.youtube.com/watch")
        components?.queryItems = [URLQueryItem(name: "v", value: id)]
        return components?.url
    }

    private var externalLinksSection: some View {
        Section("Links") {
            linkRow(title: "YouTube Gameplay", systemImage: "play.rectangle", url: youtubeURL)
            linkRow(title: "Short Play",       systemImage: "arcade.stick",   url: game.shortPlayURL)
            linkRow(title: "Manual",           systemImage: "book",           url: game.manualURL)
        }
    }

    @ViewBuilder
    private func linkRow(title: String, systemImage: String, url: URL?) -> some View {
        if let url {
            Button {
                openURL(url)
            } label: {
                Label(title, systemImage: systemImage)
            }
        }
    }

    // MARK: - PCB / status / repair

    private var pcbSection: some View {
        Section {
            Toggle("Have the PCB", isOn: $game.hasBoard)
                .onChange(of: game.hasBoard) { _, hasPCB in
                    game.ownership = hasPCB ? .owned : .none
                }
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

    // MARK: - Artwork fetch

    /// Fires from `.task` on view appear, and from the toolbar refresh button.
    /// Skips when marquee + title are already present unless `force` is true.
    private func fetchArtwork(force: Bool) async {
        if !force {
            let hasMarquee = game.artwork(.marquee) != nil
            let hasTitle = game.artwork(.title) != nil
            guard !hasMarquee || !hasTitle else { return }
        }
        guard !isFetchingArtwork else { return }

        isFetchingArtwork = true
        defer { isFetchingArtwork = false }

        let gameID = game.persistentModelID
        let container = modelContext.container
        do {
            let fetcher = ArtworkFetcher(modelContainer: container)
            try await fetcher.fetch(for: gameID)
        } catch {
            fetchError = error
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
