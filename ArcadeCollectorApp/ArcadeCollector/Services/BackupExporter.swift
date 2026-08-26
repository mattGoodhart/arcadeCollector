//
//  BackupExporter.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

@ModelActor
actor BackupExporter {

    /// Wire-format version. Bump if the manifest schema changes in a way
    /// a future importer would need to distinguish.
    static let manifestVersion = 1

    struct Manifest: Codable {
        let version: Int
        let exportedAt: Date
        let appVersion: String
        var games: [GameEntry]

        struct GameEntry: Codable {
            let romSetName: String
            let title: String
            let ownership: OwnershipStatus
            let bootStatus: ComponentStatus
            let audioStatus: ComponentStatus
            let videoStatus: ComponentStatus
            let controlsStatus: ComponentStatus
            let extendedPlayStatus: ComponentStatus
            var repairLogs: [LogEntry]
        }

        struct LogEntry: Codable {
            let date: Date
            let notes: String
            var photoFilenames: [String]
        }
    }

    struct Summary: Sendable {
        let gameCount: Int
        let repairLogCount: Int
        let photoCount: Int
        let fileURL: URL
    }

    enum ExportError: Error, LocalizedError {
        case archiveFailed(String)

        var errorDescription: String? {
            switch self {
            case .archiveFailed(let detail):
                return "Couldn't create backup archive: \(detail)"
            }
        }
    }

    /// Serializes user-authored state (ownership, per-component statuses,
    /// repair-log entries + photos) into a zip archive at a temp URL. ADB-
    /// derived data (title metadata, artwork) is intentionally excluded —
    /// those are re-fetchable and would bloat the backup by orders of magnitude.
    func export() async throws -> Summary {
        let all = try modelContext.fetch(
            FetchDescriptor<Game>(sortBy: [SortDescriptor(\.romSetName)])
        )

        let modified = all.filter { game in
            game.ownership != .none
                || game.bootStatus != .untested
                || game.audioStatus != .untested
                || game.videoStatus != .untested
                || game.controlsStatus != .untested
                || game.extendedPlayStatus != .untested
                || !game.repairLogs.isEmpty
        }

        // Stage the archive contents in a scratch directory that we'll zip.
        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArcadeCollectorBackup-\(UUID().uuidString)", isDirectory: true)
        let photosDir = staging.appendingPathComponent("photos", isDirectory: true)
        try FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)

        var manifest = Manifest(
            version: Self.manifestVersion,
            exportedAt: Date(),
            appVersion: Bundle.main.appVersion,
            games: []
        )

        var totalRepairLogs = 0
        var totalPhotos = 0

        for game in modified {
            var entry = Manifest.GameEntry(
                romSetName: game.romSetName,
                title: game.title,
                ownership: game.ownership,
                bootStatus: game.bootStatus,
                audioStatus: game.audioStatus,
                videoStatus: game.videoStatus,
                controlsStatus: game.controlsStatus,
                extendedPlayStatus: game.extendedPlayStatus,
                repairLogs: []
            )

            let sortedLogs = game.repairLogs.sorted { $0.date < $1.date }
            for log in sortedLogs {
                totalRepairLogs += 1
                var logEntry = Manifest.LogEntry(date: log.date, notes: log.notes, photoFilenames: [])
                let sortedPhotos = log.photos.sorted { $0.order < $1.order }
                for photo in sortedPhotos {
                    guard let data = photo.imageData else { continue }
                    let filename = "\(UUID().uuidString).jpg"
                    try data.write(to: photosDir.appendingPathComponent(filename))
                    logEntry.photoFilenames.append(filename)
                    totalPhotos += 1
                }
                entry.repairLogs.append(logEntry)
            }

            manifest.games.append(entry)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: staging.appendingPathComponent("backup.json"))

        let zipURL = try Self.zip(directory: staging)

        // Best-effort cleanup of the staging tree; the zip lives on separately.
        try? FileManager.default.removeItem(at: staging)

        return Summary(
            gameCount: manifest.games.count,
            repairLogCount: totalRepairLogs,
            photoCount: totalPhotos,
            fileURL: zipURL
        )
    }

    /// `NSFileCoordinator.coordinate(readingItemAt:options: .forUploading)`
    /// produces a zip snapshot of a directory in a system-managed temp location
    /// as a side effect. We copy it out to a stable named path so the
    /// resulting file survives the coordinator scope and is nice to share.
    private nonisolated static func zip(directory: URL) throws -> URL {
        var coordinatorError: NSError?
        var producedURL: URL?
        var copyError: Error?

        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: directory, options: [.forUploading], error: &coordinatorError) { tempZipURL in
            let stamp = Self.filenameDateFormatter.string(from: Date())
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("ArcadeCollector-Backup-\(stamp).zip")
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: tempZipURL, to: dest)
                producedURL = dest
            } catch {
                copyError = error
            }
        }

        if let coordinatorError {
            throw ExportError.archiveFailed(coordinatorError.localizedDescription)
        }
        if let copyError {
            throw ExportError.archiveFailed(copyError.localizedDescription)
        }
        guard let producedURL else {
            throw ExportError.archiveFailed("coordinator produced no URL")
        }
        return producedURL
    }

    private nonisolated static let filenameDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
