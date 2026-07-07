//
//  ArcadeDatabaseClient.swift
//  ArcadeCollector
//
//  Thin wrapper around the Arcade Database (adb.arcadeitalia.net) scraper
//  endpoint. Uses HTTPS so no App Transport Security exception is needed.
//

import Foundation

nonisolated struct ArcadeDatabaseClient: Sendable {

    struct GameMetadata: Sendable {
        let romSetName: String
        let title: String
        let manufacturer: String
        let year: String
        let genre: String
        let orientation: String

        // Media
        let cabinetImageURL: URL?
        let flyerImageURL: URL?
        let inGameImageURL: URL?
        let marqueeImageURL: URL?
        let titleImageURL: URL?
        let youtubeVideoID: String?
        let shortPlayURL: URL?

        // Hardware / emulation specs
        let emulationStatus: String
        let emulatorName: String
        let inputControls: String
        let inputButtons: Int?
        let screenResolution: String
    }

    enum Failure: Error, LocalizedError {
        case noResultsForRom(String)
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .noResultsForRom(let rom): return "No arcade database entry for '\(rom)'"
            case .httpStatus(let code):     return "HTTP \(code)"
            }
        }
    }

    private let session: URLSession
    private static let scraperEndpoint = URL(
        string: "https://adb.arcadeitalia.net/service_scraper.php"
    )!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func metadata(for romSetName: String) async throws -> GameMetadata {
        var components = URLComponents(url: Self.scraperEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "ajax", value: "query_mame"),
            URLQueryItem(name: "game_name", value: romSetName),
            URLQueryItem(name: "use_parent", value: "1"),
        ]
        let url = components.url!

        let (data, response) = try await session.data(from: url)
        try Self.throwIfNotOK(response)

        let payload = try JSONDecoder().decode(ScraperResponse.self, from: data)
        guard let row = payload.result.first else {
            throw Failure.noResultsForRom(romSetName)
        }
        return row.asMetadata()
    }

    func downloadImage(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        try Self.throwIfNotOK(response)
        return data
    }

    /// PCB reference photo lives at a fixed path; no metadata call required.
    func pcbImageURL(for romSetName: String) -> URL {
        URL(string: "https://adb.arcadeitalia.net/media/mame.current/pcbs/\(romSetName).png")!
    }

    private static func throwIfNotOK(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw Failure.httpStatus(http.statusCode)
        }
    }
}

// MARK: - Decoding

private nonisolated struct ScraperResponse: Decodable {
    let result: [Row]

    nonisolated struct Row: Decodable {
        let gameName: String
        let title: String?
        let shortTitle: String?
        let manufacturer: String?
        let year: String?
        let genre: String?
        let screenOrientation: String?
        let urlImageCabinet: String?
        let urlImageFlyer: String?
        let urlImageInGame: String?
        let urlImageMarquee: String?
        let urlImageTitle: String?
        let youtubeVideoID: String?
        let urlVideoShortplay: String?
        let emulationStatus: String?
        let emulatorName: String?
        let inputControls: String?
        let inputButtons: Int?
        let screenResolution: String?

        enum CodingKeys: String, CodingKey {
            case gameName = "game_name"
            case title
            case shortTitle = "short_title"
            case manufacturer
            case year
            case genre
            case screenOrientation = "screen_orientation"
            case urlImageCabinet = "url_image_cabinet"
            case urlImageFlyer = "url_image_flyer"
            case urlImageInGame = "url_image_ingame"
            case urlImageMarquee = "url_image_marquee"
            case urlImageTitle = "url_image_title"
            case youtubeVideoID = "youtube_video_id"
            case urlVideoShortplay = "url_video_shortplay"
            case emulationStatus = "status"
            case emulatorName = "emulator_name"
            case inputControls = "input_controls"
            case inputButtons = "input_buttons"
            case screenResolution = "screen_resolution"
        }

        func asMetadata() -> ArcadeDatabaseClient.GameMetadata {
            .init(
                romSetName: gameName,
                title: shortTitle ?? title ?? gameName,
                manufacturer: manufacturer ?? "",
                year: year ?? "",
                genre: genre ?? "",
                orientation: screenOrientation ?? "",
                cabinetImageURL: urlImageCabinet.flatMap(URL.init(string:)),
                flyerImageURL: urlImageFlyer.flatMap(URL.init(string:)),
                inGameImageURL: urlImageInGame.flatMap(URL.init(string:)),
                marqueeImageURL: urlImageMarquee.flatMap(URL.init(string:)),
                titleImageURL: urlImageTitle.flatMap(URL.init(string:)),
                youtubeVideoID: youtubeVideoID?.nonEmpty,
                shortPlayURL: urlVideoShortplay.flatMap(URL.init(string:)),
                emulationStatus: emulationStatus ?? "",
                emulatorName: emulatorName ?? "",
                inputControls: inputControls ?? "",
                inputButtons: inputButtons,
                screenResolution: screenResolution ?? ""
            )
        }
    }
}

private extension String {
    nonisolated var nonEmpty: String? { isEmpty ? nil : self }
}
