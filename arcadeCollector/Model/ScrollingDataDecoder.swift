//
//  ScrollingDataDecoder.swift
//  arcadeCollector
//
//  Created by TrixxMac on 4/18/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import Foundation

struct ScrollingDataDecoder: Codable {
    let result: [ScrollingData]
}

struct ScrollingData: Codable {
    let romName: String
    let title: String
    let year: String
    let manufacturer: String
    let players: String
    let orientation: String
    
    enum CodingKeys: String, CodingKey {
        case romName
        case title = "Title"
        case year
        case manufacturer
        case players = "Players"
        case orientation = "Orientation"
    }
}
