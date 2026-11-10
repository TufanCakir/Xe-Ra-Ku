//
//  MetalCardField.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct MetalCardField: View {
    let playerCards: [BattleCard?]
    let opponentCards: [BattleCard?]
    let namespace: Namespace.ID
    var onCardSelected: (BattleCard) -> Void = { _ in }
    var onFieldSelected: (Int) -> Void = { _ in }
    var accent: Color = .cyan
    var attackingCardID: UUID?
    var attackedCardIDs: Set<UUID> = []
    var canPlaceCard = false

    var body: some View {
        GeometryReader { geometry in
            let count = max(1, max(playerCards.count, opponentCards.count))
            let width = min(geometry.size.width * 0.92, 620)
            let cardWidth = max(
                1,
                (width - CGFloat(count - 1) * 8) / CGFloat(count)
            )
            ZStack {
                // One projected plane keeps every zone on the same vanishing point.
                VStack(spacing: 20) {
                    BattleFieldRow(
                        cards: opponentCards,
                        cardWidth: cardWidth,
                        isOpponent: true,
                        accent: .pink,
                        namespace: namespace,
                        attackingCardID: nil,
                        attackedCardIDs: [],
                        canPlaceCard: false,
                        onCardSelected: onCardSelected,
                        onFieldSelected: onFieldSelected
                    )

                    HStack {
                        Rectangle().frame(height: 1)
                        Text("XE • RA • KU")
                            .font(
                                .system(
                                    .caption,
                                    design: .monospaced,
                                    weight: .black
                                )
                            )
                            .tracking(4)
                            .fixedSize()
                        Rectangle().frame(height: 1)
                    }
                    .foregroundStyle(accent.opacity(0.8))

                    BattleFieldRow(
                        cards: playerCards,
                        cardWidth: cardWidth,
                        isOpponent: false,
                        accent: accent,
                        namespace: namespace,
                        attackingCardID: attackingCardID,
                        attackedCardIDs: attackedCardIDs,
                        canPlaceCard: canPlaceCard,
                        onCardSelected: onCardSelected,
                        onFieldSelected: onFieldSelected
                    )
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.12))
                        .stroke(accent.opacity(0.25), lineWidth: 1)
                }
                .rotation3DEffect(
                    .degrees(36),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.35
                )
                .rotationEffect(.degrees(-5))
                .scaleEffect(
                    min(
                        1,
                        geometry.size.height / max(1, cardWidth / 0.72 * 2 + 80)
                    )
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
            }
        }
    }
}

private struct BattleFieldRow: View {
    let cards: [BattleCard?]
    let cardWidth: CGFloat
    let isOpponent: Bool
    let accent: Color
    let namespace: Namespace.ID
    let attackingCardID: UUID?
    let attackedCardIDs: Set<UUID>
    let canPlaceCard: Bool
    let onCardSelected: (BattleCard) -> Void
    let onFieldSelected: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Slot indices are stable identities: replacing a card does not replace its zone.
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]
                Button {
                    if let card {
                        onCardSelected(card)
                    } else {
                        onFieldSelected(index)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.black.opacity(0.25))
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                accent.opacity(
                                    card == nil && canPlaceCard ? 1 : 0.45
                                ),
                                lineWidth: card == nil && canPlaceCard ? 2 : 1
                            )
                        if let card {
                            BattleCardView(card: card)
                                .matchedGeometryEffect(
                                    id: card.id,
                                    in: namespace
                                )
                                .opacity(
                                    attackedCardIDs.contains(card.id) ? 0.5 : 1
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            attackingCardID == card.id
                                                ? .yellow : .clear,
                                            lineWidth: 3
                                        )
                                }
                                .shadow(
                                    color: card.element.color.opacity(0.65),
                                    radius: 10
                                )
                        } else {
                            VStack(spacing: 6) {
                                Image(
                                    systemName: canPlaceCard
                                        ? "plus.circle" : "square.dashed"
                                )
                                .font(.title3)
                                Text("\(index + 1)").font(
                                    .caption2.monospaced()
                                )
                            }
                            .foregroundStyle(accent.opacity(0.6))
                        }
                    }
                    .frame(width: cardWidth, height: cardWidth / 0.72)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(card == nil && (isOpponent || !canPlaceCard))
                .accessibilityLabel(
                    card.map {
                        "\($0.name), Angriff \($0.attack), Verteidigung \($0.defense)"
                    }
                        ?? "Freier Platz \(index + 1)"
                )
            }
        }
    }
}
