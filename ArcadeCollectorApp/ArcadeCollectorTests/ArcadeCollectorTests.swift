//
//  ArcadeCollectorTests.swift
//  ArcadeCollectorTests
//
//  Created by Matthew Goodhart on 7/5/26.
//

import Testing
import Foundation
import SwiftData
@testable import ArcadeCollector

@Suite("GameSeeder")
struct GameSeederTests {
    private static let fixture = Data("""
    [
      {
        "romName": "pacman",
        "Title": "Pac-Man ",
        "Year": 1980,
        "manufacturer": "Namco",
        "Players": 1,
        "Orientation": "VERTICAL",
        "nplayers": "2P alt",
        "use_chds": "NO",
        "sourcefile": "namco/pacman.cpp",
        "driver_status": "GOOD",
        "display_type": "RASTER",
        "display_width": 224,
        "display_height": 288,
        "buttons": "0",
        "genre": "Maze",
        "display_refresh": "60.606061",
        "input_controls": "joystick (4-way)",
        "monitor_type": "CRT 15kHz",
        "colors": "YES",
        "url_shortplays": "-",
        "chips_cpu": "Zilog Z80",
        "chips_audio": "Speaker,Namco",
        "chips_cpu_details": "",
        "chips_audio_details": "",
        "has_dip_switches": "YES",
        "category": "Maze",
        "screens": 1
      },
      {
        "romName": "sf2",
        "Title": "Street Fighter II",
        "Year": 1991,
        "manufacturer": "Capcom",
        "Players": 2,
        "Orientation": "HORIZONTAL",
        "nplayers": "2P sim",
        "use_chds": "NO",
        "sourcefile": "capcom/cps1.cpp",
        "driver_status": "GOOD",
        "display_type": "RASTER",
        "display_width": 384,
        "display_height": 224,
        "buttons": "6",
        "genre": "Fighter",
        "display_refresh": "59.637405",
        "input_controls": "joystick (8-way)",
        "monitor_type": "CRT 15kHz",
        "colors": "YES",
        "url_shortplays": "-",
        "chips_cpu": "Motorola 68000,Zilog Z80",
        "chips_audio": "Speaker,YM2151 OPM,OKI MSM6295 ADPCM",
        "chips_cpu_details": "",
        "chips_audio_details": "",
        "has_dip_switches": "YES",
        "category": "Fighter / Versus",
        "screens": 1
      }
    ]
    """.utf8)

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Game.self,
            GameArtwork.self,
            RepairLog.self,
            RepairLogPhoto.self,
            GameCollection.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    @Test func insertsAllGamesOnEmptyStore() async throws {
        let container = try makeContainer()
        let seeder = GameSeeder(modelContainer: container)
        try await seeder.seed(from: Self.fixture)

        let context = ModelContext(container)
        let games = try context.fetch(FetchDescriptor<Game>())

        #expect(games.count == 2)

        let pacman = try #require(games.first { $0.romSetName == "pacman" })
        #expect(pacman.title == "Pac-Man") // trimmed
        #expect(pacman.year == "1980")
        #expect(pacman.manufacturer == "Namco")
        #expect(pacman.orientation == .vertical)
        #expect(pacman.ownership == .none)
        #expect(pacman.bootStatus == .untested)
        #expect(pacman.genre == "Maze")
        #expect(pacman.driver == "namco/pacman.cpp")
        #expect(pacman.emulationStatus == "GOOD")
        #expect(pacman.inputControls == "joystick (4-way)")
        #expect(pacman.resolution == "224x288")
        #expect(pacman.cpus == ["Zilog Z80"])
        #expect(pacman.soundDevices == ["Speaker", "Namco"])
        #expect(pacman.nplayers == "2P alt")

        let sf2 = try #require(games.first { $0.romSetName == "sf2" })
        #expect(sf2.orientation == .horizontal)
        #expect(sf2.cpus == ["Motorola 68000", "Zilog Z80"])
    }

    @Test func isIdempotentWhenStoreAlreadyPopulated() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(Game(romSetName: "existing", title: "Already Here"))
        try context.save()

        let seeder = GameSeeder(modelContainer: container)
        try await seeder.seed(from: Self.fixture)

        let games = try context.fetch(FetchDescriptor<Game>())
        #expect(games.count == 1)
        #expect(games.first?.romSetName == "existing")
    }

    @Test func bundledResourceLoadsAndDecodes() throws {
        let appBundle = Bundle(for: BundleLocator.self)
        guard let url = Bundle.allBundles
            .compactMap({ $0.url(forResource: "Arcade Collector Value-only Seed July 24 2026", withExtension: "json") })
            .first
        else {
            Issue.record("Seed JSON not found in any loaded bundle")
            return
        }

        let data = try Data(contentsOf: url)
        let rows = try JSONDecoder().decode([BundledRow].self, from: data)
        #expect(rows.count == 3855, "Expected 3855 seed rows, got \(rows.count)")

        _ = appBundle
    }

    private final class BundleLocator {}

    private struct BundledRow: Decodable {
        let romName: String
    }
}

