//
//  AppSchema.swift
//  ArcadeCollector
//

import SwiftData

/// Single source of truth for the app's `@Model` types. When a new model is
/// introduced, add it here — every `ModelContainer` construction (app entry
/// point, previews, tests) pulls from this list, so nothing goes unmigrated.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Game.self,
        GameArtwork.self,
        RepairLog.self,
        RepairLogPhoto.self,
        GameCollection.self,
    ]

    static var schema: Schema { Schema(models) }
}
