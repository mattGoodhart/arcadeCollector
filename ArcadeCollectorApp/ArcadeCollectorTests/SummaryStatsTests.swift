//
//  SummaryStatsTests.swift
//  ArcadeCollectorTests
//
//  `SummaryStats` folds every number on the Summary tab out of one pass over
//  the game list. It replaced a dozen separate `filter` calls, and the risk of
//  that shape is that a wrong count still *looks* plausible — nobody
//  cross-checks a pie chart against 3,855 rows by hand.
//
//  The condition buckets carry the subtle rules and get the most attention
//  here: "working" tolerates untested extended play, and "issues" excludes
//  non-booting boards so a dead board isn't double-counted as both broken and
//  having issues.
//

import Testing
import Foundation
@testable import ArcadeCollector

@Suite("SummaryStats")
struct SummaryStatsTests {

    // MARK: - Fixtures

    private static func game(
        _ rom: String,
        ownership: OwnershipStatus = .owned,
        boot: ComponentStatus = .untested,
        audio: ComponentStatus = .untested,
        video: ComponentStatus = .untested,
        controls: ComponentStatus = .untested,
        extended: ComponentStatus = .untested,
        repaired: Bool = false
    ) -> Game {
        let game = Game(romSetName: rom, title: rom, ownership: ownership)
        game.bootStatus = boot
        game.audioStatus = audio
        game.videoStatus = video
        game.controlsStatus = controls
        game.extendedPlayStatus = extended
        if repaired { game.lastRepairLogDate = Date(timeIntervalSince1970: 1_700_000_000) }
        return game
    }

    private static func allWorking(_ rom: String, extended: ComponentStatus = .working) -> Game {
        game(rom, boot: .working, audio: .working, video: .working,
             controls: .working, extended: extended)
    }

    // MARK: - Collection counts

    @Test("Empty input produces all-zero stats")
    func emptyInput() {
        let stats = SummaryStats(games: [])

        #expect(stats == SummaryStats())
        #expect(stats.total == 0)
        #expect(stats.boot.isEmpty)
    }

    @Test("Ownership counts partition the collection")
    func ownershipCounts() {
        let stats = SummaryStats(games: [
            Self.game("a", ownership: .owned),
            Self.game("b", ownership: .owned),
            Self.game("c", ownership: .wanted),
            Self.game("d", ownership: .none),
        ])

        #expect(stats.total == 4)
        #expect(stats.owned == 2)
        #expect(stats.wanted == 1)
    }

    /// "In Repair" spans the whole store, not just owned games — it has to
    /// agree with the Repair Logs tab, which applies no ownership filter.
    @Test("In-repair count includes unowned games")
    func inRepairIgnoresOwnership() {
        let stats = SummaryStats(games: [
            Self.game("a", ownership: .owned, repaired: true),
            Self.game("b", ownership: .wanted, repaired: true),
            Self.game("c", ownership: .none, repaired: true),
            Self.game("d", ownership: .owned, repaired: false),
        ])

        #expect(stats.inRepair == 3)
    }

    // MARK: - Owned-only scoping

    @Test("Component histograms count owned games only")
    func histogramsScopedToOwned() {
        let stats = SummaryStats(games: [
            Self.game("a", ownership: .owned, boot: .working),
            Self.game("b", ownership: .wanted, boot: .working),
            Self.game("c", ownership: .none, boot: .working),
        ])

        #expect(stats.boot == [.working: 1])
        #expect(stats.owned == 1)
    }

    @Test("Condition buckets count owned games only")
    func bucketsScopedToOwned() {
        let stats = SummaryStats(games: [
            Self.allWorking("owned"),
            Self.game("wanted", ownership: .wanted, boot: .working, audio: .working,
                      video: .working, controls: .working, extended: .working),
        ])

        #expect(stats.workingBoards == 1)
    }

    // MARK: - Condition buckets

    @Test("All-untested boards land in the untested bucket")
    func untestedBucket() {
        let stats = SummaryStats(games: [Self.game("a")])

        #expect(stats.untestedBoards == 1)
        #expect(stats.workingBoards == 0)
        #expect(stats.boardsWithIssues == 0)
        #expect(stats.brokenBoards == 0)
    }

    /// One tested component disqualifies a board from "untested" — it's an
    /// all-five predicate, not a majority.
    @Test("A single tested component removes a board from untested")
    func untestedRequiresAllFive() {
        let stats = SummaryStats(games: [Self.game("a", audio: .working)])

        #expect(stats.untestedBoards == 0)
    }

