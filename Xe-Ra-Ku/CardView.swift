//
//  CardView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 10.11.26.
//

import SwiftUI

struct CardView: View {
    let cards: [BattleCard]

    @State private var searchText = ""
    @State private var selectedCard: BattleCard?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @FocusState private var searchFocused: Bool

    private var style: CyberNavigationStyle {
        MenuTab.cards.style
    }

    private var accent: Color {
        style.accent
    }

    private var surface: Color {
        style.background
    }

    private let columns = [
        GridItem(
            .adaptive(minimum: 95, maximum: 145),
            spacing: 8
        )
    ]

    private var filteredCards: [BattleCard] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return cards
        }

        return cards.filter { card in
            card.name.localizedStandardContains(query)
                || card.element.title.localizedStandardContains(query)
        }
    }

    private var overlayAnimation: Animation? {
        reduceMotion
            ? nil
            : .spring(
                response: 0.32,
                dampingFraction: 0.86
            )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            searchBar
            collectionHeader
            cardGrid
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .foregroundStyle(.white)
        .overlay {
            if let selectedCard {
                cardDetailOverlay(selectedCard)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(
                                with: .scale(scale: 0.96)
                            )
                    )
                    .zIndex(10)
            }
        }
        .animation(overlayAnimation, value: selectedCard?.id)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent)

            TextField("Karte suchen", text: $searchText)
                .font(
                    .system(
                        size: 12,
                        weight: .medium,
                        design: .monospaced
                    )
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Suche löschen")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background {
            CyberPanelShape(cut: 9)
                .fill(surface.opacity(0.9))
        }
        .overlay {
            CyberPanelShape(cut: 9)
                .strokeBorder(
                    accent.opacity(searchFocused ? 0.9 : 0.45),
                    lineWidth: 1
                )
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    // MARK: - Collection Header

    private var collectionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(accent)

            Text("// SAMMLUNG")
                .foregroundStyle(accent)

            Spacer(minLength: 4)

            Text("\(filteredCards.count) / \(cards.count)")
                .foregroundStyle(.white.opacity(0.65))
                .monospacedDigit()
        }
        .font(
            .system(
                size: 10,
                weight: .bold,
                design: .monospaced
            )
        )
        .padding(.horizontal, 14)
    }

    // MARK: - Card Grid

    private var cardGrid: some View {
        ScrollView {
            if filteredCards.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 36)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredCards) { card in
                        Button {
                            openCard(card)
                        } label: {
                            collectionCard(card)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "\(card.name), \(card.element.title), Angriff \(card.attack), Verteidigung \(card.defense)"
                        )
                        .accessibilityHint("Kartendetails öffnen")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Collection Card

    private func collectionCard(
        _ card: BattleCard
    ) -> some View {
        VStack(spacing: 6) {
            BattleCardView(card: card)
                .aspectRatio(0.72, contentMode: .fit)

            Text(card.name.uppercased())
                .font(
                    .system(
                        size: 9,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            HStack(spacing: 4) {
                Text("A \(card.attack)")

                Spacer(minLength: 0)

                Text("D \(card.defense)")
            }
            .font(
                .system(
                    size: 8,
                    weight: .bold,
                    design: .monospaced
                )
            )
            .foregroundStyle(.white.opacity(0.75))
            .lineLimit(1)
            .minimumScaleFactor(0.55)
        }
        .padding(7)
        .frame(maxWidth: .infinity)
        .background {
            CyberPanelShape(cut: 10)
                .fill(surface.opacity(0.92))
        }
        .overlay {
            CyberPanelShape(cut: 10)
                .strokeBorder(
                    card.element.color.opacity(0.65),
                    lineWidth: 1
                )
        }
        .contentShape(CyberPanelShape(cut: 10))
    }

    // MARK: - Card Detail Overlay

    private func cardDetailOverlay(
        _ card: BattleCard
    ) -> some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 500
            let tint = card.element.color

            ZStack {
                Color.black.opacity(0.88)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        closeCard()
                    }

                detailPanel(
                    card,
                    tint: tint,
                    compact: compact
                )
                .frame(maxWidth: 340)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .padding(.horizontal, 16)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
    }

    // MARK: - Detail Panel

    private func detailPanel(
        _ card: BattleCard,
        tint: Color,
        compact: Bool
    ) -> some View {
        VStack(spacing: compact ? 8 : 12) {
            detailHeader(tint: tint)

            Rectangle()
                .fill(tint.opacity(0.4))
                .frame(height: 1)

            Text(card.name.uppercased())
                .font(
                    .system(
                        size: 16,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            BattleCardView(card: card)
                .frame(
                    width: compact ? 125 : 170,
                    height: compact ? 175 : 235
                )

            HStack(spacing: 7) {
                stat(
                    "ELEMENT",
                    value: card.element.title.uppercased(),
                    color: tint
                )

                stat(
                    "ATK",
                    value: "\(card.attack)",
                    color: tint
                )

                stat(
                    "DEF",
                    value: "\(card.defense)",
                    color: tint
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(tint)

                Text("KARTENINFORMATION")
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Text("XE-RA-KU")
                    .foregroundStyle(tint)
            }
            .font(
                .system(
                    size: 8,
                    weight: .bold,
                    design: .monospaced
                )
            )
        }
        .padding(compact ? 12 : 16)
        .background {
            CyberPanelShape(cut: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.15),
                            surface,
                            surface,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            CyberPanelShape(cut: 16)
                .strokeBorder(
                    tint.opacity(0.85),
                    lineWidth: 1.5
                )
        }
    }

    // MARK: - Detail Header

    private func detailHeader(
        tint: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(tint)

            Text("KARTEN-DATENBANK")
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Button {
                closeCard()
            } label: {
                Image(systemName: "xmark")
                    .font(
                        .system(
                            size: 12,
                            weight: .black
                        )
                    )
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background {
                        CyberPanelShape(cut: 8)
                            .fill(tint.opacity(0.12))
                    }
                    .overlay {
                        CyberPanelShape(cut: 8)
                            .strokeBorder(
                                tint.opacity(0.6),
                                lineWidth: 1
                            )
                    }
                    .contentShape(CyberPanelShape(cut: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kartendetails schließen")
        }
        .font(
            .system(
                size: 10,
                weight: .black,
                design: .monospaced
            )
        )
    }

    // MARK: - Statistics

    private func stat(
        _ title: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(
                    .system(
                        size: 9,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .foregroundStyle(color)

            Text(value)
                .font(
                    .system(
                        size: 12,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background {
            CyberPanelShape(cut: 8)
                .fill(surface.opacity(0.9))
        }
        .overlay {
            CyberPanelShape(cut: 8)
                .strokeBorder(
                    color.opacity(0.4),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Actions

    private func openCard(
        _ card: BattleCard
    ) {
        searchFocused = false

        withAnimation(overlayAnimation) {
            selectedCard = card
        }
    }

    private func closeCard() {
        withAnimation(overlayAnimation) {
            selectedCard = nil
        }
    }
}

#Preview {
    CardView(cards: [
        BattleCard(
            name: "NOVA",
            element: .fire,
            attack: 1800,
            defense: 1200
        ),
        BattleCard(
            name: "ABYSS",
            element: .void,
            attack: 2800,
            defense: 1400
        ),
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
    ])
    .preferredColorScheme(.dark)
}
