//
//  BulkArtworkFetcher.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

@ModelActor
actor BulkArtworkFetcher {

    struct Progress: Sendable {
        var completed: Int
        var total: Int
        var currentTitle: String
    }

    struct Result: Sendable {
        let attempted: Int
        let succeeded: Int
        var failed: Int { attempted - succeeded }
    }

    /// Returns an attempted/succeeded/failed breakdown so the UI can distinguish
    /// full success from a partial-failure run that needs a retry hint.
    @discardableResult
    func fetchAllMissing(
        onProgress: @Sendable @escaping (Progress) -> Void
    ) async throws -> Result {
        let allKinds: Set<ArtworkKind> = [.cabinet, .flyer, .inGame, .marquee, .title, .pcb]

        let allGames = try modelContext.fetch(
            FetchDescriptor<Game>(sortBy: [SortDescriptor(\.title)])
        )

        let needsFetch = allGames.filter { game in
            game.ownership == .owned && Set(game.artwork.map(\.kind)) != allKinds
        }

        let total = needsFetch.count
        if total == 0 { return Result(attempted: 0, succeeded: 0) }

        let fetcher = ArtworkFetcher(modelContainer: modelContainer)
        var succeeded = 0

        for (index, game) in needsFetch.enumerated() {
            try Task.checkCancellation()

            onProgress(Progress(
                completed: index,
                total: total,
                currentTitle: game.title
            ))

            do {
                try await fetcher.fetch(for: game.persistentModelID)
                succeeded += 1
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // Per-game failures are non-fatal; recorded in the Result count.
            }

            // Courtesy delay so a 200-game bulk fetch doesn't hammer ADB. Skipped
            // after the last game since there's nothing following. Cancellation-
            // aware — a cancelled sleep throws, which we treat as user intent.
            if index < total - 1 {
                try await Task.sleep(for: .milliseconds(250))
            }
        }

        onProgress(Progress(completed: total, total: total, currentTitle: ""))
        return Result(attempted: total, succeeded: succeeded)
    }
}
