//
//  OnlineBattleView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import SwiftUI

struct OnlineBattleView: View {
    private static let maxHandCards = 4
    private static let cardPool: [BattleCard] = [
        .init(name: "NOVA", element: .fire, attack: 1800, defense: 1200),
        .init(name: "CYBER", element: .water, attack: 2200, defense: 1500),
        .init(name: "RAIKU", element: .shadow, attack: 1600, defense: 2000),
        .init(name: "SERAPH", element: .holy, attack: 2500, defense: 1800),
        .init(name: "ABYSS", element: .void, attack: 2800, defense: 1400),
        .init(name: "FLORA", element: .plant, attack: 1200, defense: 2400),
        .init(name: "TERRA", element: .earth, attack: 1900, defense: 2100),
        .init(name: "LUMINA", element: .light, attack: 2300, defense: 1600),
        .init(name: "GOLEM", element: .stone, attack: 1500, defense: 3000),
        .init(name: "VERDANT", element: .grass, attack: 1700, defense: 1900),
        .init(name: "AMORA", element: .lust, attack: 2100, defense: 1700),
    ]

    @State private var battle = Self.makeBattle()
    @State private var selectedCardID: UUID?
    @State private var summonedCardIDs: Set<UUID> = []
    @State private var opponentSummonedIDs: Set<UUID> = []
    @State private var opponentAttackedIDs: Set<UUID> = []
    @State private var showResult = false

    private var isGameOver: Bool {
        battle.player.lifePoints <= 0 || battle.opponent.lifePoints <= 0
    }

    private var resultTitle: String {
        if battle.player.lifePoints <= 0 && battle.opponent.lifePoints <= 0 {
            return "UNENTSCHIEDEN"
        }
        return battle.opponent.lifePoints <= 0 ? "SIEG" : "NIEDERLAGE"
    }

    var body: some View {
        BattleScene(
            state: battle,
            onCardSelected: selectCard,
            onFieldSelected: placeCard,
            onEndTurn: endTurn,
            onDirectAttack: directAttack
        )
        .preferredColorScheme(.dark)
        .onChange(of: isGameOver) { _, ended in
            if ended { showResult = true }
        }
        .alert(resultTitle, isPresented: $showResult) {
            Button("NEUES DUELL") { restartBattle() }
        } message: {
            Text("Das Duell ist beendet.")
        }
    }

    private static func copyCard(_ template: BattleCard) -> BattleCard {
        BattleCard(
            name: template.name,
            element: template.element,
            attack: template.attack,
            defense: template.defense
        )
    }

    private static func randomHand() -> [BattleCard] {
        (0..<maxHandCards).compactMap { _ in
            cardPool.randomElement().map { copyCard($0) }
        }
    }

    private static func makeBattle() -> BattleSceneState {
        BattleSceneState(
            player: BattlePlayer(id: "player", name: "DU"),
            opponent: BattlePlayer(id: "opponent", name: "GEGNER"),
            opponentHand: randomHand(),
            hand: randomHand(),
            battleMessage: "WÄHLE EINE KARTE"
        )
    }

    private func restartBattle() {
        withAnimation(.easeInOut(duration: 0.25)) {
            battle = Self.makeBattle()
            selectedCardID = nil
            summonedCardIDs.removeAll()
            opponentSummonedIDs.removeAll()
            opponentAttackedIDs.removeAll()
            showResult = false
        }
    }

    private func selectCard(_ card: BattleCard) {
        guard !isGameOver else { return }

        if battle.hand.contains(where: { $0.id == card.id }) {
            selectedCardID = card.id
            battle.attackingCardID = nil
            battle.phase = .main
            battle.battleMessage = "\(card.name) AUSGEWÄHLT"
        } else if battle.playerField.contains(where: { $0?.id == card.id }) {
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
        } else if let index = battle.opponentField.firstIndex(where: {
            $0?.id == card.id
        }) {
            attackOpponent(at: index)
        }
    }

