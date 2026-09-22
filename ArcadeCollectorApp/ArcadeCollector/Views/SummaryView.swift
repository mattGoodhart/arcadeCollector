//
//  SummaryView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData
import Charts

struct SummaryView: View {
    @Query private var games: [Game]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAbout = false
    @State private var bulkFetchTask: Task<Void, Never>?
    @State private var bulkProgress: BulkArtworkFetcher.Progress?
    @State private var bulkResult: BulkArtworkFetcher.Result?
    @State private var nothingToFetch = false
    @State private var bulkFetchError: String?

    private var isBulkFetching: Bool { bulkFetchTask != nil }

    var body: some View {
        let stats = SummaryStats(games: games)

        NavigationStack {
            List {
                collectionCountsSection(stats)
                bulkArtworkSection(stats)
                boardConditionSection(stats)
                componentBreakdownSection(stats)
            }
            .scrollContentBackground(.hidden)
            .background(Color.arcadeSummaryBackground)
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
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
            .onDisappear { cancelBulkFetch() }
            .onChange(of: stats.owned) {
                guard !isBulkFetching else { return }
                // Walks the artwork relationship, so it only runs when the
                // owned count actually changes — never on a plain re-render.
                let missingArtwork = games.lazy
                    .filter { $0.ownership == .owned }
                    .contains { Set($0.artwork.map(\.kind)) != ArtworkKind.bulkFetchable }
                if missingArtwork {
                    bulkProgress = nil
                    bulkResult = nil
                    nothingToFetch = false
                }
            }
        }
    }

    // MARK: - Collection Counts

    private func collectionCountsSection(_ stats: SummaryStats) -> some View {
        Section("Collection") {
            StatRow(label: "Total Games", value: stats.total, icon: "list.bullet")
            StatRow(label: "Owned", value: stats.owned, icon: "star.circle")
            StatRow(label: "Wanted", value: stats.wanted, icon: "heart.circle")
            StatRow(label: "In Repair", value: stats.inRepair, icon: "wrench.and.screwdriver")
        }
    }

    // MARK: - Bulk Artwork Fetch

