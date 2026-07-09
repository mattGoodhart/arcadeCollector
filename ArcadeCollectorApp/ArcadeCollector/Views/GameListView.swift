//
//  GameListView.swift
//  ArcadeCollector
//
//  Dynamic-`@Query` child view. Sort and text-search predicate are captured
//  at init time; enum filters are applied in-memory on the query result
//  because SwiftData `#Predicate` doesn't support custom-enum property
//  filtering. See `GameListFilter` for background.
//

import SwiftUI
import SwiftData

struct GameListView: View {
    @Query private var games: [Game]
    private let filter: GameListFilter
    private let mode: GameListMode

    init(sort: SortDescriptor<Game>, filter: GameListFilter) {
        self._games = Query(filter: filter.searchPredicate, sort: [sort])
        self.filter = filter
        self.mode = filter.mode
    }

    private struct YearGroup: Identifiable {
        let year: String
        let games: [Game]
        let startIndex: Int
        var id: String { year }
    }

    private func groupedByYear(_ games: [Game]) -> [YearGroup] {
        let dict = Dictionary(grouping: games) { $0.year.isEmpty ? "Unknown" : $0.year }
        let sorted = dict.sorted { $0.key < $1.key }
        var groups: [YearGroup] = []
        var running = 0
        for (year, yearGames) in sorted {
            groups.append(YearGroup(year: year, games: yearGames, startIndex: running))
            running += yearGames.count
        }
        return groups
    }

    var body: some View {
        let visible = filter.hasEnumFilters
            ? games.filter(filter.matchesEnumFilters)
            : games

        let groups = groupedByYear(visible)

        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    ForEach(groups) { group in
                        Section {
                            ForEach(Array(group.games.enumerated()), id: \.element.id) { localIndex, game in
                                let globalIndex = group.startIndex + localIndex
                                NavigationLink(value: game) {
                                    GameRow(game: game, isDarkRow: !globalIndex.isMultiple(of: 2))
                                }
                                .listRowBackground(globalIndex.isMultiple(of: 2) ? Color.arcadeRowEven : Color.arcadeRowOdd)
                            }
                        } header: {
                            Text(group.year)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.arcadeRowOdd)
                        }
                        .id(group.year)
                    }
                }
                .listStyle(.plain)

                if groups.count > 1 {
                    SectionIndexOverlay(sections: groups.map(\.year)) { year in
                        proxy.scrollTo(year, anchor: .top)
                    }
                }
            }
        }
        .overlay {
            if visible.isEmpty {
                if !filter.search.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ContentUnavailableView(
                        mode.emptyTitle,
                        systemImage: mode.tabIcon,
                        description: Text(mode.emptyDescription)
                    )
                }
            }
        }
    }
}

// MARK: - Section Index

private struct SectionIndexOverlay: View {
    let sections: [String]
    let onSelect: (String) -> Void

    @State private var labelStackHeight: CGFloat = 1

    /// Named coordinate space anchored on the labels stack (not the padded
    /// outer frame), so drag `value.location.y` maps directly onto label
    /// positions without an offset from the surrounding vertical padding.
    private static let labelsSpace = "SectionIndexOverlay.labels"

    var body: some View {
        VStack(spacing: 0) {
            ForEach(sections, id: \.self) { section in
                indexLabel(for: section)
            }
        }
        .frame(width: 18)
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { labelStackHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, h in labelStackHeight = h }
            }
        }
        .coordinateSpace(name: Self.labelsSpace)
        .padding(.vertical, 4)
        .background(Color.arcadeRowOdd.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
        .padding(.trailing, 2)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .accessibilityHidden(true)
    }

    private func indexLabel(for section: String) -> some View {
        let label = section.count >= 4 ? String(section.suffix(2)) : String(section.prefix(2))
        return Text(label)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.labelsSpace))
            .onChanged { value in
                let y = max(0, min(labelStackHeight, value.location.y))
                let index = Int(y / labelStackHeight * CGFloat(sections.count))
                let clamped = max(0, min(sections.count - 1, index))
                onSelect(sections[clamped])
            }
    }
}

// MARK: - Game Row

struct GameRow: View {
    let game: Game
    var isDarkRow = false

    private var iconImage: UIImage? {
        NSDataAsset(name: "icons/\(game.romSetName)")
            .flatMap { UIImage(data: $0.data) }
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let iconImage {
                    Image(uiImage: iconImage)
                        .resizable()
                        .interpolation(.high)
                } else {
                    Image("space-invaders-placeholder")
                        .resizable()
                }
            }
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(game.title)
                    .font(.headline)
                    .foregroundStyle(isDarkRow ? .white : .primary)
                HStack(spacing: 6) {
                    Text(game.romSetName)
                    if !game.year.isEmpty {
                        Text("·")
                        Text(game.year)
                    }
                    if !game.manufacturer.isEmpty {
                        Text("·")
                        Text(game.manufacturer)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(isDarkRow ? Color.white.opacity(0.7) : .secondary)
            }
        }
    }
}
