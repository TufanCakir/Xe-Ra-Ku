//
//  OnlineBattleView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import SwiftUI

struct OnlineBattleView: View {
    private static let maxHandCards = 4

    private static let cardPool: [BattleCard] = {
        do {
            return try CardCatalogService()
                .loadBundled()
                .battleCards()
        } catch {
            print("Kartenkatalog konnte nicht geladen werden: \(error)")
            return []
        }
    }()

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var showExitOverlay = false
    @State private var battle: BattleSceneState
    @State private var runID = UUID()
    @State private var rewardGranted = false

    @State private var selectedCardID: UUID?
    @State private var summonedCardIDs: Set<UUID> = []
    @State private var opponentSummonedIDs: Set<UUID> = []
    @State private var opponentAttackedIDs: Set<UUID> = []

    @State private var showResult = false
    @State private var confirmExit = false
    @State private var isOpponentTurn = false
    @State private var autoMode = false
    @State private var battleSpeed = 1.0

    @State private var runningTask: Task<Void, Never>?
    @State private var taskGeneration = UUID()

    let launch: BattleLaunch?
    var onExit: () -> Void
    var onRestart: () -> Bool
    var onVictory: (BattleRewards, UUID) -> Void

    init(
        launch: BattleLaunch? = nil,
        onExit: @escaping () -> Void = {},
        onRestart: @escaping () -> Bool = { false },
        onVictory: @escaping (BattleRewards, UUID) -> Void = { _, _ in }
    ) {
        self.launch = launch
        self.onExit = onExit
        self.onRestart = onRestart
        self.onVictory = onVictory

        _battle = State(
            initialValue: Self.makeBattle(launch: launch)
        )
    }

    // MARK: - Configuration

    private var layout: BattleLayoutConfiguration {
        guard let launch else {
            return .standard
        }

        var configuration = launch.definition.layout(
            for: launch.enemy
        )

        configuration.mode = launch.mode
        configuration.accent = launch.mode.accent
        configuration.playerPortrait = launch.character?.portraitAsset
        configuration.opponentPortrait = launch.enemy.portraitAsset

        return configuration
    }

    private var isGameOver: Bool {
        battle.player.lifePoints <= 0 || battle.opponent.lifePoints <= 0
    }

    private var resultTitle: String {
        if battle.player.lifePoints <= 0 && battle.opponent.lifePoints <= 0 {
            return "UNENTSCHIEDEN"
        }

        return battle.opponent.lifePoints <= 0
            ? "SIEG"
            : "NIEDERLAGE"
    }

    private var canPlayerAct: Bool {
        !isGameOver && !isOpponentTurn && !showResult
    }

    private var battleAnimation: Animation? {
        reduceMotion
            ? nil
            : .spring(response: 0.3, dampingFraction: 0.85)
    }

    // MARK: - Body

