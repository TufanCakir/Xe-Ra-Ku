//
//  BattleScene.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import SwiftUI

// MARK: - Models

struct BattleCard: Identifiable, Hashable {
    let id: UUID
    var name: String
    var element: BattleElement
    var attack: Int
    var defense: Int

    init(
        id: UUID = UUID(),
        name: String,
        element: BattleElement = .fire,
        attack: Int = 0,
        defense: Int = 0
    ) {
        self.id = id
        self.name = name
        self.element = element
        self.attack = attack
        self.defense = defense
    }
}

struct BattlePlayer: Identifiable {
    let id: String
    var name: String
    var lifePoints: Int
    var maxLifePoints: Int

    init(
        id: String,
        name: String,
        lifePoints: Int = 4000,
        maxLifePoints: Int = 4000
    ) {
        self.id = id
        self.name = name
        self.lifePoints = lifePoints
        self.maxLifePoints = maxLifePoints
    }
}

enum BattlePhase: String, CaseIterable {
    case draw = "DRAW"
    case main = "MAIN"
    case battle = "BATTLE"
    case end = "END"
}

struct BattleSceneState {
    var player: BattlePlayer
    var opponent: BattlePlayer
    var playerField: [BattleCard?]
    var opponentField: [BattleCard?]
    var opponentHand: [BattleCard]
    var hand: [BattleCard]
    var turn: Int
    var phase: BattlePhase
    var attackingCardID: UUID?
    var attackedCardIDs: Set<UUID>
    var battleMessage: String

    init(
        player: BattlePlayer,
        opponent: BattlePlayer,
        playerField: [BattleCard?] = Array(repeating: nil, count: 5),
        opponentField: [BattleCard?] = Array(repeating: nil, count: 5),
        opponentHand: [BattleCard] = [],
        hand: [BattleCard] = [],
        turn: Int = 1,
        phase: BattlePhase = .main,
        attackingCardID: UUID? = nil,
        attackedCardIDs: Set<UUID> = [],
        battleMessage: String = "WÄHLE EINE KARTE"
    ) {
        self.player = player
        self.opponent = opponent
        self.playerField = playerField
        self.opponentField = opponentField
        self.opponentHand = opponentHand
        self.hand = hand
        self.turn = turn
        self.phase = phase
        self.attackingCardID = attackingCardID
        self.attackedCardIDs = attackedCardIDs
        self.battleMessage = battleMessage
    }
}

// MARK: - Battle Screen

struct BattleScene: View {
    let state: BattleSceneState
    var onCardSelected: (BattleCard) -> Void = { _ in }
    var onFieldSelected: (Int) -> Void = { _ in }
    var onEndTurn: () -> Void = {}
    var onDirectAttack: () -> Void = {}

    @Namespace private var cardNamespace

    private var isGameOver: Bool {
        state.player.lifePoints <= 0 || state.opponent.lifePoints <= 0
    }

    private var canDirectAttack: Bool {
        !isGameOver && state.attackingCardID != nil
            && state.opponentField.allSatisfy { $0 == nil }
    }

