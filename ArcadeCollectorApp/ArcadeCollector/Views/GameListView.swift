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

    init(sort: SortDescriptor<Game>, filter: GameListFilter) {
        self._games = Query(filter: filter.searchPredicate, sort: [sort])
        self.filter = filter
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
                ContentUnavailableView.search
            }
        }
    }
}

struct GameRow: View {
    let game: Game
    var isDarkRow = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: game.functionalCondition.symbolName)
                .foregroundStyle(game.functionalCondition.color)
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
