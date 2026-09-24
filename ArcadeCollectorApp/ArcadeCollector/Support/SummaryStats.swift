//
//  SummaryStats.swift
//  ArcadeCollector
//

import Foundation

/// Every collection count and component breakdown shown on the Summary tab,
/// derived in a single pass over a set of games.
///
/// `SummaryView` is the most expensive consumer of a SwiftData change in the
/// app: `ContentView` is a `TabView`, so once a tab has been visited its
/// unbounded `@Query var games: [Game]` stays live, and *any* save anywhere
/// re-evaluates that body over all ~3,855 rows. The shape this replaced —
/// `ownedGames` as an uncached computed property, read by a dozen call sites
/// including `statusCounts` five times and `gamesByCondition` three times —
/// turned one save into roughly fifteen full passes plus a Swift Charts
/// relayout, all on the main thread. One pass, one value type.
///
/// Lives here rather than nested in the view so it can be tested directly;
/// the aggregation rules below are real logic, not presentation.
struct SummaryStats: Equatable {
    var total = 0
    var owned = 0
    var wanted = 0
    var inRepair = 0

    var workingBoards = 0
    var boardsWithIssues = 0
    var brokenBoards = 0
    var untestedBoards = 0

    var boot: [ComponentStatus: Int] = [:]
    var audio: [ComponentStatus: Int] = [:]
    var video: [ComponentStatus: Int] = [:]
    var controls: [ComponentStatus: Int] = [:]
    var extendedPlay: [ComponentStatus: Int] = [:]

    init() {}

    /// - Note: The four condition buckets are evaluated independently rather
    ///   than as an `if/else if` chain. They happen to be mutually exclusive
    ///   given the predicates below, but nothing in the types enforces that,
    ///   and collapsing them into a chain would silently change the answer if
    ///   a predicate is ever edited. See `SummaryStatsTests` for the cases
    ///   that pin the boundaries.
    init(games: [Game]) {
        total = games.count

        for game in games {
            // Counted across the whole store, not just owned games — the
            // Summary's "In Repair" row matches the Repair Logs tab, which
            // filters on this field alone.
            if game.lastRepairLogDate != nil { inRepair += 1 }

            if game.ownership == .wanted { wanted += 1 }

            // Everything below is scoped to owned games only.
            guard game.ownership == .owned else { continue }
            owned += 1

            boot[game.bootStatus, default: 0] += 1
            audio[game.audioStatus, default: 0] += 1
            video[game.videoStatus, default: 0] += 1
            controls[game.controlsStatus, default: 0] += 1
            extendedPlay[game.extendedPlayStatus, default: 0] += 1

            if game.bootStatus == .untested,
               game.audioStatus == .untested,
               game.videoStatus == .untested,
               game.controlsStatus == .untested,
               game.extendedPlayStatus == .untested {
                untestedBoards += 1
            }

            // Extended play is allowed to be untested here: plenty of boards
            // are verified working without anyone sitting through a long run.
            if game.bootStatus == .working,
               game.audioStatus == .working,
               game.videoStatus == .working,
               game.controlsStatus == .working,
               game.extendedPlayStatus == .working || game.extendedPlayStatus == .untested {
                workingBoards += 1
            }

            // A board that won't boot is reported as broken, not as "issues",
            // hence the guard — otherwise a dead board with a broken speaker
            // would be counted in both buckets.
            if game.bootStatus != .broken,
               game.bootStatus == .issues
                || game.audioStatus == .issues || game.audioStatus == .broken
                || game.videoStatus == .issues || game.videoStatus == .broken
                || game.controlsStatus == .issues || game.controlsStatus == .broken
                || game.extendedPlayStatus == .issues || game.extendedPlayStatus == .broken {
                boardsWithIssues += 1
            }

            if game.bootStatus == .broken { brokenBoards += 1 }
        }
    }
}
