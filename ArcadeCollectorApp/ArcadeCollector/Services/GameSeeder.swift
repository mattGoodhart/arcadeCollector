//
//  GameSeeder.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

@ModelActor
actor GameSeeder {
    private static let resourceName = "Arcade Collector Value-only Seed ready for JSON July 23 2026"
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
            let game = Game(
                romSetName: row.romName,
                title: row.title.trimmingCharacters(in: .whitespaces),
                manufacturer: row.manufacturer ?? "",
                year: row.year,
                genre: row.genre,
                players: row.players ?? "",
                orientation: orientation(from: row.orientation)
            )
            game.driver = row.sourcefile
            game.emulationStatus = row.driverStatus
            game.inputControls = row.inputControls ?? ""
            game.inputButtons = row.buttons
            game.displayType = row.displayType
            game.monitorResolutionType = row.monitorType
            game.resolution = "\(row.displayWidth)x\(row.displayHeight)"
            game.verticalRefresh = row.displayRefresh
            game.cpus = row.chipsCpu?.components(separatedBy: ",") ?? []
            game.soundDevices = row.chipsAudio?.components(separatedBy: ",") ?? []
            if let raw = row.urlShortplays, raw != "-", let url = URL(string: raw) {
                game.shortPlayURL = url
            }
            if let raw = row.urlPlayonline, raw != "-", let url = URL(string: raw) {
                game.gamePageURL = url
            }
            modelContext.insert(game)
        }
        try modelContext.save()
    }

    private func orientation(from raw: String) -> ScreenOrientation {
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
    let urlPlayonline: String?
    let urlShortplays: String?

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
        case urlPlayonline = "url_playonline"
        case urlShortplays = "url_shortplays"
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
        urlPlayonline = try c.decodeIfPresent(String.self, forKey: .urlPlayonline)
        urlShortplays = try c.decodeIfPresent(String.self, forKey: .urlShortplays)
    }
}
