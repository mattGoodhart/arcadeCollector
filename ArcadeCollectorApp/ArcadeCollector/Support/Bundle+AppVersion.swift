//
//  Bundle+AppVersion.swift
//  ArcadeCollector
//

import Foundation

extension Bundle {
    /// Reads `CFBundleShortVersionString` (falls back to `"1.0"` if missing).
    /// Prefer over inline `object(forInfoDictionaryKey:)` calls for the app
    /// version — those were previously scattered across three files.
    /// `nonisolated` so background actors (e.g. `BackupExporter`) can read it
    /// without hopping to the main actor — `Bundle.main` picks up main-actor
    /// isolation under Swift 6.
    nonisolated var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
