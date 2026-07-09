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

    /// Returns the number of games that needed artwork fetched.
    @discardableResult
    func fetchAllMissing(
        onProgress: @Sendable @escaping (Progress) -> Void
    ) async throws -> Int {
        let allKinds: Set<ArtworkKind> = [.cabinet, .flyer, .inGame, .marquee, .title, .pcb]

        let allGames = try modelContext.fetch(
            FetchDescriptor<Game>(sortBy: [SortDescriptor(\.title)])
        )

        let needsFetch = allGames.filter { game in
            game.ownership == .owned && Set(game.artwork.map(\.kind)) != allKinds
        }

        let total = needsFetch.count
        if total == 0 { return 0 }

        let fetcher = ArtworkFetcher(modelContainer: modelContainer)

        for (index, game) in needsFetch.enumerated() {
            try Task.checkCancellation()

            onProgress(Progress(
                completed: index,
                total: total,
                currentTitle: game.title
            ))

            do {
                try await fetcher.fetch(for: game.persistentModelID)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // Per-game failures are non-fatal
            }
        }

        onProgress(Progress(completed: total, total: total, currentTitle: ""))
        return total
    }
}
