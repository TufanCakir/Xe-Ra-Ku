//
//  BattleLayoutComponents.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

enum BattleMode {
    case duel
    case event

    var accent: Color {
        switch self {
        case .duel: CyberTheme.duel
        case .event: CyberTheme.event
        }
    }

    var background: Color {
        switch self {
        case .duel: CyberTheme.duelBackground
        case .event: CyberTheme.eventBackground
        }
    }
}

struct BattleLayoutConfiguration {
    var mode: BattleMode = .duel
    var title: LocalizedStringResource
    var accent: Color
    var objective: LocalizedStringResource?
    var playerPortrait: String?
    var appearance: BattleAppearance?
    var opponentPortrait: String?
    static let standard = Self(title: "DUELL", accent: .cyan)
    static let event = Self(
        title: "EVENT",
        accent: .orange,
        objective: "Besiege den Event-Gegner"
    )
}

struct BattleTopBar: View {
    let player: BattlePlayer
    let turn: Int
    let phase: BattlePhase
    let isOpponentTurn: Bool
    let configuration: BattleLayoutConfiguration
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                BattleDuelistHUD(
                    player: player,
                    accent: configuration.accent,
                    portraitName: configuration.opponentPortrait
                )
                .frame(maxWidth: .infinity)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(configuration.title).foregroundStyle(
                        configuration.accent
                    )
                    Text("ZUG \(turn)")
                    Text(isOpponentTurn ? "GEGNER AM ZUG" : "DEIN ZUG")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .fixedSize(horizontal: true, vertical: false)
                CyberBattleControlButton(
                    title: "EXIT",
                    symbol: "rectangle.portrait.and.arrow.right",
                    isDestructive: true,
                    action: onExit
                )
                .accessibilityLabel("Duell verlassen")
                .padding(.horizontal)
            }
            HStack(spacing: 8) {
                Rectangle().frame(height: 1)
                Text("\(phase.rawValue) PHASE").fixedSize()
                Rectangle().frame(height: 1)
            }
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .foregroundStyle(configuration.accent)
            if let objective = configuration.objective {
                Text(objective).font(.caption).foregroundStyle(
                    .white.opacity(0.8)
                )
            }
        }
        .buttonStyle(.plain)
    }
}

struct BattleDuelistHUD: View {
    let player: BattlePlayer
    let accent: Color
    var portraitName: String? = nil

    private var fraction: CGFloat {
        guard player.maxLifePoints > 0 else { return 0 }
        return CGFloat(
            min(
                1,
                max(0, Double(player.lifePoints) / Double(player.maxLifePoints))
            )
        )
    }

    var body: some View {
        HStack(spacing: 7) {
            Group {
                if let portraitName {
                    Image(portraitName)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFill()
                        .frame(width: 40, height: 44)
                        .clipped()
                } else {
                    Image(systemName: "person.crop.square.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(accent)
                }
            }
            .frame(width: 40, height: 44)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name).font(
                    .system(size: 10, weight: .heavy, design: .monospaced)
                ).lineLimit(1)
                Text("LP \(player.lifePoints)")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1).minimumScaleFactor(0.65)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.16))
                        Capsule().fill(accent).frame(
                            width: geo.size.width * fraction
                        )
                    }
                }.frame(height: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(7)
        .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10).strokeBorder(accent.opacity(0.7))
        )
        .animation(.easeOut(duration: 0.22), value: player.lifePoints)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(player.name), \(player.lifePoints) von \(player.maxLifePoints) Lebenspunkten"
        )
    }
}

struct BattleOpponentHand: View {
    let cards: [BattleCard]
    var body: some View {
        HStack(spacing: -7) {
            ForEach(cards) { _ in
                BattleCardBackView().frame(width: 38, height: 53)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cards.count) verdeckte Gegnerkarten")
    }
}

struct BattleMessageBanner: View {
    let message: String
    let accent: Color
    var body: some View {
        Text(message)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.horizontal, 10)
            .background(
                .black.opacity(0.75),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3)
            }
    }
}

struct BattlePlaybackControls: View {
    let autoMode: Bool
    let speed: Double
    let onToggleAuto: () -> Void
    let onCycleSpeed: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            CyberBattleControlButton(
                title: "AUTO",
                symbol: "arrow.triangle.2.circlepath",
                isActive: autoMode,
                action: onToggleAuto
            )
            .accessibilityLabel(
                autoMode ? "Auto ausschalten" : "Auto einschalten"
            )

            CyberBattleControlButton(
                title:
                    "\(speed.formatted(.number.precision(.fractionLength(0...1))))×",
                symbol: "forward.end.fill",
                action: onCycleSpeed
            )
            .accessibilityLabel("Geschwindigkeit ändern")
        }
        .buttonStyle(.plain)
    }
}

struct BattleHandView: View {
    let cards: [BattleCard]
    let selectedCardID: UUID?
    let namespace: Namespace.ID
    let onSelect: (BattleCard) -> Void
    var body: some View {
        HStack(spacing: 5) {
            ForEach(cards) { card in
                Button {
                    onSelect(card)
                } label: {
                    BattleCardView(card: card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    selectedCardID == card.id ? .white : .clear,
                                    lineWidth: 2
                                )
                        )
                        .offset(y: selectedCardID == card.id ? -5 : 0)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(
                    selectedCardID == card.id ? .isSelected : []
                )
            }
        }
        .animation(.easeOut(duration: 0.15), value: selectedCardID)
    }
}

struct BattleActionBar: View {
    let canDirectAttack: Bool
    let isDisabled: Bool
    let isOpponentTurn: Bool
    let accent: Color
    let onDirectAttack: () -> Void
    let onEndTurn: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if canDirectAttack {
                CyberBattleControlButton(
                    title: "ANGRIFF",
                    symbol: "bolt.fill",
                    color: .orange,
                    fillsWidth: true,
                    action: onDirectAttack
                )
                .disabled(isDisabled)
            }

            CyberBattleControlButton(
                title: isOpponentTurn
                    ? "GEGNER AM ZUG"
                    : "ZUG BEENDEN",
                symbol: isOpponentTurn
                    ? "hourglass"
                    : "arrow.right.to.line",
                color: accent,
                fillsWidth: true,
                action: onEndTurn
            )
            .disabled(isDisabled)
        }
        .opacity(isDisabled ? 0.55 : 1)
    }
}

private func actionButton(
    _ title: String,
    symbol: String,
    color: Color,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .black))

            Text(title)
                .font(
                    .system(
                        size: 11,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.cyan)
        .frame(maxWidth: .infinity, minHeight: 46)
        .padding(.horizontal, 8)
        .background {
            CyberPanelShape(cut: 12)
                .fill(CyberTheme.navy.opacity(0.92))
        }
        .overlay {
            CyberPanelShape(cut: 12)
                .stroke(color.opacity(0.85), lineWidth: 1.5)
        }
    }
    .buttonStyle(.plain)
}

#Preview {
    OnlineBattleView()
}