@Suite("GameListFilter")
struct GameListFilterTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Game.self,
            GameArtwork.self,
            RepairLog.self,
            RepairLogPhoto.self,
            GameCollection.self,
        ])
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }

    private func seed(_ context: ModelContext) throws {
        let games: [(String, String, ScreenOrientation, OwnershipStatus)] = [
            ("pacman",   "Pac-Man",              .vertical,   .owned),
            ("sf2",      "Street Fighter II",    .horizontal, .wanted),
            ("galaga",   "Galaga",               .vertical,   .none),
            ("frogger",  "Frogger",              .vertical,   .owned),
            ("outrun",   "Out Run",              .horizontal, .none),
        ]
        for (rom, title, orientation, ownership) in games {
            context.insert(Game(
                romSetName: rom,
                title: title,
                orientation: orientation,
                ownership: ownership
            ))
        }
        try context.save()
    }

    // MARK: - Text search (SwiftData predicate path)

    @Test func emptyFilterReturnsNilSearchPredicateAndInactive() {
        let filter = GameListFilter()
        #expect(filter.searchPredicate == nil)
        #expect(filter.isActive == false)
        #expect(filter.hasEnumFilters == false)
    }

    @Test func searchFiltersByTitleCaseInsensitively() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seed(context)

        var filter = GameListFilter()
        filter.search = "man"
        let predicate = try #require(filter.searchPredicate)

        let matches = try context.fetch(FetchDescriptor<Game>(predicate: predicate))
        #expect(matches.map(\.title).sorted() == ["Pac-Man"])
    }

    // MARK: - Enum filters (in-memory path)

    @Test func matchesEnumFiltersAllowsEverythingWhenInactive() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seed(context)

        let filter = GameListFilter()
        let games = try context.fetch(FetchDescriptor<Game>())
        #expect(games.allSatisfy(filter.matchesEnumFilters))
    }

    @Test func matchesEnumFiltersRespectsOwnership() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seed(context)

        var filter = GameListFilter()
        filter.ownership = .owned

        let games = try context.fetch(FetchDescriptor<Game>())
        let filtered = games.filter(filter.matchesEnumFilters)
        #expect(Set(filtered.map(\.romSetName)) == ["pacman", "frogger"])
    }

    @Test func matchesEnumFiltersCombinesOwnershipAndOrientation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seed(context)

        var filter = GameListFilter()
        filter.ownership = .owned
        filter.orientation = .vertical

        let games = try context.fetch(FetchDescriptor<Game>())
        let filtered = games.filter(filter.matchesEnumFilters)
        #expect(Set(filtered.map(\.romSetName)) == ["pacman", "frogger"])
    }

    @Test func matchesEnumFiltersOrientationOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        try seed(context)

        var filter = GameListFilter()
        filter.orientation = .horizontal

        let games = try context.fetch(FetchDescriptor<Game>())
        let filtered = games.filter(filter.matchesEnumFilters)
        #expect(Set(filtered.map(\.romSetName)) == ["sf2", "outrun"])
    }
}

@Suite("ArtworkFetcher")
struct ArtworkFetcherTests {
    @Test func fetchesAndPersistsArtworkForPacman() async throws {
        let schema = Schema([
            Game.self,
            GameArtwork.self,
            RepairLog.self,
            RepairLogPhoto.self,
            GameCollection.self,
        ])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let game = Game(romSetName: "pacman", title: "Pac-Man")
        context.insert(game)
        try context.save()
        let gameID = game.persistentModelID

        let fetcher = ArtworkFetcher(modelContainer: container)
        do {
            try await fetcher.fetch(for: gameID)
        } catch {
            Issue.record("Skipping: live API unreachable — \(error)")
            return
        }

        let fetched = try context.fetch(FetchDescriptor<GameArtwork>())
        #expect(fetched.count >= 4, "Expected at least 4 artwork kinds, got \(fetched.count)")
        #expect(fetched.contains(where: { $0.kind == .marquee && ($0.imageData?.count ?? 0) > 1000 }))
        #expect(fetched.contains(where: { $0.kind == .cabinet && ($0.imageData?.count ?? 0) > 1000 }))

        // Metadata fill-in
        let updatedGame = try #require(context.fetch(FetchDescriptor<Game>()).first)
        #expect(updatedGame.manufacturer.contains("Namco"))
        #expect(updatedGame.year == "1980")

        // Hardware specs back-filled
        #expect(updatedGame.emulationStatus == "GOOD")
        #expect(!updatedGame.driver.isEmpty, "Expected driver / emulator_name to be back-filled")
        #expect(updatedGame.inputControls.contains("joystick"))
        #expect(!updatedGame.resolution.isEmpty, "Expected screen_resolution to be back-filled")
    }
}

@Suite("ArcadeDatabaseClient hardware fields")
struct ArcadeDatabaseHardwareFieldsTests {
    @Test func metadataIncludesHardwareSpecs() async throws {
        let client = ArcadeDatabaseClient()
        let metadata: ArcadeDatabaseClient.GameMetadata
        do {
            metadata = try await client.metadata(for: "pacman")
        } catch {
            Issue.record("Skipping: live API unreachable — \(error)")
            return
        }
        #expect(metadata.emulationStatus == "GOOD")
        #expect(metadata.emulatorName.hasPrefix("Mame"))
        #expect(metadata.inputControls.contains("joystick"))
        #expect(metadata.screenResolution.contains("Hz"))
    }
}

@Suite("ArcadeDatabaseClient")
struct ArcadeDatabaseClientTests {
    /// Hits the live Arcade Database API. Skipped if the network is
    /// unreachable so CI without internet doesn't break.
    @Test func fetchesPacmanMetadata() async throws {
        let client = ArcadeDatabaseClient()
        let metadata: ArcadeDatabaseClient.GameMetadata
        do {
            metadata = try await client.metadata(for: "pacman")
        } catch {
            // Network-flake tolerant: don't fail the suite on ephemeral errors.
            Issue.record("Skipping: live API unreachable — \(error)")
            return
        }
        #expect(metadata.romSetName == "pacman")
        #expect(metadata.manufacturer.contains("Namco"))
        #expect(metadata.year == "1980")
        #expect(metadata.orientation == "Vertical")
        #expect(metadata.cabinetImageURL != nil)
        #expect(metadata.marqueeImageURL != nil)
        #expect(metadata.youtubeVideoID != nil)
    }
}
