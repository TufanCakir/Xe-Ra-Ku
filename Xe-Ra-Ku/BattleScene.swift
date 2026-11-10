//
//  BattleScene.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import SwiftUI

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

// MARK: - Reusable Battle Screen

struct BattleScene: View {
    let state: BattleSceneState
    var onCardSelected: (BattleCard) -> Void = { _ in }
    var onFieldSelected: (Int) -> Void = { _ in }
    var onEndTurn: () -> Void = {}
    var onDirectAttack: () -> Void = {}
    var onExit: () -> Void = {}
    var onToggleAuto: () -> Void = {}
    var onCycleSpeed: () -> Void = {}
    var autoMode = false
    var battleSpeed = 1.0
    var isOpponentTurn = false
    var configuration: BattleLayoutConfiguration = .standard
    var selectedCardID: UUID?

    @Namespace private var cardNamespace

    private var isGameOver: Bool {
        state.player.lifePoints <= 0 || state.opponent.lifePoints <= 0
    }

    private var canDirectAttack: Bool {
        !isGameOver && !isOpponentTurn && state.attackingCardID != nil
            && state.opponentField.allSatisfy { $0 == nil }
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 600
            ZStack {
                BattleFieldMetalView(
                    intensity: Float(
                        configuration.appearance?.shaderIntensity ?? 1
                    )
                )
                .hueRotation(.degrees(configuration.appearance?.shaderHue ?? 0))
                .ignoresSafeArea()
                .allowsHitTesting(false)
                LinearGradient(
                    colors: [
                        (configuration.appearance?.top ?? .black).opacity(0.65),
                        .clear,
                        (configuration.appearance?.bottom ?? .black).opacity(
                            0.75
                        ),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: compact ? 4 : 10) {
                    BattleTopBar(
                        player: state.opponent,
                        turn: state.turn,
                        phase: state.phase,
                        isOpponentTurn: isOpponentTurn,
                        configuration: configuration,
                        onExit: onExit
                    )
                    BattleOpponentHand(cards: state.opponentHand)
                        .frame(height: compact ? 26 : 40)

                    MetalCardField(
                        playerCards: state.playerField,
                        opponentCards: state.opponentField,
                        namespace: cardNamespace,
                        onCardSelected: onCardSelected,
                        onFieldSelected: onFieldSelected,
                        accent: configuration.accent,
                        attackingCardID: state.attackingCardID,
                        attackedCardIDs: state.attackedCardIDs,
                        canPlaceCard: selectedCardID != nil
                    )
                    .disabled(isOpponentTurn || isGameOver)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    BattleMessageBanner(
                        message: state.battleMessage,
                        accent: configuration.accent
                    )

                    HStack(alignment: .bottom, spacing: 10) {
                        CyberBattlePlaybackControls(
                            autoMode: autoMode,
                            speed: battleSpeed,
                            accent: configuration.accent,
                            onToggleAuto: onToggleAuto,
                            onCycleSpeed: onCycleSpeed
                        )
                        .disabled(isGameOver)
                        Spacer(minLength: 0)
                        BattleDuelistHUD(
                            player: state.player,
                            accent: configuration.accent,
                            portraitName: configuration.playerPortrait
                        )
                        .frame(maxWidth: 230)
                    }

                    BattleHandView(
                        cards: state.hand,
                        selectedCardID: selectedCardID,
                        namespace: cardNamespace,
                        onSelect: onCardSelected
                    )
                    .frame(height: compact ? 76 : 112)
                    .disabled(isOpponentTurn || isGameOver)

                    BattleActionBar(
                        canDirectAttack: canDirectAttack,
                        isDisabled: isOpponentTurn || isGameOver,
                        isOpponentTurn: isOpponentTurn,
                        accent: configuration.accent,
                        onDirectAttack: onDirectAttack,
                        onEndTurn: onEndTurn
                    )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Hidden Opponent Card

struct BattleCardBackView: View {
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
                .strokeBorder(.cyan.opacity(0.75), lineWidth: 1)
            Text("XRK")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(.cyan)
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
                    card?.element.color.opacity(0.9) ?? .cyan.opacity(0.35),
                    lineWidth: 1.5
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
                    Image(systemName: card.element.symbol)
                        .font(.system(size: 22, weight: .semibold))
                        .shadow(color: .black.opacity(0.4), radius: 4)
                        .accessibilityHidden(true)
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
                    .foregroundStyle(.cyan.opacity(0.6))
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

#Preview("Event Layout") {
    BattleScene(
        state: BattleSceneState(
            player: BattlePlayer(id: "player", name: "DU"),
            opponent: BattlePlayer(
                id: "boss",
                name: "EVENT BOSS",
                lifePoints: 8000,
                maxLifePoints: 8000
            ),
            playerField: [
                BattleCard(
                    name: "NOVA",
                    element: .fire,
                    attack: 1800,
                    defense: 1200
                ),
                nil, nil, nil, nil,
            ],
            opponentField: [
                nil, nil,
                BattleCard(
                    name: "ABYSS",
                    element: .void,
                    attack: 2800,
                    defense: 1400
                ),
                nil, nil,
            ],
            hand: [
                BattleCard(
                    name: "SERAPH",
                    element: .holy,
                    attack: 2500,
                    defense: 1800
                ),
                BattleCard(
                    name: "CYBER",
                    element: .water,
                    attack: 2200,
                    defense: 1500
                ),
            ]
        ),
        configuration: .event
    )
    .preferredColorScheme(.dark)
}
