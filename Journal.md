# Journal.md

The living learning log for **Arcade Collector**. Read this to understand not just *what* the code does, but *why* it looks the way it does — and to hear about the bugs we squashed on the way there.

---

## The Big Picture

Imagine you own a garage full of old arcade PCBs. Some boot up beautifully. Some make noise but no picture. Some are just labeled "Neo Geo — needs recap." You want an app that's part **inventory list**, part **hardware wiki**, and part **repair diary** — a single place where "I own this," "here's what's wrong with it," and "here's what the manual says about the JAMMA pinout" all live together.

That's Arcade Collector. It started as a 2021 UIKit + Storyboards + Core Data app targeting iOS 12, and in July 2026 we kicked off a modernization pass to bring it to iOS 26 with SwiftUI and SwiftData. Both apps live in this repo right now — the old one still runs while we rebuild the new one screen-by-screen underneath it.

The reference data comes from the [Arcade Game Database](http://adb.arcadeitalia.net) — about 4,166 games' worth of rom names, titles, years, manufacturers, and orientations, shipped as a bundled JSON file the app seeds into its store on first launch.

---

## Architecture Deep Dive

### The Two-Restaurant Problem

Think of this repo like a restaurant that decided to open a **second location next door** using an entirely different menu, kitchen, and staff — but both restaurants share the same street address and neither closes during the transition.

- **`arcadeCollector/`** is the original diner. UIKit, Storyboards, Core Data, CocoaPods (a `Charts` dependency). It works. It ships. We don't remodel its kitchen.
- **`ArcadeCollectorApp/ArcadeCollector.xcodeproj`** is the new place. SwiftUI, SwiftData, SPM, iOS 26 with Liquid Glass. We're building it out one dining room at a time.
- **`ArcadeCollectorApp.xcworkspace`** at the repo root is the shared front-of-house that lets you walk into either kitchen from one door.

Why this layout instead of a big-bang rewrite? Because **rewrites die in the desert**. Keeping the old app buildable means we can ship bug fixes to real users while the new app grows. It also gives us a working comparison — when a screen in the new app misbehaves, we can boot the old one and see how it *should* look.

### The SwiftData Model as a Motherboard

The new app's data layer is designed like an arcade PCB itself — one big central chip (`Game`) with dedicated sub-boards attached for the heavy stuff:

- **`Game`** is the CPU: identity, metadata, ownership, six LED-style status indicators (boot / audio / video / controls / extended-play / overall). Every game plugs into everything else through it.
- **`GameArtwork`** is the ROM socket bank: instead of the legacy app's *seven parallel fields* (`cabinetImageData`, `flyerImageData`, `marqueeData`...), we have one relationship where each row is one artwork kind (`cabinet`, `flyer`, `marquee`, ...). Add a new artwork type? Add an enum case, not seven fields.
- **`RepairLog`** and **`RepairLogPhoto`** are the service log — a repair log has a date, notes, and *any number of photos*, not a hardcoded 3-slot limit like the legacy app.
- **`GameCollection`** is a user-defined grouping. Note what's *not* here: "All Games" and "Repair Logs" from the legacy app are gone. Those weren't collections, they were **views** — computed filters over the full game list — and modeling them as persisted rows was a design smell.

The heavy binary blobs (images, PDFs) all use `@Attribute(.externalStorage)`, so SwiftData writes them to files next to the database instead of stuffing them into the SQLite rows.

### The Seeder as an Autoloader

On first launch, the app needs to populate ~4,166 games from a bundled JSON file. If we do that on the main thread, the UI freezes for a couple of seconds and everyone thinks the app crashed. So we built `GameSeeder` as a **`@ModelActor`** — SwiftData's way of saying "this actor has its own model context, safe to use off the main thread."

The flow reads like a coin-op boot sequence:
1. App launches. `ContentView` appears with an empty list and a `ContentUnavailableView` fallback ("No Games Yet").
2. `.task { }` fires. `GameSeeder` spins up on a background actor.
3. Seeder fetches with `fetchLimit = 1`. Store empty? Continue. Not empty? Bail immediately — this is idempotent, so it's safe to call every launch.
4. JSON decoded, 4,166 `Game` rows inserted, one `save()` at the end.
5. `@Query` in `ContentView` notices new data, list populates.

---

## The Codebase Map

```
arcadeCollector/                     # Legacy UIKit app — treat as read-only-ish
├── AppDelegate.swift
├── Storyboards/
├── View Controllers/                # Where the UIKit logic lives
├── Model/
│   ├── DataController.swift         # NSPersistentContainer wrangler
│   ├── CollectionManager.swift      # Seeds Core Data from ScrollingData.json
│   └── ScrollingData.json           # The seed file, original home
└── Networking/                      # ADB image/data fetching

ArcadeCollectorApp/                  # New SwiftUI app — active development
└── ArcadeCollector/
    ├── ArcadeCollectorApp.swift     # @main, ModelContainer, seed trigger
    ├── ContentView.swift            # Root list of games
    ├── Models/                      # All @Model classes and enums
    │   ├── Game.swift
    │   ├── GameArtwork.swift
    │   ├── GameCollection.swift
    │   ├── GameEnums.swift          # ComponentStatus, ScreenOrientation, etc.
    │   ├── RepairLog.swift
    │   └── RepairLogPhoto.swift
    ├── Services/
    │   └── GameSeeder.swift         # @ModelActor for first-launch seeding
    └── Resources/
        └── ScrollingData.json       # Copy of the legacy seed, bundled

Pods/                                # CocoaPods — DO NOT edit
```

If you're touching **new SwiftUI code**, start in `ArcadeCollectorApp/`. If you're touching **legacy behavior** (probably because you're studying it before porting a screen), start in `arcadeCollector/View Controllers/`.

---

## Tech Stack & Why

| Choice | Why |
|---|---|
| **SwiftUI** (new app) | Declarative UI matches how arcade collection data flows: entity → view. Also, iOS 26's Liquid Glass looks *fantastic* for a UI that lives next to photos of Neo Geo cabinets. |
| **SwiftData** (new app) | Wanted persistence without the Core Data ceremony. Also gives us `@Model`, `@Query`, and `@Attribute(.externalStorage)` for image blobs — three features that used to be separate boilerplate. |
| **`@ModelActor`** | Seeding 4,166 rows on the main thread is a UI hitch. `@ModelActor` gives us a background context without hand-rolling `NSManagedObjectContext.perform` gymnastics. |
| **Swift Package Manager** (new app) | Dropping CocoaPods removes an entire class of "run `pod install`" surprises. Legacy app keeps CocoaPods because ripping it out of a working app isn't worth the churn. |
| **async/await, no Combine** | Combine's operator zoo is overkill for what this app needs. Async sequences and Task cover 100% of our real needs. |
| **Swift Testing** (new app) | Newer, macro-based, and reads like documentation. Better than XCTest for greenfield code. |
| **UIKit + Storyboards** (legacy app) | Because it was 2021 and it worked. Not changing this. |

---

## The Journey

### 2026-07-05 — Kickoff. The Case-Sensitivity Trap.

Started the new SwiftUI project. Wanted to name the folder `ArcadeCollector/` to match the product name. Fought Xcode for ten minutes wondering why the workspace kept refusing to open — turns out macOS is **case-insensitive by default** on APFS, and `ArcadeCollector/` collided with the sibling `arcadeCollector/` folder that already existed for the legacy app. Two files with names that differ only in case? Filesystem shrugs.

**The fix**: rename the new folder to `ArcadeCollectorApp/`. The Xcode product/scheme is still `ArcadeCollector`, so users never see the `App` suffix. Same reason we ended up with `ArcadeCollectorApp.xcworkspace` — the workspace file couldn't share a name with the legacy workspace either.

**Lesson**: on macOS, treat repo-root folder names like AWS S3 bucket names — assume case-insensitive unless you've explicitly checked.

### 2026-07-05 — Should "All Games" Be a Table?

The legacy Core Data model has a `CollectionEntity` table seeded with four rows: `"All Games"`, `"My Games"`, `"Wanted Games"`, `"Repair Logs"`. Users can't add or remove these — they're hardcoded in `CollectionManager.swift`. Every Game has a many-to-many relationship to CollectionEntity.

While drafting the SwiftData port, I sat with this for a minute. **"All Games" isn't a collection — it's `Game.all`.** "Repair Logs" isn't a collection either — it's `Game` filtered where `!repairLogs.isEmpty`. And "My Games" / "Wanted Games" are really *properties of the game itself*, not memberships in a group: is this game one I own, or one I want?

**The rewrite**: `Game.ownership: OwnershipStatus` enum (`.none / .owned / .wanted`) replaces "My Games" and "Wanted Games". "All Games" and "Repair Logs" become computed `@Query` filters in the UI, not persisted rows. `GameCollection` is now reserved for *genuinely user-authored* groupings (e.g., "shmups I'm hunting for at the next arcade auction").

**Lesson**: before porting a schema, ask which entities *are* things vs. which are *views over things*. Legacy databases love to persist views. The rewrite is the moment to draw the line.

### 2026-07-05 — Swift 6 Isolation Fight

First cut of `GameSeeder` had a nested `SeedPayload: Decodable` struct and an extension on `ScreenOrientation` with a `init(legacyValue: String)`. Compiler warnings:

> Main actor-isolated conformance of 'SeedPayload' to 'Decodable' cannot be used in actor-isolated context; this is an error in the Swift 6 language mode

The new project template ships with **default MainActor isolation** enabled at the module level. That means every type is implicitly `@MainActor` unless told otherwise. But `GameSeeder` is an actor, and calling MainActor-isolated code from actor code is a Swift 6 error.

**The fix**: mark the struct `private nonisolated struct SeedPayload` and move the `legacyValue` conversion inside the actor as a private method. `nonisolated` on the struct declaration makes the whole type — and its Decodable conformance — free of actor isolation.

**Lesson**: in Swift 6 mode, small helper types used off-main-thread need `nonisolated`. Sendable alone isn't enough — you need the *conformance* to be nonisolated, and `nonisolated` on the type declaration achieves that.

### 2026-07-06 — The Case-Collision Saga (and Why We Have Two Workspaces)

Xcode threw a scary-sounding error on the legacy scheme:

> The project item "arcadeCollector.xcodeproj/Products/arcadeCollector.app" refers to the path "arcadeCollector.app", but the capitalization on disk is "ArcadeCollector.app".

Root cause: `ArcadeCollectorApp.xcworkspace` used to contain **both** projects (legacy + new SwiftUI). Xcode workspaces share one DerivedData Products dir by default. The new app writes `ArcadeCollector.app` (uppercase, from its target name), and the legacy target expects to write `arcadeCollector.app` (lowercase). On APFS's case-insensitive filesystem, these two paths refer to the *same* file — whichever built last set the capitalization on disk, and Xcode's project-item checker screamed when the .pbxproj expectation didn't match.

**Attempt #1 (didn't work)**: Set `CONFIGURATION_BUILD_DIR` on the legacy target to a `Legacy/` subfolder to isolate its Products. Worked for the legacy app bundle itself, but the CocoaPods `[CP] Embed Pods Frameworks` script uses `$BUILT_PRODUCTS_DIR/Charts/Charts.framework` and Pods targets don't inherit our override — the framework was still built to the *standard* location, so the embed script's `install_framework` couldn't find its source. Build died with `source: unbound variable`. Reverted.

**The fix that stuck**: **Give each app its own workspace.**
- `ArcadeCollectorApp.xcworkspace` → new SwiftUI app only
- `arcadeCollector.xcworkspace` → legacy UIKit + Pods (CocoaPods-managed, unchanged from before)

Because they never share DerivedData, they can never collide. This also aligns with the CLAUDE.md guidance that legacy stays touched-only-when-necessary — no more accidentally rebuilding it via the new workspace.

**Lesson 1**: On macOS, two build products in the same directory whose names differ only in case are a ticking time bomb. Solve it at the *workspace boundary*, not with build-setting overrides.

**Lesson 2**: CocoaPods' `install_framework` script assumes `BUILT_PRODUCTS_DIR` and `PODS_CONFIGURATION_BUILD_DIR` share a build tree. If you override one and not the other, the script fails silently with an `unbound variable` error deep inside a helper function — very hard to debug from Xcode's summary. Look at the actual `StandardOutputAndStandardError.txt` inside the `.xcresult` bundle for the real message.

**Lesson 3**: `PhaseScriptExecution failed with a nonzero exit code` is Xcode-speak for "some shell script phase died — go read the log yourself." Not helpful. Learn to fish it out of the diagnostics folder.

### 2026-07-06 — First Real Screen: Game Detail

Built the game detail view — the moment the app crossed from "a list of names" into "an inventory tool." Five sections: Overview (LabeledContent rows), Ownership (segmented `None / Owned / Wanted` picker + PCB toggle), Component Status (6 rows of LED-style pickers with colored SF Symbols), Artwork (placeholder + fetch button), Repair Log (placeholder).

The status pickers use SwiftUI's menu-style `Picker` with `Label` items that carry both a symbol name and a color per case. So the row itself gets a live-updating colored dot, and the dropdown shows the same iconography — no separate legend needed.

Wired the list → detail navigation using `NavigationLink(value: game)` + `.navigationDestination(for: Game.self)`. Two-way editing "just works" because `@Model` types are already `Observable` — a `@Bindable var game: Game` in the detail view gives you `$game.ownership`, `$game.bootStatus`, etc., and SwiftData persists writes to the shared context.

**Aha moment**: I initially reached for `@Observable` + `ObservableObject`-style boilerplate before remembering SwiftData models are already observable. The magic is `@Bindable`. Zero glue code.

### 2026-07-06 — Artwork Fetching: A Small Network Actor Story

The Arcade Database API (`adb.arcadeitalia.net`) is the source of truth for game artwork. Legacy app used raw `URLSession.dataTask` with completion handlers and manual `DispatchQueue.main.async` hops. The new app gets a cleaner architecture:

- **`ArcadeDatabaseClient`** — a `nonisolated struct: Sendable`. One method to fetch metadata JSON, one to download image data, one to compute the fixed PCB URL. That's the whole surface area.
- **`ArtworkFetcher`** — a `@ModelActor` that pulls metadata, downloads 6 image kinds (cabinet, flyer, in-game, marquee, title, PCB), inserts `GameArtwork` rows, back-fills empty metadata fields, saves. Per-image failures are swallowed (missing PCB image is common — no reason to abort the batch).
- **View** — button + `Task { await fetcher.fetch(for: id) }`, progress indicator, `@Query`-driven list refresh once artwork lands.

**HTTPS win**: `adb.arcadeitalia.net` supports HTTPS and 301s HTTP → HTTPS. That means no `NSAppTransportSecurity` exception in Info.plist. The legacy app has an ATS bypass we don't need to port.

**Swift 6 isolation, round two**: default MainActor isolation bit us again. `ArcadeDatabaseClient` and its private `ScraperResponse` DTO both needed `nonisolated struct` to be callable from the `@ModelActor` context. Same lesson as with the seeder — types with no UI state should be `nonisolated` in this project's Swift 6 mode, or the compiler assumes MainActor and refuses to cross the actor boundary.

**Test strategy that paid off**: instead of mocking the API, the tests hit the real endpoint but use `Issue.record` to *skip* rather than fail if the network is out. This means when the API's response shape changes (which it will — the JSON is manufactured by a scraper), a green suite promises real compatibility. Mocked tests would have missed that the `screen_orientation` field is capitalized differently than `nplayers`, or that `youtube_video_id` is sometimes empty string vs. null.

**Lesson**: for external-API integrations, "live tests with graceful skip" beat "mocks that lie" every time. The bar for a green test should be "would this ship" not "does my recorded fixture still parse."

**Fetcher back-fills metadata**: since we're already talking to the API for images, we opportunistically fill in `manufacturer`, `year`, `genre`, `youtubeVideoID`, `shortPlayURL` if the local Game had them empty. The seed JSON only carries five fields; the full API returns dozens. Free upgrade path — every artwork fetch enriches the game.

### 2026-07-06 — "How Many Games, Actually?"

Wrote a Swift Testing suite (`GameSeederTests`) to verify seeding logic without spinning up the simulator. Three tests: empty-store insert, idempotency on populated store, and a bundle-resource sanity check that decodes the shipped JSON and counts the rows.

The bundle-resource test failed on first run — I'd been claiming "~5,500 games" in `CLAUDE.md`, `Journal.md`, and my head. Actual count from the JSON: **4,166**. The legacy `README.md` says it right there in plain text: "All Games (4166 in reference)". I never read that line closely enough on day one and just eyeballed the file size.

**Lesson**: when you're going to quote a number from someone else's data file, count it once and pin the number to a test. Rough estimates rot into folklore fast.

### 2026-07-05 — The Filesystem-Synchronized Group Win

Needed to bundle `ScrollingData.json` (~760KB) as a resource. Old Xcode workflow: drag file into project navigator, tick the target box, hope it landed in "Copy Bundle Resources". New Xcode 26 default: **PBXFileSystemSynchronizedRootGroup**. Any file placed in the source folder tree is auto-detected during build. I `cp`'d the file into `Resources/`, built the project, and the JSON was already in `ArcadeCollector.app`. No project.pbxproj edits, no build-phase adjustments.

**Lesson**: don't fight modern Xcode's synced groups. If the file's in the folder, it's in the build.

---

## Engineer's Wisdom

**Prefer normalization over parallel fields.** The legacy Game entity had seven parallel `*ImageData` / `*ImageURLString` pairs, one per artwork type. Adding an eighth artwork type would mean editing the schema, adding two attributes, migrating existing data, and updating every read site. The new `GameArtwork` model turns "add a new artwork kind" into "add an enum case" — a schema-free change.

**Enums beat magic numbers.** The legacy `bootStatus` field is `Int16`, with the developer expected to remember that `0 = white LED = untested`, `1 = red = broken`, `2 = yellow = has issues`, `3 = green = working`. That's four opportunities per call site to write the wrong number. `ComponentStatus` makes the invalid states unrepresentable.

**Idempotent side effects.** `GameSeeder.seedIfNeeded()` is safe to call every launch because it does a `fetchLimit = 1` check first. No first-launch flag in UserDefaults, no dance with `applicationDidFinishLaunching`. The store itself is the source of truth for "have we seeded yet?"

**Computed views > persisted views.** If the shape of a collection is "everything in table X where condition Y holds," it's a query, not a row. Save the row for things a user actually authored.

**Case-insensitive filesystems are lava.** Two siblings that differ only in case is a code smell that will bite you.

---

## If I Were Starting Over...

- **I'd write `Journal.md` earlier.** Starting on day one of a project lets you capture the small "why" decisions before they blur together. Writing it in retrospect always misses the tiny forks in the road that turned out to matter.

- **I'd have a `DEVLOG.md` too, maybe.** `Journal.md` is for insight and learning. A separate append-only devlog for "what I worked on today" would give a nice paper trail without polluting the learning journal with dated task notes.

- **I'd have started with a data migration plan.** The current design treats the port as a clean start — no user data carries over from the legacy app. If we ever want to import existing users' Core Data stores, the drift between the legacy and new schemas (especially the LED-int-to-enum and normalized artwork) becomes a migration script. That's fine, but it's a decision we made *implicitly* rather than intentionally. Worth revisiting before we ship.

- **I'd rely more on `#Preview` from day one.** The empty `ContentView` we have today has no meaningful preview because it queries `Game` from an in-memory store with zero rows. A `Preview` extension that inserts a few `Game` samples into the preview container would pay for itself the moment we start building detail screens.
