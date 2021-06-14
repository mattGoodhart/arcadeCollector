//
//  ArcadeDatabaseResponse.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/3/21.
//  Copyright © 2021 CatBoiz. All rights reserved.

import Foundation

struct ArcadeDatabaseAPIResponse: Codable {
    let result: [RomSetResults]
}

struct RomSetResults: Codable {
    let resultIndex: Int
    let title: String
    let romSetName: String
    let longTitle: String
    let cloneOf: String
    let manufacturer: String
    let inGameImageURLString: String
    let titleImageURLString: String
    let marqueeImageURLString: String
    let cabinetImageURLString: String
    let flyerImageURLString: String
    let iconURLString: String
    let genre: String
    let numPlayers: Int
    let nPlayers: String
    let releaseYear: String
    let emulationStatus: String
    let history: String
    let shortCopyright: String
    let longCopyright: String
    let inputControls: String
    let inputButtons: Int
    let youtubeVideoID: String
    let shortPlayURLString: String // this might allow me to bring in a media playback framework/library
//
    enum CodingKeys: String, CodingKey {
        case resultIndex = "index"
        case title = "short_title"
        case romSetName = "game_name"
        case longTitle = "title"
        case cloneOf = "cloneof"
        case manufacturer
        case inGameImageURLString = "url_image_ingame"
        case titleImageURLString = "url_image_title"
        case marqueeImageURLString = "url_image_marquee"
        case cabinetImageURLString = "url_image_cabinet"
        case flyerImageURLString = "url_image_flyer"
        case iconURLString = "url_icon"
        case genre
        case numPlayers = "players"
        case nPlayers = "nplayers"
        case releaseYear = "year"
        case emulationStatus = "status"
        case history
        case shortCopyright = "history_copyright_short"
        case longCopyright = "history_copyright_long"
        case inputControls = "input_controls"
        case youtubeVideoID = "youtube_video_id"
        case shortPlayURLString = "url_video_shortplay"
        case inputButtons = "input_buttons"
    }
}
