//
//  GameCollection.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

/// User-defined grouping of games.
///
/// Note: the legacy app persisted four default collections ("All Games",
/// "My Games", "Wanted Games", "Repair Logs"). In the clean-start model,
/// "All Games" and "Repair Logs" become computed views, and "My Games" /
/// "Wanted Games" collapse into `Game.ownership`. Only genuinely
/// user-authored groupings live here.
@Model
final class GameCollection {
    @Attribute(.unique) var name: String
    var sortOrder: Int
    var games: [Game] = []

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
    }
}
