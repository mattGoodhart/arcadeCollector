//
//  ZoomableImageView.swift
//  ArcadeCollector
//

import SwiftUI

struct ZoomableImageView: View {
    let image: UIImage
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = clampScale(lastScale * value.magnification)
                            }
                            .onEnded { value in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    scale = clampScale(lastScale * value.magnification)
                                }
                                lastScale = scale
                                if scale <= 1 {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                            .simultaneously(
                                with: DragGesture()
                                    .onChanged { value in
                                        guard scale > 1 else { return }
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if scale > 1 {
                                scale = 1
                                lastScale = 1
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 3
                                lastScale = 3
                            }
                        }
                    }
            }
            .background(.black)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black.opacity(0.6), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func clampScale(_ value: CGFloat) -> CGFloat {
        min(max(value, 1), 5)
    }
}
