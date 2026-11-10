//
//  DeckView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 10.11.26.
//

import SwiftUI

// MARK: - Saved Deck

struct SavedDeck: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var cardIDs: [String] = []
}

// MARK: - Deck Store

@MainActor
@Observable
final class DeckStore {
    private static let storageKey = "xeraku.savedDecks.v1"

    private(set) var decks: [SavedDeck] = []

    init() {
        reload()
    }

    func reload() {
        guard
            let data = UserDefaults.standard.data(
                forKey: Self.storageKey
            ),
            let decoded = try? JSONDecoder().decode(
                [SavedDeck].self,
                from: data
            )
        else {
            decks = []
            return
        }

        decks = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(decks) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Self.storageKey
        )
    }

    @discardableResult
    func create(name: String) -> UUID? {
        let trimmed = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return nil
        }

        let deck = SavedDeck(name: trimmed)
        decks.append(deck)
        persist()

        return deck.id
    }

    func rename(_ id: UUID, to name: String) {
        guard
            let index = decks.firstIndex(
                where: { $0.id == id }
            )
        else {
            return
        }

        let trimmed = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return
        }

        decks[index].name = trimmed
        persist()
    }

    func delete(_ id: UUID) {
        decks.removeAll { $0.id == id }
        persist()
    }

    func add(
        _ cardID: String,
        to deckID: UUID,
        maxCards: Int = 20,
        maxCopies: Int = 3
    ) {
        guard
            let index = decks.firstIndex(
                where: { $0.id == deckID }
            ),
            maxCards > 0,
            maxCopies > 0,
            decks[index].cardIDs.count < maxCards
        else {
            return
        }

        let copies = decks[index].cardIDs.filter {
            $0 == cardID
        }.count

        guard copies < maxCopies else {
            return
        }

        decks[index].cardIDs.append(cardID)
        persist()
    }

    func remove(_ cardID: String, from deckID: UUID) {
        guard
            let index = decks.firstIndex(
                where: { $0.id == deckID }
            ),
            let cardIndex = decks[index].cardIDs.firstIndex(
                of: cardID
            )
        else {
            return
        }

        decks[index].cardIDs.remove(at: cardIndex)
        persist()
    }
}

// MARK: - Deck View

struct DeckView: View {
    @State private var store = DeckStore()
    @State private var catalog: CardCatalog?
    @State private var errorMessage: String?

    @State private var selectedDeckID: UUID?
    @State private var searchText = ""
    @State private var selectedElement = "all"

    @State private var showingNewDeck = false
    @State private var showingRename = false
    @State private var showingDelete = false

    @State private var newDeckName = ""
    @State private var renameText = ""
    @State private var editingDeckID: UUID?
    @State private var deletingDeckID: UUID?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @FocusState private var searchFocused: Bool

    private let maxCards = 20
    private let maxCopies = 3

    // MARK: - Theme

    private var style: CyberNavigationStyle {
        MenuTab.decks.style
    }

    private var accent: Color {
        style.accent
    }

    private var surface: Color {
        style.background
    }

    private var animation: Animation? {
        reduceMotion
            ? nil
            : .easeInOut(duration: 0.2)
    }

    // MARK: - Data

    private var selectedDeck: SavedDeck? {
        store.decks.first {
            $0.id == selectedDeckID
        }
    }

    private var definitions: [CardDefinition] {
        catalog?.cards ?? []
    }

    private var definitionLookup: [String: CardDefinition] {
        Dictionary(
            uniqueKeysWithValues: definitions.map {
                ($0.id, $0)
            }
        )
    }

    private var elements: [String] {
        ["all"]
            + Set(
                definitions.map {
                    $0.element.lowercased()
                }
            ).sorted()
    }

