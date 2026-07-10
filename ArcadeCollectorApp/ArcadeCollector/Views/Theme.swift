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
    static let arcadeSummaryBackground = Color(red: 0.542, green: 0.749, blue: 0.606)

    // Legacy chart palette
    static let chartGreen = Color(red: 0, green: 104.0/255, blue: 56.0/255)
    static let chartOrange = Color(red: 231.0/255, green: 148.0/255, blue: 33.0/255)
    static let chartRed = Color.red
    static let chartSeaFoam = Color(red: 100.0/255, green: 177.0/255, blue: 148.0/255)
}

extension ShapeStyle where Self == Color {
    static var arcadeRowEven: Color { .arcadeRowEven }
    static var arcadeRowOdd: Color { .arcadeRowOdd }
}