    var body: some View {
        ZStack {
            BattleFieldMetalView(intensity: 1.0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 8) {
                header
                messageBar

                Button(action: onDirectAttack) {
                    playerStatus(state.opponent, isOpponent: true)
                }
                .buttonStyle(.plain)
                .disabled(!canDirectAttack)
                .accessibilityHint(
                    canDirectAttack
                        ? "Direkt angreifen" : "Direkter Angriff nicht möglich"
                )

                opponentHandRow

                MetalCardField(
                    playerCards: state.playerField,
                    opponentCards: state.opponentField,
                    namespace: cardNamespace,
                    onCardSelected: onCardSelected,
                    onFieldSelected: onFieldSelected
                )
                .frame(maxHeight: .infinity)

                playerStatus(state.player, isOpponent: false)
                playerHandRow
                endTurnButton
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack {
            Text("TURN \(state.turn)")
                .foregroundStyle(.blue)
            Spacer()
            Text(state.phase.rawValue)
                .foregroundStyle(.white.opacity(0.8))
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
    }

    private var messageBar: some View {
        Text(state.battleMessage)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.blue)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.horizontal, 8)
            .background(
                .black.opacity(0.55),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.blue, lineWidth: 1)
            }
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: state.battleMessage)
    }

    private func playerStatus(_ player: BattlePlayer, isOpponent: Bool)
        -> some View
    {
        let tint: Color = isOpponent ? .red : .blue
        let fraction =
            player.maxLifePoints > 0
            ? min(
                1,
                max(
                    0,
                    CGFloat(player.lifePoints) / CGFloat(player.maxLifePoints)
                )
            )
            : 0

        return VStack(spacing: 5) {
            HStack {
                Text(player.name)
                    .font(
                        .system(size: 12, weight: .black, design: .monospaced)
                    )
                Spacer()
                Text("\(player.lifePoints) / \(player.maxLifePoints) LP")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(tint)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.5), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * fraction)
                }
            }
            .frame(height: 5)
        }
        .padding(9)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    tint.opacity(isOpponent && canDirectAttack ? 1 : 0.35),
                    lineWidth: 1
                )
        }
        .animation(.easeInOut(duration: 0.3), value: player.lifePoints)
        .accessibilityElement(children: .combine)
    }

    private var opponentHandRow: some View {
        VStack(spacing: 3) {
            HStack {
                Text("GEGNERHAND")
                Spacer()
                Text("\(state.opponentHand.count) KARTEN")
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.65))

            HStack(spacing: 5) {
                ForEach(state.opponentHand) { card in
                    BattleCardBackView()
                        .frame(maxWidth: 58)
                        .accessibilityLabel("Verdeckte Gegnerkarte")
                        .id(card.id)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
    }

    private var playerHandRow: some View {
        HStack(spacing: 6) {
            ForEach(state.hand) { card in
                Button {
                    onCardSelected(card)
                } label: {
                    BattleCardView(card: card)
                        .matchedGeometryEffect(
                            id: card.id,
                            in: cardNamespace,
                            properties: .frame,
                            anchor: .center,
                            isSource: true
                        )
                }
                .buttonStyle(.plain)
                .disabled(isGameOver)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 98)
    }

    private var endTurnButton: some View {
        Button(action: onEndTurn) {
            Text(isGameOver ? "DUELL BEENDET" : "ZUG BEENDEN")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .tracking(1.5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    TechLogoFrame().fill(
                        LinearGradient(
                            colors: [.black, .blue, .black],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .overlay {
                    TechLogoFrame().stroke(.blue, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
        .disabled(isGameOver)
        .opacity(isGameOver ? 0.5 : 1)
    }
}

// MARK: - Hidden Opponent Card

private struct BattleCardBackView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.02, green: 0.05, blue: 0.12),
                            Color(red: 0.08, green: 0.24, blue: 0.5),
                            Color(red: 0.02, green: 0.05, blue: 0.12),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(.blue, lineWidth: 1)
            Text("XRK")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
        }
        .aspectRatio(0.72, contentMode: .fit)
    }
}

// MARK: - Element Card

struct BattleCardView: View {
    let card: BattleCard?
    var isOpponent: Bool = false

    private var cardGradient: LinearGradient {
        card?.element.gradient
            ?? LinearGradient(
                colors: [.black, .gray.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(cardGradient)
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    card?.element.color.opacity(0.9) ?? .blue,
                    lineWidth: 2
                )

            if let card {
                VStack(spacing: 3) {
                    Text(card.element.title)
                        .font(
                            .system(
                                size: 7,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 2)
                    Text(card.name.uppercased())
                        .font(
                            .system(
                                size: 10,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                    Spacer(minLength: 2)
                    Text("ATK \(card.attack)")
                    Text("DEF \(card.defense)")
                }
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(card.element.foregroundColor)
                .padding(5)
            } else {
                Text("+")
                    .font(
                        .system(size: 18, weight: .light, design: .monospaced)
                    )
                    .foregroundStyle(.blue)
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(
            card.map {
                "\($0.name), \($0.element.title), Angriff \($0.attack), Verteidigung \($0.defense)"
            } ?? "Leerer Kartenplatz"
        )
    }
}

#Preview {
    OnlineBattleView()
}
