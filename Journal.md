# Journal.md

The living learning log for **Arcade Collector**. Read this to understand not just *what* the code does, but *why* it looks the way it does — and to hear about the bugs we squashed on the way there.

---

## The Big Picture

Imagine you own a garage full of old arcade PCBs. Some boot up beautifully. Some make noise but no picture. Some are just labeled "Neo Geo — needs recap." You want an app that's part **inventory list**, part **hardware wiki**, and part **repair diary** — a single place where "I own this," "here's what's wrong with it," and "here's what the manual says about the JAMMA pinout" all live together.

That's Arcade Collector. It started as a 2021 UIKit + Storyboards + Core Data app targeting iOS 12, and in July 2026 we kicked off a modernization pass to bring it to iOS 26 with SwiftUI and SwiftData. Both apps live in this repo right now — the old one still runs while we rebuild the new one screen-by-screen underneath it.

The reference data comes from the [Arcade Game Database](http://adb.arcadeitalia.net) — 3,855 games' worth of rom names, titles, years, manufacturers, hardware specs, and more, shipped as a bundled JSON file the app seeds into its store on first launch.

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
    ├── ContentView.swift            # TabView root: Summary, All Games, My Collection, Wanted, Repair Logs
    ├── Models/                      # All @Model classes and enums
    │   ├── Game.swift
    │   ├── GameArtwork.swift
    │   ├── GameCollection.swift
    │   ├── GameEnums.swift          # ComponentStatus, ScreenOrientation, etc.
    │   ├── RepairLog.swift
    │   └── RepairLogPhoto.swift
    ├── Views/
    │   ├── AboutView.swift          # Data-source credits with banner images
    │   ├── GameDetailView.swift     # Full game detail: metadata, ownership, status, artwork, repair log
    │   ├── GameListFilter.swift     # GameListMode, GameSort, GameListFilter predicate/enum filtering
    │   ├── GameListTab.swift        # Per-tab wrapper: NavigationStack, sort/filter, search, toolbar
    │   ├── GameListView.swift       # Year-grouped list with section index, alternating rows, game icons
    │   ├── HardwareDetailView.swift # API-driven hardware specs sheet
    │   ├── RepairLogEntryView.swift # Edit entry: date, notes, PhotosPicker for photos
    │   ├── RepairLogListView.swift  # Repair entries for a game, add/delete
    │   ├── SummaryView.swift        # Collection stats, donut chart, component status bars
    │   ├── Theme.swift              # Color palette extensions (arcadeRowEven/Odd, arcadeToolbar, etc.)
    │   └── ZoomableImageView.swift  # Full-screen pinch-to-zoom image viewer
    ├── Services/
    │   ├── ArcadeDatabaseClient.swift # API client for adb.arcadeitalia.net
    │   ├── ArtworkFetcher.swift     # @ModelActor: downloads artwork, back-fills metadata
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

### 2026-07-07 — About View and the Legacy Color Scheme

Built the About view — a scrolling list of data-source credits with banner images (Arcade Database, MAME, Progetto-SNAPS, Gaming-History, World of Longplays, MAME Icons, NPlayers). Each row links out to the source's website. The banners were already in the legacy asset catalog, so we copied them into the new app's `Assets.xcassets/About Banners/` folder.

Then came the color scheme pass. The legacy app has a very distinctive teal/green palette — alternating sage green (`0.45, 0.62, 0.50`) and dark teal (`0.098, 0.392, 0.392`) table rows, a deep teal accent (`0.099, 0.391, 0.394`), and green-tinted nav bars. Ported it all:

- **AccentColor.colorset** set to the legacy deep teal, with a brighter variant for dark mode.
- **Toolbar backgrounds** use `.toolbarBackground(Color.arcadeToolbar)` + `.toolbarColorScheme(.dark)` for white-on-green nav bars across every view.
- **Alternating row colors** in the game list via `.listRowBackground()`, with `isDarkRow` passed down to `GameRow` so text flips to white on the dark teal rows.
- **Theme.swift** centralizes the palette as `Color` extensions.

**Design call**: the legacy app was light-mode only. For the new app, we added a brighter dark-mode accent color but kept the row colors the same in both modes. The teal-on-teal look is the app's identity — it should feel like the same app regardless of system appearance.

### 2026-07-07 — Repair Log CRUD

The model layer (`RepairLog`, `RepairLogPhoto`) had been defined since day one but had no UI. Built two views:

- **RepairLogListView** — shows all entries for a game sorted newest-first, swipe-to-delete, plus button to create. Empty state uses `ContentUnavailableView` with a wrench icon.
- **RepairLogEntryView** — `Form` with editable date picker, multi-line `TextEditor` for notes, and a `PhotosPicker` for attaching images. Photos show as a horizontal scroll of 100×100 thumbnails with long-press context menu to delete.

All edits are live via `@Bindable` on the `RepairLog` — SwiftData's implicit auto-save means no manual save button. The `Game.lastRepairLogDate` timestamp is kept in sync on add/delete/date-change so the Repair Logs tab can filter without traversing relationships.

**Why `PhotosPicker` over camera**: `UIImagePickerController` with `.camera` source requires a `UIViewControllerRepresentable` bridge and camera permission handling. `PhotosPicker` is pure SwiftUI, supports multi-select, and covers the 90% case. Camera capture can come later as an enhancement.

### 2026-07-07 — Tab-Based Navigation

The legacy app uses a `UITabBarController` with five tabs: Summary, My Collection, All Games, Wanted Games, Repair Logs. Each tab is a `TableViewController` instance with a `collectionTab` enum that determines its data source.

For the new app, the challenge was: how do you reuse the same list view across tabs that differ only in their filter? The solution: a `GameListMode` enum (`.allGames`, `.myCollection`, `.wanted`, `.repairLogs`) and a `GameListTab` view that wraps `GameListView` with its own `NavigationStack`, sort/filter state, and About sheet. Each tab is independent — its own navigation stack, its own search bar, its own filter state.

The mode drives three things:
1. **Filtering** — `GameListFilter.matchesEnumFilters` checks the mode first (e.g., `.myCollection` requires `ownership == .owned`), then applies user-selected filters on top.
2. **Menu visibility** — the Ownership picker is hidden on tabs where it's redundant.
3. **Empty state** — each mode has its own title and description ("Mark games as Owned to add them here").

**Why not a single list with tab-bar-driven filter?** Independent `NavigationStack`s per tab means navigating into a game detail on one tab doesn't blow away your scroll position on another. This is the iOS convention and users expect it.

### 2026-07-08 — Summary Tab with Swift Charts

Added the Summary tab — the legacy app's first tab, which showed a pie chart of board conditions and a wanted-games count. The new version uses Apple's **Swift Charts** framework (no more CocoaPods `Charts` dependency):

- **Collection counts section** — stat rows for total games, owned, wanted, in repair, boards owned.
- **Board condition chart** — `SectorMark` donut chart with Working/Issues/Broken/Untested segments. Count annotations overlay each slice, custom legend at the bottom.
- **Component status breakdown** — horizontal stacked bars for boot/audio/video/controls/extended-play across owned games, each bar color-coded by `ComponentStatus`.

Hit one build hiccup: `import Charts` initially caused a linker error because stale DerivedData from the legacy workspace's CocoaPods `Charts` framework was confusing the linker. A clean build resolved it — the system Swift Charts framework auto-links fine.

**Lesson**: when two workspaces in the same repo both use something called "Charts" (one CocoaPods, one system framework), stale DerivedData can cross-contaminate. Clean builds are cheap insurance.

### 2026-07-08 — Zoomable Image Viewer

The legacy app has a `ZoomableImageViewController` backed by a `UIScrollView` with `minimumZoomScale = 1.0` and `maximumZoomScale = 5.0`. Built the SwiftUI equivalent as `ZoomableImageView`:

- **Pinch-to-zoom** via `MagnifyGesture`, clamped 1×–5×.
- **Drag-to-pan** via simultaneous `DragGesture`, only active when zoomed past 1×.
- **Double-tap** toggles between 1× and 3×.
- Black background with a dark translucent toolbar.
- Presented as `.fullScreenCover` from both artwork thumbnails (GameDetailView) and repair log photos (RepairLogEntryView).

**Why `MagnifyGesture` + `DragGesture` instead of wrapping `UIScrollView`?** Fewer lines, no `UIViewRepresentable` boilerplate, and the gesture composition API handles the simultaneous pinch+drag case cleanly. The tradeoff: `UIScrollView` has bounce physics and content-inset handling built in. For a simple image viewer, the SwiftUI gestures are good enough.

### 2026-07-08 — Collections: Built, Then Removed

Built a full Collections UI — `CollectionsListView` (create/rename/delete collections), `CollectionDetailView` (view games, swipe to remove), and a toggles section in `GameDetailView` for managing collection membership. Added a Collections tab.

With six tabs, iOS pushed the last one into a "More" ellipsis menu — not great for discoverability. More importantly, the `GameCollection` model was designed for *user-authored groupings*, but the primary use case ("My Collection") was already handled by the `ownership == .owned` filter on the My Collection tab.

**Removed the tab and all three view files.** The `GameCollection` model stays in the schema (removing it would require a migration), but nothing references it in the UI. If users later need custom groupings ("games to bring to the meetup"), we can resurface it without a schema change.

**Lesson**: building something end-to-end before deciding to cut it is a valid design process. The ten minutes of code taught us that the tab bar was already at capacity and that the model's design was sound even if the UI wasn't needed yet.

### 2026-07-08 — Game Icons from the Legacy Asset Catalog

The legacy app's game list shows a small icon for each game, loaded from `NSDataAsset(name: "icons/\(romSetName)")` — 3,762 `.ico` files bundled as data assets. Copied the entire `icons/` folder (31MB) plus the `space-invaders-placeholder.imageset` fallback into the new app's asset catalog.

Updated `GameRow` to load the icon via `NSDataAsset` and render it as a 32×32 rounded thumbnail, falling back to the Space Invaders placeholder when no matching icon exists. This replaced the `ComponentStatus` circle that was previously the leading element in each row.

**Why `NSDataAsset` instead of `UIImage(named:)`?** The icons are `.ico` files, not standard image assets. Xcode's asset catalog stores them as **data assets** (`.dataset`), not image sets (`.imageset`). `NSDataAsset` reads the raw bytes, then `UIImage(data:)` decodes the ICO format. `UIImage(named:)` would look for an imageset and find nothing.

### 2026-07-08 — Year-Grouped Sections with Section Index

The legacy app groups games by year with section headers and a right-side alphabetical index for fast scrubbing — critical UX for navigating 4,166 games. SwiftUI's `List` with `.listStyle(.plain)` doesn't provide an automatic section index like UIKit's `sectionIndexTitles(for:)`, so we built one.

The implementation groups visible games into `YearGroup` structs (year string + games array + starting global index for alternating row colors), renders them as `Section` views with bold year headers, and overlays a custom `SectionIndexOverlay` on the trailing edge. The overlay is a `VStack` of 2-digit year labels inside a dark teal pill; dragging along it computes which section the finger is over and calls `ScrollViewReader.scrollTo()`.

**Global row index tracking**: alternating row colors need to continue across section boundaries (row 0 = sage green, row 1 = dark teal, regardless of which year section they're in). Each `YearGroup` stores its `startIndex` — the sum of all games in preceding groups — and the local `ForEach` index is added to it.

**Compiler type-check timeout**: the first draft of `SectionIndexOverlay.body` was a single expression with inline gesture handling and conditional text formatting. Swift's type checker gave up. Breaking `indexLabel(for:)` and `dragGesture` into separate computed properties fixed it instantly.

**Lesson**: when SwiftUI gives "unable to type-check this expression in reasonable time," the fix is almost always to extract sub-expressions into named properties or methods. The compiler's exponential type inference doesn't scale past ~3 levels of generic nesting.

### 2026-07-08 — Hero Header and Detail View Redesign

(Done in a separate session.) Replaced the horizontal artwork thumbnail scroll + manual "Fetch Artwork" button with a legacy-style hero header at the top of `GameDetailView`:

- **Marquee banner** (full-width, 4:1 aspect). Falls back to a `missing_marquee` placeholder image imported from the legacy asset catalog. Overlays a `ProgressView` while artwork is in flight.
- **Main image** below with a 5-segment picker (Title / In-Game / Cabinet / Flyer / PCB), matching the legacy `DetailViewController`.
- **Auto-fetch on `.task`**: if the game is missing either marquee or title artwork, calls `ArtworkFetcher.fetch` on appear — ~1s round trip, matches legacy behavior.
- **Refresh** moved to a toolbar `arrow.clockwise` button for force-refetching missing kinds.

Also cleaned up the external links section: YouTube URLs now built via `URLComponents` instead of raw string interpolation (the video ID could contain characters that break `URL(string:)`), and a `linkRow(title:systemImage:url:)` helper replaced three near-identical button blocks.

The section index overlay got a precision fix: a named coordinate space anchored on the labels `VStack` (not the padded outer frame), so the drag gesture maps directly to label positions without dead zones at top and bottom.

### 2026-07-09 — Camera Integration for Repair Logs

Added the ability to take photos directly from the camera in `RepairLogEntryView`, complementing the existing `PhotosPicker` for choosing from the library:

- **CameraPicker.swift** — `UIViewControllerRepresentable` wrapping `UIImagePickerController` with `.camera` source. The coordinator handles `didFinishPickingMediaWithInfo` and `imagePickerControllerDidCancel`, dismissing via `@Environment(\.dismiss)`.
- **RepairLogEntryView** — Photos section now has two buttons: "Choose from Library" (existing `PhotosPicker`) and "Take Photo" (new). The camera button only appears when `UIImagePickerController.isSourceTypeAvailable(.camera)` is true, so it's hidden in the Simulator.
- **Info.plist** — Added `NSCameraUsageDescription` via `INFOPLIST_KEY_NSCameraUsageDescription` in both Debug and Release build settings: *"Take photos of arcade PCBs and repairs to attach to repair log entries."*

Captured photos are compressed to JPEG at 80% quality before being stored as `RepairLogPhoto` rows with `@Attribute(.externalStorage)`.

### 2026-07-09 — Bulk Artwork Fetching

Added a "Fetch All Missing Artwork" action to the Summary tab so users don't have to open each game individually to trigger artwork downloads:

- **BulkArtworkFetcher.swift** — a `@ModelActor` that fetches all owned games missing any of the 6 artwork kinds, then iterates through them calling the existing `ArtworkFetcher.fetch(for:)`. Reports progress via a callback struct (`completed`/`total`/`currentTitle`). Supports cancellation via `Task.checkCancellation()` between games. Per-game failures are swallowed — the API may not have artwork for every ROM. Returns the count so the UI can distinguish "nothing to fetch" from "fetched some."
- **SummaryView** — new "Artwork" section with four states: idle (fetch button), in-progress (`ProgressView` bar + cancel button), complete (green checkmark), and nothing-to-fetch ("All owned games have artwork"). Fetch errors flash for 3 seconds before auto-dismissing.

**Why not parallel downloads?** The Arcade Database is a community server, not a CDN. Serial per-game fetches (~6 images each) keep us from hammering it with concurrent connections. For a typical collection of 20–50 owned games, the total fetch time is a few minutes — fine for a background operation you kick off once.

### 2026-07-09 — Ownership Model Simplified

Removed the segmented `None / Owned / Wanted` picker from `GameDetailView`. The new model is simpler and more physical:

- **"Have the PCB"** toggle → game goes into My Collection. Toggling it on sets `ownership = .owned`; toggling off sets it back to `.none`.
- **Heart button** in the toolbar → marks a game as wanted. Empty heart = not wanted, filled heart = wanted. Only visible when the game is *not* owned (you don't "want" something you already have).
- The `OwnershipStatus` enum and filter logic are unchanged — they're just driven by two focused controls instead of a three-way picker.

Also updated the empty-state descriptions on the My Collection and Wanted tabs to match the new interaction ("Toggle 'Have the PCB' on a game to add it here" / "Tap the heart on a game to add it here").

### 2026-07-09 — UI Polish Pass

Several small refinements to reduce visual clutter:

- **Inline nav titles everywhere.** Switched `GameDetailView`, all `GameListTab` tabs, and `SummaryView` from large to inline navigation bar titles. The large title block was eating ~100pt of vertical space on every screen — space better used for content, especially on smaller devices.
- **Search bar scoped to All Games only.** The My Collection, Wanted, and Repair Logs tabs no longer show a search bar. These lists are small enough (user's own collection) that scrolling is faster than searching. Implemented by extracting the `GameListView` into a `@ViewBuilder` computed property with conditional `.searchable()`.
- **Section index scoped to All Games only.** The year-scrubber overlay on the right edge is useful for navigating 4,166 games but unnecessary on the smaller filtered tabs.
- **Default main image** changed from Title to In-Game in the detail view hero section — in-game screenshots are more recognizable at a glance.

### 2026-07-09 — All-Black Image Detection and Artwork Fallback

The Arcade Database sometimes returns all-black placeholder PNGs instead of real artwork — a valid HTTP 200 with image data, but visually useless. Added an `isEffectivelyBlack(_:)` check in `ArtworkFetcher` that renders each downloaded image into an 8×8 sRGB bitmap and computes the average brightness. If it's below 5/255, the image is skipped and the `GameArtwork` row is never created.

On the display side, the detail view's main image area now falls back through a priority list — In-Game → Title → Cabinet → Flyer → PCB — to always show the best available artwork rather than a placeholder. The segmented picker dynamically hides kinds that have no imagery, so users never tap a segment that leads to "No Artwork Available." If only one kind came back, the picker is hidden entirely.

### 2026-07-09 — Game History from Arcade Database

The legacy app had a "History" button that displayed a block of text from the `history` field in the scraper API response — arcade history and trivia sourced from the Arcade History project. Ported it to the new app:

- Added `history: String = ""` to the `Game` model (inline default for migration safety).
- Added the `history` key to `ArcadeDatabaseClient`'s decoder and `GameMetadata` struct.
- `ArtworkFetcher` back-fills `game.history` alongside the other metadata fields.
- `GameDetailView` shows a "History" section between Overview and Hardware when history text is available.

**SwiftData migration gotcha**: the first attempt used `var history: String` without an inline default. On launch, the `ModelContainer` initializer hit a `fatalError` because SQLite can't add a `NOT NULL` column without a default value to an existing table. Changing it to `var history: String = ""` let lightweight migration succeed. Deleted the corrupted simulator store to recover.

**Lesson**: every new non-optional property on a SwiftData `@Model` must have an inline default value, or the app will crash on devices with an existing store. This is easy to miss during development because a clean install always works.

---

## Engineer's Wisdom

**Prefer normalization over parallel fields.** The legacy Game entity had seven parallel `*ImageData` / `*ImageURLString` pairs, one per artwork type. Adding an eighth artwork type would mean editing the schema, adding two attributes, migrating existing data, and updating every read site. The new `GameArtwork` model turns "add a new artwork kind" into "add an enum case" — a schema-free change.

**Enums beat magic numbers.** The legacy `bootStatus` field is `Int16`, with the developer expected to remember that `0 = white LED = untested`, `1 = red = broken`, `2 = yellow = has issues`, `3 = green = working`. That's four opportunities per call site to write the wrong number. `ComponentStatus` makes the invalid states unrepresentable.

**Idempotent side effects.** `GameSeeder.seedIfNeeded()` is safe to call every launch because it does a `fetchLimit = 1` check first. No first-launch flag in UserDefaults, no dance with `applicationDidFinishLaunching`. The store itself is the source of truth for "have we seeded yet?"

**Computed views > persisted views.** If the shape of a collection is "everything in table X where condition Y holds," it's a query, not a row. Save the row for things a user actually authored.

**Case-insensitive filesystems are lava.** Two siblings that differ only in case is a code smell that will bite you.

**Filter garbage at the boundary, not the view layer.** The Arcade Database sometimes returns all-black placeholder PNGs instead of real artwork. Catching that in the fetcher (before it becomes a `GameArtwork` row) is cleaner than teaching every view to detect and hide bad images.

**New SwiftData fields need inline defaults.** Adding a non-optional `String` property to an existing `@Model` without `= ""` creates a `NOT NULL` column with no default — SQLite can't add that to a table with existing rows. The app crashes in the `ModelContainer` initializer. Always give new stored properties an inline default so lightweight migration can add the column.

---

## If I Were Starting Over...

- **I'd write `Journal.md` earlier.** Starting on day one of a project lets you capture the small "why" decisions before they blur together. Writing it in retrospect always misses the tiny forks in the road that turned out to matter.

- **I'd have a `DEVLOG.md` too, maybe.** `Journal.md` is for insight and learning. A separate append-only devlog for "what I worked on today" would give a nice paper trail without polluting the learning journal with dated task notes.

- **I'd have started with a data migration plan.** The current design treats the port as a clean start — no user data carries over from the legacy app. If we ever want to import existing users' Core Data stores, the drift between the legacy and new schemas (especially the LED-int-to-enum and normalized artwork) becomes a migration script. That's fine, but it's a decision we made *implicitly* rather than intentionally. Worth revisiting before we ship.

- **I'd rely more on `#Preview` from day one.** The empty `ContentView` we have today has no meaningful preview because it queries `Game` from an in-memory store with zero rows. A `Preview` extension that inserts a few `Game` samples into the preview container would pay for itself the moment we start building detail screens.

### 2026-07-10 — Game Condition Chart Rework

The Summary tab's donut chart was showing "Board Condition" based solely on the `functionalCondition` field — a single top-level status that didn't reflect the nuance captured in the per-component statuses. Reworked it to derive an overall game condition from the five individual component fields (boot, audio, video, controls, extended play):

- **Untested** — every component is `.untested`. The default state for a newly added game.
- **Working** — boot, audio, video, and controls are all `.working`; extended play can be `.working` or `.untested` (since many games don't get extended-play testing).
- **Issues** — the board boots (bootStatus ≠ `.broken`), but at least one component is `.issues` or `.broken`. This catches partially-working boards where, say, audio is dead but everything else runs.
- **Broken** — bootStatus is `.broken`. Nothing else matters if it won't boot.

Changed the scope from boards-only (`hasBoard == true`) to **all owned games**, since the component statuses are meaningful even before you've marked a board as owned separately. Section renamed from "Board Condition" to "Game Condition."

Switched the chart colors from the legacy chart palette (`chartGreen`, `chartOrange`, etc.) to `ComponentStatus.color` — the same `.green`, `.yellow`, `.red`, `.secondary` used in the per-component status bars below the chart. Visual consistency: same colors mean the same things everywhere.

Added **labels** to each donut sector (category name above the count) so the chart is readable without cross-referencing the legend.

**App icon in the donut hole**: copied the legacy app's PCB icon (`appstore.png`) into the new app's asset catalog as `AppIconImage.imageset`, then overlaid it centered in the donut's inner radius via `.chartBackground`. Also set the same image as the actual app icon for the new app (light appearance slot).

**Background cleanup**: matched the chart's row background and chart background to `Color.arcadeSummaryBackground`, and zeroed out list row insets so the chart bleeds seamlessly into the summary view's background.

**Preview data fix**: the existing preview set random statuses on only 3 of 5 component fields, so most owned games fell through all four chart categories and were invisible. Replaced with deterministic statuses — one game per category (Pac-Man = Working, Donkey Kong = Issues, Street Fighter II = Broken, Defender = Untested).

### 2026-07-10 — MAME Driver Source from XML

The legacy app's `HardwareViewController` fetches hardware details from an XML endpoint (`adb.arcadeitalia.net/download_file.php?tipo=xml&codice={rom}`) and parses the `sourcefile` attribute from the `<machine>` element — this is the MAME driver source file name (e.g. `pacman.cpp`). The new app was instead storing the `emulator_name` field from the JSON scraper (e.g. "Mame 0.288 (may-29 2026)") in `Game.driver`, which is the emulator version string, not the driver source.

Added `driverSourceFile(for:)` to `ArcadeDatabaseClient` — fetches the XML, parses with a minimal `MachineSourceFileParser` (an `XMLParserDelegate` that aborts as soon as it reads the `sourcefile` attribute, so it doesn't waste time parsing chip/display/sound data we don't need yet). `ArtworkFetcher` now calls this instead of using `emulatorName`.

Made the Driver row in `HardwareDetailView` tappable — it opens the raw MAME source file on GitHub (`raw.githubusercontent.com/mamedev/mame/master/src/mame/{driver}`), matching the "open" link under "Driver source" on the ADB game page. The URL was verified by scraping the ADB page: the current MAME repo structure puts drivers at `src/mame/{driver}`, not `src/mame/drivers/{driver}` as the legacy app assumed.

Also added `gamePageURL` to the `Game` model and `ArcadeDatabaseClient.GameMetadata`, populated from the `url` field in the scraper JSON (`https://adb.arcadeitalia.net/?mame={rom}`), for potential future use.

### 2026-07-10 — Preview Navigation Crash Fix

Tapping a game in the canvas preview crashed with a fatal error in SwiftData's `BackingData.swift`. Root cause: the `#Preview` block inserted games into an in-memory `ModelContainer` but never called `context.save()`. Without a save, persistent identifiers aren't fully materialized, and `NavigationLink(value: game)` + `.navigationDestination(for: Game.self)` triggers a crash when SwiftData tries to resolve the backing data during navigation.

**Fix**: added `try! context.save()` after the insertion loop.

**Lesson**: in-memory SwiftData preview containers need an explicit `save()` before any navigation that resolves model instances by their `PersistentIdentifier`. Insert-without-save works for display but not for identity-based lookups.

### 2026-07-10 — Removed "Overall" from Component Status

Removed the `functionalCondition` / "Overall" picker row from the `componentStatusSection` in `GameDetailView`. The overall game condition is now *derived* from the individual component statuses (as the reworked donut chart shows), so a separate manually-set "Overall" field was redundant and potentially contradictory. The five component pickers (Boot, Audio, Video, Controls, Extended Play) remain.

### 2026-07-10 — Removed `hasBoard`, Ownership Simplification

The `Game` model had two overlapping concepts: `hasBoard: Bool` and `ownership: OwnershipStatus`. In practice, "having a board" *is* ownership — if you have the PCB, you own the game. Removed `hasBoard` entirely. The "Have the PCB" toggle in `GameDetailView` now drives `ownership` directly via a computed `Binding` (`get: ownership == .owned`, `set: .owned / .none`). The heart button in the toolbar is shown when `ownership != .owned` instead of `!hasBoard`. `boardsOwned` in `SummaryView` filters on `ownership == .owned`.

**Lesson**: when two fields always change in lockstep (toggling `hasBoard` immediately set `ownership = .owned`), one of them is redundant. The `.onChange` synchronization was a code smell pointing at a modeling problem. One source of truth is always better.

### 2026-07-10 — Collapsible History Section

The Arcade Database history text can be very long (Pac-Man's entry is several pages of ports, trivia, and release history). Made the History section in `GameDetailView` collapsible using `DisclosureGroup`, defaulting to collapsed. This keeps the detail view scannable — users can expand it when they want the deep dive.

### 2026-07-10 — Flat Lists for Non-All-Games Tabs

Year-grouped sections with a section index make sense for navigating 4,166 games on the All Games tab, but they're noise on the smaller tabs (My Collection, Wanted, Repair Logs) where the user has maybe 20–50 games. Split `GameListView.body` into two paths:

- **All Games**: year-grouped sections with year headers and the section index overlay (unchanged).
- **Everything else**: a flat, alphabetically-sorted list with alternating row colors but no section grouping.

The sort uses `localizedCaseInsensitiveCompare` so titles like "1942" sort naturally alongside alphabetic titles.

### 2026-07-12 — Preview GroupRecordingError Fix

The `GameDetailView` preview was crashing with a `GroupRecordingError` — SwiftUI's vague internal error for "something in the view hierarchy blew up during a render pass." The culprit was the `.task { await fetchArtwork(force: false) }` modifier, which fires immediately in the preview. That call creates an `ArtworkFetcher` `@ModelActor` on a background actor, makes network requests to the Arcade Database, and mutates the SwiftData store when artwork comes back. The cross-context store mutation triggers a view update in the preview renderer, which chokes.

**Fix (two parts)**:
1. **Skip the network fetch in previews** — added a `ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"]` guard at the top of the `.task` block. Previews don't need live artwork.
2. **Save the context after insert** — the `#Preview` block was inserting a `Game` into the in-memory container without calling `save()`. While this works for display, any cross-context lookup by `PersistentIdentifier` (like the `@ModelActor` does) needs a saved context to resolve the ID. Added `try! container.mainContext.save()` after insert.

Also gated the component status and repair log sections behind `game.ownership == .owned` — these sections are only meaningful for owned games, and showing empty status pickers for games you don't own is confusing.

**Lesson**: Xcode previews run `.task` modifiers just like the real app. If your `.task` does network I/O or background-actor SwiftData mutations, the preview will either crash or behave unpredictably. Guard against the preview environment for side effects that don't contribute to the preview's visual output.

### 2026-07-12 — Preview Fix, Follow-up Cleanup

Ran a three-agent parallel review over the previous commit (reuse / quality / efficiency). Two findings were worth acting on; the rest were either false positives or premature abstractions.

**Leaky-abstraction fix**: the `XCODE_RUNNING_FOR_PREVIEWS` guard was sitting at the *call site* — the view's `.task` block. That works, but it puts the burden on every future caller of `ArtworkFetcher.fetch` to remember to guard. Moved the guard into `ArtworkFetcher.fetch(for:)` itself. Now the fetcher self-protects: any caller (this view, `BulkArtworkFetcher`, any future feature) automatically skips network + cross-context mutations in previews without knowing about the pitfall. The view's `.task` shrinks back to `await fetchArtwork(force: false)`.

**Reuse fix**: both `ContentView.swift` and `GameDetailView.swift` had `#Preview` blocks that spelled out the full in-memory `ModelContainer` scaffolding (schema list of all five model types, in-memory config, force-try). Extracted `PreviewSupport.container` under a new `Support/` folder. Each preview now opens with `let container = PreviewSupport.container` — one line, and adding a sixth model type to the schema is a one-file change.

**Skipped findings**:
- Extracting a `ProcessInfo.isRunningInPreview` extension. After the leaky-abstraction fix, there's exactly *one* usage of the raw env-var string. A named constant for a single call site is premature abstraction — extract when the second caller appears.
- A `game.isOwned` computed property. The `ownership == .owned` check is clear inline; the `OwnershipStatus` enum is small and well-named. Adding a helper wouldn't buy readability.

**Lesson**: guards that protect against a specific runtime environment (previews, tests, CI) should live inside the thing being protected, not at every call site. Same principle as putting HTTP retries inside the HTTP client, not in every service that uses it: the thing that owns the risky behavior should own the safety net.

### 2026-07-12 — Inline Short Play Video

Replaced the "Short Play" external link in `GameDetailView` with an inline collapsible video player. The Arcade Database serves short gameplay clips as direct MP4 downloads (`download_file.php?...&entity=shortplay`), so a native `VideoPlayer` (AVKit) works without any YouTube embed scaffolding.

The player lives inside a `DisclosureGroup` — collapsed by default, the `AVPlayer` is created lazily on first expand (no network hit until the user asks), and paused on collapse.

**Content-type snag**: the server returns `Content-Type: application/octet-stream` with `Content-disposition: attachment` — it's treating the file as a download, not a stream. `AVPlayer(url:)` refused to play it (slashed play icon). The fix: create an `AVURLAsset` with `AVURLAssetOutOfBandMIMETypeKey` set to `"video/mp4"`, which tells AVPlayer to treat the bytes as MP4 regardless of what the server claims.

The aspect ratio adapts to the game's orientation — 4:3 for horizontal games, 3:4 for vertical.

**Simulator caveat**: the iOS Simulator doesn't support hardware video decoding, so the player renders audio-only with a black frame. Confirmed working (audio plays, controls respond) — visual playback requires a physical device.

**Lesson**: when streaming video from a server you don't control, check the `Content-Type` and `Content-Disposition` headers. `AVPlayer` is strict about MIME types — if the server says "binary blob," the player won't guess. `AVURLAssetOutOfBandMIMETypeKey` is the escape hatch for servers that serve valid video with wrong headers.

### 2026-07-12 — App Store Preparation

Ran an App Store readiness audit and addressed the gaps:

1. **App category** — added `INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.reference"` to both Debug and Release build configurations. The app is a reference tool for arcade game collectors, so "Reference" fits.

2. **Code signing** — configured via Xcode's Signing & Capabilities pane with automatic signing. The `DEVELOPMENT_TEAM` is stored locally in `.xcuserdata`, not in the shared project file — standard practice for a solo developer.

3. **Privacy manifest** — created `PrivacyInfo.xcprivacy` declaring no tracking, no tracking domains, no collected data types, and no required-reason API usage. The app uses `URLSession` for artwork fetching and the camera for repair log photos, but neither is a required-reason API. `PhotosPicker` uses limited photo library access and doesn't need a usage description. The camera's `NSCameraUsageDescription` was already in place.

4. **Graceful database error handling** — replaced the `fatalError` in `ArcadeCollectorApp.swift` with optional `ModelContainer` initialization. If the SwiftData store can't be created (corrupted database, disk full, etc.), the app now shows a `ContentUnavailableView` with a "Unable to Load Database" message instead of crashing on launch. The previous `fatalError` would have been an instant rejection if App Review triggered it.

**What the audit confirmed was already fine**:
- App icon present (1024×1024 universal, dark/tinted slots declared but optional).
- Auto-generated launch screen via `UILaunchScreen_Generation`.
- Camera usage description in place.
- Zero third-party dependencies — no license compliance or supply chain concerns.
- No TODOs, FIXMEs, or stub views in the codebase.
- 12 unit/integration tests covering seeding, filtering, and API client logic.

**Remaining nice-to-haves** (not blockers):
- Dark/tinted app icon variants for adaptive icon support.
- Real UI test coverage (current UI tests are Xcode-generated stubs).
- The iOS 26.0 deployment target limits the audience to the latest OS — an intentional choice for a Liquid Glass–first design, but worth revisiting if wider reach matters.

**Lesson**: most App Store rejections come from missing metadata (category, privacy manifest) or launch crashes — things that are trivial to fix but easy to overlook when you're focused on features. An audit pass before submission catches them in minutes instead of days in the review queue.

### 2026-07-19 — Test Coverage Push: Fixture Decoding + Golden-Path UI

The App Store audit called out two soft spots: the `ArcadeDatabaseClient` decoder was only exercised via live network calls (skipped on flake), and the UI test file was still Xcode's boilerplate `testExample() {}`. Fixed both.

**Fixture-based decoder tests** — five new tests in `ArcadeDatabaseClientFixtureTests.swift` that never touch the network:

- A tiny `FixtureURLProtocol` subclass gets registered on a custom `URLSession`; the tests set a stubbed status + JSON body, then call `client.metadata(for:)` normally. The wire format is fully exercised — decoding, key mapping, fallback logic — without depending on adb.arcadeitalia.net being up.
- Five scenarios covered: happy path (all fields map correctly), missing optional fields (empty-string / nil fallbacks), empty-string `youtube_video_id` (must become nil, not `""`), empty `result` array (throws `noResultsForRom`), and HTTP 500 (throws `httpStatus`).

**The `.serialized` gotcha**: first run had 3 of 5 tests fail with bizarre assertion failures — the *happy-path* fixture test would see the *minimal* fixture's data. Turns out Swift Testing parallelizes tests within a suite by default, and my `FixtureURLProtocol`'s static `stubbedBody` was getting stomped mid-flight by concurrent tests. Adding `@Suite(..., .serialized)` fixed it instantly. XCTest ran tests serially by default; Swift Testing is opt-out. Worth remembering.

**Golden-path UI test** — one end-to-end flow in `GoldenPathUITests.swift`: launch → search "donkey" on All Games → tap `game-row-dkong` → toggle "Have the PCB" on → assert Donkey Kong shows up on My Collection → tap it → toggle back off → assert it's gone. Exercises tab bar routing, `NavigationLink(value:)` + `.navigationDestination(for:)`, `@Bindable` writes, and the ownership → filter cascade in a single 30-second run.

Getting this to work reliably was a war story. The bugs, in order:

1. **Lazy list rendering.** `List` with 4,166 rows only materializes visible cells into the accessibility tree, so `app.staticTexts["Pac-Man"]` returned nothing even though the row "existed" logically. Search narrows the list to one row → problem solved.
2. **Compound row labels.** `GameRow` bundles title + rom + year + manufacturer into one accessibility element, so `app.buttons["Pac-Man"]` didn't match either — the label was actually `"Pac-Man, pacman, 1980, Namco"`. Added `.accessibilityIdentifier("game-row-\(romSetName)")` to every row's `NavigationLink`.
3. **Section wrapping.** Same lazy-materialization problem on the detail view — `pcbSection` sits below several other sections in the detail's `List`. Added `.accessibilityIdentifier("pcb-toggle")` and a scroll-until-visible helper.
4. **Toggle taps landing on the label side.** Even after finding the switch element, `pcbToggle.tap()` didn't flip the state — SwiftUI's Toggle cell is wide (label on the left, switch on the right), and the tap was landing on the label area which is inert. Fix: `coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()` to hit the switch knob directly.
5. **Async Binding propagation.** After a successful tap, `pcbToggle.value` was still `"0"` for a beat — SwiftUI Toggle state flows through the binding on the next render, not synchronously. Added a `waitForSwitch(_:on:timeout:)` poll helper instead of asserting immediately.

**Two production-code affordances** were needed to make this test tractable: the two `.accessibilityIdentifier(...)` calls above. That's it — no launch-arg store reset, no test-only view modifiers, no feature flags. Clean.

**Lesson 1**: SwiftUI `List` and XCUITest have a fundamental impedance mismatch — the accessibility tree is a *rendered* snapshot, not the logical view hierarchy. For any list with > a screenful of data, you need either search-first navigation or explicit `.scrollTo(...)` in the test. Off-screen rows are invisible.

**Lesson 2**: If you're going to write UI tests against SwiftUI, budget for accessibility identifiers on your interactive elements. It's one line per element, and it makes the difference between a UI test suite and a UI test wish.

**Lesson 3**: Coordinate-based taps are a code smell, but for wide-cell controls like `Toggle` in a `Form`/`List`, they're the only reliable option. Element-based `.tap()` doesn't know which sub-region of a compound cell is the interactive part.

Suite count: 15 → 21 tests. The five decoder tests are ~0.1s each, deterministic, and cover the JSON contract that used to be verified only by live-API integration tests. The one UI test is ~30s and catches routing / binding / cross-tab observation regressions that no unit test can.

### 2026-07-19 — Display Type Parsing and Forced 4:3 Aspect Ratio

The Arcade Database's XML endpoint contains `<display>` elements with a `type` attribute ("raster" or "vector") and — for multi-monitor games like Punch-Out!! — multiple `<display>` elements. The legacy app parsed this into a `displayType` string, but the new app's `MachineSourceFileParser` was aborting as soon as it found the `<machine>` element's `sourcefile` attribute, throwing away everything else in the XML.

**Extended the XML parser** — renamed `MachineSourceFileParser` to `MachineXMLParser` and changed it to continue parsing past `<machine>`. It now captures the `type` attribute from the first `<display>` element and counts all `<display>` elements. The public method was renamed from `driverSourceFile(for:)` to `machineXMLInfo(for:)`, returning a `MachineXMLInfo` struct with `sourceFile`, `displayType`, and `displayCount`.

**Populating `displayType`** — `ArtworkFetcher` now calls `machineXMLInfo` and stores the display type. For single-monitor games, `displayType` is set to "raster" or "vector" directly. For multi-monitor games (displayCount > 1), it's set to "multiple". This single field encodes both the monitor technology and the single-vs-multiple distinction.

**Forced aspect ratio on screenshots** — title and in-game images from the Arcade Database are gameplay screenshots captured from the emulated display. Standard arcade monitors are 4:3 (or 3:4 when rotated for vertical games), but the source images aren't always pixel-perfect 4:3 — emulator capture can introduce slight ratio drift. For games with a single raster or vector monitor, we now force the aspect ratio to match the physical monitor: `4:3` for horizontal games, `3:4` for vertical. Games with multiple monitors (which have non-standard display geometries) keep their natural image ratio.

The logic lives in a `shouldForceScreenAspectRatio` computed property on the detail view, and the ratio is passed through to `ZoomableImageView` via a new optional `forcedAspectRatio` parameter so the constraint holds in both the thumbnail and the full-screen viewer.

**Why not force it on all artwork kinds?** Cabinet photos, flyers, and PCB photos have no relationship to the monitor's aspect ratio — they're photographs of physical objects with arbitrary dimensions. Only title and in-game images represent what appears on the CRT.

### 2026-07-19 — In-App Manual Viewer

The legacy app's `HardwareViewController` had a "Manual" button that downloaded a PDF from the Arcade Database, validated it was a real PDF, cached it on the Game entity, and displayed it inline via PDFKit. The new app had a "Manual" link in the external links section that just opened the URL in Safari — useful but clunky, and it re-downloaded every time.

**Ported the full flow:**

1. **URL construction** — added `manualURL(for:)` to `ArcadeDatabaseClient`, which builds the download URL from the ROM set name using the same endpoint as the legacy app (`download_file.php?tipo=mame_current&codice={rom}&entity=manual`). `ArtworkFetcher` now populates `game.manualURL` during the metadata back-fill pass so every game that's been fetched from the API gets the URL.

2. **Download + validate** — the `loadManual()` method in `GameDetailView` downloads the data and checks the first four bytes for the `%PDF` magic header (hex `25 50 44 46`), matching the legacy `checkForRealPDF` logic. The Arcade Database sometimes returns HTML error pages or empty responses for games that don't have manuals — without this check, we'd cache garbage and try to render it as a PDF. If validation fails, `manualURL` is cleared so the row disappears.

3. **Caching** — validated PDF data is stored in `game.manualData` (with `@Attribute(.externalStorage)`), so subsequent taps show the manual instantly without re-downloading. Same pattern as artwork caching.

4. **In-app viewer** — `ManualView` wraps PDFKit's `PDFView` in a `UIViewRepresentable`, presented as a `.sheet`. Single-page continuous scrolling with auto-scaling, matching the legacy `PopOverViewController`'s PDF mode. The sheet gets a "Done" button and the arcade toolbar styling.

The manual row lives in its own section (between Links and Have the PCB), separate from external links — because it's not an external link anymore. Tapping it shows an inline `ProgressView` during download, then presents the sheet.

**Why not eagerly download manuals during artwork fetch?** Manuals are 1–20MB PDFs. Downloading them for every game the user views (or worse, during bulk artwork fetch) would waste bandwidth and storage on content most users will never look at. Lazy download on tap is the right call — same as the legacy app.

**UI test race condition**: the golden-path UI test broke after adding the manual section. The PCB toggle sits below all the metadata/media sections in the detail view's `List`. Before the artwork fetch completes, the view is short and the toggle is in the initial viewport — `findPCBToggle` finds it immediately. But ~0.5s later the fetch completes, inserting history, short play, links, and manual sections above it, pushing the toggle off-screen. SwiftUI `List` de-materializes off-screen cells from the accessibility tree, so accessing `toggle.value` immediately after fails with "No matches found for Descendants matching type Switch."

**Fix**: added `waitForDetailToSettle` — waits for the "Manual" button to appear (the last section inserted by the fetch) before scrolling to find the toggle. This ensures the view's layout is stable and the toggle's final position is known. Also bumped `maxSwipes` from 8 to 12 for the longer post-fetch content.

**Lesson**: when a SwiftUI `List` has async content insertion (via `.task`, `@Query` updates, etc.), UI tests must wait for the insertions to complete before querying elements lower in the list. An element that `.exists` in the pre-insertion layout can vanish from the accessibility tree milliseconds later when new sections push it off-screen. The fix is to wait for a sentinel element that marks "all async content has landed" before interacting with position-sensitive elements below it.

### 2026-07-19 — UI Test: The Tab Bar Was Eating the Tap

Golden-path test broke again after the manual viewer landed. Same test flow — search, tap Donkey Kong, toggle "Have the PCB" on, verify on My Collection, cleanup — but the cleanup tap on the second detail view was silently doing nothing, and eventually `.value` reads on the switch would hard-fail with "No matches found for Descendants matching type Switch." Watching the simulator, the tap wasn't hitting the switch at all — it was landing on the Repair Logs tab button.

Two overlapping bugs:

**Bug 1: the tap coordinate was hitting the tab bar.** On the second detail visit, the game was owned, so `componentStatusSection` and `repairLogSection` were rendering *below* `pcbSection`. `findPCBToggle` scrolled until the switch was `.isHittable` and returned. But the switch element's compound frame extended partway behind the tab bar overlay. `coordinate(withNormalizedOffset: (0.9, 0.5)).tap()` normalizes to the *frame center* — which resolved to a point inside the tab bar's "Repair Logs" button. The tap changed tabs instead of toggling the switch. `.isHittable` is not sufficient: it only checks that the center point is reachable through system UI, not that arbitrary normalized offsets land inside the visible area.

**Fix 1**: `findPCBToggle` now scrolls until BOTH `.isHittable` AND `toggle.frame.maxY <= tabBar.frame.minY`. The switch must be fully above the tab bar, not just centered-clear of it.

**Bug 2: `.value` hard-failed during a `List` re-layout transition.** When we toggle ownership off, `componentStatusSection` and `repairLogSection` disappear from the list. Between the state change and the layout settling, the switch briefly leaves the accessibility tree. `waitForSwitch`'s polling loop kept calling `isSwitchOn` → `toggle.value` → snapshot query failure → hard test failure with "No matches found for Descendants matching type Switch." A poll loop shouldn't crash because the element blinked out of existence for 200ms.

**Fix 2**: `isSwitchOn` now guards `.exists` before reading `.value`. `waitForSwitch` also checks `.exists` before calling `isSwitchOn` — a transient absence during layout re-shuffle is treated as "keep polling", not "fail the test."

**Lesson**: XCUITest's element resolution is a *snapshot* at query time. Any code path that touches `.value`, `.frame`, or other snapshot-dependent properties can hard-fail if the element vanishes between resolution and access — even for one poll tick during a normal SwiftUI re-layout. Poll loops need to treat "element temporarily missing" as retry-worthy, not fatal.

**Lesson**: `isHittable` guarantees the center point is tappable; it says nothing about whether the *rest* of the frame is on-screen. For coordinate-based taps at non-center offsets (which we need for wide-cell controls like `Toggle`), also verify the target region is clear of overlays — tab bar, keyboard, safe area — via explicit `frame` comparisons.

### 2026-07-19 — Summary View Dark Mode Visibility

The Summary tab's color scheme was designed light-mode-first (the legacy app was light-mode only). Two visibility problems in dark mode:

1. **`StatRow` text was invisible.** The collection stats (Total Games, Owned, Wanted, In Repair) used `Color.arcadeRowOdd` — a dark teal (0.098, 0.392, 0.392) — as the text color. This was originally a background color in the game list (with white text on top). Using it as text on the standard dark-mode cell background (near black) produced zero contrast. Fix: removed the hardcoded color; text now uses `.primary` which is dark in light mode and white in dark mode.

2. **Donut chart annotations were unreadable.** The sector label text used hardcoded `.white` (or `.black` for the yellow "Issues" sector). In dark mode, SwiftUI's semantic colors (`.green`, `.red`, `.secondary`) produce brighter fills than in light mode — white text on bright green has a contrast ratio around 2.4:1, well below WCAG AA. Fix: label colors now adapt via `colorScheme` — dark mode uses black text (high contrast on bright fills), light mode uses white (high contrast on darker fills).

3. **Component bar count labels.** The horizontal stacked bars in the component breakdown used `.white` for all count labels. The yellow "Issues" bar has always had poor contrast with white text. Added a `barLabelColor` property to `ComponentStatus` — black for yellow, white for green/red/gray.

### 2026-07-19 — Dark Mode Pass: Game Lists and About View

Extended the dark mode visibility fixes to the remaining views that inherited light-mode-only color assumptions from the legacy app.

**Adaptive view backgrounds.** `arcadeAboutBackground` and `arcadeSummaryBackground` in `Theme.swift` were fixed bright greens. Section header text in dark mode uses light gray by default, and light gray on bright green fails contrast. Made both colors adaptive via `UIColor { traitCollection }` — the existing bright greens stay in light mode, darker greens take over in dark mode. This lets all auto-adaptive text colors (section headers, labels) remain readable without per-view overrides.

**Game list section headers.** Year headers in the All Games tab used `Color.arcadeRowOdd` (dark teal) as the text color — the same "background-as-text" mistake we fixed in `StatRow`. Dark teal text on a dark section header background is invisible. Changed to `.primary`.

**Game row text on fixed backgrounds.** The alternating row colors (sage green and dark teal) are fixed — they're the app's visual identity and don't adapt to color scheme. But the text on sage green rows was using `.primary`, which flips to white in dark mode. White on sage green (0.45, 0.62, 0.50) has a contrast ratio around 3:1 — below the WCAG AA minimum. Fixed by using `.black` / `.black.opacity(0.6)` instead of `.primary` / `.secondary` for even-row text. The dark teal rows already used `.white`, which is correct.

**The principle**: when a background color is fixed (doesn't adapt to color scheme), text on it must also be fixed to whatever provides adequate contrast. Adaptive text colors (`.primary`, `.secondary`) only work correctly on adaptive backgrounds (system cell colors, default list backgrounds). Mixing fixed backgrounds with adaptive text is a contrast bug waiting to happen in whichever mode the background wasn't designed for.

### 2026-07-19 — In-App MAME Driver Source Viewer

The legacy app's Hardware view showed the MAME driver name as a tappable row that opened the raw source file on GitHub in Safari. For the new app, we initially did the same — a `NavigationLink` in `HardwareDetailView` that pushed a `DriverSourceView` showing the C++ source in a bidirectional scrollable view. Two bugs shipped with the first implementation:

**Bug 1: Donkey Kong showed a blank page.** `String(data: data, encoding: .utf8)` returned `nil` for some responses, and the view had no branch for the `sourceText == nil && isLoading == false && errorMessage == nil` state — it just rendered nothing. The nil decode could happen when the server response contained bytes outside the valid UTF-8 range.

**Fix**: added an `.isoLatin1` fallback (`String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)`) and a proper error view for the remaining nil/empty case. ISO Latin 1 never fails — it maps every byte to a character — so it acts as a lossless catch-all for any text the server sends.

**Bug 2: X-Men vs Street Fighter loaded forever.** The driver for X-Men vs SF is `cps2.cpp` — about 14,000 lines of C++ in the MAME source tree. The original implementation used a SwiftUI `Text` view inside a `ScrollView([.horizontal, .vertical])` with `.fixedSize(horizontal: true, vertical: false)`. SwiftUI's `Text` isn't designed for this — it tried to layout the entire 14,000-line string as a single text element, and the type system ground to a halt computing the intrinsic content size. The spinner never stopped.

**Fix**: replaced the SwiftUI `Text` with a `UITextView` wrapped inside a `UIScrollView` via `UIViewRepresentable`. `UITextView` handles large text natively — it's what Terminal.app and every code editor on iOS uses under the hood. Key configuration:

- `textContainer.widthTracksTextView = false` + `textContainer.size = (.greatestFiniteMagnitude, .greatestFiniteMagnitude)` — tells the text container not to wrap at the view's width, enabling true horizontal scrolling. Lines extend as far as they need to.
- `textView.isScrollEnabled = false` — the `UITextView` delegates scrolling to the parent `UIScrollView`, which owns both axes.
- Parent `UIScrollView` sets `contentSize` from `textView.sizeToFit()` after text assignment, providing correct bidirectional scroll bounds.
- Pinch-to-zoom (0.5x–3x) via `UIScrollViewDelegate.viewForZooming(in:)` — useful for scanning wide C++ files or zooming into specific functions.

The result renders 14,000+ lines instantly with smooth bidirectional scrolling and zoom. Monospaced 12pt system font, `.label` text color for automatic dark mode support.

**Lesson**: SwiftUI's `Text` is a layout primitive, not a text rendering engine. For content measured in hundreds of lines, it's fine. For content measured in thousands, `UITextView` (or `UITextView` via `UIViewRepresentable`) is the right tool. The boundary is roughly "if the user might need to scroll for more than a few seconds, use UIKit."

**Lesson**: always handle the nil case from `String(data:encoding:)`. UTF-8 decoding is strict — a single invalid byte rejects the entire input. For display-only use cases where lossy decoding is acceptable, `.isoLatin1` is a safe fallback that never fails.

### 2026-07-23 — New Seed File: Richer Data, Messier Types

Replaced `ScrollingData.json` (4,166 games, 6 fields per row) with a new seed file — `Arcade Collector Value-only Seed ready for JSON July 23 2026.json` (3,855 games, 29 fields per row). The new file carries hardware specs, control details, driver info, genre, and URLs that the old seed didn't have, eliminating the need to fetch much of this data from the API on first artwork pull.

**JSON shape change**: the old file wrapped its array in `{"result": [...]}`, matching a web API response format. The new file is a top-level array — cleaner, no wrapper object. `SeedPayload` (with its `result` property) was replaced by decoding directly as `[SeedRow]`.

**Mixed types bit us twice.** The new JSON was generated from a spreadsheet/database export with inconsistent typing:

1. **`Players`** — integer for most rows (`2`), but string for 49 rows (`"1"`). Likely a formatting artifact from the source data. The `JSONDecoder` threw `typeMismatch` on row 41 (`centiped`), crashing the app at launch.

2. **Missing keys** — `url_playonline` is absent from 3,237 of 3,855 rows. `Players` missing from 392. `chips_audio` from 124. `manufacturer` from 16. Every non-universal field needed `decodeIfPresent` or the decoder threw `keyNotFound`.

**The fix**: a custom `init(from decoder:)` on `SeedRow` that tries `Int` first, falls back to `String` for `Year` and `Players`, and uses `decodeIfPresent` for every field that's missing from any row. Both `year` and `players` are stored as `String` on the `Game` model, so the int-to-string conversion is lossless.

**Sentinel filtering**: the source data uses `"-"` as a sentinel for "no value" in URL fields. Added `raw != "-"` guards before attempting `URL(string:)` construction — without this, every game would get a `shortPlayURL` pointing to the string literal `"-"`, which `URL(string:)` happily accepts as a valid relative URL.

**Fields now populated at seed time** (previously required an API fetch): `genre`, `driver` (MAME source file), `emulationStatus`, `inputControls`, `inputButtons`, `displayType`, `monitorResolutionType`, `resolution` (computed from `display_width` × `display_height`), `verticalRefresh`, `cpus`, `soundDevices`, `shortPlayURL`, `gamePageURL`.

**Lesson**: when consuming JSON from an external source (especially spreadsheet exports), assume every field can be missing and every "numeric" field might arrive as a string. A custom `Decodable` init with try/fallback per field is more resilient than relying on synthesized conformance with exact type matching. The crash-on-launch failure mode (fatal error in the seeder's `.task`) makes this especially punishing — there's no UI to show an error, the app just dies.

### 2026-07-24 — Seed File v3: Screen Count and Aspect Ratio Fix

Upgraded to a third seed file iteration (`Arcade Collector Value-only Seed July 24 2026.json`). Same 3,855 games, but with a new `screens` field (integer: 1–4) and three removed fields (`description`, `has_disks`, `url_playonline`).

**The multi-screen regression.** The July 23 seed populated `displayType` with `"RASTER"` for every game at seed time. The `ArtworkFetcher` had previously been the only place that detected multi-screen games — it fetched the MAME XML, counted `<display>` elements, and set `displayType = "multiple"` for games with more than one screen. But the fetcher's guard was `if game.displayType.isEmpty`, so once the seed filled it with `"RASTER"`, the XML fetch was skipped and multi-screen games like The Ninja Warriors (3 screens) got a forced 4:3 aspect ratio on their screenshots.

**Two-part fix:**

1. **Seed-time detection** — the new `screens` field lets the seeder set `displayType = "multiple"` at insert time for any game with `screens > 1`. No XML fetch needed.

2. **ArtworkFetcher still overrides** — removed the `game.displayType.isEmpty` guard so the XML fetch always runs during artwork pull. If the XML reports multiple displays, `displayType` is overwritten to `"multiple"` regardless of what the seed set. Belt and suspenders: the seed handles the common case, the fetcher catches anything the seed missed.

**Aspect ratio rule simplified** — `shouldForceScreenAspectRatio` was checking for `type == "raster" || type == "vector"`. Changed to `!type.isEmpty && type != "multiple"` (case-insensitive). This means: force 4:3 for any single-screen game, regardless of whether it's raster or vector. The only games that should keep their natural image aspect ratio are multi-screen games with non-standard display geometries.

**Lesson**: when you add a new data source that populates a field the existing code treated as "empty until enriched," audit every `isEmpty` guard downstream. The seed-then-enrich pattern creates an implicit contract: "this field starts empty and gets filled later." Populating it earlier breaks every conditional that relied on emptiness as a signal for "hasn't been processed yet."

### 2026-07-24 — Genre and Players Filters

Added two new filter options to the game list toolbar menu: **Genre** and **Players**.

**Genre** — 16 values from the seed data (Shooter, Sports, Fighter, Platform, Puzzle, Driving, Maze, etc.). Straightforward: `genre: String?` on `GameListFilter`, a `Picker` in the menu populated from a `@Query`-derived `availableGenres` computed property. Same pattern as the existing Ownership and Orientation filters.

**Players** — uses the `nplayers` field from the seed data (e.g., "2P sim", "4P alt", "2P alt / 4P sim"). Added `nplayers: String` to the `Game` model. The seeder populates it from the JSON `nplayers` key, falling back to `Players` with a "P" suffix (e.g., "2" → "2P") when `nplayers` is empty or `"???"`. This gives every game a human-readable player-count label suitable for both display and filtering.

Also removed the **Year** sort option from `GameSort` — the All Games tab is already sectioned by year, making a year sort redundant.

**Design note on filter architecture**: all filters follow the same split architecture described in the `GameListFilter` doc comment — text search goes into the `@Query` predicate (SwiftData/SQLite), while enum/string filters run in-memory via `matchesEnumFilters`. This is because SwiftData's `#Predicate` macro still can't handle custom enum KeyPaths or arbitrary string equality on non-indexed fields without runtime crashes. The in-memory pass is fine for the dataset size (3,855 games) — filtering completes in under a millisecond.

### 2026-07-27 — About View Data Sources Readability

The "Data Sources" section in `AboutView` was hard to read — seven rows crammed into a grouped list with tiny 60pt banners and link-tinted text that washed out the descriptions.

**Card-style rows** — `DataSourceRow` got a visual overhaul. Banner images doubled from 60pt to 120pt max height and stretch full-width, giving each data source enough visual weight to be scannable. Text below uses explicit `.primary` / `.secondary` foreground styles instead of inheriting the `Link` tint, so names and descriptions are readable without fighting the blue. A subtle `arrow.up.right` icon on the trailing edge signals tappability without relying on tinted text.

**Wrapping descriptions** — several data sources got longer descriptions with proper attributions and copyright notices (MAME trademark, Gaming-History copyright, NPlayers copyright). Added `.fixedSize(horizontal: false, vertical: true)` to the description `Text` so longer strings wrap to multiple lines instead of truncating.

### 2026-07-27 — Monitor Type in Hardware View

Added a "Monitor Type" row to the Display section of `HardwareDetailView`, visible only when `displayType` is "raster" and `monitorResolutionType` is non-empty. The value comes straight from the seed data's `monitor_type` field (populated in the July 24 seed with values like "CRT 15kHz", "CRT 31kHz", "CRT 25kHz") via `game.monitorResolutionType`. Initially tried computing it from horizontal refresh thresholds (matching the legacy `getMonitorResolutionType()` logic), but the seed data already has clean labels — no need to recompute what's already there.

### 2026-07-27 — Code Review Pass: Query Cost, Test Debt, Seeder Cleanup

Ran a self-review over the recent seed-overhaul work and picked off the highest-leverage items. Five things worth doing turned up; four were done in-place, one was flagged for later.

**Killed a whole-table `@Query` used only for picker options.** `GameListTab` had `@Query(sort: \Game.genre) private var allGames: [Game]` fetching all 3,855 fully-materialized `Game` rows per tab instance, just so `availableGenres` and `availableNplayers` could call `Array(Set(map)).sorted()` on every body invalidation. Two full-table observations were running per screen (one here, one in `GameListView`). Replaced with a one-shot `FetchDescriptor(propertiesToFetch: [\.genre, \.nplayers])` fired via `.task` and guarded by an `availableGenres.isEmpty` check — reads two columns instead of 29, runs once per view lifetime, and skips the continuous-observation overhead. Reactivity cost: if the artwork fetcher back-fills a genre for a previously-empty game while the tab is open, the picker won't refresh. In practice this never happens (the July 24 seed populates genre for every row), and the tradeoff is documented in the helper's doc comment.

**Wrote fixture tests for the fragile transformations that caused real regressions.** The `SeedRow` decoder had inline logic for mixed Int/String types (the `centiped` crash), missing keys (thousands of rows), the `"-"` URL sentinel, the `"???"` nplayers placeholder, and the `screens > 1 → "multiple"` rewrite (the Ninja Warriors regression) — all untested. Added a `GameSeederEdgeCaseTests` suite with nine focused tests, each with a minimal inline JSON fixture wrapped through a `wrapRow(_:)` helper. Tests hit `GameSeeder.seed(from:)` because `SeedRow` is `private` — but that's the right level anyway, since the transformations these tests care about live in the seeder, not just the DTO. Suite count 30 → 39.

**Split `GameSeeder.seed(from:)` into a linear top-level plus five named helpers.** The per-row block had grown to ~40 lines of `game.field = row.field ?? ""` interleaved with three sentinel-style guards inline — a mix of pass-through assignments and consequential decisions with no way to tell them apart at a glance. Extracted `makeGame(from:)`, `nplayersLabel(from:)`, `displayType(from:)`, `chipList(from:)`, and `sanitizedURL(from:)` as pure `private static` functions on the actor. Each one is short enough to fit on screen, has a doc comment citing *why* it exists (which specific regression it prevents), and the `seed(from:)` body shrinks to fetch-guard → decode → loop-insert → save. Behavior unchanged; all 12 seeder tests still green. Also lifted `"???"` and `"-"` into named `unknownNplayers` / `noValueSentinel` constants at the top of the block — future URL fields with the same sentinel can reuse the second one.

**Documented why `.year` isn't in `GameSort`.** Removed in an earlier commit, but no code comment explained why. Three-line doc comment now sits above `enum GameSort` at `GameListFilter.swift:53-58` — "already section-grouped by year with a scrubber, so a year sort would just reorder within-section without adding navigability." Future readers spot the intentional absence without a `git blame` archaeology run.

**Renamed the seed file to something stable.** The bundled JSON was named `Arcade Collector Value-only Seed July 24 2026.json` — a literal date embedded in the filename. Every seed refresh required editing the filename constant in `GameSeeder`, the resource-lookup string in `ArcadeCollectorTests`, and re-adding the file to Xcode. Renamed via `git mv` to `seed.json`. Version/date info lives in git history and this journal — the filename no longer needs to carry it. Also removed an orphaned `Resources/ScrollingData.json` — a copy of the old 4,166-game seed left behind from before the July 23 switch, with zero references in the new-app target.

**Skipped intentionally**: consolidating the two `GameListTab`-per-instance `.task` fetches into a single app-level cache. Would drop total per-launch cost from 4 × (2-column fetch) to 1 × — but the current cost is milliseconds against 3,855 rows, and a shared cache introduces a new sync problem (when does it invalidate?). Not worth the complexity yet.

**Lesson**: `@Query` is the right tool when the view *needs* to observe changes over time. When you only need a snapshot at appearance to populate static UI (filter dropdowns, picker options), a one-shot `FetchDescriptor` with `propertiesToFetch` is dramatically cheaper — you skip the observation overhead entirely and read only the columns you need.

**Lesson**: for data-ingest code (seeders, decoders, importers), the test-writing bar is *lower* than for regular business logic, not higher. Every "custom `Decodable` init" and "sentinel value handling" line is a footgun that will silently regress the day someone touches it. The `centiped` crash cost hours to diagnose; a 15-line inline-fixture test would have caught it before submit.

**Lesson**: filenames are interfaces. When a filename encodes state (a date, a version, a hash), every consumer of that filename becomes coupled to the version. Stable names + versioning inside the file (or in git history) is nearly always the right factoring.

### 2026-07-29 — Reset Fetch Artwork Button on Ownership Change

The "Fetch All Missing Artwork" button in `SummaryView` would stick in its completed state ("All artwork fetched" / "All owned games have artwork") until the app was relaunched. If a user toggled a new game to "owned" via the PCB toggle, they had to restart the app to see the fetch button again.

**Fix** — added `.onChange(of: ownedGames.count)` to the `NavigationStack`. When the owned count changes and a bulk fetch isn't in progress, it checks whether any owned game is still missing artwork (comparing stored `ArtworkKind`s against the full set of six). If so, it resets `bulkProgress` and `nothingToFetch`, which returns the button to its actionable "Fetch All Missing Artwork" state. The artwork-kind set is shared as a view-level constant (`allArtworkKinds`) to stay consistent with `BulkArtworkFetcher`'s own check.

### 2026-07-29 — Swift 6 Isolation Warning in XML Parser

A pre-submission audit turned up a lingering warning: `main actor-isolated static method 'parse(data:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode` in `ArcadeDatabaseClient.swift`. Left unfixed, it would become a hard build error the moment the project flips to Swift 6.

**Why it fired.** `MachineXMLParser` inherits from `NSObject` and conforms to `XMLParserDelegate`. Under Swift 6 language mode, `NSObject`-derived classes are inferred as `@MainActor`-isolated by default (a compatibility default for legacy Cocoa classes). That isolation propagates to the class's static methods too — so `MachineXMLParser.parse(data:)` was implicitly main-actor. Meanwhile `ArcadeDatabaseClient` is declared `nonisolated` (it's a stateless Sendable wrapper), so calling the parser from `machineXMLInfo(for:)` was a cross-actor hop the compiler flagged.

**Fix** — one keyword. Declared the parser `nonisolated` at the class level:

```swift
private nonisolated final class MachineXMLParser: NSObject, XMLParserDelegate {
```

The parser does zero UI work, holds no main-actor state, and its output is a `Sendable` struct — it has no business being on the main actor.

**Lesson**: `NSObject`-derived classes in the Swift 6 world need explicit `nonisolated` (or an explicit actor annotation) whenever they're going to be called from off-main-actor contexts. The main-actor default is a footgun that will bite silently: your code works today under Swift 5 mode, but the same file becomes uncompilable the day you enable Swift 6. Audit any bridging class (delegates, parsers, coders) that inherits from `NSObject` and gets called from `async` code that isn't `@MainActor`.

### 2026-07-29 — Being a Good Neighbor to the Arcade Database

The Arcade Database (`adb.arcadeitalia.net`) is a community-run resource, not a CDN with infinite capacity. Before submitting the app to the store, added two small courtesies so that a user with a 200-game collection doesn't accidentally DDoS the site.

**User-Agent header on every request.** The default `URLSession.shared` sends a generic `CFNetwork/...` user-agent — indistinguishable from any other iOS app. If the ADB admins ever see a traffic spike from our app, they have no way to identify it or reach us. Fixed by giving `ArcadeDatabaseClient` a dedicated session with `httpAdditionalHeaders = ["User-Agent": "ArcadeCollector/<version> (iOS)"]`, sourced from `CFBundleShortVersionString` so the value tracks the current release automatically. Tests pass their own `URLSession` (via `FixtureURLProtocol`) and are unaffected.

**Between-games courtesy delay.** `BulkArtworkFetcher` was hammering ADB in tight sequential loops — a game with 6 missing artwork kinds fires 6 image downloads back-to-back, then immediately moves to the next game. For a 50-owned-games bulk fetch, that's ~300 requests over a few minutes. Added `try await Task.sleep(for: .milliseconds(250))` between games (skipped after the last). Costs the user 12.5 seconds on a 50-game pass in exchange for giving ADB's server breathing room. The sleep is cancellation-aware, so hitting Cancel still terminates promptly.

**Why between-games and not between-requests?** A single game already fires 6 sequential downloads inside `ArtworkFetcher.fetch`, but that's a bounded burst — the polite thing is to space out the *bursts*, not to stretch each burst by a factor of six. Between-games gives ADB idle time to serve other users between rounds; between-requests would just make our user wait longer without meaningfully changing our impact.

**Lesson**: when your app depends on a third-party service that's a labor of love rather than a business, "polite by default" is a moral and pragmatic obligation. Identify yourself in the User-Agent, throttle bursts, and stagger long-running operations. The cost to you (a few seconds of latency) is trivial; the cost to them of being flooded is real.

### 2026-07-29 — More Swift 6 Actor Isolation: GameListFilter

While cleaning up before submission, `searchFiltersByTitleCaseInsensitively()` and its sibling tests in `GameListFilterTests` were emitting a cluster of Swift 6 warnings:

```
main actor-isolated initializer 'init()' cannot be called from outside of the actor
main actor-isolated property 'search' can not be mutated from a nonisolated context
main actor-isolated property 'searchPredicate' can not be referenced from a nonisolated context
```

**Root cause.** SwiftData's `@Model` macro (applied to `Game`) infers the class as `@MainActor`-isolated under Swift 6. `GameListFilter.searchPredicate` uses `#Predicate<Game>`, which references the main-actor type. That single reference is enough to pull the *whole* `GameListFilter` struct's inferred isolation to `@MainActor` — including the memberwise `init()` and every stored property setter, even ones as innocent as `search: String`.

Once the struct is main-actor, calling `GameListFilter()` from a nonisolated test (Swift Testing test functions default to nonisolated) crosses actor boundaries — hence the warnings.

**Fix.** Explicitly mark `GameListFilter` and its sibling enum `GameListMode` as `nonisolated`:

```swift
nonisolated enum GameListMode: Hashable { ... }
nonisolated struct GameListFilter: Equatable { ... }
```

Both are plain value types with no legitimate main-actor dependency. The `#Predicate<Game>` inside `searchPredicate` compiles fine from a nonisolated context — SwiftData's macro-generated code handles the isolation correctly, it just needs a hint from us that we're not opting into main-actor for the whole struct. `GameListMode` needed the same treatment because its Equatable conformance was being pulled into main-actor isolation for the same file-level reason, and `GameListFilter` compares `mode != .allGames`.

**Lesson**: Swift 6's isolation inference is aggressive and viral. One `#Predicate<@ModelType>` reference in a computed property can silently isolate the enclosing struct, which then isolates every method the struct exposes, which then breaks every nonisolated caller. When you see a chain of "cannot be called from outside the actor" warnings on trivial members (plain `String` setters, memberwise `init`), don't fix them one at a time — declare the enclosing type `nonisolated` at the source and cut the whole chain in one stroke.

### 2026-07-29 — Accessibility Pass

Pre-submission audit for VoiceOver, Reduce Motion, and combined element semantics. Grep-first discovery: only 11 accessibility annotations across the whole new-app target, concentrated in three files. Most custom controls had *nothing*.

**ZoomableImageView.** Three `withAnimation(.easeOut/.easeInOut)` calls (pinch-to-zoom settle, snap-back, and double-tap toggle) are now gated on `@Environment(\.accessibilityReduceMotion)` — `withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2))` cleanly disables the transitions when the user has Reduce Motion on. Also added `.accessibilityLabel(title)` + `.accessibilityAddTraits(.isImage)` + `.accessibilityHint("Double-tap to zoom. Pinch to scale.")` so VoiceOver users know they've landed on something interactive rather than a generic image.

**SummaryView donut chart.** The Charts-generated `Chart` was completely opaque to VoiceOver — a rotating sector graph with visual annotations but no textual equivalent. Added `.accessibilityLabel("Game condition breakdown")` on the whole chart and a computed `.accessibilityValue` that reads "Working 3, Issues 1, Broken 1, Untested 0" (derived from the same `gamesByCondition` array the chart itself uses, so the label and the visual stay in sync automatically). Chart-legend rows are now combined elements labeled "Working: 3" rather than the default "circle, Working" split reading.

**SummaryView ComponentStatRow.** The horizontal colored bar with per-status counts was pure visual — VoiceOver would announce each colored rectangle individually. Wrapped it with `.accessibilityElement(children: .ignore)` and gave the row a proper label ("Boot") + accessibility value that composes the non-zero counts ("Working 3, Issues 1, Untested 2"). Same trick as the chart: one shared source of truth for the visual and the announcement.

**AboutView.** The decorative `arcade.stick.console` app icon is now `.accessibilityHidden(true)` — screen-reader users get "Arcade Collector, Version X, by Matt Goodhart" without the redundant icon announcement. Each `DataSourceRow` is now a single accessible element ("Arcade Database. The primary source…" with hint "Opens website") instead of VoiceOver navigating banner → name → description → arrow separately. Banner image and trailing `arrow.up.right` glyph are hidden as decorative.

**RepairLogEntryView.** Photo thumbnails were bare buttons — VoiceOver announced "button, button, button" with no way to distinguish photos or discover the context-menu delete. Now announces "Photo N of M" with hint "Double-tap to view. Touch and hold for delete option." Also refactored the `ForEach` to enumerate so the index label stays accurate as photos are added/removed.

**Intentionally not touched.**
- `SectionIndexOverlay` in `GameListView` — already `.accessibilityHidden(true)`, and its size-9 non-scaling font is intentional (it's a spatial scrubber, not readable text; enlarging would break the compact overlay layout).
- `HardwareDetailView` — uses `LabeledContent` and `NavigationLink` throughout, both fully accessible by default.
- `GameRow` — the parent `.accessibilityElement(children: .combine)` produces an acceptable-if-imperfect combined reading. Deferring an explicit label until real-device VoiceOver testing shows a specific problem.

**Lesson**: for accessibility work, grep is the fastest audit. `.accessibilityLabel` / `.accessibilityHint` / `.accessibilityValue` / `.animation(` / `.font(.system(size:` — five searches across the codebase gave a complete picture of what needed attention in under a minute. Custom controls without any of the first three are almost always bugs.

**Lesson**: when a visual control encodes information (colored bars, donut sectors, badges, dots), the accessibility label/value should be derived from the *same data source* as the visual, in the same view — not duplicated with hand-rolled strings. Otherwise you get drift: the chart says "3 working games" and VoiceOver says "2 working games" a month later because someone edited one and not the other.

### 2026-07-29 — Bulk Fetch: Report Partial Failures

The bulk artwork fetcher was returning `Int` — the number of games attempted — and silently swallowing per-game failures inside a `catch { }`. If ADB went down mid-run, the UI showed "All artwork fetched" for a run where zero games actually succeeded, because the *attempt count* equaled the *total count* and the successes were never distinguished from the failures.

**Return-type refactor.** `BulkArtworkFetcher.fetchAllMissing` now returns a `Result` struct with `attempted` and `succeeded` counts (and a derived `failed` property). The internal loop now increments `succeeded += 1` on a successful `try await fetcher.fetch(...)` call and leaves it alone on `catch`. Cancellations still rethrow to distinguish user intent from network failure.

**Three completion states in the UI**, rendered by a `bulkResultRow(_:)` `@ViewBuilder`:

- **Fully succeeded** → green ✓ "Fetched artwork for N game(s)"
- **Partial failure** → orange ⚠ "Fetched N of M. K failed." + **Retry** button
- **Complete failure** (zero succeeded) → orange ⚠ "Couldn't fetch artwork. Check your connection and try again." + **Retry** button

The retry button is safe to press repeatedly because `ArtworkFetcher.fetch(for:)` already skips artwork kinds that exist, so a retry only re-attempts what's still actually missing. That's a nice property that fell out of the earlier "existingKinds" deduplication — a small design decision from months ago paying dividends now.

Also cleared `bulkResult` in the `onChange(of: ownedGames.count)` handler so newly-owned games force the section back to its actionable "Fetch All Missing Artwork" state instead of leaving a stale success/failure message glued to the screen.

**Lesson**: silent per-item failures are a lie by omission. When a background operation iterates over N things and some fail, the caller has a right to know the split — and the UI has a right to render a "we did what we could, but here's what didn't work" state. Wrapping the loop's outcome in a small `Result`-shaped struct (attempted/succeeded/failed) beats returning a single opaque count. Same principle as HTTP batch APIs returning per-item statuses rather than a single "OK" for the whole call.

### 2026-07-29 — Backup Collection: JSON + Photos Zip Export

Users who invest time in repair logs (photos, dates, notes across 20+ games) need a way out of the app. Added a Backup feature reachable from About → "Your Data" → Backup Collection.

**What's in the backup** — user-authored only:
- `Game.ownership`, the five component statuses, and the game's `romSetName` + `title` (title is a nicety for humans reading the JSON — the identity is `romSetName`).
- Every `RepairLog` with its date, notes, and photos.

**What's out** — ADB-derived data (game metadata, artwork, hardware specs). Those are re-fetchable by design, and including them would balloon a typical backup from tens of KB to hundreds of MB. Users can trigger the bulk artwork refetch after restore.

**Filter** — only games with *modified* state are included (any non-`.none` ownership, any non-`.untested` component, or any repair log). A default game in a 3,855-entry seed is worthless to serialize.

**Archive format:**
```
ArcadeCollector-Backup-2026-07-29-153042.zip
├── backup.json          (manifest with games + repair-log entries)
└── photos/
    ├── <uuid>.jpg
    └── ...
```
Photos are referenced from the manifest by filename to avoid base64 bloat. `UUID` filenames dodge collisions across repair logs.

**Zipping without a dependency** — iOS Foundation has no `zip()`. Trick: `NSFileCoordinator.coordinate(readingItemAt: sourceDir, options: [.forUploading])` synchronously delivers a zip archive of the source directory into a coordinator-managed temp location. We copy that out to a stable named path (`ArcadeCollector-Backup-<timestamp>.zip`) and hand the URL to `ShareLink`. No SPM dependency, no bridging headers, no third-party zip library.

**Actor isolation** — `BackupExporter` is a `@ModelActor` because it fetches games via `FetchDescriptor`. The private `zip(directory:)` helper is `nonisolated static` — file I/O and `NSFileCoordinator` don't need model-actor context. Same for the `filenameDateFormatter`. Keeping these off the actor sidesteps a needless hop and makes the zip step pure.

**UI states in `BackupView`**:
- Idle — "Create Backup" button.
- In progress — `ProgressView` + "Preparing backup…".
- Success — a summary row ("N games, M repair logs, K photos"), a `ShareLink` to hand the file off to Files / AirDrop / Mail / Messages, and a "Create Another Backup" button.
- Error — inline red label + "Try Again".

**Import is v1.1.** Round-trip restore needs conflict resolution (what if the target device already has repair logs on the same game? Merge? Overwrite? Skip?) which is a real design problem worth deliberating rather than shipping half-baked. Export alone still delivers the core value: users can safely reinstall / migrate devices without losing their work, even if manual re-entry is the interim recovery path.

**Lesson**: for a "get my data out" feature in a small utility app, the killer feature is *not* fidelity — it's the ability to hand off the file. `ShareLink` on a self-contained zip means the user's backup instantly reaches every destination iOS knows about (iCloud Drive, email, Slack, Dropbox, Files.app to a USB drive, etc.) without us writing a single line of destination-specific code. Design your export format so the sharing surface is a single file, not a directory.

**Lesson**: `NSFileCoordinator`'s `.forUploading` option is one of those quiet Apple APIs that solves a real problem (zip a directory) without documentation making it obvious. Worth knowing about. It's what iCloud Drive and the share sheet use internally when they present a folder as a single item for upload.

### 2026-07-29 — Seeder Failure Now Has a User-Facing Story

`ArcadeCollectorApp.body` had `assertionFailure("Seeding failed: \(error)")` as its only response to a first-launch seed error. That's fine in debug builds — the app halts and the developer sees the error — but in a Release build `assertionFailure` is a no-op, so a real user with a corrupt bundle or exhausted disk would launch the app, see an *empty* game list, and have no idea what happened.

**Fix.** Introduced a private `RootView` wrapper that owns `@State private var seedFailure: String?` (App types can't hold `@State`, so a small child view is the standard workaround). The seeder task now writes into that state instead of assertion-failing:

```swift
.task {
    do {
        try await GameSeeder(modelContainer: container).seedIfNeeded()
    } catch {
        seedFailure = error.localizedDescription
    }
}
```

When `seedFailure` is set, the whole `ContentView` tree is replaced with a new `ContentView.seedFailureView(message:)` — a `ContentUnavailableView` titled "Couldn't Load Game Database" with description "Try quitting and reopening the app. If the problem persists, please reinstall." The underlying error string is shown in tertiary caption text below the description so a support conversation can capture the actual cause instead of "it didn't work."

**Why not a retry button?** The seed is a one-shot idempotent operation on launch. If the user reopens the app, the seeder runs again automatically. A retry button would just add UI noise for a code path that's already exercised by the "quit and reopen" instruction — and the failure modes (missing bundle resource, corrupt JSON, disk full, keychain lockout) are essentially all resolved by a fresh launch or a reinstall. Better to keep the error state passive and let the user's normal recovery flow do the work.

**Why not merge with `databaseErrorView`?** Both errors are container-related but distinct root causes. Container-init failure ("Unable to Load Database") almost always means the SwiftData schema is incompatible with the on-disk store — usually a downgrade from a newer app version, or a corrupted store file. Seed failure ("Couldn't Load Game Database") means the bundled JSON is missing or malformed, or a save transaction bombed. Distinct messages give a user (or a support engineer helping a user) a real signal about which layer to investigate.

**Lesson**: `assertionFailure` is the right tool for "this can't happen without a code bug." It is *not* the right tool for "this might rarely happen if the bundle is corrupt or the disk is full." The distinction is: does a Release-build user need to see this? If yes, `assertionFailure` is worse than nothing because it silently swallows in production. Every use of `assertionFailure` in an app should get a one-line audit: is this a "developer, wake up" signal, or a "shipping user needs feedback" signal?

### 2026-07-29 — Persistence Roundtrip Test as Migration Safety Net

The 2026-07-09 "History" field crash — `fatalError` in `ModelContainer.init` because a new non-optional `String` property had no inline default — was the single most expensive SwiftData bug this project has hit. It only reproduces on a *second* app launch (an existing store meets a new schema), so every existing test (which uses `isStoredInMemoryOnly: true`) is blind to it.

**Fix, structurally**: added `PersistenceMigrationTests` — a Swift Testing suite that runs the actual migration path a user hits on every relaunch, backed by an on-disk store in a temp directory.

**Test shape:**

```swift
// Launch 1 — write
do {
    let container = try ModelContainer(for: schema,
        configurations: ModelConfiguration(schema: schema, url: storeURL))
    // insert Game with ownership, statuses, RepairLog, RepairLogPhoto
    try context.save()
} // container falls out of scope

// Launch 2 — read
let container2 = try ModelContainer(for: schema,
    configurations: ModelConfiguration(schema: schema, url: storeURL))
// fetch and assert every user-authored field survived
```

Two tests: `userDataSurvivesContainerRestart` covers the "populated store round-trips" case, `emptyStoreOpensCleanlyAfterRestart` covers the empty-store variant (because a broken schema will fail even without data). Both run in <150ms so they're cheap to keep in the default suite.

**Cleanup detail**: SwiftData writes SQLite `-shm` and `-wal` sidecar files next to the main store file. The teardown `defer` block removes all three so temp directories don't accumulate leftover state across test runs.

**Manual rehearsal checklist (before shipping v1.0):**

1. Delete the app from the simulator / device to guarantee a clean install.
2. Fresh install the current build.
3. Wait for the seeder to complete (~1 sec for 3,855 rows).
4. Toggle several games to `.owned`, set a few component statuses, add 2–3 repair logs with photos.
5. Force-quit.
6. Relaunch and verify all the state is still there. (This is what the automated test now covers, but doing it once on a device confirms it in reality.)
7. **The real rehearsal**: add a new stored property to one of the `@Model` classes *with an inline default* (`var newField: String = ""` or similar). Rebuild and relaunch. Confirm the store migrates without a `fatalError`.
8. Bonus: temporarily *drop* the inline default to see what the failure looks like — it should be caught in dev, never in Release.

**Safety rule**: any new non-optional stored property added to a `@Model` class MUST have an inline default value. Enforcement is by review + this test suite. If the automated roundtrip breaks after a model change, the fix is to add an inline default to the new property, not to disable the test.

**Lesson**: in-memory tests validate logic; on-disk tests validate persistence contracts. Every SwiftData app should have at least one on-disk roundtrip test in CI, even if it feels redundant with the in-memory suite — the failure mode it catches (schema migration bug) is not exercised by any other kind of test, and it's the one that ships broken apps.

**Lesson**: don't couple test lifetimes to test-file lifetimes when working with temp directories. `defer { try? FileManager.default.removeItem(at: url) }` is nice; make sure you also nuke the `-shm` and `-wal` sidecars SQLite creates. Otherwise flaky failures pile up as prior-run detritus gets in the way of subsequent runs.

### 2026-07-29 — Reuse Pass: Kill the Three Duplications

Three-agent parallel review across this session's 9 commits turned up three real duplications worth acting on. The quality and efficiency reviews came back clean — the useful signal was concentrated in the reuse review.

**Duplication 1: schema construction** was in three places — `ArcadeCollectorApp.init`, `PreviewSupport.container`, and `PersistenceMigrationTests.schema()` — each spelled out `Schema([Game.self, GameArtwork.self, RepairLog.self, RepairLogPhoto.self, GameCollection.self])`. Adding a new `@Model` currently required three coordinated edits, which is exactly the kind of chore that gets skipped and then discovered later when tests inexplicably fail to see a new entity type.

Fixed with a new `Support/AppSchema.swift`:

```swift
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Game.self, GameArtwork.self, RepairLog.self, RepairLogPhoto.self, GameCollection.self,
    ]
    static var schema: Schema { Schema(models) }
}
```

All three call sites now say `AppSchema.schema`. Adding a new model is a one-file change.

**Duplication 2: the artwork-kinds set** — `Set<ArtworkKind> = [.cabinet, .flyer, .inGame, .marquee, .title, .pcb]` was hand-rolled in both `BulkArtworkFetcher` and `SummaryView`. Not a huge win, but easy to make right by adding a `static let bulkFetchable` on `ArtworkKind` itself. Discoverable from the enum's namespace, deliberately excludes `.userPCB` (user-supplied only), and both call sites now share the same reality — if we ever add a seventh downloadable kind, we edit one line.

**Duplication 3: `CFBundleShortVersionString` fetch** appeared in three subsystems (`ArcadeDatabaseClient.defaultSession`, `BackupExporter.export`, and `AboutView.appSection`), two using `object(forInfoDictionaryKey:)` and the third using `infoDictionary?[...]`. Both are the same key, both need the same "1.0" fallback. Extracted to a `Bundle.appVersion` extension property.

**Swift 6 tax: two more `nonisolated` markers.** Both `Bundle.appVersion` and `ArtworkKind.bulkFetchable` initially built with warnings that they were `@MainActor`-isolated when called from `BackupExporter` and `BulkArtworkFetcher` (both `@ModelActor` types). `Bundle.main` is main-actor-inferred under Swift 6; static enum properties on types referenced elsewhere in the codebase also seem to inherit isolation from context. Explicit `nonisolated` at the declaration site fixes it and is documented at the declaration ("so background actors can read this without hopping to the main actor").

**Skipped intentionally**:
- Merging `ContentView.databaseErrorView` with `seedFailureView` into a shared fatal-startup-error helper. Only two call sites, and the seed variant adds structure (a `VStack` wrapping the `ContentUnavailableView` to surface the underlying error message). Extract on the third occurrence.
- Changing `bulkFetchError: String?` and `errorMessage: String?` to typed `Error?` in the two views. They're only consumed for display via `.localizedDescription`; the type erasure is deliberate.
- Rewriting the backup manifest to encode enums as strings/ints via a custom `Codable` conformance. `OwnershipStatus` and `ComponentStatus` are already raw-value-backed (`String` and `Int`), so their default synthesized encoding is stable. The `manifestVersion: 1` field is the versioning hook if any of that changes.
- Optional streaming-zip in `BackupExporter` (skip re-reading everything through NSFileCoordinator). Optimization has no meaningful impact at the app's expected backup sizes (< 100 MB); revisit if a real user reports it.

**Flake note**: the first post-refactor test run failed with `Failed to create a bundle instance representing ...ArcadeCollectorTests.xctest` — a simulator install race, not a real regression. Zero test-case failures in that log; xcodebuild bailed during setup. Re-running against the same code passed cleanly, 35/0. Documenting because the exit-65 was scary in the moment; the discipline was "read the log, don't just retry blindly."

**Lesson**: static let constants that reference an enum's own cases and don't touch main-actor state should still be marked `nonisolated` under Swift 6 if they'll be read from any non-`@MainActor` async context. The compiler can't always figure out that "this is just a set of enum cases" is nonisolated by nature — it has to be told.

**Lesson**: three duplication sites is the threshold where an abstraction pays for itself. Two sites can be "same value, different files, that's fine." Three sites is a maintenance liability: adding a new value requires editing three places, forgetting one gets discovered days later, and the fix is *always* larger than just extracting the abstraction would have been. Extract on the second occurrence when the pattern is obvious; latest by the third.

### 2026-08-12 — Attributions Section: Making the Permission Claim Explicit

Pre-submission thinking about App Review guideline 5.2 (Intellectual Property). The Arcade Database's owner and maintainer, motoschifo, has given explicit written permission to use ADB in this app — but that permission only covers what motoschifo actually owns (the ADB dataset and site). It does **not** cover the underlying arcade titles, marquees, cabinet art, flyers, or screenshots, which belong to the original rights holders (Capcom, Bandai Namco, Nintendo, Sega, et al.). A reviewer scanning the About screen for the "we know what's ours vs. someone else's" signal shouldn't have to squint at the existing Disclaimer + Acknowledgments prose to find it.

**The addition.** A dedicated `attributionsSection` in `AboutView`, positioned between Disclaimer and Data Sources, that says three things plainly:

1. Game metadata and reference imagery come from ADB, used with motoschifo's express written permission.
2. All arcade game titles, logos, marquees, cabinet art, flyers, and screenshots are trademarks and copyrights of their respective owners; their inclusion here is for informational/collection-tracking purposes only and implies no endorsement or affiliation.
3. MAME® is a registered trademark of Gregory Ember.

Point 3 was already tucked inside the MAME `DataSourceRow` description, but repeating it at the top-level "Attributions" surface is the standard trademark-recognition pattern reviewers (and lawyers) expect to see.

**Why not just edit the existing Disclaimer?** The Disclaimer speaks in the language of *user assumptions* ("this app is not an emulator, not a ROM source, uses names under fair use"). Attributions speaks in the language of *legal provenance* ("here's who gave us permission, here's what we don't own"). Same neighborhood, different jobs — reviewers know to look for both and having them side-by-side is easier to skim than a single 400-word wall.

**What this doesn't fix.** The IP exposure surface is proportional to how much artwork we redistribute. If a rights holder decides tomorrow that even fair-use display of a marquee bothers them, an Attributions section doesn't stop the takedown notice — it just makes clear we weren't claiming ownership. The higher-leverage risk mitigations are (a) fetch artwork on demand rather than bundling it, and (b) prefer user-supplied photos over auto-populated ADB assets where the UX allows it. Both are v1.x considerations, not blockers for the initial submission.

**Lesson**: App Review guidelines aren't checkboxes you satisfy once — they're patterns a reviewer scans for in 30 seconds. Named sections ("Attributions", "Disclaimer", "Data Sources") beat prose paragraphs because they signal *you already thought about this*. Same logic as writing PR descriptions with headers instead of paragraph mush: the reader is skimming, help them.

**Lesson**: written permission from a data aggregator is necessary but not sufficient. The aggregator can grant you what they own; they can't grant you what upstream rights holders own. If your app touches trademark-heavy vertical content (video games, film, sports, music), the trademark-recognition boilerplate in the About screen is table stakes even when you have written permission from your primary data source.

### 2026-08-14 — Repair Log Tab Direct Navigation & Entry View Performance

Two changes to the repair log experience.

**Repair Logs tab now navigates directly to RepairLogListView.** Previously, tapping a game on the Repair Logs tab opened `GameDetailView` — the same destination as every other tab — forcing users to then navigate *again* into the repair log section. Since the user is already on the Repair Logs tab, the intent is obvious: they want to see the repair entries. The fix is a one-line conditional in `GameListTab`'s `.navigationDestination(for: Game.self)` that checks `mode == .repairLogs` and routes to `RepairLogListView` instead.

**RepairLogEntryView was unusably slow on-device.** Typing notes felt like molasses on a real iPhone. Two compounding causes:

1. **Photo thumbnails decoded inline in `body`.** Every photo's full-resolution `imageData` blob was loaded from SwiftData external storage and decoded into a `UIImage` *inside the `ForEach`*. The `TextEditor` binding triggered body re-evaluation on every keystroke, which re-decoded every photo from disk every time a character was typed.

2. **`TextEditor` bound directly to SwiftData.** `$log.notes` wrote to the `@Model` object on every keystroke. Each write triggered SwiftData's dirty-tracking, which sent a change notification back to SwiftUI, which re-evaluated the entire `Form` body — including the photo decoding above. So each character produced: keystroke → SwiftData write → change notification → body re-eval → N full-resolution image decodes. On an iPhone with a few photos attached, this was catastrophic.

**Fix 1: `PhotoThumbnail` subview.** Extracted the inline photo rendering into a private `PhotoThumbnail` struct with its own `@State private var thumbnail: UIImage?`. The thumbnail is loaded once via `.task`, decoded and downscaled to 300×300px off the main thread using `UIImage.byPreparingThumbnail(ofSize:)` inside a `Task.detached`. Because it's a separate view with its own `@State`, SwiftUI's diffing skips it entirely when the parent's `TextEditor` binding changes — the thumbnail is already rendered and cached.

**Fix 2: buffered notes text.** Replaced `TextEditor(text: $log.notes)` with a local `@State private var notesText: String` initialized from `log.notes` in `init`. The `TextEditor` now writes to plain SwiftUI state, not SwiftData, so keystrokes stay inside SwiftUI's lightweight state system with no persistence overhead. The model is updated once in `.onDisappear` when the user navigates away.

**Lesson**: `@Bindable` two-way bindings to SwiftData `@Model` properties are convenient but dangerous in text-editing contexts. Every keystroke becomes a database write, which triggers change observation, which triggers view re-evaluation, which triggers anything expensive in the body. For high-frequency input like text editing, buffer in `@State` and flush on disappear.

**Lesson**: SwiftUI's view-diffing optimization only works at subview boundaries. An expensive computation inlined in a parent's `body` re-runs every time *any* state in that parent changes. Extracting it into a child view with its own `@State` gives SwiftUI a diffing boundary — if the child's inputs haven't changed, its body is skipped entirely.

### 2026-08-14 — Short Play Video Playback: YouTube + AVPlayer Dual Path

The Short Play section in `GameDetailView` was broken on device — videos never played. Root cause: the seed data's `url_shortplays` field contains **YouTube watch URLs** (`youtube.com/watch?v=...`), not direct video file URLs. `AVPlayer` can't play YouTube page links; it needs direct media URLs (`.mp4`, `.m3u8`).

Meanwhile, the ADB API returns two separate things: a direct video download URL (`url_video_shortplay` → `adb.arcadeitalia.net/download_file.php?...`) and a YouTube video ID (`youtube_video_id`). The `youtubeVideoID` was being fetched and stored on `Game` but never used in any view.

**The fix: a two-path video player with YouTube priority.**

Priority logic in `GameDetailView`:
1. `resolvedYouTubeID` — checks `game.youtubeVideoID` first (set by ADB API), then falls back to extracting a video ID from `game.shortPlayURL` if it's a YouTube link (covers seed data). Helper `extractYouTubeID(from:)` handles both `youtube.com/watch?v=` and `youtu.be/` formats.
2. `directVideoURL` — returns `game.shortPlayURL` only when it's *not* a YouTube URL, so `AVPlayer` is used only for actual video file URLs.

**YouTube path: `YouTubePlayerView` (WKWebView).** This went through several iterations:

- **Attempt 1: YouTube IFrame embed** (`/embed/{id}?playsinline=1`) — YouTube rejected it with error 153 (origin validation failure). WKWebView's default origin is `about:blank`, which YouTube doesn't allow.
- **Attempt 2: IFrame with `baseURL: youtube.com`** — Still rejected, error 152-4. Setting the HTML page's origin via `loadHTMLString(baseURL:)` wasn't enough; YouTube's embed player does deeper validation.
- **Attempt 3: YouTube IFrame Player API** (the approach Google's own `youtube-ios-player-helper` uses) — Same error 152-4. The specific Contra video has embedding disabled by its owner, so *no* embed approach can work for it.
- **Attempt 4: Load `m.youtube.com/watch` directly** — This works because it's just loading the YouTube mobile website, not embedding. Embed restrictions don't apply. But the raw mobile page showed YouTube's full UI (top bar, comments, related videos) and had layout issues.

**Cleaning up the mobile page.** A `WKUserScript` injected at document end handles two things:

1. **CSS** hides YouTube chrome (`ytm-mobile-topbar-renderer`, `#below-player`, `ytm-pivot-bar-renderer`) and positions `#player-container-id` as a fixed full-viewport overlay.
2. **JavaScript** scales the player to fill the WKWebView. Rather than fighting YouTube's internal element sizing (which YouTube's JS constantly resets via inline styles), the script uses `transform: scale()` on `#movie_player`: it measures the player's natural size, calculates `Math.min(viewportWidth/playerWidth, viewportHeight/playerHeight)`, and applies `translate(-50%,-50%) scale(factor)` from `position: fixed; top: 50%; left: 50%`. This preserves YouTube's internal layout (controls, aspect ratio) while uniformly zooming to fit. A `setInterval` at 500ms re-applies in case YouTube's JS resets styles.

**Fullscreen support** required `config.preferences.isElementFullscreenEnabled = true` on the `WKWebViewConfiguration` — without it, YouTube's fullscreen button is a no-op in WKWebView.

**Layout fix.** The original `DisclosureGroup` wrapper indented the video player content, clipping the left edge. Replaced with a manual toggle button (with rotating chevron) + conditional content, so the `YouTubePlayerView` is its own list row with `.listRowInsets(EdgeInsets(...))` for full-width display.

**AVPlayer path** is unchanged — `AVURLAsset` with MIME type hint, created lazily on expand. Only used when `resolvedYouTubeID` is nil and `directVideoURL` is a non-YouTube URL.

**Lesson**: YouTube's embed restrictions are per-video, set by the uploader. There is no client-side configuration — not origin headers, not the IFrame API, not `baseURL` tricks — that can bypass a video with embedding disabled. If your app needs to play arbitrary YouTube videos inline, the only reliable path is loading the full YouTube mobile page and cleaning it up with injected CSS/JS.

**Lesson**: when you need to scale third-party web content to fit a WKWebView frame, `transform: scale()` on the content's root container is far more robust than overriding individual element sizes. The third party's JS will fight your size overrides with inline styles, but `transform` on a parent element doesn't conflict with child sizing — it applies uniformly after layout.

**Lesson**: `WKWebView` does not enable the JavaScript Fullscreen API by default. Set `config.preferences.isElementFullscreenEnabled = true` (iOS 15.4+) or fullscreen buttons in embedded web content silently do nothing.

### 2026-08-20 — App Icon Appearance Variants: Two Bugs Wearing a Trenchcoat

The dark and tinted app icon variants weren't showing up on the simulator *or* on the physical device. Started chasing this as an asset problem and ended up finding two overlapping issues — one in the assets, one in the tester's mental model of how iOS 18+ icon appearance actually works.

**Bug 1: The PNGs were fully opaque.** `sips -g hasAlpha` on all three icon files came back `no` — every variant was `RGB / samplesPerPixel: 3`. iOS 18+ has strict requirements for the appearance variants that the source PNGs from the design tool weren't meeting:

- **Dark variant** needs an **alpha channel with a transparent background** — iOS composites the icon over its own dark glass chrome. A fully opaque dark icon just displays its own background rectangle instead of picking up the system aesthetic.
- **Tinted variant** needs to be **grayscale with luminance as alpha** — iOS reads the alpha (or grayscale intensity) to know where to paint the user's chosen tint color. A fully opaque color-RGB PNG has nothing for the tint system to key off of, so it just displays as-is.

Wrote `scripts/prepare_app_icons.py` to fix both:

- **Dark**: samples the corner pixel as the background reference (came back as RGB (9, 14, 24) — near-black), then uses `ImageChops.difference` across all three channels to compute per-pixel max distance from that reference. Pixels within threshold=40 become alpha=0; distances above 2× ramp smoothly to alpha=255 for anti-aliased edges. Post-processing, corners are (9,14,24,0) and content pixels are (color, 255).
- **Tinted**: converts to grayscale via PIL's `.convert("L")`, then reassembles as `RGBA` with the grayscale in R/G/B *and* alpha. Black background naturally becomes fully transparent; bright grayscale content becomes fully opaque with the same intensity value in RGB.

Idempotent by design: on first run, the script backs up each opaque source to `scripts/icon_sources/<name>.opaque.png` before overwriting the iconset PNG. Subsequent runs read from the backup, so re-running always produces the same output even after the iconset PNGs have already been overwritten. Backups are checked into git as the pristine source of truth for future re-runs. **First cut of the script kept the backups inside the `.appiconset` folder** — clean data flow, but Xcode's asset catalog scans every file in the folder and warns about anything not referenced by `Contents.json` ("The app icon set 'AppIcon' has 2 unassigned children"). Moved them out to `scripts/icon_sources/` next to the script that owns them.

**Bug 2 (the real gotcha): system Dark Mode ≠ home screen icon appearance on iOS 18+.** After the asset fix, the tester reported that not just our app's icon but *Apple's own stock icons* also weren't changing appearance when they toggled Dark Mode. That last detail cracked the case — the tester was flipping Settings → Display & Brightness → Dark and expecting the home screen icons to swap variants, but on iOS 18+ those are **two independent controls**:

- Settings → Display & Brightness → Dark changes the **system UI** appearance (control center, keyboard, apps' internal chrome).
- Long-press the home screen → **Edit → Customize** → pick **Automatic / Dark / Light / Tinted** — this is what controls **home screen icon appearance**.

Only the "Automatic" mode ties icon appearance to the system Dark Mode toggle. Any of the other three modes is a hard override that pins the icon variant regardless of what the system-level Dark Mode says. So a tester who happens to have this set to "Light" (the default in some configurations) will never see icon changes from toggling Dark Mode.

Once the tester used the Customize tray explicitly (long-press home screen → Edit → Customize → Dark, then Tinted), both bugs' fixes were visible immediately — our processed variants rendered correctly, and Apple's stock icons also swapped alongside them.

**Lesson**: when a whole class of visual features fails to change, check whether *any* similar feature — including first-party apps — is behaving correctly. If Apple's own icons don't change appearance, the app's asset catalog isn't the bug. The signal "even the built-in stuff is broken" narrows the search space from "our code" to "the environment or the user's mental model" instantly.

**Lesson**: for iOS 18+ app icon variants, the asset requirements aren't documented in the same place as the Contents.json format. The Contents.json accepts opaque PNGs happily with no build warnings — the wrong-format icons ship, they just don't render correctly at runtime. Any icon-preparation tooling should assert alpha=4-samples on the dark and tinted PNGs before check-in, because the failure mode is silent.

**Lesson**: idempotent asset-processing scripts want a "pristine source" convention that lives *outside* the folder the tooling scans. Sources go next to the script (`scripts/icon_sources/`), processed outputs go into the asset catalog. Colocating sources with outputs is tempting for the clean data flow but immediately conflicts with any folder that has its own scanner — asset catalogs, resource bundles, build phases. Same principle as `.gitignore`-ing generated files: producers and consumers of a folder shouldn't share a namespace with unrelated visitors of that folder.

### 2026-08-20 — Swift 6 Isolation: `flatMap(Self.method)` Requires `nonisolated`

A build warning in `GameDetailView`: `Call to main actor-isolated static method 'extractYouTubeID(from:)' in a synchronous nonisolated context`. Only line 287 fired — `game.shortPlayURL.flatMap(Self.extractYouTubeID)` — while the same static method called directly on line 292 (`Self.extractYouTubeID(from: url)`) was silent.

The mechanism is the closure conversion. `GameDetailView` is main-actor-isolated by SwiftUI convention, so `Self.extractYouTubeID` inherits main-actor isolation. Direct call from another main-actor context is fine. But passing the method as a bare reference to `Optional.flatMap` binds it as a closure with type `(URL) -> String?` — and `flatMap`'s parameter is *nonisolated*. Swift 6 refuses to convert a main-actor method into a nonisolated closure.

**Fix**: one keyword — `private nonisolated static func extractYouTubeID(from:)`. Pure URL parsing, no view state, no reason to be on the main actor.

**Lesson**: pure helpers that get passed as function references (`.flatMap`, `.map`, `Task { }`, etc.) need `nonisolated` even inside main-actor types. Direct call sites hide the issue — the closure-conversion path is what enforces the isolation contract. When you see a warning on line X but "the same call one line down" is fine, look for a callable-reference conversion at line X.

### 2026-08-20 — Repair Log Notes: Crash-Safe Buffered Writes

The 2026-08-14 perf fix moved `TextEditor` off SwiftData and into a `@State` buffer that only flushed to `log.notes` on `.onDisappear`. Keystroke latency went from unusable back to instant, but a code review spotted the tradeoff: any time between "user typed" and "user navigates back" is a data-loss window if iOS reclaims the backgrounded process or the app crashes.

**Three-way flush** in `RepairLogEntryView`:

1. **Debounced auto-save while typing** — `.onChange(of: notesText)` schedules a `Task { @MainActor in ... try? await Task.sleep(for: .seconds(1)); flushNotes() }`. Every keystroke cancels the previous task, so the actual write only fires after a 1-second typing pause. This still keeps SwiftData off the per-keystroke hot path (the whole point of the buffer) but bounds the loss window to ~1 second of typing.

2. **Background flush** — `.onChange(of: scenePhase)` fires `flushNotes()` whenever the scene leaves `.active` (either `.inactive` transitions or full `.background`). This catches the "user swipes up to the app switcher before pausing to type" scenario.

3. **Disappear flush** — kept the existing `.onDisappear { flushNotes() }` for the normal navigation-back path.

All three routes call a single `flushNotes()` that cancels the pending debounce task, writes `notesText → log.notes` (guarded by inequality check to avoid touching the model unnecessarily), and explicitly calls `try? modelContext.save()`. SwiftData's implicit periodic auto-save is not scene-aware — you have to force the save yourself before the OS can kill the process.

**Lesson**: any UI pattern that "buffers writes into `@State` for performance and flushes later" has two failure modes to design around: the process getting killed while the buffer is stale, and the view getting reused for a different underlying record while the buffer holds the previous record's content. The first is fixed with `scenePhase` + debounce; the second requires either view-identity tagging (`.id(model.persistentModelID)`) or an `.onChange(of: model.id)` re-seed. This pass covered the first — the second is worth adding when a use case that could exercise it surfaces.

**Lesson**: `Task { @MainActor in ... }` explicitly marks the debounce task as main-actor even inside an already-main-actor view. That's belt-and-suspenders for readability — a future reader can grep for "`@MainActor in`" and immediately see "yes this UI-adjacent async work is on the main actor" without having to trace enclosing isolation.
