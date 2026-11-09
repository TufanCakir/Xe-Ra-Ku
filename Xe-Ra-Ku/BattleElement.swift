//
//  BattleElement.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import SwiftUI

enum BattleElement: String, CaseIterable, Codable, Identifiable {
    case fire
    case holy
    case shadow
    case void
    case water
    case light
    case earth
    case plant
    case stone
    case grass
    case lust

    var id: String { rawValue }

    var title: String {
        rawValue.uppercased()
    }

    var color: Color {
        switch self {
        case .fire: Color(red: 0.94, green: 0.35, blue: 0.21)
        case .holy: Color(red: 0.95, green: 0.85, blue: 0.55)
        case .shadow: Color(red: 0.37, green: 0.29, blue: 0.57)
        case .void: Color(red: 0.14, green: 0.13, blue: 0.20)
        case .water: Color(red: 0.14, green: 0.49, blue: 0.81)
        case .light: Color(red: 0.96, green: 0.91, blue: 0.73)
        case .earth: Color(red: 0.55, green: 0.40, blue: 0.27)
        case .plant: Color(red: 0.29, green: 0.62, blue: 0.38)
        case .stone: Color(red: 0.47, green: 0.51, blue: 0.56)
        case .grass: Color(red: 0.60, green: 0.74, blue: 0.31)
        case .lust: Color(red: 0.84, green: 0.35, blue: 0.61)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .holy, .light, .grass:
            .black
        default:
            .white
        }
    }

    var symbol: String {
        switch self {
        case .fire: "flame.fill"
        case .holy: "sparkles"
        case .shadow: "moon.fill"
        case .void: "circle.hexagongrid.fill"
        case .water: "drop.fill"
        case .light: "sun.max.fill"
        case .earth: "mountain.2.fill"
        case .plant: "leaf.fill"
        case .stone: "hexagon.fill"
        case .grass: "tree.fill"
        case .lust: "heart.fill"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .fire:
            [.red, .orange, .yellow]
        case .holy:
            [.white, .yellow, .orange]
        case .shadow:
            [.black, .purple, .indigo]
        case .void:
            [.black, .indigo, .purple]
        case .water:
            [.blue, .cyan, .mint]
        case .light:
            [.white, .yellow, .white]
        case .earth:
            [.brown, .orange, .brown]
        case .plant:
            [.green, .mint, .teal]
        case .stone:
            [.gray, .white, .gray]
        case .grass:
            [.green, .yellow, .mint]
        case .lust:
            [.pink, .purple, .red]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
