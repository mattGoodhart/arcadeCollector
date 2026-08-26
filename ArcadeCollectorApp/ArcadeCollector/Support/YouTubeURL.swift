//
//  YouTubeURL.swift
//  ArcadeCollector
//

import Foundation

/// Parse and validate YouTube video identifiers from URLs the app receives
/// from Arcade Database seed / API data. Recognizes the URL shapes that
/// actually appear in the wild (`watch?v=`, `youtu.be/`, `shorts/`) and
/// gates the extracted ID through a strict regex before any downstream use.
nonisolated enum YouTubeURL {
    /// YouTube video IDs are canonically 11 base64url chars; widened to 6–32 to
    /// tolerate future format drift without opening up to injection-friendly
    /// punctuation. Anything outside this shape is rejected upstream, so the
    /// player never receives a value that could break out of URL / JS contexts.
    private static let idPattern = /^[A-Za-z0-9_-]{6,32}$/

    static func isValid(id: String) -> Bool {
        (try? Self.idPattern.wholeMatch(in: id)) != nil
    }

    /// Return the raw video ID for any recognized YouTube URL shape, or nil.
    /// The returned string is *not* passed through `isValid` — callers should
    /// validate before use so bad extractions (e.g. `youtu.be/xyz/embed` returning
    /// `"embed"`) don't silently reach the player.
    static func extractID(from url: URL) -> String? {
        guard let host = url.host()?.lowercased() else { return nil }

        switch host {
        case "youtu.be":
            let id = url.lastPathComponent
            return id.isEmpty || id == "/" ? nil : id

        case "youtube.com", "www.youtube.com", "m.youtube.com":
            let path = url.pathComponents
            // `/shorts/<id>` → path components are ["/", "shorts", "<id>"]
            if path.count >= 3, path[1] == "shorts", !path[2].isEmpty {
                return path[2]
            }
            // `/watch?v=<id>`
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let id = components.queryItems?.first(where: { $0.name == "v" })?.value,
               !id.isEmpty {
                return id
            }
            return nil

        default:
            return nil
        }
    }
}