    private func bulkArtworkSection(_ stats: SummaryStats) -> some View {
        Section("Artwork") {
            if let progress = bulkProgress, isBulkFetching {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(
                        value: Double(progress.completed),
                        total: Double(max(progress.total, 1))
                    )
                    Text("\(progress.completed) of \(progress.total) — \(progress.currentTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)

                Button(role: .destructive) {
                    cancelBulkFetch()
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
            } else if let result = bulkResult {
                bulkResultRow(result)
                if result.failed > 0 {
                    Button {
                        startBulkFetch()
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                }
            } else if nothingToFetch {
                Label("All owned games have artwork", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            } else if let error = bulkFetchError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            } else {
                Button {
                    startBulkFetch()
                } label: {
                    Label("Fetch All Missing Artwork", systemImage: "arrow.down.circle")
                }
                .disabled(stats.owned == 0)
            }
        }
    }

    @ViewBuilder
    private func bulkResultRow(_ result: BulkArtworkFetcher.Result) -> some View {
        if result.failed == 0 {
            Label("Fetched artwork for \(result.succeeded) game\(result.succeeded == 1 ? "" : "s")",
                  systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        } else if result.succeeded == 0 {
            Label("Couldn't fetch artwork. Check your connection and try again.",
                  systemImage: "wifi.exclamationmark")
                .foregroundStyle(.orange)
        } else {
            Label("Fetched \(result.succeeded) of \(result.attempted). \(result.failed) failed.",
                  systemImage: "exclamationmark.circle")
                .foregroundStyle(.orange)
        }
    }

    private func startBulkFetch() {
        nothingToFetch = false
        bulkResult = nil
        let container = modelContext.container
        bulkFetchTask = Task {
            let fetcher = BulkArtworkFetcher(modelContainer: container)
            do {
                let result = try await fetcher.fetchAllMissing { progress in
                    Task { @MainActor in
                        bulkProgress = progress
                    }
                }
                if result.attempted == 0 {
                    nothingToFetch = true
                } else {
                    bulkResult = result
                }
            } catch is CancellationError {
                // User cancelled
            } catch {
                bulkFetchError = error.localizedDescription
                try? await Task.sleep(for: .seconds(3))
                bulkFetchError = nil
            }
            bulkFetchTask = nil
        }
    }

    private func cancelBulkFetch() {
        bulkFetchTask?.cancel()
        bulkFetchTask = nil
    }

    // MARK: - Board Condition Chart

    private func gamesByCondition(_ stats: SummaryStats) -> [(label: String, count: Int, color: Color, labelColor: Color)] {
        let isDark = colorScheme == .dark
        return [
            ("Working", stats.workingBoards, ComponentStatus.working.color, isDark ? .black : .white),
            ("Issues", stats.boardsWithIssues, ComponentStatus.issues.color, .black),
            ("Broken", stats.brokenBoards, ComponentStatus.broken.color, isDark ? .black : .white),
            ("Untested", stats.untestedBoards, ComponentStatus.untested.color, isDark ? .black : .white),
        ].filter { $0.count > 0 }
    }

    private func boardConditionSection(_ stats: SummaryStats) -> some View {
        // Bound once so the chart, its legend, and the accessibility value
        // share one array instead of rebuilding it three times.
        let conditions = gamesByCondition(stats)

        return Section("Game Condition") {
            if stats.owned == 0 {
                Text("No owned games yet")
                    .foregroundStyle(.secondary)
            } else {
                Chart(conditions, id: \.label) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        if item.count > 0 {
                            VStack(spacing: 0) {
                                Text(item.label)
                                    .font(.caption2)
                                Text("\(item.count)")
                                    .font(.caption2.bold())
                            }
                            .foregroundStyle(item.labelColor)
                        }
                    }
                }
                .accessibilityLabel("Game condition breakdown")
                .accessibilityValue(conditions.map { "\($0.label) \($0.count)" }.joined(separator: ", "))
                .chartLegend(position: .bottom) {
                    HStack(spacing: 16) {
                        ForEach(conditions, id: \.label) { item in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                    .accessibilityHidden(true)
                                Text(item.label)
                                    .font(.caption)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(item.label): \(item.count)")
                        }
                    }
                }
                .chartBackground { proxy in
                    Color.arcadeSummaryBackground.overlay {
                        Image("AppIconImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 8)
                .listRowBackground(Color.arcadeSummaryBackground)
                .listRowInsets(EdgeInsets())
            }
        }
    }

    // MARK: - Component Status Breakdown

    private func componentBreakdownSection(_ stats: SummaryStats) -> some View {
        Section("Component Status (Owned Games)") {
            if stats.owned == 0 {
                Text("No owned games yet")
                    .foregroundStyle(.secondary)
            } else {
                ComponentStatRow(label: "Boot", counts: stats.boot)
                ComponentStatRow(label: "Audio", counts: stats.audio)
                ComponentStatRow(label: "Video", counts: stats.video)
                ComponentStatRow(label: "Controls", counts: stats.controls)
                ComponentStatRow(label: "Extended Play", counts: stats.extendedPlay)
            }
        }
    }
}

// MARK: - Supporting Views

private struct StatRow: View {
    let label: String
    let value: Int
    let icon: String

    var body: some View {
        LabeledContent {
            Text("\(value)")
                .fontDesign(.rounded)
                .bold()
        } label: {
            Label(label, systemImage: icon)
        }
    }
}

private struct ComponentStatRow: View {
    let label: String
    let counts: [ComponentStatus: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)

            HStack(spacing: 0) {
                ForEach(ComponentStatus.allCases) { status in
                    let count = counts[status, default: 0]
                    if count > 0 {
                        Rectangle()
                            .fill(status.color)
                            .overlay {
                                Text("\(count)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(status.barLabelColor)
                            }
                    }
                }
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        ComponentStatus.allCases
            .compactMap { status in
                let count = counts[status, default: 0]
                return count > 0 ? "\(status.displayName) \(count)" : nil
            }
            .joined(separator: ", ")
    }
}
