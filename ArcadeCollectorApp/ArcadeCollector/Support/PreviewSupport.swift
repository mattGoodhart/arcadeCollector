//
//  PreviewSupport.swift
//  ArcadeCollector
//

import SwiftData

enum PreviewSupport {
    /// In-memory `ModelContainer` wired with the full app schema, for use in `#Preview` blocks.
    /// Force-unwraps because a preview crash is loud and immediate — appropriate for dev-only code.
    static var container: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: AppSchema.schema, configurations: config)
    }
}
