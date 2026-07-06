//
//  GameArtwork.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

/// A single piece of artwork attached to a Game.
/// Replaces the seven parallel `*ImageData` / `*ImageURLString` field pairs on
/// the legacy Core Data Game entity with a normalized one-to-many relationship.
@Model
final class GameArtwork {
    var game: Game?
    var kind: ArtworkKind
    @Attribute(.externalStorage) var imageData: Data?
    var sourceURL: URL?

    init(kind: ArtworkKind, imageData: Data? = nil, sourceURL: URL? = nil) {
        self.kind = kind
        self.imageData = imageData
        self.sourceURL = sourceURL
    }
}
