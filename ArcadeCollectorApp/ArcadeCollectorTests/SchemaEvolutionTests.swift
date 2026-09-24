//
//  SchemaEvolutionTests.swift
//  ArcadeCollectorTests
//
//  Automates steps 7–8 of the manual rehearsal checklist in Journal.md.
//
//  The most expensive bug this project has hit (2026-07-09) was a `fatalError`
//  inside `ModelContainer.init`: a non-optional `String` was added to a
//  `@Model` with no inline default, so SwiftData had nothing to backfill into
//  existing rows. It only reproduces on a *second* launch, when an existing
//  store meets a new schema — which means no in-memory test and no
//  same-schema roundtrip can see it. `PersistenceMigrationTests` writes and
//  reads with one compiled schema, so it can't either.
//
//  Two complementary guards here:
//
//  1. `newNonOptionalAttributesDeclareDefaults` — the real one. Asserts the
//     set of non-optional attributes lacking a default value hasn't grown.
//     Runs against the actual app models, so it catches the actual bug.
//
//  2. `storeSurvivesAddingADefaultedProperty` — an end-to-end on-disk
//     migration across two genuine schema versions, which is the literal
//     manual rehearsal expressed as code. Guards the framework behavior the
//     first check assumes.
//

import Testing
import Foundation
import SwiftData
@testable import ArcadeCollector

@Suite("Schema evolution")
struct SchemaEvolutionTests {

    // MARK: - 1. The safety rule, asserted against the real models

    /// Non-optional attributes that carry no default value.
    ///
    /// These are all assigned in `init` and are **safe**, because every one of
    /// them shipped as part of its entity from the beginning — there has never
    /// been a store without them, so there is nothing for SwiftData to
    /// backfill. The hazard is only ever an *addition* to this list: a
    /// non-optional property added to an entity that already exists in
    /// someone's store, with no default to populate old rows.
    ///
    /// So this baseline is a tripwire, not a wish list. Nothing here needs
    /// fixing. If the test fails because the set grew, the fix is almost
    /// always to give the new property an inline default
    /// (`var newField: String = ""`), not to edit this list.
    ///
    /// Legitimate reasons to edit it: a brand-new entity (no existing rows to
    /// migrate), or a property whose backfill is handled by a custom
    /// `SchemaMigrationPlan`. Both are deliberate acts that deserve to show up
    /// in a diff, which is the point of spelling the set out here rather than
    /// computing it.
    private static let attributesWithoutDefaults: Set<String> = [
        "Game.audioChannels",
        "Game.audioStatus",
        "Game.bootStatus",
        "Game.controlsStatus",
        "Game.cpus",
        "Game.displayType",
        "Game.driver",
        "Game.emulationStatus",
        "Game.extendedPlayStatus",
        "Game.functionalCondition",
        "Game.genre",
        "Game.horizontalRefresh",
        "Game.inputButtons",
        "Game.inputControls",
        "Game.isBootleg",
        "Game.mameNotes",
        "Game.manufacturer",
        "Game.monitorResolutionType",
        "Game.orientation",
        "Game.ownership",
        "Game.players",
        "Game.resolution",
        "Game.romSetName",
        "Game.screens",
        "Game.soundDevices",
        "Game.title",
        "Game.verticalRefresh",
        "Game.verticalTotalLines",
        "Game.videoStatus",
        "Game.year",
        "GameArtwork.kind",
        "GameCollection.name",
        "GameCollection.sortOrder",
        "RepairLog.date",
        "RepairLog.notes",
        "RepairLogPhoto.order",
    ]

    private static func liveAttributesWithoutDefaults() -> Set<String> {
        var result: Set<String> = []
        for entity in AppSchema.schema.entities {
            for attribute in entity.attributes where !attribute.isOptional && attribute.defaultValue == nil {
                result.insert("\(entity.name).\(attribute.name)")
            }
        }
        return result
    }

