//
//  GameEnums+Display.swift
//  ArcadeCollector
//
//  UI-side display helpers for the model enums. Kept out of the Models/
//  folder so the model layer stays SwiftUI-free.
//

import SwiftUI

extension ComponentStatus {
    var displayName: String {
        switch self {
        case .untested: return "Untested"
        case .broken:   return "Broken"
        case .issues:   return "Issues"
        case .working:  return "Working"
        }
    }

    var color: Color {
        switch self {
        case .untested: return .secondary
        case .broken:   return .red
        case .issues:   return .yellow
        case .working:  return .green
        }
    }

    var barLabelColor: Color {
        switch self {
        case .issues:                    return .black
        case .untested, .broken, .working: return .white
        }
    }

    var symbolName: String {
        switch self {
        case .untested: return "circle"
        case .broken:   return "xmark.circle.fill"
        case .issues:   return "exclamationmark.circle.fill"
        case .working:  return "checkmark.circle.fill"
        }
    }
}

extension ScreenOrientation {
    var displayName: String {
        switch self {
        case .horizontal: return "Horizontal"
        case .vertical:   return "Vertical"
        }
    }
}

extension OwnershipStatus {
    var displayName: String {
        switch self {
        case .none:   return "None"
        case .owned:  return "Owned"
        case .wanted: return "Wanted"
        }
    }
}

extension ArtworkKind {
    var displayName: String {
        switch self {
        case .cabinet:  return "Cabinet"
        case .flyer:    return "Flyer"
        case .inGame:   return "In-Game"
        case .marquee:  return "Marquee"
        case .title:    return "Title"
        case .pcb:      return "PCB"
        case .userPCB:  return "My PCB"
        }
    }
}
