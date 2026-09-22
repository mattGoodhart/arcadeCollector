//
//  GoldenPathUITests.swift
//  ArcadeCollectorUITests
//

import XCTest

/// Exercises the primary user flow end-to-end: launch, find a specific seeded
/// game, mark it owned, verify it shows up on the My Collection tab, then toggle
/// ownership back off so the test leaves no persistent state behind.
///
/// Targets Donkey Kong specifically because the seeded dataset guarantees it
/// exists (`romSetName == "dkong"`) and both `GameRow` and the ownership toggle
/// carry stable accessibility identifiers (`game-row-dkong`, `pcb-toggle`) that
/// don't depend on the row being visible in the accessibility tree.
///
/// **Runs against whatever data is already on the device.** There is no store
/// reset here, so the My Collection tab contains however many games the device's
/// owner actually owns, and the list is sorted by title. Every membership check
/// below therefore has to *scan* — a `List` only puts visible rows in the
/// accessibility tree, so "not found" and "not currently on screen" are
/// indistinguishable from a single query. See `scanForGameRow(_:)`.
final class GoldenPathUITests: XCTestCase {

    private static let romSetName = "dkong"
    private static let searchQuery = "donkey"
    private static let gameRowIdentifier = "game-row-\(romSetName)"
    private static let pcbToggleIdentifier = "pcb-toggle"

