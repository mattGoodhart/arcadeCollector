//
//  SummaryView.swift
//  ArcadeCollector
//

import SwiftUI
import SwiftData
import Charts

struct SummaryView: View {
    @Query private var games: [Game]
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                collectionCountsSection
                boardConditionSection
                componentBreakdownSection
            }
            .navigationTitle("Summary")
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
        }
    }

    // MARK: - Collection Counts

    private var ownedGames: [Game] { games.filter { $0.ownership == .owned } }
    private var wantedGames: [Game] { games.filter { $0.ownership == .wanted } }
    private var gamesInRepair: [Game] { games.filter { $0.lastRepairLogDate != nil } }
    private var boardsOwned: [Game] { games.filter { $0.hasBoard } }

    private var collectionCountsSection: some View {
        Section("Collection") {
            StatRow(label: "Total Games", value: games.count, icon: "list.bullet")
            StatRow(label: "Owned", value: ownedGames.count, icon: "star.circle")
            StatRow(label: "Wanted", value: wantedGames.count, icon: "heart.circle")
            StatRow(label: "In Repair", value: gamesInRepair.count, icon: "wrench.and.screwdriver")
            StatRow(label: "Boards Owned", value: boardsOwned.count, icon: "cpu")
        }
    }

    // MARK: - Board Condition Chart

    private var boardsByCondition: [(label: String, count: Int, color: Color)] {
        let boards = boardsOwned
        let working = boards.filter { $0.functionalCondition == .working }.count
        let issues = boards.filter { $0.functionalCondition == .issues }.count
        let broken = boards.filter { $0.functionalCondition == .broken }.count
        let untested = boards.filter { $0.functionalCondition == .untested }.count

        return [
            ("Working", working, .green),
            ("Issues", issues, .yellow),
            ("Broken", broken, .red),
            ("Untested", untested, .secondary),
        ].filter { $0.count > 0 }
    }

    private var boardConditionSection: some View {
        Section("Board Condition") {
            if boardsOwned.isEmpty {
                Text("No boards in collection yet")
                    .foregroundStyle(.secondary)
            } else {
                Chart(boardsByCondition, id: \.label) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .chartLegend(position: .bottom) {
                    HStack(spacing: 16) {
                        ForEach(boardsByCondition, id: \.label) { item in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                Text(item.label)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Component Status Breakdown

    private var componentBreakdownSection: some View {
        Section("Component Status (Owned Games)") {
            if ownedGames.isEmpty {
                Text("No owned games yet")
                    .foregroundStyle(.secondary)
            } else {
                ComponentStatRow(label: "Boot", counts: statusCounts(\.bootStatus))
                ComponentStatRow(label: "Audio", counts: statusCounts(\.audioStatus))
                ComponentStatRow(label: "Video", counts: statusCounts(\.videoStatus))
                ComponentStatRow(label: "Controls", counts: statusCounts(\.controlsStatus))
                ComponentStatRow(label: "Extended Play", counts: statusCounts(\.extendedPlayStatus))
            }
        }
    }

    private func statusCounts(_ keyPath: KeyPath<Game, ComponentStatus>) -> [ComponentStatus: Int] {
        var counts: [ComponentStatus: Int] = [:]
        for game in ownedGames {
            counts[game[keyPath: keyPath], default: 0] += 1
        }
        return counts
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
                                    .foregroundStyle(.white)
                            }
                    }
                }
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 4)
    }
}
