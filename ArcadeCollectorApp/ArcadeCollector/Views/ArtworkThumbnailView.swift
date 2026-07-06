//
//  ArtworkThumbnailView.swift
//  ArcadeCollector
//

import SwiftUI

struct ArtworkThumbnailView: View {
    let artwork: GameArtwork
    var size: CGFloat = 72

    var body: some View {
        Group {
            if let uiImage = artwork.imageData.flatMap(UIImage.init(data:)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .accessibilityLabel(artwork.kind.displayName)
    }
}
