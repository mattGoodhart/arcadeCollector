//
//  GameEnums.swift
//  ArcadeCollector
//

import Foundation

/// LED-style status indicator for a game component.
/// Replaces the legacy Int16 0-3 scale (white/red/yellow/green).
enum ComponentStatus: Int, Codable, CaseIterable, Identifiable {
    case untested = 0
    case broken = 1
    case issues = 2
    case working = 3

    var id: Int { rawValue }
}

enum ScreenOrientation: String, Codable, CaseIterable, Identifiable {
    case horizontal
    case vertical

    var id: String { rawValue }
}

/// Whether the user owns, wants, or has no interest in a given game.
/// Replaces the legacy "My Games" / "Wanted Games" default collections.
enum OwnershipStatus: String, Codable, CaseIterable, Identifiable {
    case none
    case owned
    case wanted

    var id: String { rawValue }
}

/// Category slot for a piece of game artwork.
enum ArtworkKind: String, Codable, CaseIterable, Identifiable {
    case cabinet
    case flyer
    case inGame
    case marquee
    case title
    case pcb
    case userPCB

    var id: String { rawValue }

    /// The set of artwork kinds a bulk artwork fetch tries to populate for a
    /// game. Excludes `.userPCB`, which is user-supplied only.
    /// `nonisolated` so background actors (`BulkArtworkFetcher`) can read it
    /// without hopping to the main actor.
    nonisolated static let bulkFetchable: Set<ArtworkKind> = [.cabinet, .flyer, .inGame, .marquee, .title, .pcb]
}