    private var visibleCards: [CardDefinition] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return definitions.filter { card in
            let matchesElement =
                selectedElement == "all"
                || card.element.lowercased() == selectedElement

            let matchesSearch =
                query.isEmpty || card.name.localizedStandardContains(query)

            return matchesElement && matchesSearch
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let errorMessage {
                errorContent(errorMessage)
            } else if catalog == nil {
                loadingContent
            } else {
                mainContent
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .foregroundStyle(.white)
        .task {
            if catalog == nil {
                loadCatalog()
            }
        }
        .alert(
            "NEUES DECK",
            isPresented: $showingNewDeck
        ) {
            TextField("Deckname", text: $newDeckName)

            Button("ERSTELLEN") {
                if let id = store.create(name: newDeckName) {
                    selectedDeckID = id
                }
            }

            Button("ABBRECHEN", role: .cancel) {}
        } message: {
            Text("Vergib einen Namen für dein Deck.")
        }
        .alert(
            "DECK UMBENENNEN",
            isPresented: $showingRename
        ) {
            TextField("Deckname", text: $renameText)

            Button("SPEICHERN") {
                if let editingDeckID {
                    store.rename(editingDeckID, to: renameText)
                }

                editingDeckID = nil
            }

            Button("ABBRECHEN", role: .cancel) {
                editingDeckID = nil
            }
        }
        .confirmationDialog(
            "Deck wirklich löschen?",
            isPresented: $showingDelete,
            titleVisibility: .visible
        ) {
            Button("DECK LÖSCHEN", role: .destructive) {
                deleteSelectedDeck()
            }

            Button("ABBRECHEN", role: .cancel) {}
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heading
                deckSelector

                if let deck = selectedDeck {
                    deckContents(deck)
                    collectionSection(deck)
                } else {
                    emptyDeckContent
                }
            }
            .padding(12)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Heading

    private var heading: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("// DECK SYSTEM")
                    .font(
                        .system(
                            size: 10,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(accent)

                Text("DECK-BUILDER")
                    .font(
                        .system(
                            size: 23,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 4)

            Button {
                newDeckName = "DECK \(store.decks.count + 1)"
                showingNewDeck = true
            } label: {
                Label("NEU", systemImage: "plus")
                    .font(
                        .system(
                            size: 11,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .foregroundStyle(surface)
                    .background(
                        accent,
                        in: CyberPanelShape(cut: 9)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Neues Deck erstellen")
        }
    }

    // MARK: - Deck Selector

    private var deckSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.decks) { deck in
                    deckSelectorButton(deck)
                }
            }
            .padding(.vertical, 3)
        }
        .contentMargins(.horizontal, 1)
    }

    private func deckSelectorButton(
        _ deck: SavedDeck
    ) -> some View {
        let active = selectedDeckID == deck.id

        return Button {
            withAnimation(animation) {
                selectedDeckID = deck.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(deck.name.uppercased())
                    .lineLimit(1)

                Text("\(deck.cardIDs.count)/\(maxCards)")
                    .foregroundStyle(
                        active
                            ? surface.opacity(0.75)
                            : .white.opacity(0.65)
                    )
                    .monospacedDigit()
            }
            .font(
                .system(
                    size: 10,
                    weight: .bold,
                    design: .monospaced
                )
            )
            .foregroundStyle(active ? surface : .white)
            .padding(.horizontal, 14)
            .frame(height: 55)
            .background {
                CyberPanelShape(cut: 10)
                    .fill(
                        active
                            ? accent
                            : surface.opacity(0.88)
                    )
            }
            .overlay {
                CyberPanelShape(cut: 10)
                    .strokeBorder(
                        accent.opacity(active ? 1 : 0.4),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    // MARK: - Deck Contents

    private func deckContents(
        _ deck: SavedDeck
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("// \(deck.name.uppercased())")
                    .font(
                        .system(
                            size: 12,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .lineLimit(1)

                Spacer()

                Text("\(deck.cardIDs.count)/\(maxCards)")
                    .font(
                        .system(
                            size: 12,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(accent)
                    .monospacedDigit()
            }

            ProgressView(
                value: Double(deck.cardIDs.count),
                total: Double(maxCards)
            )
            .tint(accent)

            HStack(spacing: 10) {
                Button("UMBENENNEN") {
                    editingDeckID = deck.id
                    renameText = deck.name
                    showingRename = true
                }

                Button("LÖSCHEN", role: .destructive) {
                    deletingDeckID = deck.id
                    showingDelete = true
                }
            }
            .font(
                .system(
                    size: 10,
                    weight: .bold,
                    design: .monospaced
                )
            )
            .buttonStyle(.bordered)
            .tint(accent)

            Divider()
                .overlay(accent.opacity(0.3))

            let grouped = Dictionary(
                grouping: deck.cardIDs,
                by: { $0 }
            )

            if grouped.isEmpty {
                Text("Noch keine Karten. Wähle unten Karten aus.")
                    .font(
                        .system(
                            size: 11,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.vertical, 12)
            } else {
                ForEach(grouped.keys.sorted(), id: \.self) { id in
                    deckCardRow(
                        id: id,
                        copies: grouped[id]?.count ?? 0,
                        deckID: deck.id
                    )
                }
            }
        }
        .padding(14)
        .background {
            CyberPanelShape(cut: 14)
                .fill(surface.opacity(0.9))
        }
        .overlay {
            CyberPanelShape(cut: 14)
                .strokeBorder(
                    accent.opacity(0.4),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Deck Card Row

    @ViewBuilder
    private func deckCardRow(
        id: String,
        copies: Int,
        deckID: UUID
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.portrait.fill")
                .foregroundStyle(accent)

            VStack(alignment: .leading, spacing: 4) {
                if let definition = definitionLookup[id] {
                    Text(definition.name.uppercased())
                        .fontWeight(.bold)

                    Text(
                        "ATK \(definition.attack) · DEF \(definition.defense)"
                    )
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("UNBEKANNTE KARTE")
                        .fontWeight(.bold)

                    Text(id)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer(minLength: 4)

            Text("×\(copies)")
                .foregroundStyle(accent)
                .monospacedDigit()

            Button {
                store.remove(id, from: deckID)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Karte entfernen")
        }
        .font(
            .system(
                size: 11,
                design: .monospaced
            )
        )
        .padding(.vertical, 5)
    }

    // MARK: - Collection

    private func collectionSection(
        _ deck: SavedDeck
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("// KARTEN HINZUFÜGEN")
                .font(
                    .system(
                        size: 12,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .foregroundStyle(accent)

            searchBar
            elementPicker

            if visibleCards.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: 125),
                            spacing: 10
                        )
                    ],
                    spacing: 12
                ) {
                    ForEach(visibleCards) { definition in
                        collectionCard(
                            definition,
                            deck: deck
                        )
                    }
                }
            }
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(accent)

            TextField("Karten suchen …", text: $searchText)
                .font(
                    .system(
                        size: 12,
                        design: .monospaced
                    )
                )
                .focused($searchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Suche löschen")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(
            surface.opacity(0.9),
            in: CyberPanelShape(cut: 9)
        )
        .overlay {
            CyberPanelShape(cut: 9)
                .strokeBorder(
                    accent.opacity(searchFocused ? 0.9 : 0.4),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Element Picker

    private var elementPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(elements, id: \.self) { element in
                    elementButton(element)
                }
            }
        }
    }

    private func elementButton(
        _ element: String
    ) -> some View {
        let active = selectedElement == element

        return Button {
            selectedElement = element
        } label: {
            Text(
                element == "all"
                    ? "ALLE"
                    : element.uppercased()
            )
            .font(
                .system(
                    size: 9,
                    weight: .bold,
                    design: .monospaced
                )
            )
            .foregroundStyle(active ? surface : .white)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                active
                    ? accent
                    : surface.opacity(0.88),
                in: CyberPanelShape(cut: 8)
            )
            .overlay {
                CyberPanelShape(cut: 8)
                    .strokeBorder(
                        accent.opacity(active ? 1 : 0.35),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    // MARK: - Collection Card

    private func collectionCard(
        _ definition: CardDefinition,
        deck: SavedDeck
    ) -> some View {
        let copies = deck.cardIDs.filter {
            $0 == definition.id
        }.count

        let canAdd =
            copies < maxCopies && deck.cardIDs.count < maxCards

        return VStack(spacing: 8) {
            if let card = try? definition.battleCard() {
                BattleCardView(card: card)
                    .aspectRatio(0.72, contentMode: .fit)
                    .frame(maxWidth: 145)
            }

            Text(definition.name.uppercased())
                .font(
                    .system(
                        size: 10,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Button {
                store.add(
                    definition.id,
                    to: deck.id,
                    maxCards: maxCards,
                    maxCopies: maxCopies
                )
            } label: {
                Label(
                    "\(copies)/\(maxCopies) HINZUFÜGEN",
                    systemImage: "plus.circle.fill"
                )
                .font(
                    .system(
                        size: 9,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .foregroundStyle(surface)
                .background(
                    accent,
                    in: CyberPanelShape(cut: 8)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
            .opacity(canAdd ? 1 : 0.4)
        }
        .padding(9)
        .frame(maxWidth: .infinity)
        .background(
            surface.opacity(0.9),
            in: CyberPanelShape(cut: 12)
        )
        .overlay {
            CyberPanelShape(cut: 12)
                .strokeBorder(
                    accent.opacity(0.35),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Empty State

    private var emptyDeckContent: some View {
        ContentUnavailableView {
            Label(
                "NOCH KEIN DECK",
                systemImage: "square.stack.3d.up"
            )
        } description: {
            Text(
                "Erstelle dein erstes Deck, um Karten hinzuzufügen."
            )
        } actions: {
            Button("DECK ERSTELLEN") {
                newDeckName = "DECK 1"
                showingNewDeck = true
            }
            .tint(accent)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loading

    private var loadingContent: some View {
        ProgressView("Kartenkatalog laden …")
            .tint(accent)
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
                loadCatalog()
            }
            .tint(accent)
        }
    }

    // MARK: - Actions

    private func deleteSelectedDeck() {
        guard let deletingDeckID else {
            return
        }

        store.delete(deletingDeckID)

        if selectedDeckID == deletingDeckID {
            selectedDeckID = store.decks.first?.id
        }

        self.deletingDeckID = nil
    }

    private func loadCatalog() {
        do {
            catalog = try CardCatalogService().loadBundled()
            errorMessage = nil

            if selectedDeckID == nil
                || !store.decks.contains(
                    where: { $0.id == selectedDeckID }
                )
            {
                selectedDeckID = store.decks.first?.id
            }
        } catch {
            catalog = nil
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    DeckView()
        .preferredColorScheme(.dark)
}
