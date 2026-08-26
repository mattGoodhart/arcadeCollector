//
//  YouTubeURLTests.swift
//  ArcadeCollectorTests
//

import Testing
import Foundation
@testable import ArcadeCollector

@Suite("YouTubeURL")
struct YouTubeURLTests {

    // MARK: - isValid

    @Test("Canonical 11-char IDs are valid", arguments: [
        "dQw4w9WgXcQ",
        "abc-DEF_123",
        "0000000000A",
    ])
    func canonicalIDsValid(id: String) {
        #expect(YouTubeURL.isValid(id: id))
    }

    @Test("6-char lower bound is valid")
    func lowerBoundValid() {
        #expect(YouTubeURL.isValid(id: "abcdef"))
    }

    @Test("32-char upper bound is valid")
    func upperBoundValid() {
        #expect(YouTubeURL.isValid(id: String(repeating: "a", count: 32)))
    }

    @Test("Too-short IDs are invalid", arguments: ["", "a", "abc", "abcde"])
    func tooShortInvalid(id: String) {
        #expect(!YouTubeURL.isValid(id: id))
    }

    @Test("Too-long IDs are invalid")
    func tooLongInvalid() {
        #expect(!YouTubeURL.isValid(id: String(repeating: "a", count: 33)))
    }

    @Test("Illegal characters make an ID invalid", arguments: [
        "hello world",     // space
        "abc.def1234",     // dot
        "abc/def1234",     // slash
        "abc?def1234",     // question mark
        "abc=def1234",     // equals
        "abc<def1234",     // angle bracket
        "abc\"def1234",    // quote
        "abc\ndef1234",    // newline
    ])
    func illegalCharsInvalid(id: String) {
        #expect(!YouTubeURL.isValid(id: id))
    }

    // MARK: - extractID / watch URLs

    @Test("watch URL returns the v parameter")
    func watchURL() throws {
        let url = try #require(URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("Mobile subdomain works")
    func mobileWatch() throws {
        let url = try #require(URL(string: "https://m.youtube.com/watch?v=dQw4w9WgXcQ"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("Bare youtube.com host works")
    func bareHostWatch() throws {
        let url = try #require(URL(string: "https://youtube.com/watch?v=dQw4w9WgXcQ"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("Extra query params are ignored")
    func watchWithExtraParams() throws {
        let url = try #require(URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLxx&t=30"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("v param not first in query")
    func watchVNotFirst() throws {
        let url = try #require(URL(string: "https://www.youtube.com/watch?list=PLxx&v=dQw4w9WgXcQ&t=30"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("watch URL missing v returns nil")
    func watchMissingV() throws {
        let url = try #require(URL(string: "https://www.youtube.com/watch?list=PLxx"))
        #expect(YouTubeURL.extractID(from: url) == nil)
    }

    // MARK: - extractID / short links

    @Test("youtu.be short link returns the path")
    func youtuBe() throws {
        let url = try #require(URL(string: "https://youtu.be/dQw4w9WgXcQ"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("youtu.be with query preserves the ID")
    func youtuBeWithQuery() throws {
        let url = try #require(URL(string: "https://youtu.be/dQw4w9WgXcQ?t=30"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("Empty youtu.be path returns nil")
    func youtuBeEmpty() throws {
        let url = try #require(URL(string: "https://youtu.be/"))
        #expect(YouTubeURL.extractID(from: url) == nil)
    }

    @Test("youtu.be trailing segment returns raw last component (validated upstream)")
    func youtuBeTrailingSegment() throws {
        // Real-world curveball: an unusual youtu.be shape returns the trailing
        // path element as-is. Callers must gate through isValid so odd extractions
        // like "embed" don't reach the player.
        let url = try #require(URL(string: "https://youtu.be/dQw4w9WgXcQ/embed"))
        #expect(YouTubeURL.extractID(from: url) == "embed")
        #expect(!YouTubeURL.isValid(id: "embed"))
    }

    // MARK: - extractID / shorts

    @Test("Shorts URL returns the ID")
    func shortsURL() throws {
        let url = try #require(URL(string: "https://www.youtube.com/shorts/dQw4w9WgXcQ"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("Shorts URL with query params returns the ID")
    func shortsWithQuery() throws {
        let url = try #require(URL(string: "https://www.youtube.com/shorts/dQw4w9WgXcQ?feature=share"))
        #expect(YouTubeURL.extractID(from: url) == "dQw4w9WgXcQ")
    }

    // MARK: - extractID / rejection

    @Test("Non-YouTube host returns nil")
    func nonYouTubeHost() throws {
        let url = try #require(URL(string: "https://example.com/watch?v=dQw4w9WgXcQ"))
        #expect(YouTubeURL.extractID(from: url) == nil)
    }

    @Test("Deceptive host suffix returns nil")
    func deceptiveHost() throws {
        // Guards against a `host.contains("youtu.be")` bug that would match
        // "notyoutu.be" and treat it as a legitimate short link.
        let url = try #require(URL(string: "https://notyoutu.be/dQw4w9WgXcQ"))
        #expect(YouTubeURL.extractID(from: url) == nil)
    }

    @Test("Non-http scheme returns nil")
    func fileScheme() throws {
        let url = try #require(URL(string: "file:///tmp/watch?v=dQw4w9WgXcQ"))
        #expect(YouTubeURL.extractID(from: url) == nil)
    }
}
