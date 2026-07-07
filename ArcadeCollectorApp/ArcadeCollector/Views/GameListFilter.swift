//
//  GameListFilter.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

/// Sort options exposed in the games list toolbar.
enum GameSort: String, CaseIterable, Identifiable {
    case title
    case year
    case manufacturer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .title:        return "Title"
        case .year:         return "Year"
        case .manufacturer: return "Manufacturer"
        }
    }

    var descriptor: SortDescriptor<Game> {
        switch self {
        case .title:        return SortDescriptor(\Game.title)
        case .year:         return SortDescriptor(\Game.year)
        case .manufacturer: return SortDescriptor(\Game.manufacturer)
        }
    }
}

/// Value-type bundle of the currently active list filters.
///
/// SwiftData's `#Predicate` doesn't (yet) support KeyPaths that traverse
/// into custom enum types — `\Game.ownership.rawValue`,
/// `\Game.ownership.id`, and even `game.ownership == OwnershipStatus.owned`
/// all fail at either macro expansion, schema validation, or
/// `unsupportedPredicate` runtime.
///
/// So the split is:
/// - **`searchPredicate`** goes into the `@Query` at the SwiftData layer
///   (String predicates are fully supported and fast on SQLite).
/// - **`matchesEnumFilters(_:)`** runs in-memory on the query result to
///   apply ownership + orientation filters.
struct GameListFilter: Equatable {
    var search: String = ""
    var ownership: OwnershipStatus? = nil
    var orientation: ScreenOrientation? = nil

    var isActive: Bool {
        !search.trimmingCharacters(in: .whitespaces).isEmpty
            || ownership != nil
            || orientation != nil
    }

    var hasEnumFilters: Bool {
        ownership != nil || orientation != nil
    }

    /// SwiftData-friendly predicate covering the text-search portion.
    /// Returns nil when the search field is empty, letting SwiftData skip
    /// the predicate entirely.
    var searchPredicate: Predicate<Game>? {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return nil }
        return #Predicate<Game> { game in
            game.title.localizedStandardContains(query)
        }
    }

    /// Post-fetch filter for enum-typed properties.
    func matchesEnumFilters(_ game: Game) -> Bool {
        if let ownership, game.ownership != ownership { return false }
        if let orientation, game.orientation != orientation { return false }
        return true
    }
}
