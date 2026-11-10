//
//  MenuView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import SwiftUI

struct MenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ResourceManager.self) private var resourceManager

    @State private var selectedTab: MenuTab = .home
    @State private var catalogStore = BattleCatalogStore()
    @State private var activeBattle: BattleLaunch?
    @State private var launchError: String?
    @State private var showCharacters = false
    @State private var pendingBattle: BattleEventDefinition?
    @State private var pendingBattleIsEvent = false
    @State private var temporaryCharacterID: String?

    @AppStorage("account.selectedCharacterID")
    private var selectedCharacterID = ""

    private var currentStyle: CyberNavigationStyle {
        selectedTab.style
    }

    var body: some View {
        ZStack {
            ForEach(MenuTab.allCases) { tab in
                CyberBackground(
                    accent: tab.style.accent,
                    showGrid: tab.style.showGrid,
                    background: tab.style.background,
                    glow: tab.style.backgroundGlow
                )
                .opacity(selectedTab == tab ? 1 : 0)
            }
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.35),
                value: selectedTab
            )

            VStack(spacing: 0) {
                CyberAccountHeader(
                    tab: selectedTab,
                    onBack: { dismiss() }
                )

                pageContainer

                CyberFooter(selection: $selectedTab)
            }

            // Overlay über dem gesamten Menü
            if showCharacters {
                characterSelectionOverlay
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center
                    )
                    .transition(
                        .opacity.combined(with: .scale(scale: 0.94))
                    )
                    .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(currentStyle.accent)
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .task {
            await catalogStore.refresh()
        }
        .task {
            await refreshEnergyLoop()
        }
        .fullScreenCover(item: $activeBattle) { launch in
            battleScreen(launch)
        }
        .alert(
            "Kampf nicht verfügbar",
            isPresented: Binding(
                get: { launchError != nil },
                set: { if !$0 { launchError = nil } }
            )
        ) {
            Button("OK") {
                launchError = nil
            }
        } message: {
            Text(launchError ?? "")
        }
    }

    // MARK: - Pager

    private var pageContainer: some View {
        TabView(selection: $selectedTab) {
            ForEach(MenuTab.allCases) { tab in
                pageContent(for: tab)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .tag(tab)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(nil, value: selectedTab)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .clipped()
    }

    @ViewBuilder
    private func pageContent(for tab: MenuTab) -> some View {
        switch tab {
        case .home:
            homeContent

        case .duel:
            battleCatalogPage(isEvent: false)

        case .events:
            battleCatalogPage(isEvent: true)

        case .cards:
            CardCatalogView()

        case .decks:
            DeckView()

        case .settings:
            SettingsView()
        }
    }

    // MARK: - Home

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("// KOMMANDOZENTRALE")
                            .font(
                                .system(
                                    size: 10,
                                    weight: .black,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(currentStyle.accent)

                        Text("XE-RA-KU")
                            .font(
                                .system(
                                    size: 24,
                                    weight: .black,
                                    design: .monospaced
                                )
                            )
                    }

                    Spacer()
                }
                .padding(.bottom, 8)

                CyberActionButton(
                    title: MenuTab.duel.title,
                    subtitle: MenuTab.duel.style.subtitle,
                    symbol: MenuTab.duel.symbol,
                    accent: MenuTab.duel.style.accent
                ) {
                    changeTab(.duel)
                }

                CyberActionButton(
                    title: MenuTab.events.title,
                    subtitle: MenuTab.events.style.subtitle,
                    symbol: MenuTab.events.symbol,
                    accent: MenuTab.events.style.accent
                ) {
                    changeTab(.events)
                }

                HStack(spacing: 10) {
                    CyberMenuShortcut(tab: .cards) {
                        changeTab(.cards)
                    }

                    CyberMenuShortcut(tab: .decks) {
                        changeTab(.decks)
                    }
                }
            }
            .padding(14)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Battle Catalog

    @ViewBuilder
    private func battleCatalogPage(
        isEvent: Bool
    ) -> some View {
        if let catalog = catalogStore.catalog {
            VStack(spacing: 8) {
                characterSelectionButton

                EventView(
                    events: isEvent
                        ? catalog.events
                        : catalog.battles,
                    title: isEvent
                        ? MenuTab.events.title
                        : MenuTab.duel.title,
                    mode: isEvent ? .event : .duel,
                    onStartEvent: { definition in
                        prepareBattle(
                            definition,
                            isEvent: isEvent
                        )
                    }
                )
            }
        } else if let error = catalogStore.errorMessage {
            catalogError(error)
        } else {
            ProgressView("Katalog laden …")
                .tint(currentStyle.accent)
        }
    }

    private func prepareBattle(
        _ definition: BattleEventDefinition,
        isEvent: Bool
    ) {
        guard activeBattle == nil else { return }

        pendingBattle = definition
        pendingBattleIsEvent = isEvent
        temporaryCharacterID = selectedCharacterID

        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            showCharacters = true
        }
    }

    private var characterSelectionButton: some View {
        Button {
            pendingBattle = nil
            pendingBattleIsEvent = selectedTab == .events
            temporaryCharacterID = selectedCharacterID

            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                showCharacters = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.square")
                    .foregroundStyle(currentStyle.accent)

                Text("CHARAKTER WÄHLEN")
                    .font(
                        .system(
                            size: 11,
                            weight: .black,
                            design: .monospaced
                        )
                    )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(currentStyle.accent)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .cyberPanel(
                accent: currentStyle.accent,
                cut: 10
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func catalogError(_ message: String) -> some View {
        ContentUnavailableView {
            Label(
                "Katalog nicht verfügbar",
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Erneut laden") {
                Task {
                    await catalogStore.refresh()
                }
            }
        }
    }

    // MARK: - Character Selection

    private var characterSelectionOverlay: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()
                .onTapGesture {
                    closeCharacterSelection()
                }

            if let catalog = catalogStore.catalog {
                let style =
                    pendingBattleIsEvent
                    ? MenuTab.events.style
                    : MenuTab.duel.style

                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("XE-RA-KU / AUSWAHL")
                                .font(
                                    .system(
                                        size: 10,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                                .foregroundStyle(style.accent)

                            Text("CHARAKTER WÄHLEN")
                                .font(
                                    .system(
                                        size: 19,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                        }

                        Spacer()

                        Button {
                            closeCharacterSelection()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    style.accent.opacity(0.16),
                                    in: CyberPanelShape(cut: 9)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Schließen")
                    }

                    Rectangle()
                        .fill(style.accent.opacity(0.35))
                        .frame(height: 1)

                    ScrollView {
                        BattleCharacterPicker(
                            characters: catalog.characters,
                            accountLevel: resourceManager.resources.level,
                            selectedID: temporaryCharacterID,
                            onSelect: { character in
                                temporaryCharacterID = character.id
                            },
                            style: style
                        )
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 340)

                    if pendingBattle != nil {
                        Button {
                            confirmCharacterSelection()
                        } label: {
                            Label(
                                "KAMPF STARTEN",
                                systemImage: "bolt.fill"
                            )
                            .font(
                                .system(
                                    size: 13,
                                    weight: .black,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .cyberPanel(
                                accent: style.accent,
                                cut: 12,
                                prominent: true
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(temporaryCharacterID == nil)
                        .opacity(temporaryCharacterID == nil ? 0.4 : 1)
                    } else {
                        Button {
                            saveCharacterSelection()
                        } label: {
                            Text("AUSWAHL SPEICHERN")
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .cyberPanel(
                                    accent: style.accent,
                                    cut: 12,
                                    prominent: true
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(temporaryCharacterID == nil)
                    }
                }
                .foregroundStyle(.white)
                .padding(18)
                .background {
                    CyberPanelShape(cut: 20)
                        .fill(style.background)
                }
                .overlay {
                    CyberPanelShape(cut: 20)
                        .strokeBorder(
                            style.accent.opacity(0.75),
                            lineWidth: 1.5
                        )
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 520)
            }
        }
    }

    private func closeCharacterSelection() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            showCharacters = false
        }

        pendingBattle = nil
        temporaryCharacterID = nil
    }

    private func saveCharacterSelection() {
        guard let temporaryCharacterID else { return }

        selectedCharacterID = temporaryCharacterID
        closeCharacterSelection()
    }

    private func confirmCharacterSelection() {
        guard
            let definition = pendingBattle,
            let catalog = catalogStore.catalog,
            let character = catalog.characters.first(where: {
                $0.id == temporaryCharacterID
            }),
            character.isUnlocked(
                accountLevel: resourceManager.resources.level
            )
        else {
            return
        }

        let isEvent = pendingBattleIsEvent

        selectedCharacterID = character.id
        closeCharacterSelection()

        startBattle(
            definition,
            isEvent: isEvent,
            selectedCharacter: character
        )
    }

    private func resolvedCharacterID(
        from characters: [BattleCharacterDefinition]
    ) -> String? {
        let unlocked = characters.filter {
            $0.isUnlocked(
                accountLevel: resourceManager.resources.level
            )
        }

        return unlocked.first {
            $0.id == selectedCharacterID
        }?.id ?? unlocked.first?.id
    }

    // MARK: - Battle Launch

    private func startBattle(
        _ definition: BattleEventDefinition,
        isEvent: Bool,
        selectedCharacter: BattleCharacterDefinition? = nil
    ) {
        guard activeBattle == nil else { return }

        let level = resourceManager.resources.level

        guard definition.isAvailable(accountLevel: level),
            let catalog = catalogStore.catalog,
            let enemy = catalog.enemies.first(where: {
                $0.id == definition.enemyID
            }),
            enemy.isUnlocked(accountLevel: level)
        else {
            launchError = "Dieser Kampf ist aktuell gesperrt."
            return
        }

        let unlockedCharacters = catalog.characters.filter {
            $0.isUnlocked(accountLevel: level)
        }

        guard
            let character = unlockedCharacters.first(where: {
                $0.id == (selectedCharacter?.id ?? selectedCharacterID)
            }) ?? unlockedCharacters.first
        else {
            launchError = "Kein freigeschalteter Charakter verfügbar."
            return
        }

        do {
            let deck = try loadOpponentDeck(
                cardIDs: enemy.deckCardIDs
            )

            guard
                resourceManager.spendEnergy(
                    definition.energyCost
                )
            else {
                launchError = "Nicht genügend Energie für diesen Kampf."
                return
            }

            activeBattle = BattleLaunch(
                mode: isEvent ? .event : .duel,
                definition: definition,
                enemy: enemy,
                opponentDeck: deck,
                character: character
            )
        } catch {
            launchError = error.localizedDescription
        }
    }

    private func loadOpponentDeck(
        cardIDs: [String]
    ) throws -> [BattleCard] {
        let definitions = try CardCatalogService()
            .loadBundled()
            .cards

        let lookup = Dictionary(
            uniqueKeysWithValues: definitions.map {
                ($0.id, $0)
            }
        )

        let deck = try cardIDs.map { id in
            guard let definition = lookup[id] else {
                throw BattleCatalogError.invalidEntry
            }

            return try definition.battleCard()
        }

        guard !deck.isEmpty else {
            throw BattleCatalogError.invalidEntry
        }

        return deck
    }

    // MARK: - Battle Screen

    private func battleScreen(
        _ launch: BattleLaunch
    ) -> some View {
        OnlineBattleView(
            launch: launch,
            onExit: {
                activeBattle = nil
            },
            onRestart: {
                guard
                    launch.definition.isAvailable(
                        accountLevel: resourceManager.resources.level
                    )
                else {
                    return false
                }

                return resourceManager.spendEnergy(
                    launch.definition.energyCost
                )
            },
            onVictory: { rewards, runID in
                resourceManager.award(
                    rewards,
                    runID: runID
                )
            }
        )
    }

    // MARK: - Energy

    private func refreshEnergyLoop() async {
        while !Task.isCancelled {
            resourceManager.refreshEnergy()

            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                break
            }
        }
    }

    // MARK: - Navigation

    private func changeTab(_ tab: MenuTab) {
        guard selectedTab != tab else { return }

        if reduceMotion {
            selectedTab = tab
        } else {
            withAnimation(
                .easeInOut(duration: 0.25)
            ) {
                selectedTab = tab
            }
        }
    }
}

// MARK: - Menu Shortcut

private struct CyberMenuShortcut: View {
    let tab: MenuTab
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                Image(systemName: tab.symbol)
                    .font(
                        .system(
                            size: 20,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(tab.style.accent)

                Text(tab.title)
                    .font(
                        .system(
                            size: 11,
                            weight: .black,
                            design: .monospaced
                        )
                    )

                Text(tab.style.subtitle)
                    .font(
                        .system(
                            size: 9,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(
                maxWidth: .infinity,
                minHeight: 86,
                alignment: .leading
            )
            .padding(12)
            .cyberPanel(
                accent: tab.style.accent,
                cut: 12
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuView()
        .environment(ResourceManager())
}
