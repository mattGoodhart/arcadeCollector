//
//  DriverSourceView.swift
//  ArcadeCollector
//

import SwiftUI
import UIKit

struct DriverSourceView: View {
    let driverFileName: String
    @State private var sourceText: String?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var sourceURL: URL? {
        URL(string: "https://raw.githubusercontent.com/mamedev/mame/master/src/mame/\(driverFileName)")
    }

    var body: some View {
        Group {
            if let sourceText {
                SourceTextView(text: sourceText)
                    .ignoresSafeArea(edges: .bottom)
            } else if isLoading {
                ProgressView("Loading source…")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Couldn't Load Source",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            }
        }
        .navigationTitle(driverFileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.arcadeToolbar, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadSource() }
    }

    private func loadSource() async {
        guard let url = sourceURL else {
            errorMessage = "Invalid driver URL"
            isLoading = false
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                errorMessage = "HTTP \(http.statusCode)"
                isLoading = false
                return
            }
            guard let text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .isoLatin1),
                  !text.isEmpty else {
                errorMessage = "File is empty or has an unsupported encoding"
                isLoading = false
                return
            }
            sourceText = text
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

private struct SourceTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UIScrollView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineBreakMode = .byClipping
        textView.textContainer.widthTracksTextView = false
        textView.textContainer.size = CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.text = text

        let scrollView = UIScrollView()
        scrollView.addSubview(textView)
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = context.coordinator
        scrollView.backgroundColor = .systemBackground

        textView.sizeToFit()
        scrollView.contentSize = textView.frame.size

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.subviews.first
        }
    }
}
