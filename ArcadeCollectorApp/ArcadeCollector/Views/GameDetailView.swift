//
//  GameDetailView.swift
//  ArcadeCollector
//

import AVKit
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
    @State private var shortPlayExpanded = false
    @State private var shortPlayPlayer: AVPlayer?

    /// Priority order for the main image area and segmented picker.
    private static let mainKinds: [ArtworkKind] = [.inGame, .title, .cabinet, .flyer, .pcb]

    var body: some View {
        List {
            heroSection
                .listSectionSeparator(.hidden, edges: .top)
            metadataSection
            if !game.history.isEmpty {
                historySection
            }
            hardwareLinkSection
            if game.shortPlayURL != nil {
                shortPlaySection
            }
            if hasExternalLinks {
                externalLinksSection
            }
            pcbSection
            if game.ownership == .owned {
                componentStatusSection
                repairLogSection
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if game.ownership != .owned {
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
            .padding(.bottom, 8)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listSectionSpacing(0)
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

    private var availableKinds: [ArtworkKind] {
        Self.mainKinds.filter { kind in
            game.artwork(kind)?.imageData != nil
        }
    }

    private var mainImageWithPicker: some View {
        VStack(spacing: 10) {
            mainImage
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 300)

            if availableKinds.count > 1 {
                Picker("Artwork", selection: $mainImageKind) {
                    ForEach(availableKinds) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: availableKinds) {
                    if !availableKinds.contains(mainImageKind),
                       let first = availableKinds.first {
                        mainImageKind = first
                    }
                }
            }
        }
    }

    private var bestAvailableArtwork: (artwork: GameArtwork, image: UIImage)? {
        let selected = game.artwork(mainImageKind)
        if let selected, let img = selected.imageData.flatMap(UIImage.init(data:)) {
            return (selected, img)
        }
        for kind in Self.mainKinds where kind != mainImageKind {
            if let art = game.artwork(kind),
               let img = art.imageData.flatMap(UIImage.init(data:)) {
                return (art, img)
            }
        }
        return nil
    }

    private var mainImage: some View {
        Group {
            if let best = bestAvailableArtwork {
                Image(uiImage: best.image)
                    .resizable()
                    .scaledToFit()
                    .onTapGesture { selectedArtwork = best.artwork }
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel(best.artwork.kind.displayName)
            } else if isFetchingArtwork {
                ProgressView()
                    .controlSize(.large)
                    .frame(height: 200)
            } else {
                ContentUnavailableView(
                    "No Artwork Available",
                    systemImage: "photo",
                    description: Text("The Arcade Database may not have artwork for \(game.title).")
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

    @State private var historyExpanded = false

    private var historySection: some View {
        Section {
            DisclosureGroup("History", isExpanded: $historyExpanded) {
                Text(game.history)
                    .font(.subheadline)
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
        youtubeURL != nil || game.manualURL != nil
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

    private var shortPlaySection: some View {
        Section {
            DisclosureGroup(isExpanded: $shortPlayExpanded) {
                if let player = shortPlayPlayer {
                    VideoPlayer(player: player)
                        .aspectRatio(game.orientation == .vertical ? 3/4 : 4/3, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                }
            } label: {
                Label("Short Play", systemImage: "arcade.stick")
            }
            .onChange(of: shortPlayExpanded) {
                if shortPlayExpanded, shortPlayPlayer == nil, let url = game.shortPlayURL {
                    let asset = AVURLAsset(url: url, options: [
                        "AVURLAssetOutOfBandMIMETypeKey": "video/mp4"
                    ])
                    shortPlayPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                } else if !shortPlayExpanded {
                    shortPlayPlayer?.pause()
                }
            }
        }
    }

    private var externalLinksSection: some View {
        Section("Links") {
            linkRow(title: "YouTube Longplay", systemImage: "play.rectangle", url: youtubeURL)
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
            Toggle("Have the PCB", isOn: Binding(
                get: { game.ownership == .owned },
                set: { game.ownership = $0 ? .owned : .none }
            ))
        }
    }

    private var componentStatusSection: some View {
        Section("Component Status") {
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
    let container = PreviewSupport.container
    let game = Game(
        romSetName: "pacman",
        title: "Pac-Man",
        manufacturer: "Namco",
        year: "1980",
        players: "1",
        orientation: .vertical,
        ownership: .owned
    )
    game.bootStatus = .working
    game.videoStatus = .issues
    container.mainContext.insert(game)
    try! container.mainContext.save()

    return NavigationStack {
        GameDetailView(game: game)
    }
    .modelContainer(container)
}
