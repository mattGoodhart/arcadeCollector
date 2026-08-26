//
//  PersistenceMigrationTests.swift
//  ArcadeCollectorTests
//
//  Smoke test for the migration path every user hits on app relaunch: a
//  persistent store is written on launch N, then re-opened on launch N+1
//  with (potentially) an updated schema. If a future schema change breaks
//  that path — the canonical example being adding a non-optional stored
//  property without an inline default — this test catches it before the
//  build reaches the App Store.
//

import Testing
import Foundation
import SwiftData
@testable import ArcadeCollector

@Suite("SwiftData persistence roundtrip")
struct PersistenceMigrationTests {

    private static func schema() -> Schema { AppSchema.schema }

    private static func makeOnDiskURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PersistenceMigrationTest-\(UUID().uuidString).store")
    }

    /// Populates an on-disk store, tears down the container, re-opens it, and
    /// verifies every user-authored field survived. Exercises the exact
    /// path a returning user hits on every launch after the first one.
    @Test func userDataSurvivesContainerRestart() async throws {
        let storeURL = Self.makeOnDiskURL()
        defer {
            try? FileManager.default.removeItem(at: storeURL)
            // SwiftData also writes -shm / -wal sidecar files.
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
        }

        let schema = Self.schema()
        let photoBytes = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])

        // --- First launch: write ---
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, url: storeURL)
            )
            let context = ModelContext(container)

            let game = Game(
                romSetName: "pacman",
                title: "Pac-Man",
                manufacturer: "Namco",
                year: "1980",
                players: "1",
                orientation: .vertical,
                ownership: .owned
            )
            game.bootStatus = .working
            game.audioStatus = .issues
            game.videoStatus = .broken
            game.controlsStatus = .untested
            game.extendedPlayStatus = .working

            let log = RepairLog(
                date: Date(timeIntervalSince1970: 1_700_000_000),
                notes: "Replaced blown audio amp"
            )
            log.photos.append(RepairLogPhoto(order: 0, imageData: photoBytes))
            game.repairLogs.append(log)

            context.insert(game)
            try context.save()
        }

        // --- Second launch: read ---
        let container2 = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: storeURL)
        )
        let context2 = ModelContext(container2)
        let games = try context2.fetch(FetchDescriptor<Game>())

        #expect(games.count == 1)
        let game = try #require(games.first)
        #expect(game.romSetName == "pacman")
        #expect(game.title == "Pac-Man")
        #expect(game.ownership == .owned)
        #expect(game.orientation == .vertical)
        #expect(game.bootStatus == .working)
        #expect(game.audioStatus == .issues)
        #expect(game.videoStatus == .broken)
        #expect(game.controlsStatus == .untested)
        #expect(game.extendedPlayStatus == .working)

        #expect(game.repairLogs.count == 1)
        let log = try #require(game.repairLogs.first)
        #expect(log.notes == "Replaced blown audio amp")
        #expect(log.date == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(log.photos.count == 1)
        #expect(log.photos.first?.imageData == photoBytes)
    }

    /// Empty stores must round-trip too — this catches "the schema doesn't
    /// open cleanly" bugs even when there's no user data to lose.
    @Test func emptyStoreOpensCleanlyAfterRestart() async throws {
        let storeURL = Self.makeOnDiskURL()
        defer {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
        }
        let schema = Self.schema()

        do {
            _ = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, url: storeURL)
            )
        }

        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: storeURL)
        )
        let context = ModelContext(container)
        let games = try context.fetch(FetchDescriptor<Game>())
        #expect(games.isEmpty)
    }
}