    @Test("Fully working boards count as working")
    func workingBucket() {
        let stats = SummaryStats(games: [Self.allWorking("a")])

        #expect(stats.workingBoards == 1)
        #expect(stats.untestedBoards == 0)
    }

    /// The deliberate allowance: extended play may be untested and the board
    /// still counts as working. Plenty of PCBs are verified without sitting
    /// through a long run.
    @Test("Untested extended play still counts as working")
    func workingToleratesUntestedExtendedPlay() {
        let stats = SummaryStats(games: [Self.allWorking("a", extended: .untested)])

        #expect(stats.workingBoards == 1)
    }

    @Test("Broken extended play disqualifies working")
    func workingRejectsBrokenExtendedPlay() {
        let stats = SummaryStats(games: [Self.allWorking("a", extended: .broken)])

        #expect(stats.workingBoards == 0)
        #expect(stats.boardsWithIssues == 1)
    }

    @Test("A non-boot failure anywhere counts as issues")
    func issuesBucket() {
        let stats = SummaryStats(games: [
            Self.game("audio", boot: .working, audio: .issues),
            Self.game("video", boot: .working, video: .broken),
            Self.game("controls", boot: .working, controls: .issues),
            Self.game("extended", boot: .working, extended: .broken),
        ])

        #expect(stats.boardsWithIssues == 4)
        #expect(stats.brokenBoards == 0)
    }

    @Test("Boot status of issues counts as issues")
    func bootIssuesCountAsIssues() {
        let stats = SummaryStats(games: [Self.game("a", boot: .issues)])

        #expect(stats.boardsWithIssues == 1)
        #expect(stats.brokenBoards == 0)
    }

    @Test("A broken board counts as broken")
    func brokenBucket() {
        let stats = SummaryStats(games: [Self.game("a", boot: .broken)])

        #expect(stats.brokenBoards == 1)
    }

    /// The `bootStatus != .broken` guard. A dead board with other faults is
    /// broken and *only* broken — without the guard it would appear in both
    /// slices of the pie chart and the percentages would exceed 100%.
    @Test("A broken board with other faults is not double-counted as issues")
    func brokenExcludedFromIssues() {
        let stats = SummaryStats(games: [
            Self.game("a", boot: .broken, audio: .broken, video: .issues)
        ])

        #expect(stats.brokenBoards == 1)
        #expect(stats.boardsWithIssues == 0)
    }

    /// The chart treats these four as slices of one whole, so they must not
    /// overlap. Nothing in the type system enforces it — this does.
    @Test("Condition buckets stay mutually exclusive across the status matrix")
    func bucketsAreDisjoint() {
        let all: [ComponentStatus] = [.untested, .working, .issues, .broken]
        var index = 0

        for boot in all {
            for audio in all {
                for video in all {
                    for controls in all {
                        for extended in all {
                            index += 1
                            let stats = SummaryStats(games: [
                                Self.game("rom\(index)", boot: boot, audio: audio,
                                          video: video, controls: controls, extended: extended)
                            ])
                            let hits = stats.untestedBoards + stats.workingBoards
                                + stats.boardsWithIssues + stats.brokenBoards
                            #expect(
                                hits <= 1,
                                "boot=\(boot) audio=\(audio) video=\(video) controls=\(controls) extended=\(extended) landed in \(hits) buckets"
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Histograms

    @Test("Each component histogram tallies its own field")
    func histogramsAreIndependent() {
        let stats = SummaryStats(games: [
            Self.game("a", boot: .working, audio: .issues, video: .broken,
                      controls: .untested, extended: .working),
            Self.game("b", boot: .working, audio: .working, video: .broken,
                      controls: .untested, extended: .issues),
        ])

        #expect(stats.boot == [.working: 2])
        #expect(stats.audio == [.issues: 1, .working: 1])
        #expect(stats.video == [.broken: 2])
        #expect(stats.controls == [.untested: 2])
        #expect(stats.extendedPlay == [.working: 1, .issues: 1])
    }

    @Test("Histogram totals equal the owned count")
    func histogramTotalsMatchOwned() {
        let stats = SummaryStats(games: [
            Self.game("a", ownership: .owned, boot: .working),
            Self.game("b", ownership: .owned, boot: .broken),
            Self.game("c", ownership: .owned, boot: .issues),
            Self.game("d", ownership: .wanted, boot: .working),
        ])

        #expect(stats.boot.values.reduce(0, +) == stats.owned)
        #expect(stats.audio.values.reduce(0, +) == stats.owned)
        #expect(stats.video.values.reduce(0, +) == stats.owned)
        #expect(stats.controls.values.reduce(0, +) == stats.owned)
        #expect(stats.extendedPlay.values.reduce(0, +) == stats.owned)
    }
}