    @MainActor
    override func setUpWithError() throws {
        continueAfterFailure = false

        // Pin portrait. The app itself is now portrait-only
        // (`INFOPLIST_KEY_UISupportedInterfaceOrientations`), so this is
        // belt-and-suspenders rather than the thing holding the test up — but
        // it's worth keeping, because it states the requirement locally and
        // still normalizes the device before the first tap.
        //
        // It mattered a great deal before the app was locked: this suite runs
        // on a physical device, so the starting orientation was simply however
        // the phone happened to be lying, and every geometric assumption here
        // is portrait-shaped (`findPCBToggle` compares the toggle's frame
        // against the tab bar's; the list scans need swipes to actually
        // advance the content). In landscape the collection view reported a
        // rotated frame and swipes stopped scrolling — which is how this test
        // passed standalone and failed in the full suite right after a test
        // that left the device rotated.
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testOwnershipRoundTripAcrossTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 30), "Tab bar never appeared — ModelContainer init likely failed")

        // Step 1: on All Games, use search to narrow the 4,166-row list down to
        //         just Donkey Kong so its row materializes into the viewport.
        openTab(app, named: "All Games")
        searchForTestGame(app)
        let gameRow = findGameRow(app)
        XCTAssertTrue(gameRow.waitForExistence(timeout: 15), "Donkey Kong row not visible after searching — seed or search filter broken")
        gameRow.tap()

        // Step 2: toggle "Have the PCB" on. The artwork fetch fires on view
        //         appear and inserts sections (history, short play, links,
        //         manual) above the toggle — wait for it to settle so we
        //         don't find the toggle then lose it to a re-render.
        waitForDetailToSettle(app)
        let pcbToggle = findPCBToggle(app)
        XCTAssertTrue(pcbToggle.waitForExistence(timeout: 5), "PCB toggle not reachable after scrolling detail view")
        if isSwitchOn(pcbToggle) {
            tapToggle(pcbToggle)
            XCTAssertTrue(waitForSwitch(pcbToggle, on: false), "Failed to reset PCB toggle to off before test body")
        }
        tapToggle(pcbToggle)
        XCTAssertTrue(waitForSwitch(pcbToggle, on: true), "Toggling 'Have the PCB' on didn't stick")

        // Step 3: cross-tab observation — My Collection should now contain
        //         Donkey Kong. The tab has no search field to narrow with and
        //         the device may already own any number of games, so scan the
        //         list instead of assuming the row is at the top.
        navigateBack(app)
        openTab(app, named: "My Collection")
        XCTAssertTrue(scanForGameRow(app), "Donkey Kong missing from My Collection after marking owned")

        // Step 4: cleanup — flip back off so state doesn't leak into subsequent runs.
        //         The scan left the row on screen and hittable.
        let collectionRow = findGameRow(app)
        collectionRow.tap()
        waitForDetailToSettle(app)
        let cleanupToggle = findPCBToggle(app)
        XCTAssertTrue(cleanupToggle.waitForExistence(timeout: 5), "PCB toggle not reachable during cleanup")
        tapToggle(cleanupToggle)
        XCTAssertTrue(waitForSwitch(cleanupToggle, on: false), "Cleanup toggle-off didn't stick")

        // Step 5: confirm My Collection no longer lists Donkey Kong. This also
        //         has to scan: a single query would "pass" merely because the
        //         list happened to be scrolled somewhere else, which is how
        //         this assertion could go green while proving nothing.
        navigateBack(app)
        XCTAssertFalse(scanForGameRow(app), "Donkey Kong still on My Collection after cleanup — ownership filter isn't reactive")
    }

    // MARK: - Helpers

    /// Whether Donkey Kong's row exists anywhere in the currently displayed
    /// list, rewinding to the top and scrolling the whole way down to decide.
    ///
    /// This test used to assume Donkey Kong would be the *only* owned game and
    /// therefore sitting at row 0. That holds on a clean simulator and is false
    /// on any device whose owner actually uses the app: on a real iPhone with a
    /// populated collection, the title-sorted list showed A through C and
    /// `game-row-dkong` was simply below the fold — absent from the
    /// accessibility tree because `List` is lazy, not because the app was
    /// wrong. Scanning removes the assumption entirely.
    ///
    /// Ends the scan early when a swipe fails to change the topmost realized
    /// row, which means the list has stopped moving and we've hit the bottom.
    /// On success the row is left on screen and hittable so the caller can tap
    /// it directly.
    private func scanForGameRow(_ app: XCUIApplication, maxSwipes: Int = 40) -> Bool {
        let scroller = app.collectionViews.firstMatch
        guard scroller.waitForExistence(timeout: 5) else { return false }

        rewindToTop(app, scroller: scroller, maxSwipes: maxSwipes)

        var lastTopRow = ""
        for _ in 0..<maxSwipes {
            if isGameRowReady(app) { return true }
            let topRow = topRealizedRowIdentifier(app)
            if topRow == lastTopRow { break }
            lastTopRow = topRow
            scroller.swipeUp()
        }
        return isGameRowReady(app)
    }

    /// Scrolls back to the top so a scan always covers the full list. Returning
    /// to My Collection from a detail view restores the previous scroll offset,
    /// so "start from wherever we are" would silently skip rows above it.
    private func rewindToTop(_ app: XCUIApplication, scroller: XCUIElement, maxSwipes: Int) {
        var lastTopRow = ""
        for _ in 0..<maxSwipes {
            let topRow = topRealizedRowIdentifier(app)
            if topRow == lastTopRow { return }
            lastTopRow = topRow
            scroller.swipeDown()
        }
    }

    /// Requires `isHittable`, not just `exists`: a row straddling the viewport
    /// edge enters the accessibility tree but can be evicted before the caller
    /// taps it, which is the same trap `findPCBToggle` documents below.
    private func isGameRowReady(_ app: XCUIApplication) -> Bool {
        let row = findGameRow(app)
        return row.exists && row.isHittable
    }

    /// Identifier of the topmost realized `game-row-*` button, or `""` if none.
    /// Used purely as a "did the list actually move?" signal, so the exact
    /// ordering guarantee doesn't matter — only that the value changes when the
    /// content scrolls and stops changing at the end.
    private func topRealizedRowIdentifier(_ app: XCUIApplication) -> String {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "game-row-")
        let rows = app.descendants(matching: .button).matching(predicate)
        guard rows.count > 0 else { return "" }
        return rows.element(boundBy: 0).identifier
    }

    /// Queries by accessibility identifier across any element type. SwiftUI's
    /// `.accessibilityIdentifier(_:)` inside a `NavigationLink` may surface on
    /// a button, cell, or otherElement depending on the platform release, so
    /// we accept whichever the accessibility tree exposes.
    private func findGameRow(_ app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@", Self.gameRowIdentifier)
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    /// Scrolls the detail view's `List` up until the PCB toggle is reachable
    /// AND fully clear of the tab bar. Two conditions are checked:
    ///
    /// 1. `.isHittable` — a row sitting at the very bottom edge of the
    ///    viewport enters the accessibility tree but the tree can evict it on
    ///    the next query, so requiring hittable keeps subsequent `.value`
    ///    reads from missing.
    /// 2. `frame.maxY <= tabBar.frame.minY` — the switch's compound frame can
    ///    extend behind the tab bar even when hittable. Without this check,
    ///    `coordinate(withNormalizedOffset: (0.9, 0.5)).tap()` lands on the
    ///    Repair Logs tab button instead of the switch knob.
    private func findPCBToggle(_ app: XCUIApplication, maxSwipes: Int = 12) -> XCUIElement {
        let toggle = app.switches[Self.pcbToggleIdentifier]
        let scroller = app.collectionViews.firstMatch
        let tabBar = app.tabBars.firstMatch
        for _ in 0..<maxSwipes {
            if toggle.exists && toggle.isHittable {
                let clearsTabBar = !tabBar.exists || toggle.frame.maxY <= tabBar.frame.minY
                if clearsTabBar { return toggle }
            }
            if scroller.exists {
                scroller.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        return toggle
    }

    private func openTab(_ app: XCUIApplication, named name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(name) tab button missing")
        tab.tap()
    }

    private func searchForTestGame(_ app: XCUIApplication) {
        // `.searchable()` on iOS 26 renders a search field in the nav bar area;
        // the field may need to be scrolled into view via a downward drag on
        // the list if it's initially hidden.
        var searchField = app.searchFields.firstMatch
        if !searchField.waitForExistence(timeout: 3) {
            let list = app.collectionViews.firstMatch
            if list.exists {
                list.swipeDown()
            }
            searchField = app.searchFields.firstMatch
        }
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field not found on All Games")
        searchField.tap()
        searchField.typeText(Self.searchQuery)
    }

    /// SwiftUI `Toggle`'s accessibility element sometimes reports type `.switch`
    /// but the tap target is the whole cell (label + switch). A plain `.tap()`
    /// can land on the label area and be swallowed — hitting the right-hand
    /// side of the frame guarantees we land on the switch control itself.
    private func tapToggle(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    }

    /// SwiftUI Toggle exposes value as "0" or "1"; belt-and-suspenders for
    /// platform versions that report a Bool or localized "On"/"Off". Guards
    /// `.exists` before reading `.value` because on a missing element `.value`
    /// hard-fails the test with "No matches found for Descendants matching
    /// type Switch" — which can happen mid-flight when a `List` re-layouts
    /// after the toggled change adds or removes sections below.
    private func isSwitchOn(_ toggle: XCUIElement) -> Bool {
        guard toggle.exists else { return false }
        if let boolValue = toggle.value as? Bool { return boolValue }
        if let stringValue = toggle.value as? String {
            return stringValue == "1" || stringValue.lowercased() == "on"
        }
        return false
    }

    /// SwiftUI `Toggle` state changes propagate asynchronously through the
    /// bound property, so the accessibility `.value` doesn't flip on the same
    /// event-loop tick as the tap. Poll for a bounded window, treating a
    /// transient element absence (during `List` re-layout) as "keep polling"
    /// rather than a terminal failure.
    private func waitForSwitch(_ toggle: XCUIElement, on desired: Bool, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if toggle.exists, isSwitchOn(toggle) == desired { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return toggle.exists && isSwitchOn(toggle) == desired
    }

    /// Waits for the artwork fetch to complete and the detail view to
    /// stabilize before interacting with lower sections. The Manual button
    /// only appears after `ArtworkFetcher` populates `manualURL`, so its
    /// presence signals the async content insertion is done.
    private func waitForDetailToSettle(_ app: XCUIApplication) {
        let manualButton = app.buttons["Manual"]
        _ = manualButton.waitForExistence(timeout: 10)
    }

    private func navigateBack(_ app: XCUIApplication) {
        let back = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5), "Back button not found")
        back.tap()
    }
}
