//
//  RepairLogDateTests.swift
//  ArcadeCollectorTests
//
//  Pins `Game.lastRepairLogDate`, a denormalized cache with an outsized blast
//  radius: it is the *only* field the Repair Logs tab filters on
//  (`GameListFilter.matchesEnumFilters`) and the only one behind the Summary's
//  "In Repair" count. Neither reads `repairLogs` directly, because both run
//  in-memory across every row in the store.
//
//  That made a stale cache invisible to every other test in the suite. A real
//  bug shipped because of it: deleting a game's last repair log left the date
//  set, so the game sat on the Repair Logs tab claiming history it no longer
//  had. The delete-path cases below are that bug, written down.
//

import Testing
import Foundation
import SwiftData
@testable import ArcadeCollector

@Suite("Game.lastRepairLogDate")
struct RepairLogDateTests {

    // MARK: - Fixtures

    private static func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: AppSchema.schema,
            configurations: ModelConfiguration(schema: AppSchema.schema, isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    /// Fixed reference date so ordering assertions don't depend on wall clock.
    private static let base = Date(timeIntervalSince1970: 1_700_000_000)

    private static func day(_ offset: Int) -> Date {
        base.addingTimeInterval(Double(offset) * 86_400)
    }

    @discardableResult
    private static func attach(_ dates: [Date], to game: Game) -> [RepairLog] {
        let logs = dates.map { RepairLog(date: $0, notes: "") }
        game.repairLogs.append(contentsOf: logs)
        return logs
    }

    // MARK: - Recompute from the relationship

    @Test("No repair logs leaves the date nil")
    func emptyIsNil() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        game.refreshLastRepairLogDate()

        #expect(game.lastRepairLogDate == nil)
    }

    @Test("Date tracks the newest entry, not the last appended")
    func picksMaximumNotLast() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        // Deliberately out of order, newest in the middle.
        Self.attach([Self.day(1), Self.day(9), Self.day(4)], to: game)
        game.refreshLastRepairLogDate()

        #expect(game.lastRepairLogDate == Self.day(9))
    }

    /// Guards the original `addEntry` bug: it assigned the new entry's date
    /// outright, so a back-dated entry would drag "Last Entry" backwards.
    @Test("Adding a back-dated entry does not regress the date")
    func backDatedEntryDoesNotRegress() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        Self.attach([Self.day(9)], to: game)
        game.refreshLastRepairLogDate()
        #expect(game.lastRepairLogDate == Self.day(9))

        Self.attach([Self.day(2)], to: game)
        game.refreshLastRepairLogDate()

        #expect(game.lastRepairLogDate == Self.day(9))
    }

    // MARK: - Delete paths

    /// Deletes `logs` the way `RepairLogListView.deleteLogs` does *minus* the
    /// `repairLogs.removeAll` detach step, leaving the inverse relationship
    /// stale on purpose.
    ///
    /// This is the configuration the shipped bug actually occurred in, and
    /// leaving the detach out is deliberate. An earlier draft of these tests
    /// mirrored production exactly — detach, delete, recompute — and every
    /// one of them still passed when the fix was reverted, because the detach
    /// had already cleaned the array and `excluding:` never did any work.
    /// They proved the happy path and nothing else. Exercising the stale-array
    /// case is the only way these fail when the bug comes back; the
    /// belt-and-suspenders combination is covered separately by
    /// `fullDeletePathMatchesProduction`.
    private static func deleteLeavingRelationshipStale(
        _ logs: [RepairLog],
        from game: Game,
        in context: ModelContext
    ) {
        let doomed = Set(logs.map(\.persistentModelID))
        for log in logs { context.delete(log) }
        game.refreshLastRepairLogDate(excluding: doomed)
    }

    /// The shipped bug. Deleting the only entry has to clear the date, or the
    /// game is stranded on the Repair Logs tab forever.
    @Test("Deleting the only entry clears the date")
    func deletingOnlyEntryClearsDate() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        let logs = Self.attach([Self.day(3)], to: game)
        game.refreshLastRepairLogDate()
        #expect(game.lastRepairLogDate != nil)

        Self.deleteLeavingRelationshipStale([logs[0]], from: game, in: context)

        #expect(game.lastRepairLogDate == nil)
    }

    @Test("Deleting the newest entry falls back to the surviving maximum")
    func deletingNewestFallsBack() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        let logs = Self.attach([Self.day(1), Self.day(5), Self.day(9)], to: game)
        game.refreshLastRepairLogDate()
        #expect(game.lastRepairLogDate == Self.day(9))

        Self.deleteLeavingRelationshipStale([logs[2]], from: game, in: context)

        #expect(game.lastRepairLogDate == Self.day(5))
    }

    @Test("Deleting an older entry leaves the date untouched")
    func deletingOlderKeepsDate() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        let logs = Self.attach([Self.day(1), Self.day(9)], to: game)
        game.refreshLastRepairLogDate()

        Self.deleteLeavingRelationshipStale([logs[0]], from: game, in: context)

        #expect(game.lastRepairLogDate == Self.day(9))
    }

    @Test("Deleting every entry at once clears the date")
    func deletingAllClearsDate() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        let logs = Self.attach([Self.day(1), Self.day(5), Self.day(9)], to: game)
        game.refreshLastRepairLogDate()

        Self.deleteLeavingRelationshipStale(logs, from: game, in: context)

        #expect(game.lastRepairLogDate == nil)
    }

    /// Both defenses together, in the order `RepairLogListView.deleteLogs`
    /// applies them: detach from the relationship, delete, then recompute with
    /// the doomed IDs excluded. Also pins the detach itself, which is what
    /// keeps the list and its empty-state overlay correct on the same pass.
    @Test("Full delete path clears both the relationship and the date")
    func fullDeletePathMatchesProduction() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        let logs = Self.attach([Self.day(1), Self.day(9)], to: game)
        game.refreshLastRepairLogDate()

        let doomed = Set(logs.map(\.persistentModelID))
        game.repairLogs.removeAll { doomed.contains($0.persistentModelID) }
        for log in logs { context.delete(log) }
        game.refreshLastRepairLogDate(excluding: doomed)

        #expect(game.repairLogs.isEmpty)
        #expect(game.lastRepairLogDate == nil)
    }

    // MARK: - Tab filter integration

    /// Ties the cache to the thing that actually consumes it. If this fails,
    /// the Repair Logs tab is showing or hiding the wrong games regardless of
    /// what the field says.
    @Test("Repair Logs tab filter follows the cache")
    func repairLogsFilterFollowsCache() throws {
        let context = try Self.makeContext()
        let game = Game(romSetName: "dkong", title: "Donkey Kong")
        context.insert(game)

        var filter = GameListFilter()
        filter.mode = .repairLogs

        #expect(filter.matchesEnumFilters(game) == false)

        let logs = Self.attach([Self.day(3)], to: game)
        game.refreshLastRepairLogDate()
        #expect(filter.matchesEnumFilters(game) == true)

        Self.deleteLeavingRelationshipStale([logs[0]], from: game, in: context)

        #expect(filter.matchesEnumFilters(game) == false)
    }
}