    private func placeCard(at index: Int) {
        guard !isGameOver,
            let selectedCardID,
            battle.playerField.indices.contains(index),
            battle.playerField[index] == nil,
            let handIndex = battle.hand.firstIndex(where: {
                $0.id == selectedCardID
            })
        else { return }

        let card = battle.hand[handIndex]
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            battle.playerField[index] = card
            battle.hand.remove(at: handIndex)
            summonedCardIDs.insert(card.id)
            self.selectedCardID = nil
            battle.phase = .main
            battle.battleMessage = "\(card.name) BESCHWOREN"
        }
        if battle.hand.isEmpty { battle.hand = Self.randomHand() }
    }

    private func attackOpponent(at index: Int) {
        guard !isGameOver,
            let id = battle.attackingCardID,
            !battle.attackedCardIDs.contains(id),
            !summonedCardIDs.contains(id),
            let attacker = battle.playerField.compactMap({ $0 }).first(where: {
                $0.id == id
            }),
            battle.opponentField.indices.contains(index),
            let defender = battle.opponentField[index]
        else { return }

        let difference = attacker.attack - defender.attack
        withAnimation(.spring(response: 0.4)) {
            if difference > 0 {
                battle.opponentField[index] = nil
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
                battle.opponentField[index] = nil
                battle.battleMessage = "BEIDE KARTEN ZERSTÖRT"
            }
            battle.attackedCardIDs.insert(id)
            battle.attackingCardID = nil
            battle.phase = .main
        }
    }

    private func directAttack() {
        guard !isGameOver,
            battle.opponentField.allSatisfy({ $0 == nil }),
            let id = battle.attackingCardID,
            !battle.attackedCardIDs.contains(id),
            !summonedCardIDs.contains(id),
            let attacker = battle.playerField.compactMap({ $0 }).first(where: {
                $0.id == id
            })
        else { return }

        withAnimation {
            battle.opponent.lifePoints = max(
                0,
                battle.opponent.lifePoints - attacker.attack
            )
            battle.attackedCardIDs.insert(id)
            battle.attackingCardID = nil
            battle.phase = .main
            battle.battleMessage = "DIREKTER ANGRIFF -\(attacker.attack) LP"
        }
    }

    private func endTurn() {
        guard !isGameOver else { return }
        selectedCardID = nil
        battle.attackingCardID = nil
        battle.phase = .end
        battle.battleMessage = "GEGNER IST AM ZUG"
        opponentTurn()
        guard !isGameOver else { return }
        withAnimation {
            battle.turn += 1
            battle.phase = .main
            battle.attackedCardIDs.removeAll()
            summonedCardIDs.removeAll()
            battle.battleMessage = "DEIN ZUG"
        }
        if battle.hand.isEmpty { battle.hand = Self.randomHand() }
    }

    private func opponentTurn() {
        opponentAttackedIDs.removeAll()
        // Keep a snapshot of cards already on the field before summoning.
        let eligibleAttackers = battle.opponentField.compactMap { $0 }

        if battle.opponentHand.isEmpty {
            battle.opponentHand = Self.randomHand()
        }
        if let slot = battle.opponentField.firstIndex(where: { $0 == nil }),
            let handIndex = bestOpponentHandIndex()
        {
            let card = battle.opponentHand.remove(at: handIndex)
            withAnimation { battle.opponentField[slot] = card }
            opponentSummonedIDs.insert(card.id)
            battle.battleMessage = "GEGNER BESCHWÖRT \(card.name)"
        }
        // Refill immediately after using the final card.
        if battle.opponentHand.isEmpty {
            battle.opponentHand = Self.randomHand()
        }

        for attacker in eligibleAttackers {
            guard !isGameOver else { break }
            performOpponentAttack(attacker)
        }
        // These IDs are only relevant during this opponent turn.
        opponentSummonedIDs.removeAll()
    }

    private func bestOpponentHandIndex() -> Int? {
        guard !battle.opponentHand.isEmpty else { return nil }
        let defenders = battle.playerField.compactMap { $0 }
        return battle.opponentHand.indices.max { a, b in
            func score(_ card: BattleCard) -> Int {
                let beatable = defenders.filter { card.attack > $0.attack }
                let bonus =
                    beatable.isEmpty
                    ? 0 : 500 + (beatable.map(\.attack).max() ?? 0) / 10
                return card.attack + bonus
            }
            return score(battle.opponentHand[a]) < score(battle.opponentHand[b])
        }
    }

    private func performOpponentAttack(_ attacker: BattleCard) {
        guard !opponentAttackedIDs.contains(attacker.id),
            battle.opponentField.contains(where: { $0?.id == attacker.id })
        else { return }
        opponentAttackedIDs.insert(attacker.id)

        let targets = battle.playerField.indices.filter {
            battle.playerField[$0] != nil
        }
        guard !targets.isEmpty else {
            withAnimation {
                battle.player.lifePoints = max(
                    0,
                    battle.player.lifePoints - attacker.attack
                )
                battle.battleMessage =
                    "\(attacker.name): DIREKT -\(attacker.attack) LP"
            }
            return
        }

        let winning = targets.filter {
            guard let defender = battle.playerField[$0] else { return false }
            return attacker.attack > defender.attack
        }
        // Prefer the strongest card that can be beaten: highest LP damage.
        let targetIndex =
            winning.max {
                (battle.playerField[$0]?.attack ?? 0)
                    < (battle.playerField[$1]?.attack ?? 0)
            }
            ?? targets.first(where: {
                battle.playerField[$0]?.attack == attacker.attack
            })

        guard let targetIndex, let defender = battle.playerField[targetIndex]
        else {
            battle.battleMessage = "GEGNER HÄLT \(attacker.name) ZURÜCK"
            return
        }

        let difference = attacker.attack - defender.attack
        withAnimation(.spring(response: 0.4)) {
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
                battle.battleMessage = "BEIDE KARTEN ZERSTÖRT"
            }
        }
    }

    private func removePlayerCard(_ id: UUID) {
        guard let index = battle.playerField.firstIndex(where: { $0?.id == id })
        else { return }
        battle.playerField[index] = nil
        summonedCardIDs.remove(id)
        if battle.attackingCardID == id { battle.attackingCardID = nil }
    }

    private func removeOpponentCard(_ id: UUID) {
        guard
            let index = battle.opponentField.firstIndex(where: { $0?.id == id })
        else { return }
        battle.opponentField[index] = nil
        opponentSummonedIDs.remove(id)
    }
}

#Preview {
    OnlineBattleView()
}
