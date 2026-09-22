//
//  GameListFilter.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

nonisolated enum GameListMode: Hashable {
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
        case .myCollection: return "Toggle \"Have the PCB\" on a game to add it here."
        case .wanted:       return "Tap the heart on a game to add it here."
        case .repairLogs:   return "Games with repair entries will appear here."
        }
    }

    var showsOwnershipFilter: Bool {
        self == .allGames
    }
}

/// Sort options exposed in the games list toolbar.
///
/// Intentionally does *not* include `.year` — the All Games tab is already
/// grouped into year sections with a section-index scrubber, so a year sort
/// would just reorder within-section without adding navigability.
enum GameSort: String, CaseIterable, Identifiable {
    case title
    case manufacturer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .title:        return "Title"
        case .manufacturer: return "Manufacturer"
        }
    }

    var descriptor: SortDescriptor<Game> {
        switch self {
        case .title:        return SortDescriptor(\Game.title)
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
nonisolated struct GameListFilter: Equatable {
    var search: String = ""
    var ownership: OwnershipStatus? = nil
    var orientation: ScreenOrientation? = nil
    var genre: String? = nil
    var nplayers: String? = nil

    var isActive: Bool {
        !search.trimmingCharacters(in: .whitespaces).isEmpty
            || ownership != nil
            || orientation != nil
            || genre != nil
            || nplayers != nil
    }

    var hasEnumFilters: Bool {
        ownership != nil || orientation != nil || genre != nil || nplayers != nil || mode != .allGames
    }

    var mode: GameListMode = .allGames

    /// SwiftData-friendly predicate: the text search, plus the repair-log
    /// clause on the Repair Logs tab. Returns nil when neither applies,
    /// letting SwiftData skip the predicate entirely.
    ///
    /// `lastRepairLogDate` is a plain `Date?` column, so unlike the enum
    /// properties it *is* expressible in `#Predicate` — which matters a lot
    /// here. Pushing it down to SQLite takes that tab's fetch from all 3,855
    /// rows to just the handful with repair history, and shrinks the set of
    /// per-object observation dependencies the list body registers by the
    /// same factor. `matchesEnumFilters` still re-checks it in memory: a
    /// pending delete is not visible to SQL until the context saves, so the
    /// in-memory pass stays authoritative.
    var searchPredicate: Predicate<Game>? {
        let query = search.trimmingCharacters(in: .whitespaces)

        switch (query.isEmpty, mode == .repairLogs) {
        case (true, false):
            return nil
        case (false, false):
            return #Predicate<Game> { game in
                game.title.localizedStandardContains(query)
            }
        case (true, true):
            return #Predicate<Game> { game in
                game.lastRepairLogDate != nil
            }
        case (false, true):
            return #Predicate<Game> { game in
                game.lastRepairLogDate != nil && game.title.localizedStandardContains(query)
            }
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
        if let genre, game.genre != genre { return false }
        if let nplayers, game.nplayers != nplayers { return false }
        return true
    }
}
