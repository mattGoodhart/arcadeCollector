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

        List(visible) { game in
            NavigationLink(value: game) {
                GameRow(game: game)
            }
        }
        .overlay {
            if visible.isEmpty {
                ContentUnavailableView.search
            }
        }
    }
}

struct GameRow: View {
    let game: Game

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: game.functionalCondition.symbolName)
                .foregroundStyle(game.functionalCondition.color)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(game.title)
                    .font(.headline)
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
                .foregroundStyle(.secondary)
            }
        }
    }
}
