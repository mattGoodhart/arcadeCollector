//
//  ArcadeDatabaseClientFixtureTests.swift
//  ArcadeCollectorTests
//

import Testing
import Foundation
@testable import ArcadeCollector

// `.serialized` is required — `FixtureURLProtocol` holds stub state in
// static storage, and Swift Testing's default parallel execution would
// let concurrent tests stomp on each other's responses.
@Suite("ArcadeDatabaseClient decoding (fixture)", .serialized)
struct ArcadeDatabaseClientFixtureTests {

    @Test func happyPathFixtureMapsAllFields() async throws {
        FixtureURLProtocol.stub(status: 200, body: Self.pacmanFixture)
        let client = ArcadeDatabaseClient(session: FixtureURLProtocol.session)

        let metadata = try await client.metadata(for: "pacman")

        #expect(metadata.romSetName == "pacman")
        #expect(metadata.title == "Pac-Man")
        #expect(metadata.manufacturer == "Namco")
        #expect(metadata.year == "1980")
        #expect(metadata.genre == "Maze")
        #expect(metadata.orientation == "Vertical")
        #expect(metadata.cabinetImageURL?.absoluteString == "https://adb.arcadeitalia.net/media/mame.current/cabinets/pacman.png")
        #expect(metadata.flyerImageURL?.absoluteString == "https://adb.arcadeitalia.net/media/mame.current/flyers/pacman.png")
        #expect(metadata.inGameImageURL?.absoluteString == "https://adb.arcadeitalia.net/media/mame.current/ingames/pacman.png")
        #expect(metadata.marqueeImageURL?.absoluteString == "https://adb.arcadeitalia.net/media/mame.current/marquees/pacman.png")
        #expect(metadata.titleImageURL?.absoluteString == "https://adb.arcadeitalia.net/media/mame.current/titles/pacman.png")
        #expect(metadata.youtubeVideoID == "dScq4P5gn5A")
        #expect(metadata.shortPlayURL?.absoluteString == "https://adb.arcadeitalia.net/download_file.php?tipo=video&codice=pacman&entity=shortplay")
        #expect(metadata.emulationStatus == "GOOD")
        #expect(metadata.emulatorName.hasPrefix("Mame"))
        #expect(metadata.inputControls == "8-way joystick")
        #expect(metadata.inputButtons == 1)
        #expect(metadata.screenResolution == "224 x 288 @ 60.606061 Hz")
        #expect(metadata.history.contains("1980"))
        #expect(metadata.gamePageURL?.absoluteString == "https://adb.arcadeitalia.net/?mame=pacman")
    }

    @Test func missingOptionalFieldsFallBackToEmptyOrNil() async throws {
        FixtureURLProtocol.stub(status: 200, body: Self.minimalFixture)
        let client = ArcadeDatabaseClient(session: FixtureURLProtocol.session)

        let metadata = try await client.metadata(for: "minimal")

        #expect(metadata.romSetName == "minimal")
        #expect(metadata.title == "minimal")               // no short_title / title → fall back to game_name
        #expect(metadata.manufacturer == "")
        #expect(metadata.year == "")
        #expect(metadata.cabinetImageURL == nil)
        #expect(metadata.youtubeVideoID == nil)
        #expect(metadata.shortPlayURL == nil)
        #expect(metadata.inputButtons == nil)
        #expect(metadata.gamePageURL == nil)
        #expect(metadata.history == "")
    }

    @Test func emptyYoutubeIDBecomesNil() async throws {
        FixtureURLProtocol.stub(status: 200, body: Self.emptyYoutubeFixture)
        let client = ArcadeDatabaseClient(session: FixtureURLProtocol.session)

        let metadata = try await client.metadata(for: "noytid")
        #expect(metadata.youtubeVideoID == nil, "Empty youtube_video_id string should map to nil, not \"\"")
    }

    @Test func emptyResultArrayThrowsNoResults() async throws {
        FixtureURLProtocol.stub(status: 200, body: Data(#"{"result":[]}"#.utf8))
        let client = ArcadeDatabaseClient(session: FixtureURLProtocol.session)

        await #expect(throws: ArcadeDatabaseClient.Failure.self) {
            _ = try await client.metadata(for: "nonesuch")
        }
    }

    @Test func httpErrorSurfacesFailure() async throws {
        FixtureURLProtocol.stub(status: 500, body: Data("upstream broke".utf8))
        let client = ArcadeDatabaseClient(session: FixtureURLProtocol.session)

        await #expect(throws: ArcadeDatabaseClient.Failure.self) {
            _ = try await client.metadata(for: "pacman")
        }
    }

    // MARK: - Fixtures

    private static let pacmanFixture = Data(#"""
    {
      "result": [
        {
          "game_name": "pacman",
          "title": "Pac-Man (Midway)",
          "short_title": "Pac-Man",
          "manufacturer": "Namco",
          "year": "1980",
          "genre": "Maze",
          "screen_orientation": "Vertical",
          "url_image_cabinet": "https://adb.arcadeitalia.net/media/mame.current/cabinets/pacman.png",
          "url_image_flyer": "https://adb.arcadeitalia.net/media/mame.current/flyers/pacman.png",
          "url_image_ingame": "https://adb.arcadeitalia.net/media/mame.current/ingames/pacman.png",
          "url_image_marquee": "https://adb.arcadeitalia.net/media/mame.current/marquees/pacman.png",
          "url_image_title": "https://adb.arcadeitalia.net/media/mame.current/titles/pacman.png",
          "youtube_video_id": "dScq4P5gn5A",
          "url_video_shortplay": "https://adb.arcadeitalia.net/download_file.php?tipo=video&codice=pacman&entity=shortplay",
          "status": "GOOD",
          "emulator_name": "Mame 0.288 (may-29 2026)",
          "input_controls": "8-way joystick",
          "input_buttons": 1,
          "screen_resolution": "224 x 288 @ 60.606061 Hz",
          "history": "Pac-Man was released in 1980 by Namco...",
          "url": "https://adb.arcadeitalia.net/?mame=pacman"
        }
      ]
    }
    """#.utf8)

    private static let minimalFixture = Data(#"""
    {
      "result": [
        { "game_name": "minimal" }
      ]
    }
    """#.utf8)

    private static let emptyYoutubeFixture = Data(#"""
    {
      "result": [
        { "game_name": "noytid", "youtube_video_id": "" }
      ]
    }
    """#.utf8)
}

// MARK: - URLProtocol stub

/// Serves canned responses for `URLSession` requests without hitting the network.
/// Tests set a status + body via `stub(status:body:)`; every request the session
/// makes returns that response until the next `stub` call. Serial execution of
/// the test suite (the default) makes this safe.
final class FixtureURLProtocol: URLProtocol {
    nonisolated(unsafe) static var stubbedStatus: Int = 200
    nonisolated(unsafe) static var stubbedBody: Data = Data()

    static func stub(status: Int, body: Data) {
        stubbedStatus = status
        stubbedBody = body
    }

    static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FixtureURLProtocol.self]
        return URLSession(configuration: config)
    }()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url ?? URL(string: "https://example.invalid")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: Self.stubbedStatus,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.stubbedBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
