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

    var body: some View {
        let visible = filter.hasEnumFilters
            ? games.filter(filter.matchesEnumFilters)
            : games

        List {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, game in
                NavigationLink(value: game) {
                    GameRow(game: game, isDarkRow: !index.isMultiple(of: 2))
                }
                .listRowBackground(index.isMultiple(of: 2) ? Color.arcadeRowEven : Color.arcadeRowOdd)
            }
        }
        .listStyle(.plain)
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
