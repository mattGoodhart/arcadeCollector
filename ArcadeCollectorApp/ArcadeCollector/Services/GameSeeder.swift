//
//  GameSeeder.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

/// Seeds the SwiftData store from the bundled `ScrollingData.json` on first
/// launch. The JSON shape mirrors the legacy Core Data seed file and only
/// carries a minimal subset of Game fields (rom name, title, year,
/// manufacturer, players, orientation).
@ModelActor
actor GameSeeder {
    private static let resourceName = "ScrollingData"
    private static let resourceExtension = "json"

    /// Loads the bundled seed file and inserts games if the store is empty.
    /// Idempotent — safe to call on every launch.
    func seedIfNeeded() throws {
        guard let url = Bundle.main.url(
            forResource: Self.resourceName,
            withExtension: Self.resourceExtension
        ) else {
            assertionFailure("Missing bundled resource \(Self.resourceName).\(Self.resourceExtension)")
            return
        }
        let data = try Data(contentsOf: url)
        try seed(from: data)
    }

    /// Test-friendly seam: seeds from an arbitrary JSON payload matching the
    /// legacy `ScrollingData.json` shape.
    func seed(from data: Data) throws {
        var descriptor = FetchDescriptor<Game>()
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { return }

        let payload = try JSONDecoder().decode(SeedPayload.self, from: data)
        for row in payload.result {
            let game = Game(
                romSetName: row.romName,
                title: row.title.trimmingCharacters(in: .whitespaces),
                manufacturer: row.manufacturer,
                year: row.year,
                players: row.players,
                orientation: orientation(fromLegacy: row.orientation)
            )
            modelContext.insert(game)
        }
        try modelContext.save()
    }

    private func orientation(fromLegacy raw: String) -> ScreenOrientation {
        switch raw.lowercased() {
        case "vertical": return .vertical
        default: return .horizontal
        }
    }
}

private nonisolated struct SeedPayload: Decodable {
    let result: [Row]

    struct Row: Decodable {
        let romName: String
        let title: String
        let year: String
        let manufacturer: String
        let players: String
        let orientation: String

        enum CodingKeys: String, CodingKey {
            case romName
            case title = "Title"
            case year
            case manufacturer
            case players = "Players"
            case orientation = "Orientation"
        }
    }
}
