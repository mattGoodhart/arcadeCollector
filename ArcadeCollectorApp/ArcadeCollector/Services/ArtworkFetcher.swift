//
//  ArtworkFetcher.swift
//  ArcadeCollector
//

import Foundation
import SwiftData
import UIKit

/// Fetches artwork for a Game from the Arcade Database and inserts
/// `GameArtwork` rows into the SwiftData store. Runs off the main actor.
@ModelActor
actor ArtworkFetcher {

    /// Fetches every canonical artwork kind that the game doesn't already
    /// have. Serial downloads — good enough for ~6 images per game.
    func fetch(for gameID: PersistentIdentifier) async throws {
        guard let game = self[gameID, as: Game.self] else { return }

        let romSetName = game.romSetName
        let existingKinds = Set(game.artwork.map(\.kind))

        let client = ArcadeDatabaseClient()

        // From metadata JSON
        let metadata = try await client.metadata(for: romSetName)
        let plan: [(ArtworkKind, URL)] = [
            (.cabinet, metadata.cabinetImageURL),
            (.flyer,   metadata.flyerImageURL),
            (.inGame,  metadata.inGameImageURL),
            (.marquee, metadata.marqueeImageURL),
            (.title,   metadata.titleImageURL),
            (.pcb,     client.pcbImageURL(for: romSetName)),
        ].compactMap { kind, url in
            guard let url, !existingKinds.contains(kind) else { return nil }
            return (kind, url)
        }

        // Fill in richer metadata while we're here.
        if game.manufacturer.isEmpty, !metadata.manufacturer.isEmpty {
            game.manufacturer = metadata.manufacturer
        }
        if game.year.isEmpty, !metadata.year.isEmpty {
            game.year = metadata.year
        }
        if game.genre.isEmpty, !metadata.genre.isEmpty {
            game.genre = metadata.genre
        }
        if game.youtubeVideoID.isEmpty, let ytID = metadata.youtubeVideoID {
            game.youtubeVideoID = ytID
        }
        if game.shortPlayURL == nil, let shortPlay = metadata.shortPlayURL {
            game.shortPlayURL = shortPlay
        }
        if game.emulationStatus.isEmpty, !metadata.emulationStatus.isEmpty {
            game.emulationStatus = metadata.emulationStatus
        }
        if game.driver.isEmpty, !metadata.emulatorName.isEmpty {
            // `Game.driver` holds the MAME driver / emulator identifier.
            game.driver = metadata.emulatorName
        }
        if game.inputControls.isEmpty, !metadata.inputControls.isEmpty {
            game.inputControls = metadata.inputControls
        }
        if game.inputButtons.isEmpty, let buttons = metadata.inputButtons {
            game.inputButtons = String(buttons)
        }
        if game.resolution.isEmpty, !metadata.screenResolution.isEmpty {
            game.resolution = metadata.screenResolution
        }

        for (kind, url) in plan {
            do {
                let data = try await client.downloadImage(from: url)
                if Self.isEffectivelyBlack(data) { continue }
                let artwork = GameArtwork(kind: kind, imageData: data, sourceURL: url)
                artwork.game = game
                modelContext.insert(artwork)
            } catch {
                continue
            }
        }

        try modelContext.save()
    }

    /// Detects placeholder/blank images the server returns as all-black PNGs.
    /// Renders the image into an 8×8 sRGB bitmap and checks whether the
    /// average brightness is near zero.
    private static nonisolated func isEffectivelyBlack(_ data: Data) -> Bool {
        guard let image = UIImage(data: data)?.cgImage else { return true }
        let size = 8
        let bytesPerPixel = 4
        let bytesPerRow = size * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: size * size * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return true }

        context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))

        var totalBrightness: UInt64 = 0
        for i in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let r = UInt64(pixels[i])
            let g = UInt64(pixels[i + 1])
            let b = UInt64(pixels[i + 2])
            totalBrightness += r + g + b
        }

        let pixelCount = UInt64(size * size)
        let avgBrightness = totalBrightness / (pixelCount * 3)
        return avgBrightness < 5
    }
}