    var body: some View {
        BattleScene(
            state: battle,
            onCardSelected: selectCard,
            onFieldSelected: placeCard,
            onEndTurn: endTurn,
            onDirectAttack: directAttack,
            onExit: {
                showExitOverlay = true
            },
            onToggleAuto: toggleAuto,
            onCycleSpeed: cycleSpeed,
            autoMode: autoMode,
            battleSpeed: battleSpeed,
            isOpponentTurn: isOpponentTurn,
            configuration: layout,
            selectedCardID: selectedCardID
        )
        .preferredColorScheme(.dark)
        .overlay {
            if showExitOverlay {
                CyberBattleOverlay(
                    title: "DUELL VERLASSEN?",
                    subtitle: "Dein aktueller Kampf wird beendet.",
                    symbol: "rectangle.portrait.and.arrow.right",
                    accent: layout.accent,
                    primaryTitle: "VERLASSEN",
                    primarySymbol: "door.left.hand.open",
                    primaryAction: {
                        showExitOverlay = false
                        stopTasks()
                        onExit()
                    },
                    secondaryTitle: "WEITERSPIELEN",
                    secondaryAction: {
                        showExitOverlay = false

                        if autoMode && !isOpponentTurn && !isGameOver {
                            scheduleAutoTurn()
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(2)
            } else if showResult {
                CyberBattleOverlay(
                    title: resultTitle,
                    subtitle: rewardGranted
                        ? launch?.definition.rewards.summary ?? ""
                        : "Das Duell ist beendet. Keine Belohnung.",
                    symbol: resultSymbol,
                    accent: resultAccent,
                    primaryTitle: "ZUR AUSWAHL",
                    primarySymbol: "square.grid.2x2.fill",
                    primaryAction: {
                        stopTasks()
                        onExit()
                    },
                    secondaryTitle: canRestart ? "NOCH EINMAL" : nil,
                    secondaryAction: {
                        restartBattle()
                    }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .onChange(of: isGameOver) { _, ended in
            if ended {
                finishBattle()
            }
        }
        .onDisappear {
            stopTasks()
        }
    }

    private var resultSymbol: String {
        switch resultTitle {
        case "SIEG":
            return "trophy.fill"
        case "NIEDERLAGE":
            return "xmark.shield.fill"
        default:
            return "equal.circle.fill"
        }
    }

    private var resultAccent: Color {
        switch resultTitle {
        case "SIEG":
            return .green
        case "NIEDERLAGE":
            return .red
        default:
            return layout.accent
        }
    }

    private var canRestart: Bool {
        launch == nil || launch?.definition.isWithinSchedule == true
    }

    // MARK: - Cards

    @MainActor
    private static func randomHand(
        from pool: [BattleCard]? = nil
    ) -> [BattleCard] {
        let available = pool ?? cardPool

        guard !available.isEmpty else {
            return []
        }

        return (0..<maxHandCards).compactMap { _ in
            guard let template = available.randomElement() else {
                return nil
            }

            return BattleCard(
                name: template.name,
                element: template.element,
                attack: template.attack,
                defense: template.defense
            )
        }
    }

    private static func makeBattle(
        launch: BattleLaunch?
    ) -> BattleSceneState {
        BattleSceneState(
            player: BattlePlayer(
                id: launch?.character?.id ?? "player",
                name: launch?.character?.name ?? "DU"
            ),
            opponent: BattlePlayer(
                id: launch?.enemy.id ?? "opponent",
                name: launch?.enemy.name ?? "GEGNER",
                lifePoints: launch?.enemy.lifePoints ?? 4000,
                maxLifePoints: launch?.enemy.lifePoints ?? 4000
            ),
            opponentHand: randomHand(
                from: launch?.opponentDeck
            ),
            hand: randomHand(),
            battleMessage: "WÄHLE EINE KARTE"
        )
    }

    // MARK: - Battle Lifecycle

    private func finishBattle() {
        guard !showResult else { return }

        stopTasks()

        if battle.opponent.lifePoints <= 0,
            battle.player.lifePoints > 0,
            !rewardGranted,
            let launch
        {
            rewardGranted = true
            onVictory(launch.definition.rewards, runID)
        }

        showResult = true
    }

    private func restartBattle() {
        guard launch == nil || onRestart() else {
            stopTasks()
            onExit()
            return
        }

        stopTasks()

        withAnimation(battleAnimation) {
            battle = Self.makeBattle(launch: launch)

            runID = UUID()
            rewardGranted = false

            selectedCardID = nil
            summonedCardIDs.removeAll()
            opponentSummonedIDs.removeAll()
            opponentAttackedIDs.removeAll()

            isOpponentTurn = false
            autoMode = false
            battleSpeed = 1
            showResult = false
            confirmExit = false
        }
    }

    // MARK: - Player Selection

    private func selectCard(_ card: BattleCard) {
        guard canPlayerAct else { return }

        if battle.hand.contains(where: { $0.id == card.id }) {
            selectedCardID = card.id
            battle.attackingCardID = nil
            battle.phase = .main
            battle.battleMessage = "\(card.name) AUSGEWÄHLT"
            return
        }

        if battle.playerField.contains(where: { $0?.id == card.id }) {
            guard !battle.attackedCardIDs.contains(card.id) else {
                battle.battleMessage = "BEREITS ANGEGRIFFEN"
                return
            }

            guard !summonedCardIDs.contains(card.id) else {
                battle.battleMessage = "KARTE MUSS EINEN ZUG WARTEN"
                return
            }

            selectedCardID = nil
            battle.attackingCardID = card.id
            battle.phase = .battle
            battle.battleMessage = "\(card.name): ZIEL WÄHLEN"
            return
        }

        if let index = battle.opponentField.firstIndex(
            where: { $0?.id == card.id }
        ) {
            attackOpponent(at: index)
        }
    }

    // MARK: - Summoning

    private func placeCard(at index: Int) {
        guard canPlayerAct,
            let selectedCardID,
            battle.playerField.indices.contains(index),
            battle.playerField[index] == nil,
            let handIndex = battle.hand.firstIndex(
                where: { $0.id == selectedCardID }
            )
        else {
            return
        }

        let card = battle.hand[handIndex]

        withAnimation(battleAnimation) {
            battle.playerField[index] = card
            battle.hand.remove(at: handIndex)

            summonedCardIDs.insert(card.id)

            self.selectedCardID = nil
            battle.phase = .main
            battle.battleMessage = "\(card.name) BESCHWOREN"
        }

        if battle.hand.isEmpty {
            battle.hand = Self.randomHand()
        }
    }

    // MARK: - Player Attacks

    private func attackOpponent(at index: Int) {
        guard canPlayerAct,
            let id = battle.attackingCardID,
            !battle.attackedCardIDs.contains(id),
            !summonedCardIDs.contains(id),
            let attacker = battle.playerField
                .compactMap({ $0 })
                .first(where: { $0.id == id }),
            battle.opponentField.indices.contains(index),
            let defender = battle.opponentField[index]
        else {
            return
        }

        let difference = attacker.attack - defender.attack

        withAnimation(battleAnimation) {
            if difference > 0 {
                removeOpponentCard(defender.id)

                battle.opponent.lifePoints = max(
                    0,
                    battle.opponent.lifePoints - difference
                )

                battle.battleMessage =
                    "\(defender.name) ZERSTÖRT (-\(difference) LP)"
            } else if difference < 0 {
                removePlayerCard(id)

                battle.player.lifePoints = max(
                    0,
                    battle.player.lifePoints + difference
                )

                battle.battleMessage =
                    "\(attacker.name) ZERSTÖRT (\(difference) LP)"
            } else {
                removePlayerCard(id)
                removeOpponentCard(defender.id)

                battle.battleMessage = "BEIDE KARTEN ZERSTÖRT"
            }

            battle.attackedCardIDs.insert(id)
            battle.attackingCardID = nil
            battle.phase = .main
        }

        if isGameOver {
            finishBattle()
        }
    }

    private func directAttack() {
        guard canPlayerAct,
            battle.opponentField.allSatisfy({ $0 == nil }),
            let id = battle.attackingCardID,
            !battle.attackedCardIDs.contains(id),
            !summonedCardIDs.contains(id),
            let attacker = battle.playerField
                .compactMap({ $0 })
                .first(where: { $0.id == id })
        else {
            return
        }

        withAnimation(battleAnimation) {
            battle.opponent.lifePoints = max(
                0,
                battle.opponent.lifePoints - attacker.attack
            )

            battle.attackedCardIDs.insert(id)
            battle.attackingCardID = nil
            battle.phase = .main

            battle.battleMessage =
                "DIREKTER ANGRIFF -\(attacker.attack) LP"
        }

        if isGameOver {
            finishBattle()
        }
    }

    // MARK: - Auto Mode

    private func toggleAuto() {
        guard !isGameOver else { return }

        autoMode.toggle()

        if autoMode {
            if !isOpponentTurn {
                scheduleAutoTurn()
            }
        } else if !isOpponentTurn {
            cancelRunningTask()
        }
    }

    private func cycleSpeed() {
        battleSpeed =
            battleSpeed >= 4
            ? 1
            : battleSpeed * 2
    }

    private func scheduleAutoTurn() {
        guard autoMode,
            canPlayerAct,
            !showExitOverlay
        else {
            return
        }

        cancelRunningTask()

        let generation = taskGeneration

        runningTask = Task { @MainActor in
            guard await wait(milliseconds: 650),
                taskGeneration == generation,
                autoMode,
                canPlayerAct
            else {
                return
            }

            autoPlayerActions()

            guard !Task.isCancelled,
                taskGeneration == generation,
                !isGameOver
            else {
                return
            }

            endTurn()
        }
    }

    private func autoPlayerActions() {
        guard canPlayerAct else { return }

        if let slot = battle.playerField.firstIndex(
            where: { $0 == nil }
        ),
            let handIndex = battle.hand.indices.max(
                by: {
                    battle.hand[$0].attack < battle.hand[$1].attack
                }
            )
        {
            selectedCardID = battle.hand[handIndex].id
            placeCard(at: slot)
        }

        let attackers = battle.playerField
            .compactMap { $0 }
            .filter {
                !summonedCardIDs.contains($0.id)
                    && !battle.attackedCardIDs.contains($0.id)
            }

        for attacker in attackers {
            guard !isGameOver else { break }

            selectCard(attacker)

            if let target = bestPlayerTarget(for: attacker) {
                attackOpponent(at: target)
            } else if battle.opponentField.allSatisfy({
                $0 == nil
            }) {
                directAttack()
            } else {
                battle.attackingCardID = nil
            }
        }
    }

    private func bestPlayerTarget(
        for attacker: BattleCard
    ) -> Int? {
        battle.opponentField.indices
            .filter { index in
                guard let defender = battle.opponentField[index] else {
                    return false
                }

                return attacker.attack >= defender.attack
            }
            .min { lhs, rhs in
                let left = battle.opponentField[lhs]?.attack ?? 0
                let right = battle.opponentField[rhs]?.attack ?? 0
                return left < right
            }
    }

    // MARK: - Opponent Turn

    private func endTurn() {
        guard canPlayerAct, !showExitOverlay else {
            return
        }

        cancelRunningTask()

        selectedCardID = nil
        battle.attackingCardID = nil
        isOpponentTurn = true

        opponentAttackedIDs.removeAll()

        battle.phase = .end
        battle.battleMessage = "GEGNER IST AM ZUG"

        let generation = taskGeneration

        runningTask = Task { @MainActor in
            await performOpponentTurn(generation: generation)
        }
    }

    private func performOpponentTurn(
        generation: UUID
    ) async {
        // Nur Karten, die bereits auf dem Feld liegen,
        // dürfen in diesem Gegnerzug angreifen.
        let eligible = battle.opponentField
            .compactMap { $0 }
            .filter {
                !opponentSummonedIDs.contains($0.id)
            }

        if battle.opponentHand.isEmpty {
            battle.opponentHand = Self.randomHand(
                from: launch?.opponentDeck
            )
        }

        if let slot = battle.opponentField.firstIndex(
            where: { $0 == nil }
        ),
            let handIndex = bestOpponentHandIndex()
        {
            let card = battle.opponentHand.remove(
                at: handIndex
            )

            withAnimation(battleAnimation) {
                battle.opponentField[slot] = card
            }

            opponentSummonedIDs.insert(card.id)
            battle.battleMessage =
                "GEGNER BESCHWÖRT \(card.name)"
        }

        if battle.opponentHand.isEmpty {
            battle.opponentHand = Self.randomHand(
                from: launch?.opponentDeck
            )
        }

        for attacker in eligible {
            guard await wait(milliseconds: 440),
                taskGeneration == generation,
                !isGameOver
            else {
                return
            }

            performOpponentAttack(attacker)

            if isGameOver {
                finishBattle()
                return
            }
        }

        guard !Task.isCancelled,
            taskGeneration == generation,
            !isGameOver
        else {
            return
        }

        battle.turn += 1
        battle.phase = .main
        battle.attackedCardIDs.removeAll()
        summonedCardIDs.removeAll()
        opponentSummonedIDs.removeAll()

        battle.battleMessage = "DEIN ZUG"

        if battle.hand.isEmpty {
            battle.hand = Self.randomHand()
        }

        isOpponentTurn = false
        runningTask = nil

        if autoMode {
            scheduleAutoTurn()
        }
    }

    // MARK: - Opponent AI

    private func bestOpponentHandIndex() -> Int? {
        guard !battle.opponentHand.isEmpty else {
            return nil
        }

        let defenders = battle.playerField.compactMap { $0 }

        return battle.opponentHand.indices.max { lhs, rhs in
            func score(_ card: BattleCard) -> Int {
                let beatable = defenders.filter {
                    card.attack > $0.attack
                }

                let bonus =
                    beatable.isEmpty
                    ? 0
                    : 500 + (beatable.map(\.attack).max() ?? 0) / 10

                return card.attack + bonus
            }

            return score(battle.opponentHand[lhs])
                < score(battle.opponentHand[rhs])
        }
    }

    private func performOpponentAttack(
        _ attacker: BattleCard
    ) {
        guard !isGameOver,
            !opponentAttackedIDs.contains(attacker.id),
            battle.opponentField.contains(
                where: { $0?.id == attacker.id }
            )
        else {
            return
        }

        opponentAttackedIDs.insert(attacker.id)

        let targets = battle.playerField.indices.filter {
            battle.playerField[$0] != nil
        }

        guard !targets.isEmpty else {
            withAnimation(battleAnimation) {
                battle.player.lifePoints = max(
                    0,
                    battle.player.lifePoints - attacker.attack
                )

                battle.battleMessage =
                    "\(attacker.name): DIREKT -\(attacker.attack) LP"
            }

            return
        }

        let winning = targets.filter { index in
            guard let defender = battle.playerField[index] else {
                return false
            }

            return attacker.attack > defender.attack
        }

        let targetIndex =
            winning.max { lhs, rhs in
                (battle.playerField[lhs]?.attack ?? 0)
                    < (battle.playerField[rhs]?.attack ?? 0)
            }
            ?? targets.first {
                battle.playerField[$0]?.attack == attacker.attack
            }

        guard let targetIndex,
            let defender = battle.playerField[targetIndex]
        else {
            battle.battleMessage =
                "GEGNER HÄLT \(attacker.name) ZURÜCK"
            return
        }

        let difference = attacker.attack - defender.attack

        withAnimation(battleAnimation) {
            if difference > 0 {
                removePlayerCard(defender.id)

                battle.player.lifePoints = max(
                    0,
                    battle.player.lifePoints - difference
                )

                battle.battleMessage =
                    "\(defender.name) ZERSTÖRT (-\(difference) LP)"
            } else {
                removePlayerCard(defender.id)
                removeOpponentCard(attacker.id)

                battle.battleMessage =
                    "BEIDE KARTEN ZERSTÖRT"
            }
        }
    }

    // MARK: - Field Helpers

    private func removePlayerCard(_ id: UUID) {
        guard
            let index = battle.playerField.firstIndex(
                where: { $0?.id == id }
            )
        else {
            return
        }

        battle.playerField[index] = nil
        summonedCardIDs.remove(id)

        if battle.attackingCardID == id {
            battle.attackingCardID = nil
        }
    }

    private func removeOpponentCard(_ id: UUID) {
        guard
            let index = battle.opponentField.firstIndex(
                where: { $0?.id == id }
            )
        else {
            return
        }

        battle.opponentField[index] = nil
        opponentSummonedIDs.remove(id)
    }

    // MARK: - Task Management

    private func wait(milliseconds: Double) async -> Bool {
        let delay = max(
            1,
            Int(milliseconds / max(1, battleSpeed))
        )

        do {
            try await Task.sleep(
                for: .milliseconds(delay)
            )

            return !Task.isCancelled
        } catch {
            return false
        }
    }

    private func cancelRunningTask() {
        taskGeneration = UUID()
        runningTask?.cancel()
        runningTask = nil
    }

    private func stopTasks() {
        cancelRunningTask()
        isOpponentTurn = false
        autoMode = false
    }
}

#Preview {
    OnlineBattleView()
}
