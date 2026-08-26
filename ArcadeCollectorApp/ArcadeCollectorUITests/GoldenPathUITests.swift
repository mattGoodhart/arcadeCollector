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
final class GoldenPathUITests: XCTestCase {

    private static let romSetName = "dkong"
    private static let searchQuery = "donkey"
    private static let gameRowIdentifier = "game-row-\(romSetName)"
    private static let pcbToggleIdentifier = "pcb-toggle"

    override func setUpWithError() throws {
        continueAfterFailure = false
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

        // Step 3: cross-tab observation — My Collection should now show Donkey
        //         Kong without any search needed (it's the only owned game).
        navigateBack(app)
        openTab(app, named: "My Collection")
        let collectionRow = findGameRow(app)
        XCTAssertTrue(collectionRow.waitForExistence(timeout: 5), "Donkey Kong missing from My Collection after marking owned")

        // Step 4: cleanup — flip back off so state doesn't leak into subsequent runs.
        collectionRow.tap()
        waitForDetailToSettle(app)
        let cleanupToggle = findPCBToggle(app)
        XCTAssertTrue(cleanupToggle.waitForExistence(timeout: 5), "PCB toggle not reachable during cleanup")
        tapToggle(cleanupToggle)
        XCTAssertTrue(waitForSwitch(cleanupToggle, on: false), "Cleanup toggle-off didn't stick")

        // Step 5: confirm My Collection no longer lists Donkey Kong.
        navigateBack(app)
        let stillVisible = findGameRow(app).waitForExistence(timeout: 2)
        XCTAssertFalse(stillVisible, "Donkey Kong still visible on My Collection after cleanup — ownership filter isn't reactive")
    }

    // MARK: - Helpers

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
