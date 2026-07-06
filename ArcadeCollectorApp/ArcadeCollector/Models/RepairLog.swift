//
//  RepairLog.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

@Model
final class RepairLog {
    var date: Date
    var notes: String
    var game: Game?

    @Relationship(deleteRule: .cascade, inverse: \RepairLogPhoto.repairLog)
    var photos: [RepairLogPhoto] = []

    init(date: Date = .now, notes: String = "") {
        self.date = date
        self.notes = notes
    }
}
