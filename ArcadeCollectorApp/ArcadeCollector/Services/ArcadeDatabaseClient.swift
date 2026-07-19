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

        // History
        let history: String

        // Hardware / emulation specs
        let emulationStatus: String
        let emulatorName: String
        let inputControls: String
        let inputButtons: Int?
        let screenResolution: String

        // ADB page
        let gamePageURL: URL?
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

    struct MachineXMLInfo: Sendable {
        let sourceFile: String?
        let displayType: String?
        let displayCount: Int
    }

    func machineXMLInfo(for romSetName: String) async throws -> MachineXMLInfo {
        var components = URLComponents(string: "https://adb.arcadeitalia.net/download_file.php")!
        components.queryItems = [
            URLQueryItem(name: "tipo", value: "xml"),
            URLQueryItem(name: "codice", value: romSetName),
        ]
        let url = components.url!

        let (data, response) = try await session.data(from: url)
        try Self.throwIfNotOK(response)

        return MachineXMLParser.parse(data: data)
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

    /// Manual PDF download URL for a given ROM.
    func manualURL(for romSetName: String) -> URL {
        var components = URLComponents(string: "https://adb.arcadeitalia.net/download_file.php")!
        components.queryItems = [
            URLQueryItem(name: "tipo", value: "mame_current"),
            URLQueryItem(name: "codice", value: romSetName),
            URLQueryItem(name: "entity", value: "manual"),
        ]
        return components.url!
    }

    func downloadData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        try Self.throwIfNotOK(response)
        return data
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
        let history: String?
        let url: String?

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
            case history
            case url
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
                history: history ?? "",
                emulationStatus: emulationStatus ?? "",
                emulatorName: emulatorName ?? "",
                inputControls: inputControls ?? "",
                inputButtons: inputButtons,
                screenResolution: screenResolution ?? "",
                gamePageURL: url.flatMap(URL.init(string:))
            )
        }
    }
}

private extension String {
    nonisolated var nonEmpty: String? { isEmpty ? nil : self }
}

// MARK: - XML Parser for <machine> and <display> elements

private final class MachineXMLParser: NSObject, XMLParserDelegate {
    private var sourceFile: String?
    private var displayType: String?
    private var displayCount = 0

    static func parse(data: Data) -> ArcadeDatabaseClient.MachineXMLInfo {
        let delegate = MachineXMLParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return .init(
            sourceFile: delegate.sourceFile,
            displayType: delegate.displayType,
            displayCount: delegate.displayCount
        )
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "machine":
            sourceFile = attributeDict["sourcefile"]
        case "display":
            displayCount += 1
            if displayType == nil {
                displayType = attributeDict["type"]
            }
        default:
            break
        }
    }
}
