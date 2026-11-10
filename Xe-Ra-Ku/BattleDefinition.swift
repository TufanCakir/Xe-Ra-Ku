//
//  BattleDefinition.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct BattleAppearance: Codable, Hashable, Sendable {
    let accentHex: String
    let backgroundTopHex: String
    let backgroundBottomHex: String
    let shaderHue: Double
    let shaderIntensity: Double

    var accent: Color { Self.color(accentHex) }
    var top: Color { Self.color(backgroundTopHex) }
    var bottom: Color { Self.color(backgroundBottomHex) }

    static func validHex(_ value: String) -> Bool {
        value.count == 7 && value.first == "#"
            && UInt32(value.dropFirst(), radix: 16) != nil
    }

    private static func color(_ hex: String) -> Color {
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
        return Color(
            red: Double((value >> 16) & 255) / 255,
            green: Double((value >> 8) & 255) / 255,
            blue: Double(value & 255) / 255
        )
    }

    var isValid: Bool {
        Self.validHex(accentHex) && Self.validHex(backgroundTopHex)
            && Self.validHex(backgroundBottomHex)
            && shaderHue.isFinite && (-360...360).contains(shaderHue)
            && shaderIntensity.isFinite && (0...2).contains(shaderIntensity)
    }
}

/// The same schema powers both catalog sections; only their content differs.
struct BattleEventDefinition: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let enemyID: String
    let requiredAccountLevel: Int
    let rewards: BattleRewards
    let appearance: BattleAppearance
    let startsAt: Date?
    let endsAt: Date?
    let energyCost: Int

    var rewardDescription: String { rewards.summary }

    // MARK: - Unlock Requirements

    func isLevelUnlocked(accountLevel: Int) -> Bool {
        accountLevel >= requiredAccountLevel
    }

    func missingLevels(accountLevel: Int) -> Int {
        max(0, requiredAccountLevel - accountLevel)
    }

    func lockDescription(
        accountLevel: Int,
        now: Date = .now
    ) -> String? {

        if !isLevelUnlocked(accountLevel: accountLevel) {
            return "AB LEVEL \(requiredAccountLevel)"
        }

        if let startsAt, now < startsAt {
            return "NOCH NICHT VERFÜGBAR"
        }

        if let endsAt, now >= endsAt {
            return "EVENT BEENDET"
        }

        return nil
    }

    func isAvailable(
        accountLevel: Int,
        now: Date = .now
    ) -> Bool {
        lockDescription(
            accountLevel: accountLevel,
            now: now
        ) == nil
    }

    var isWithinSchedule: Bool {
        (startsAt.map { Date.now >= $0 } ?? true)
            && (endsAt.map { Date.now < $0 } ?? true)
    }

    func layout(for enemy: BattleEnemyDefinition) -> BattleLayoutConfiguration {
        var result = BattleLayoutConfiguration(
            title: LocalizedStringResource(stringLiteral: title),
            accent: appearance.accent,
            objective: LocalizedStringResource(stringLiteral: subtitle)
        )

        result.appearance = appearance
        result.opponentPortrait = enemy.portraitAsset

        return result
    }
}

struct BattleLaunch: Identifiable {
    let id = UUID()
    let mode: BattleMode

    let definition: BattleEventDefinition
    let enemy: BattleEnemyDefinition
    let opponentDeck: [BattleCard]
    var character: BattleCharacterDefinition? = nil

    var layout: BattleLayoutConfiguration {
        var result = definition.layout(for: enemy)
        result.playerPortrait = character?.portraitAsset
        return result
    }
}

struct BattleRewardLabel: View {
    let rewards: BattleRewards

    var body: some View {
        Text(rewards.summary)
            .font(.caption.monospaced())
            .foregroundStyle(.white.opacity(0.85))
    }
}
