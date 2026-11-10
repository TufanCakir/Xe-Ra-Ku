//
//  CyberNavigationStyle.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 10.11.26.
//

import SwiftUI

struct CyberNavigationStyle {
    let title: String
    let symbol: String
    let subtitle: String
    let accent: Color
    let background: Color
    let backgroundGlow: Color

    var showGrid: Bool = true

    var panel: Color {
        accent.opacity(0.12)
    }
}

enum MenuTab: String, CaseIterable, Identifiable {
    case home
    case duel
    case events
    case cards
    case decks
    case settings

    var id: Self { self }

    var style: CyberNavigationStyle {
        switch self {
        case .home:
            CyberNavigationStyle(
                title: "HOME",
                symbol: "house.fill",
                subtitle: "Deine Kommandozentrale",
                accent: CyberTheme.blue,
                background: CyberTheme.navy,
                backgroundGlow: CyberTheme.blue.opacity(0.35)
            )

        case .duel:
            CyberNavigationStyle(
                title: "DUELL",
                symbol: "gamecontroller.fill",
                subtitle: "Gegen KI antreten",
                accent: CyberTheme.duel,
                background: CyberTheme.duelBackground,
                backgroundGlow: CyberTheme.duel.opacity(0.22)
            )

        case .events:
            CyberNavigationStyle(
                title: "EVENT",
                symbol: "bolt.shield.fill",
                subtitle: "Herausforderungen",
                accent: CyberTheme.event,
                background: CyberTheme.eventBackground,
                backgroundGlow: CyberTheme.event.opacity(0.22)
            )

        case .cards:
            CyberNavigationStyle(
                title: "KARTEN",
                symbol: "rectangle.stack.fill",
                subtitle: "Kartensammlung",
                accent: CyberTheme.cards,
                background: CyberTheme.cardsBackground,
                backgroundGlow: CyberTheme.cards.opacity(0.20)
            )

        case .decks:
            CyberNavigationStyle(
                title: "DECKS",
                symbol: "square.stack.3d.up.fill",
                subtitle: "Decks bearbeiten",
                accent: CyberTheme.decks,
                background: CyberTheme.decksBackground,
                backgroundGlow: CyberTheme.decks.opacity(0.22)
            )

        case .settings:
            CyberNavigationStyle(
                title: "SETTINGS",
                symbol: "gearshape.fill",
                subtitle: "Einstellungen",
                accent: CyberTheme.settings,
                background: CyberTheme.settingsBackground,
                backgroundGlow: CyberTheme.settings.opacity(0.18),
                showGrid: false
            )
        }
    }

    var title: String { style.title }
    var symbol: String { style.symbol }
}
