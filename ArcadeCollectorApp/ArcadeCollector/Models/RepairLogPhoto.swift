//
//  RepairLogPhoto.swift
//  ArcadeCollector
//

import Foundation
import SwiftData

/// Photo attached to a RepairLog entry. Replaces the legacy fixed
/// `entryPhoto1/2/3` triple with an unbounded relationship.
@Model
final class RepairLogPhoto {
    var repairLog: RepairLog?
    var order: Int
    @Attribute(.externalStorage) var imageData: Data?

    init(order: Int, imageData: Data? = nil) {
        self.order = order
        self.imageData = imageData
    }
}
