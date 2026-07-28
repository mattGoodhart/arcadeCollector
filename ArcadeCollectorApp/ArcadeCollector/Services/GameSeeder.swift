//
//  GameSeeder.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

@ModelActor
actor GameSeeder {
    /// The seed JSON is renamed to a stable `seed.json` at copy-in time so
    /// this string never changes across seed refreshes. Version/date info
    /// lives in git history and `Journal.md`, not the filename.
    private static let resourceName = "seed"
    private static let resourceExtension = "json"

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

    func seed(from data: Data) throws {
        var descriptor = FetchDescriptor<Game>()
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { return }

        let rows = try JSONDecoder().decode([SeedRow].self, from: data)
        for row in rows {
            modelContext.insert(Self.makeGame(from: row))
        }
        try modelContext.save()
    }

    // MARK: - Row → Game

    /// `nplayers` field placeholder in the source data ("we don't know").
    private static let unknownNplayers = "???"

    /// `"-"` marks "no value" for URL fields in the source data. `URL(string:)`
    /// happily accepts it as a relative URL, so every field must be guarded.
    private static let noValueSentinel = "-"

    private static func makeGame(from row: SeedRow) -> Game {
        let game = Game(
            romSetName: row.romName,
            title: row.title.trimmingCharacters(in: .whitespaces),
            manufacturer: row.manufacturer ?? "",
            year: row.year,
            genre: row.genre,
            players: row.players ?? "",
            orientation: orientation(from: row.orientation)
        )
        game.nplayers = nplayersLabel(from: row)
        game.driver = row.sourcefile
        game.emulationStatus = row.driverStatus
        game.inputControls = row.inputControls ?? ""
        game.inputButtons = row.buttons
        game.displayType = displayType(from: row)
        game.screens = row.screens ?? 1
        game.monitorResolutionType = row.monitorType
        game.resolution = "\(row.displayWidth)x\(row.displayHeight)"
        game.verticalRefresh = row.displayRefresh
        game.cpus = chipList(from: row.chipsCpu)
        game.soundDevices = chipList(from: row.chipsAudio)
        game.shortPlayURL = sanitizedURL(from: row.urlShortplays)
        return game
    }

    /// Uses the human-readable `nplayers` value when present ("2P sim",
    /// "4P alt"), otherwise falls back to `players + "P"`. Empty strings
    /// and the `"???"` sentinel both count as absent.
    private static func nplayersLabel(from row: SeedRow) -> String {
        if let np = row.nplayers, !np.isEmpty, np != unknownNplayers {
            return np
        }
        if let p = row.players, !p.isEmpty {
            return "\(p)P"
        }
        return ""
    }

    /// `screens > 1` rewrites `display_type` to `"multiple"` so downstream
    /// code (aspect-ratio forcing, hardware view labels) can treat multi-
    /// monitor cabinets as a distinct category rather than raster/vector.
    /// Regression source: The Ninja Warriors got a forced 4:3 aspect ratio
    /// on its screenshots before this rewrite existed.
    private static func displayType(from row: SeedRow) -> String {
        if let screens = row.screens, screens > 1 {
            return "multiple"
        }
        return row.displayType
    }

    private static func chipList(from raw: String?) -> [String] {
        raw?.components(separatedBy: ",") ?? []
    }

    private static func sanitizedURL(from raw: String?) -> URL? {
        guard let raw, raw != noValueSentinel else { return nil }
        return URL(string: raw)
    }

    private static func orientation(from raw: String) -> ScreenOrientation {
        switch raw.uppercased() {
        case "VERTICAL": return .vertical
        default: return .horizontal
        }
    }
}

private nonisolated struct SeedRow: Decodable {
    let romName: String
    let title: String
    let year: String
    let manufacturer: String?
    let players: String?
    let orientation: String
    let sourcefile: String
    let driverStatus: String
    let displayType: String
    let displayWidth: Int
    let displayHeight: Int
    let displayRefresh: String
    let buttons: String
    let genre: String
    let inputControls: String?
    let monitorType: String
    let chipsCpu: String?
    let chipsAudio: String?
    let nplayers: String?
    let urlShortplays: String?
    let screens: Int?

    enum CodingKeys: String, CodingKey {
        case romName
        case title = "Title"
        case year = "Year"
        case manufacturer
        case players = "Players"
        case orientation = "Orientation"
        case sourcefile
        case driverStatus = "driver_status"
        case displayType = "display_type"
        case displayWidth = "display_width"
        case displayHeight = "display_height"
        case displayRefresh = "display_refresh"
        case buttons
        case genre
        case inputControls = "input_controls"
        case monitorType = "monitor_type"
        case chipsCpu = "chips_cpu"
        case chipsAudio = "chips_audio"
        case nplayers
        case urlShortplays = "url_shortplays"
        case screens
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        romName = try c.decode(String.self, forKey: .romName)
        title = try c.decode(String.self, forKey: .title)
        if let intVal = try? c.decode(Int.self, forKey: .year) {
            year = String(intVal)
        } else {
            year = try c.decode(String.self, forKey: .year)
        }
        manufacturer = try c.decodeIfPresent(String.self, forKey: .manufacturer)
        if let intVal = try? c.decode(Int.self, forKey: .players) {
            players = String(intVal)
        } else {
            players = try c.decodeIfPresent(String.self, forKey: .players)
        }
        orientation = try c.decode(String.self, forKey: .orientation)
        sourcefile = try c.decode(String.self, forKey: .sourcefile)
        driverStatus = try c.decode(String.self, forKey: .driverStatus)
        displayType = try c.decode(String.self, forKey: .displayType)
        displayWidth = try c.decode(Int.self, forKey: .displayWidth)
        displayHeight = try c.decode(Int.self, forKey: .displayHeight)
        displayRefresh = try c.decode(String.self, forKey: .displayRefresh)
        buttons = try c.decode(String.self, forKey: .buttons)
        genre = try c.decode(String.self, forKey: .genre)
        inputControls = try c.decodeIfPresent(String.self, forKey: .inputControls)
        monitorType = try c.decode(String.self, forKey: .monitorType)
        chipsCpu = try c.decodeIfPresent(String.self, forKey: .chipsCpu)
        chipsAudio = try c.decodeIfPresent(String.self, forKey: .chipsAudio)
        nplayers = try c.decodeIfPresent(String.self, forKey: .nplayers)
        urlShortplays = try c.decodeIfPresent(String.self, forKey: .urlShortplays)
        screens = try c.decodeIfPresent(Int.self, forKey: .screens)
    }
}
