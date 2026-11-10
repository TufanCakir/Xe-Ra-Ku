//
//  CardCatalog.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import Foundation

struct CardDefinition: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let element: String
    let attack: Int
    let defense: Int

    func battleCard() throws -> BattleCard {
        let kind: BattleElement
        switch element.lowercased() {
        case "fire": kind = .fire
        case "water": kind = .water
        case "shadow": kind = .shadow
        case "holy": kind = .holy
        case "void": kind = .void
        case "plant": kind = .plant
        case "earth": kind = .earth
        case "light": kind = .light
        case "stone": kind = .stone
        case "grass": kind = .grass
        case "lust": kind = .lust
        default: throw CardCatalogError.unknownElement(element)
        }
        return BattleCard(
            name: name,
            element: kind,
            attack: attack,
            defense: defense
        )
    }
}

struct CardCatalog: Codable, Sendable {
    let schemaVersion: Int
    let cards: [CardDefinition]

    func validated() throws -> CardCatalog {
        guard schemaVersion == 1 else {
            throw CardCatalogError.unsupportedVersion
        }
        guard !cards.isEmpty else { throw CardCatalogError.empty }
        guard Set(cards.map(\.id)).count == cards.count else {
            throw CardCatalogError.duplicateIDs
        }
        for card in cards {
            guard !card.id.isEmpty, !card.name.isEmpty,
                card.attack >= 0, card.defense >= 0
            else { throw CardCatalogError.invalidCard }
            _ = try card.battleCard()
        }
        return self
    }

    func battleCards() throws -> [BattleCard] {
        try validated().cards.map { try $0.battleCard() }
    }
}

enum CardCatalogError: LocalizedError {
    case missingFile, unsupportedVersion, empty, duplicateIDs, invalidCard
    case unknownElement(String)
    case invalidResponse
    var errorDescription: String? {
        switch self {
        case .missingFile: "cards.json fehlt im App-Bundle."
        case .unsupportedVersion: "Nicht unterstützte Kartenkatalog-Version."
        case .empty: "Der Kartenkatalog ist leer."
        case .duplicateIDs: "Karten-IDs müssen eindeutig sein."
        case .invalidCard: "Ungültige Kartendaten."
        case .unknownElement(let value): "Unbekanntes Kartenelement: \(value)."
        case .invalidResponse: "Ungültige Serverantwort."
        }
    }
}

struct CardCatalogService {
    func loadBundled() throws -> CardCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "cards",
                withExtension: "json"
            )
        else {
            throw CardCatalogError.missingFile
        }
        return try JSONDecoder().decode(
            CardCatalog.self,
            from: Data(contentsOf: url)
        ).validated()
    }

    func loadRemote(from url: URL) async throws -> CardCatalog {
        guard url.scheme?.lowercased() == "https" else {
            throw CardCatalogError.invalidResponse
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode)
        else {
            throw CardCatalogError.invalidResponse
        }
        return try JSONDecoder().decode(CardCatalog.self, from: data)
            .validated()
    }
}