    /// The guard that would have caught the 2026-07-09 crash at desk time
    /// instead of on second launch.
    @Test("New non-optional attributes declare an inline default")
    func newNonOptionalAttributesDeclareDefaults() {
        let live = Self.liveAttributesWithoutDefaults()
        let added = live.subtracting(Self.attributesWithoutDefaults)

        #expect(
            added.isEmpty,
            """
            New non-optional attribute(s) with no default value: \
            \(added.sorted().joined(separator: ", ")).

            A non-optional property added to an existing entity needs an \
            inline default (`var newField: String = ""`) so SwiftData can \
            backfill rows in stores written by earlier builds. Without one, \
            ModelContainer.init hits a fatalError on the next launch — in \
            Release, on a user's device, with their data already on disk.

            If the addition is genuinely safe (brand-new entity, or a custom \
            SchemaMigrationPlan handles the backfill), add it to \
            `attributesWithoutDefaults` with a note saying which.
            """
        )
    }

    /// Catches the inverse drift: an attribute disappearing from the baseline
    /// means the model layer changed shape, and the baseline is now lying
    /// about what it's protecting.
    @Test("Baseline has no stale entries")
    func baselineHasNoStaleEntries() {
        let live = Self.liveAttributesWithoutDefaults()
        let removed = Self.attributesWithoutDefaults.subtracting(live)

        #expect(
            removed.isEmpty,
            """
            `attributesWithoutDefaults` lists attribute(s) that no longer \
            exist or now have defaults: \(removed.sorted().joined(separator: ", ")). \
            Remove them so the baseline keeps describing reality.
            """
        )
    }

    // MARK: - 2. End-to-end on-disk migration across two schema versions

    /// Two versions of the same entity. Nesting the `@Model` inside a
    /// `VersionedSchema` namespace is what lets both exist in one module:
    /// SwiftData derives the entity name from the unqualified type name, so
    /// `ProbeSchemaV1.MigrationProbe` and `ProbeSchemaV2.MigrationProbe` are
    /// distinct Swift types that both map to the entity `MigrationProbe`.
    enum ProbeSchemaV1: VersionedSchema {
        static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
        static var models: [any PersistentModel.Type] { [MigrationProbe.self] }

        @Model final class MigrationProbe {
            var name: String
            init(name: String) { self.name = name }
        }
    }

    /// V1 plus one non-optional property *with* an inline default — the exact
    /// shape the safety rule prescribes.
    enum ProbeSchemaV2: VersionedSchema {
        static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
        static var models: [any PersistentModel.Type] { [MigrationProbe.self] }

        @Model final class MigrationProbe {
            var name: String
            var addedWithDefault: String = "backfilled"
            init(name: String) { self.name = name }
        }
    }

    private static func makeOnDiskURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SchemaEvolutionTest-\(UUID().uuidString).store")
    }

    private static func removeStore(at url: URL) {
        let fm = FileManager.default
        try? fm.removeItem(at: url)
        // SwiftData also writes -shm / -wal sidecars.
        try? fm.removeItem(at: url.appendingPathExtension("shm"))
        try? fm.removeItem(at: url.appendingPathExtension("wal"))
    }

    /// The manual rehearsal, automated: write a store under one schema, close
    /// it, then reopen the same file under a schema that adds a defaulted
    /// non-optional property. The container must open, the existing row must
    /// survive, and the new column must be backfilled with the default.
    @Test("An on-disk store survives adding a defaulted property")
    func storeSurvivesAddingADefaultedProperty() async throws {
        let storeURL = Self.makeOnDiskURL()
        defer { Self.removeStore(at: storeURL) }

        // --- Launch 1: the shipped build ---
        do {
            let schema = Schema(versionedSchema: ProbeSchemaV1.self)
            let container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, url: storeURL)
            )
            let context = ModelContext(container)
            context.insert(ProbeSchemaV1.MigrationProbe(name: "pacman"))
            try context.save()
        }

        // --- Launch 2: the update, with a wider schema ---
        let schema = Schema(versionedSchema: ProbeSchemaV2.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: storeURL)
        )
        let context = ModelContext(container)
        let rows = try context.fetch(FetchDescriptor<ProbeSchemaV2.MigrationProbe>())

        #expect(rows.count == 1, "the pre-existing row should survive the migration")
        #expect(rows.first?.name == "pacman", "existing data should be preserved verbatim")
        #expect(rows.first?.addedWithDefault == "backfilled",
                "the new column should be backfilled with its inline default")
    }

    // MARK: - What isn't tested here, and why
    //
    // Step 8 of the checklist — drop the inline default and watch it fail —
    // stays manual, deliberately. That failure is a `fatalError` inside
    // `ModelContainer.init`, and `fatalError` is uncatchable in Swift: it
    // would abort the test process rather than report a failure, taking the
    // rest of the suite with it. A test that can only signal by crashing the
    // runner is worse than the assertion in
    // `newNonOptionalAttributesDeclareDefaults`, which catches the same
    // mistake statically and prints a useful message.
}
