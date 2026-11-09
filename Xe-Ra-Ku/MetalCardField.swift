//
//  MetalCardField.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import SwiftUI

struct MetalCardField: View {

    let playerCards: [BattleCard?]
    let opponentCards: [BattleCard?]
    let namespace: Namespace.ID

    var onCardSelected: (BattleCard) -> Void = { _ in }
    var onFieldSelected: (Int) -> Void = { _ in }

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width - 24, 440.0)
            let cardWidth = (width - 32) / 5

            ZStack {
                // Gegner: weiter entfernt, kleinere Karten.
                cardRow(
                    opponentCards,
                    cardWidth: cardWidth * 0.78,
                    isOpponent: true
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height * 0.34
                )

                // Spieler: näher an der Kamera.
                cardRow(
                    playerCards,
                    cardWidth: cardWidth,
                    isOpponent: false
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height * 0.67
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
    }

    private func cardRow(
        _ cards: [BattleCard?],
        cardWidth: CGFloat,
        isOpponent: Bool
    ) -> some View {
        HStack(spacing: 6) {
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]

                Button {
                    if let card {
                        onCardSelected(card)
                    } else if !isOpponent {
                        onFieldSelected(index)
                    }
                } label: {
                    cardContent(card)
                        .frame(
                            width: cardWidth,
                            height: cardWidth / 0.72
                        )
                        .rotation3DEffect(
                            .degrees(48),
                            axis: (x: 1, y: 0, z: 0),
                            perspective: 0.4
                        )
                        .modifier(
                            MetalCardMatchModifier(
                                cardID: card?.id,
                                namespace: namespace,
                                enabled: !isOpponent
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(card == nil && isOpponent)
            }
        }
    }

    private func cardContent(_ card: BattleCard?) -> some View {
        BattleCardView(card: card)
    }
}

private struct MetalCardMatchModifier: ViewModifier {

    let cardID: UUID?
    let namespace: Namespace.ID
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled, let cardID {
            content.matchedGeometryEffect(
                id: cardID,
                in: namespace
            )
        } else {
            content
        }
    }
}
