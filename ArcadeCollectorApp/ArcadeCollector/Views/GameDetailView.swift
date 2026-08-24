//
//  GameDetailView.swift
//  ArcadeCollector
//

import AVKit
import SwiftUI
import SwiftData
import WebKit

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
    @State private var isLoadingManual = false
    @State private var showManual = false
    @State private var showManualUnavailable = false

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
            if videoMode.isPresent {
                shortPlaySection
            }
            if game.manualURL != nil {
                manualSection
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
                let forceAspect = shouldForceScreenAspectRatio
                    && (art.kind == .title || art.kind == .inGame)
                ZoomableImageView(
                    image: uiImage,
                    title: art.kind.displayName,
                    forcedAspectRatio: forceAspect
                        ? (game.orientation == .vertical ? 3.0/4.0 : 4.0/3.0)
                        : nil
                )
            }
        }
        .sheet(isPresented: $showManual) {
            if let data = game.manualData {
                ManualView(title: "\(game.title) Manual", pdfData: data)
            }
        }
        .alert(
            "Manual Unavailable",
            isPresented: $showManualUnavailable
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No manual is available for \(game.title) on the Arcade Database.")
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

    private var shouldForceScreenAspectRatio: Bool {
        let type = game.displayType.lowercased()
        return !type.isEmpty && type != "multiple"
    }

    private var mainImage: some View {
        Group {
            if let best = bestAvailableArtwork {
                let forceAspect = shouldForceScreenAspectRatio
                    && (best.artwork.kind == .title || best.artwork.kind == .inGame)
                Image(uiImage: best.image)
                    .resizable()
                    .aspectRatio(
                        forceAspect
                            ? (game.orientation == .vertical ? 3.0/4.0 : 4.0/3.0)
                            : nil,
                        contentMode: .fit
                    )
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

    /// The single source of truth for the Short Play section: what kind of video (if any)
    /// this game has. Callers pattern-match on the case rather than nil-checking two
    /// parallel optionals — that way the "youtube ID present *and* direct URL present"
    /// mixed state is unrepresentable.
    private enum VideoMode: Equatable {
        case youtube(id: String)
        case direct(URL)
        case none

        var isPresent: Bool {
            if case .none = self { return false }
            return true
        }
    }

    private var videoMode: VideoMode {
        if let id = game.youtubeVideoID, YouTubeURL.isValid(id: id) {
            return .youtube(id: id)
        }
        if let url = game.shortPlayURL {
            if let id = YouTubeURL.extractID(from: url), YouTubeURL.isValid(id: id) {
                return .youtube(id: id)
            }
            return .direct(url)
        }
        return .none
    }

    private var shortPlaySection: some View {
        Section {
            Button {
                withAnimation { shortPlayExpanded.toggle() }
            } label: {
                HStack {
                    Label("Short Play", systemImage: "arcade.stick")
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(shortPlayExpanded ? 0 : -90))
                }
            }
            .tint(.primary)

            if shortPlayExpanded {
                if case .youtube(let ytID) = videoMode {
                    YouTubePlayerView(videoID: ytID)
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                } else if let player = shortPlayPlayer {
                    VideoPlayer(player: player)
                        .aspectRatio(game.orientation == .vertical ? 3/4 : 4/3, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                }
            }
        }
        .onChange(of: shortPlayExpanded) {
            if shortPlayExpanded, shortPlayPlayer == nil,
               case .direct(let url) = videoMode {
                let asset = AVURLAsset(url: url, options: [
                    "AVURLAssetOutOfBandMIMETypeKey": "video/mp4"
                ])
                shortPlayPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            } else if !shortPlayExpanded {
                shortPlayPlayer?.pause()
            }
        }
    }

    // MARK: - Manual

    private var manualSection: some View {
        Section {
            Button {
                Task { await loadManual() }
            } label: {
                HStack {
                    Label("Manual", systemImage: "book")
                    Spacer()
                    if isLoadingManual {
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .disabled(isLoadingManual)
        }
    }

    private func loadManual() async {
        if game.manualData != nil {
            showManual = true
            return
        }
        guard let url = game.manualURL else { return }

        isLoadingManual = true
        defer { isLoadingManual = false }

        let client = ArcadeDatabaseClient()
        do {
            let data = try await client.downloadData(from: url)
            guard data.count >= 4,
                  data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]) else {
                game.manualURL = nil
                showManualUnavailable = true
                return
            }
            game.manualData = data
            showManual = true
        } catch {
            game.manualURL = nil
            showManualUnavailable = true
        }
    }

    // MARK: - PCB / status / repair

    private var pcbSection: some View {
        Section {
            Toggle("Have the PCB", isOn: Binding(
                get: { game.ownership == .owned },
                set: { game.ownership = $0 ? .owned : .none }
            ))
            .accessibilityIdentifier("pcb-toggle")
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

private struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String

    func makeCoordinator() -> Coordinator {
        Coordinator(allowedVideoID: videoID)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.preferences.isElementFullscreenEnabled = true
        // Ephemeral: no persistent cookies, cache, or YouTube login state across launches.
        config.websiteDataStore = .nonPersistent()

        let hideUI = WKUserScript(
            source: Self.hideUIScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(hideUI)

        #if DEBUG
        // Monitor whether YouTube renamed any DOM selectors we depend on so
        // the "layout looks off" symptom shows up in the debugger before a
        // real user reports it. No-op in Release builds.
        let monitor = WKUserScript(
            source: Self.selectorMonitorScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(monitor)
        config.userContentController.add(context.coordinator, name: "selectorMissed")
        #endif

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black

        guard YouTubeURL.isValid(id: videoID),
              var components = URLComponents(string: "https://m.youtube.com/watch") else {
            return webView
        }
        components.queryItems = [URLQueryItem(name: "v", value: videoID)]
        if let url = components.url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.navigationDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let allowedVideoID: String

        init(allowedVideoID: String) {
            self.allowedVideoID = allowedVideoID
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "selectorMissed" {
                print("[YouTubePlayer] DOM selector missing on YouTube page: \(message.body)")
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            // Non-link navigation (initial load, YouTube's own AJAX, fullscreen transitions)
            // stays in-frame. Only user-driven link taps and form submits get filtered.
            let type = navigationAction.navigationType
            guard type == .linkActivated || type == .formSubmitted,
                  let url = navigationAction.request.url else {
                return .allow
            }

            // Same video on YouTube's watch page: stay in-frame.
            if let host = url.host()?.lowercased(),
               host.hasSuffix("youtube.com") || host.hasSuffix("youtu.be"),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               components.queryItems?.first(where: { $0.name == "v" })?.value == allowedVideoID {
                return .allow
            }

            // Anything else (channel, related, share, sign-in, external site) → hand off
            // to the system so the user leaves via Safari instead of getting stuck in a
            // stripped-mobile-YouTube session inside our WKWebView.
            await UIApplication.shared.open(url)
            return .cancel
        }
    }

    private static let hideUIScript = """
    const s = document.createElement('style');
    s.textContent = `
        ytm-mobile-topbar-renderer,
        .mobile-topbar-header,
        #below-player,
        ytm-pivot-bar-renderer { display:none!important }
        body { margin:0!important; background:#000!important; overflow:hidden!important }
        #player-container-id {
            position:fixed!important; top:0!important; left:0!important;
            width:100vw!important; height:100vh!important;
        }
    `;
    document.head.appendChild(s);
    function fitVideo() {
        var mp = document.getElementById('movie_player');
        if (!mp) {
            var v = document.querySelector('video');
            if (v) mp = v.parentElement;
        }
        if (!mp || !mp.offsetWidth || !mp.offsetHeight) return;
        var scale = Math.min(
            window.innerWidth / mp.offsetWidth,
            window.innerHeight / mp.offsetHeight
        );
        mp.style.setProperty('position','fixed','important');
        mp.style.setProperty('top','50%','important');
        mp.style.setProperty('left','50%','important');
        mp.style.setProperty('transform',
            'translate(-50%,-50%) scale('+scale+')','important');
        mp.style.setProperty('transform-origin','center center','important');
    }
    setInterval(fitVideo, 500);
    """

    /// DEBUG-only diagnostic: 3s after page load, checks each selector our CSS
    /// and JS depend on and reports any that don't match anything. The 3s wait
    /// covers YouTube's initial hydration; if a selector is still missing after
    /// that, YouTube has almost certainly renamed it and our layout will be off.
    private static let selectorMonitorScript = """
    setTimeout(function() {
        var selectors = [
            'ytm-mobile-topbar-renderer',
            '.mobile-topbar-header',
            '#below-player',
            'ytm-pivot-bar-renderer',
            '#movie_player',
            '#player-container-id'
        ];
        selectors.forEach(function(sel) {
            if (!document.querySelector(sel)) {
                window.webkit.messageHandlers.selectorMissed.postMessage(sel);
            }
        });
    }, 3000);
    """
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
