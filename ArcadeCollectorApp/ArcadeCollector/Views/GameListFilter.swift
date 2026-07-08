//
//  GameListFilter.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

enum GameListMode: Hashable {
    case allGames, myCollection, wanted, repairLogs

    var title: String {
        switch self {
        case .allGames:     return "All Games"
        case .myCollection: return "My Collection"
        case .wanted:       return "Wanted"
        case .repairLogs:   return "Repair Logs"
        }
    }

    var tabIcon: String {
        switch self {
        case .allGames:     return "list.bullet"
        case .myCollection: return "star.circle"
        case .wanted:       return "heart.circle"
        case .repairLogs:   return "list.clipboard"
        }
    }

    var emptyTitle: String {
        switch self {
        case .allGames:     return "No Games"
        case .myCollection: return "No Games in Collection"
        case .wanted:       return "No Wanted Games"
        case .repairLogs:   return "No Repair Logs"
        }
    }

    var emptyDescription: String {
        switch self {
        case .allGames:     return "Games will appear here once seeded."
        case .myCollection: return "Mark games as Owned to add them here."
        case .wanted:       return "Mark games as Wanted to add them here."
        case .repairLogs:   return "Games with repair entries will appear here."
        }
    }

    var showsOwnershipFilter: Bool {
        self == .allGames
    }
}

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
        ownership != nil || orientation != nil || mode != .allGames
    }

    var mode: GameListMode = .allGames

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

    /// Post-fetch filter for enum-typed properties and tab mode.
    func matchesEnumFilters(_ game: Game) -> Bool {
        switch mode {
        case .myCollection:
            if game.ownership != .owned { return false }
        case .wanted:
            if game.ownership != .wanted { return false }
        case .repairLogs:
            if game.lastRepairLogDate == nil { return false }
        case .allGames:
            if let ownership, game.ownership != ownership { return false }
        }
        if let orientation, game.orientation != orientation { return false }
        return true
    }
}
