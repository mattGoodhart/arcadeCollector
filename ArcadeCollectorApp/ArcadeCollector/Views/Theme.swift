//
//  Theme.swift
//  ArcadeCollector
//

import SwiftUI

extension Color {
    static let arcadeRowEven = Color(red: 0.45, green: 0.62, blue: 0.50)
    static let arcadeRowOdd = Color(red: 0.098, green: 0.392, blue: 0.392)
    static let arcadeToolbar = Color(red: 0.45, green: 0.62, blue: 0.50)
    static let arcadeAboutBackground = Color(red: 0.614, green: 0.842, blue: 0.680)
}

extension ShapeStyle where Self == Color {
    static var arcadeRowEven: Color { .arcadeRowEven }
    static var arcadeRowOdd: Color { .arcadeRowOdd }
}
