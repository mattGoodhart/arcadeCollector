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
