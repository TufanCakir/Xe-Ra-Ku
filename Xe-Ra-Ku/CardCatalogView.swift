//
//  CardCatalogView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct CardCatalogView: View {
    @State private var catalog: CardCatalog?
    @State private var errorMessage: String?
    @State private var selectedCategory = "all"
    @State private var isLoading = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Theme

    private var style: CyberNavigationStyle {
        MenuTab.cards.style
    }

    private var accent: Color {
        style.accent
    }

    private var surface: Color {
        style.background
    }

    private var selectionAnimation: Animation? {
        reduceMotion
            ? nil
            : .easeInOut(duration: 0.2)
    }

    // MARK: - Data

    private var categories: [String] {
        guard let catalog else {
            return ["all"]
        }

        let elements = Set(
            catalog.cards.map {
                $0.element.lowercased()
            }
        )

        return ["all"] + elements.sorted()
    }

    private var filteredCards: [BattleCard] {
        guard let catalog else {
            return []
        }

        return catalog.cards.compactMap { definition in
            let element = definition.element.lowercased()

            guard
                selectedCategory == "all"
                    || element == selectedCategory
            else {
                return nil
            }

            return try? definition.battleCard()
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading && catalog == nil {
                loadingContent
            } else if let errorMessage {
                errorContent(errorMessage)
            } else if catalog != nil {
                catalogContent
            } else {
                loadingContent
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .task {
            if catalog == nil && !isLoading {
                loadCards()
            }
        }
    }

    // MARK: - Catalog

    private var catalogContent: some View {
        VStack(spacing: 0) {
            catalogHeader

            categoryPicker

            Rectangle()
                .fill(accent.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, 12)

            CardView(cards: filteredCards)
                .id(selectedCategory)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
        .animation(
            selectionAnimation,
            value: selectedCategory
        )
    }

    // MARK: - Header

    private var catalogHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(
                    .system(
                        size: 13,
                        weight: .bold
                    )
                )
                .foregroundStyle(accent)

            Text("KARTENKATALOG")
                .font(
                    .system(
                        size: 11,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .tracking(0.8)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 6)

            if let catalog {
                Text("\(catalog.cards.count) KARTEN")
                    .font(
                        .system(
                            size: 9,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(accent)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
    }

    // MARK: - Categories

    private var categoryPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 7) {
                    ForEach(categories, id: \.self) { category in
                        categoryButton(category)
                            .id(category)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedCategory) { _, category in
                withAnimation(selectionAnimation) {
                    proxy.scrollTo(
                        category,
                        anchor: .center
                    )
                }
            }
        }
    }

    private func categoryButton(
        _ category: String
    ) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            guard selectedCategory != category else {
                return
            }

            withAnimation(selectionAnimation) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(
                            .system(
                                size: 9,
                                weight: .black
                            )
                        )
                }

                Text(categoryTitle(category))
                    .lineLimit(1)
            }
            .font(
                .system(
                    size: 9,
                    weight: .black,
                    design: .monospaced
                )
            )
            .foregroundStyle(
                isSelected
                    ? surface
                    : .white.opacity(0.8)
            )
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background {
                CyberPanelShape(cut: 8)
                    .fill(
                        isSelected
                            ? accent
                            : surface.opacity(0.88)
                    )
            }
            .overlay {
                CyberPanelShape(cut: 8)
                    .strokeBorder(
                        accent.opacity(
                            isSelected ? 1 : 0.4
                        ),
                        lineWidth: 1
                    )
            }
            .contentShape(
                CyberPanelShape(cut: 8)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(categoryTitle(category))
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    // MARK: - Loading

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(accent)

            Text("KARTEN WERDEN GELADEN")
                .font(
                    .system(
                        size: 10,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .foregroundStyle(accent)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Error

    private func errorContent(
        _ message: String
    ) -> some View {
        ContentUnavailableView {
            Label(
                "KARTEN NICHT VERFÜGBAR",
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(message)
        } actions: {
            Button("ERNEUT LADEN") {
                loadCards()
            }
            .tint(accent)
            .disabled(isLoading)
        }
    }

    // MARK: - Category Titles

    private func categoryTitle(
        _ category: String
    ) -> String {
        switch category {
        case "all": "ALLE"
        case "fire": "FEUER"
        case "water": "WASSER"
        case "shadow": "SCHATTEN"
        case "holy": "HEILIG"
        case "void": "LEERE"
        case "plant": "PFLANZEN"
        case "earth": "ERDE"
        case "light": "LICHT"
        case "stone": "STEIN"
        case "grass": "GRAS"
        case "lust": "LUST"
        default: category.uppercased()
        }
    }

    // MARK: - Loading Data

    private func loadCards() {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let loadedCatalog = try CardCatalogService()
                .loadBundled()

            catalog = loadedCatalog

            let availableCategories = Set(
                loadedCatalog.cards.map {
                    $0.element.lowercased()
                }
            )

            if selectedCategory != "all"
                && !availableCategories.contains(selectedCategory)
            {
                selectedCategory = "all"
            }
        } catch {
            catalog = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    CardCatalogView()
        .preferredColorScheme(.dark)
}
