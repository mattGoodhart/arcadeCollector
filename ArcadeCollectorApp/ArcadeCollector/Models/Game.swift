//
//  Game.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

@Model
final class Game {
    // MARK: Identity
    @Attribute(.unique) var romSetName: String
    var title: String

    // MARK: Metadata
    var manufacturer: String
    var year: String
    var genre: String
    var players: String
    var orientation: ScreenOrientation
    var isBootleg: Bool

    // MARK: Ownership
    var ownership: OwnershipStatus
    var hasBoard: Bool

    // MARK: Component status (LED indicators)
    var functionalCondition: ComponentStatus
    var bootStatus: ComponentStatus
    var audioStatus: ComponentStatus
    var videoStatus: ComponentStatus
    var controlsStatus: ComponentStatus
    var extendedPlayStatus: ComponentStatus

    // MARK: Technical specs
    var driver: String
    var emulationStatus: String
    var inputControls: String
    var inputButtons: String
    var displayType: String
    var monitorResolutionType: String
    var resolution: String
    var horizontalRefresh: String
    var verticalRefresh: String
    var verticalTotalLines: String
    var audioChannels: String
    var cpus: [String]
    var soundDevices: [String]

    // MARK: Notes & external media
    var mameNotes: String
    var youtubeVideoID: String
    var shortPlayURL: URL?
    var manualURL: URL?
    @Attribute(.externalStorage) var manualData: Data?

    // MARK: Timeline
    var lastRepairLogDate: Date?

    // MARK: Relationships
    @Relationship(deleteRule: .cascade, inverse: \RepairLog.game)
    var repairLogs: [RepairLog] = []

    @Relationship(deleteRule: .cascade, inverse: \GameArtwork.game)
    var artwork: [GameArtwork] = []

    @Relationship(inverse: \GameCollection.games)
    var collections: [GameCollection] = []

    init(
        romSetName: String,
        title: String,
        manufacturer: String = "",
        year: String = "",
        genre: String = "",
        players: String = "",
        orientation: ScreenOrientation = .horizontal,
        isBootleg: Bool = false,
        ownership: OwnershipStatus = .none,
        hasBoard: Bool = false
    ) {
        self.romSetName = romSetName
        self.title = title
        self.manufacturer = manufacturer
        self.year = year
        self.genre = genre
        self.players = players
        self.orientation = orientation
        self.isBootleg = isBootleg
        self.ownership = ownership
        self.hasBoard = hasBoard

        self.functionalCondition = .untested
        self.bootStatus = .untested
        self.audioStatus = .untested
        self.videoStatus = .untested
        self.controlsStatus = .untested
        self.extendedPlayStatus = .untested

        self.driver = ""
        self.emulationStatus = ""
        self.inputControls = ""
        self.inputButtons = ""
        self.displayType = ""
        self.monitorResolutionType = ""
        self.resolution = ""
        self.horizontalRefresh = ""
        self.verticalRefresh = ""
        self.verticalTotalLines = ""
        self.audioChannels = ""
        self.cpus = []
        self.soundDevices = []
        self.mameNotes = ""
        self.youtubeVideoID = ""
    }
}

extension Game {
    /// Convenience lookup for a specific artwork slot.
    func artwork(_ kind: ArtworkKind) -> GameArtwork? {
        artwork.first { $0.kind == kind }
    }
}
