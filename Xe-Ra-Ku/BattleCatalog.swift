//
//  BattleCatalog.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import Foundation
import Observation

// MARK: - Character

struct BattleCharacterDefinition:
    Codable, Identifiable, Hashable, Sendable
{

    let id: String
    let name: String
    let portraitAsset: String
    let requiredAccountLevel: Int
    let description: String?

    func isUnlocked(accountLevel: Int) -> Bool {
        accountLevel >= max(1, requiredAccountLevel)
    }
}

// MARK: - Enemy

struct BattleEnemyDefinition:
    Codable, Identifiable, Hashable, Sendable
{

    let id: String
    let name: String
    let portraitAsset: String?
    let difficulty: Int
    let lifePoints: Int
    let requiredAccountLevel: Int
    let deckCardIDs: [String]

    func isUnlocked(accountLevel: Int) -> Bool {
        accountLevel >= max(1, requiredAccountLevel)
    }
}

// MARK: - Catalog

struct BattleCatalog: Codable, Sendable {

    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    let characters: [BattleCharacterDefinition]
    let enemies: [BattleEnemyDefinition]
    let battles: [BattleEventDefinition]
    let events: [BattleEventDefinition]

    func validated() throws -> BattleCatalog {

        guard schemaVersion == Self.supportedSchemaVersion else {
            throw BattleCatalogError.unsupportedVersion(
                schemaVersion
            )
        }

        guard !characters.isEmpty, !enemies.isEmpty else {
            throw BattleCatalogError.emptyCatalog
        }

        let characterIDs = characters.map(\.id)
        let enemyIDs = enemies.map(\.id)
        let encounters = battles + events
        let encounterIDs = encounters.map(\.id)

        guard
            Set(characterIDs).count == characterIDs.count,
            Set(enemyIDs).count == enemyIDs.count,
            Set(encounterIDs).count == encounterIDs.count
        else {
            throw BattleCatalogError.duplicateIDs
        }

        guard
            characters.allSatisfy({ character in
                !character.id.isEmpty
                    && !character.name.isEmpty
                    && !character.portraitAsset.isEmpty
                    && character.requiredAccountLevel >= 1
            })
        else {
            throw BattleCatalogError.invalidEntry
        }

        guard
            enemies.allSatisfy({ enemy in
                !enemy.id.isEmpty
                    && !enemy.name.isEmpty
                    && enemy.lifePoints > 0
                    && enemy.difficulty >= 1
                    && enemy.requiredAccountLevel >= 1
                    && !enemy.deckCardIDs.isEmpty
                    && enemy.deckCardIDs.allSatisfy {
                        !$0.isEmpty
                    }
            })
        else {
            throw BattleCatalogError.invalidEntry
        }

        let knownEnemyIDs = Set(enemyIDs)

        guard
            encounters.allSatisfy({ encounter in
                !encounter.id.isEmpty
                    && !encounter.title.isEmpty
                    && encounter.requiredAccountLevel >= 1
                    && encounter.energyCost > 0
                    && encounter.rewards.isValid
                    && encounter.appearance.isValid
                    && knownEnemyIDs.contains(encounter.enemyID)
                    && validDateRange(encounter)
            })
        else {
            throw BattleCatalogError.invalidEntry
        }

        return self
    }

    private func validDateRange(
        _ encounter: BattleEventDefinition
    ) -> Bool {
        guard
            let start = encounter.startsAt,
            let end = encounter.endsAt
        else {
            return true
        }

        return start < end
    }
}

// MARK: - Errors

enum BattleCatalogError: LocalizedError {

    case missingBundledFile(String)
    case invalidFile(String)
    case unsupportedVersion(Int)
    case emptyCatalog
    case duplicateIDs
    case invalidEntry
    case invalidRemoteURL
    case invalidResponse
    case fileTooLarge
    case invalidManifest

    var errorDescription: String? {
        switch self {

        case .missingBundledFile(let name):
            return "\(name) fehlt im App-Bundle."

        case .invalidFile(let name):
            return "\(name) enthält ungültige JSON-Daten."

        case .unsupportedVersion(let version):
            return "Unbekannte Katalogversion: \(version)."

        case .emptyCatalog:
            return "Der Katalog enthält keine Charaktere oder Gegner."

        case .duplicateIDs:
            return "IDs im Katalog müssen eindeutig sein."

        case .invalidEntry:
            return "Der Katalog enthält ungültige Einträge."

        case .invalidRemoteURL:
            return "Nur gültige HTTPS-Adressen sind erlaubt."

        case .invalidResponse:
            return "Der Server hat keine gültige Antwort geliefert."

        case .fileTooLarge:
            return "Die JSON-Datei überschreitet die erlaubte Größe."

        case .invalidManifest:
            return "Das Katalog-Manifest enthält ungültige Dateipfade."
        }
    }
}

// MARK: - Catalog Service

struct BattleCatalogService {

    private static let maximumJSONSize = 2_000_000

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Manifest

    private struct Manifest: Decodable {
        let schemaVersion: Int
        let characters: String
        let enemies: String
        let battles: String
        let events: String

        var files: [String] {
            [
                characters,
                enemies,
                battles,
                events,
            ]
        }

        func validated() throws -> Manifest {
            guard schemaVersion == BattleCatalog.supportedSchemaVersion
            else {
                throw BattleCatalogError.unsupportedVersion(
                    schemaVersion
                )
            }

            guard
                files.allSatisfy({
                    BattleCatalogService.isSafeFileName($0)
                })
            else {
                throw BattleCatalogError.invalidManifest
            }

            return self
        }
    }

    // MARK: - Decoder

    private func decode<T: Decodable>(
        _ type: T.Type,
        data: Data,
        file: String
    ) throws -> T {

        guard data.count <= Self.maximumJSONSize else {
            throw BattleCatalogError.fileTooLarge
        }

        do {
            return try decoder.decode(
                type,
                from: data
            )
        } catch {
            throw BattleCatalogError.invalidFile(file)
        }
    }

    // MARK: - File Validation

    private static func isSafeFileName(
        _ file: String
    ) -> Bool {
        guard
            !file.isEmpty,
            file.count <= 128,
            file.hasSuffix(".json"),
            file != ".",
            file != "..",
            !file.contains(".."),
            !file.contains("/"),
            !file.contains("\\")
        else {
            return false
        }

        let allowed = CharacterSet(
            charactersIn:
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-."
        )

        return file.unicodeScalars.allSatisfy {
            allowed.contains($0)
        }
    }

    // MARK: - Bundled Data

    private func bundledData(
        _ file: String
    ) throws -> Data {

        guard Self.isSafeFileName(file) else {
            throw BattleCatalogError.invalidManifest
        }

        guard
            let url = Bundle.main.url(
                forResource: file,
                withExtension: nil
            )
        else {
            throw BattleCatalogError.missingBundledFile(file)
        }

        let data = try Data(contentsOf: url)

        guard data.count <= Self.maximumJSONSize else {
            throw BattleCatalogError.fileTooLarge
        }

        return data
    }

    // MARK: - Build Catalog

    private func makeCatalog(
        manifest: Manifest,
        charactersData: Data,
        enemiesData: Data,
        battlesData: Data,
        eventsData: Data
    ) throws -> BattleCatalog {

        let characters = try decode(
            [BattleCharacterDefinition].self,
            data: charactersData,
            file: manifest.characters
        )

        let enemies = try decode(
            [BattleEnemyDefinition].self,
            data: enemiesData,
            file: manifest.enemies
        )

        let battles = try decode(
            [BattleEventDefinition].self,
            data: battlesData,
            file: manifest.battles
        )

        let events = try decode(
            [BattleEventDefinition].self,
            data: eventsData,
            file: manifest.events
        )

        return try BattleCatalog(
            schemaVersion: manifest.schemaVersion,
            characters: characters,
            enemies: enemies,
            battles: battles,
            events: events
        ).validated()
    }

    // MARK: - Bundled Catalog

    func loadBundled() throws -> BattleCatalog {

        let manifestData = try bundledData(
            "BattleCatalog.json"
        )

        let manifest = try decode(
            Manifest.self,
            data: manifestData,
            file: "BattleCatalog.json"
        ).validated()

        return try makeCatalog(
            manifest: manifest,
            charactersData: bundledData(manifest.characters),
            enemiesData: bundledData(manifest.enemies),
            battlesData: bundledData(manifest.battles),
            eventsData: bundledData(manifest.events)
        )
    }

    // MARK: - Remote Data

    private func remoteData(
        _ url: URL
    ) async throws -> Data {

        guard
            url.scheme?.lowercased() == "https",
            url.host != nil,
            url.user == nil,
            url.password == nil,
            url.query == nil,
            url.fragment == nil
        else {
            throw BattleCatalogError.invalidRemoteURL
        }

        var request = URLRequest(url: url)

        request.timeoutInterval = 12

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode)
        else {
            throw BattleCatalogError.invalidResponse
        }

        guard data.count <= Self.maximumJSONSize else {
            throw BattleCatalogError.fileTooLarge
        }

        return data
    }

    // MARK: - Remote Catalog

    func load(
        remoteURL: URL?
    ) async throws -> BattleCatalog {

        guard let remoteURL else {
            return try loadBundled()
        }

        let manifestData = try await remoteData(remoteURL)

        let manifest = try decode(
            Manifest.self,
            data: manifestData,
            file: "BattleCatalog.json"
        ).validated()

        let baseURL = remoteURL.deletingLastPathComponent()

        let charactersURL = baseURL.appendingPathComponent(
            manifest.characters
        )

        let enemiesURL = baseURL.appendingPathComponent(
            manifest.enemies
        )

        let battlesURL = baseURL.appendingPathComponent(
            manifest.battles
        )

        let eventsURL = baseURL.appendingPathComponent(
            manifest.events
        )

        async let charactersData = remoteData(charactersURL)
        async let enemiesData = remoteData(enemiesURL)
        async let battlesData = remoteData(battlesURL)
        async let eventsData = remoteData(eventsURL)

        let (
            loadedCharacters,
            loadedEnemies,
            loadedBattles,
            loadedEvents
        ) = try await (
            charactersData,
            enemiesData,
            battlesData,
            eventsData
        )

        return try makeCatalog(
            manifest: manifest,
            charactersData: loadedCharacters,
            enemiesData: loadedEnemies,
            battlesData: loadedBattles,
            eventsData: loadedEvents
        )
    }
}

// MARK: - Catalog Store

@MainActor
@Observable
final class BattleCatalogStore {

    private(set) var catalog: BattleCatalog?
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    @ObservationIgnored
    private var refreshID = UUID()

    func refresh(
        remoteURL: URL? = nil
    ) async {

        let requestID = UUID()
        refreshID = requestID

        isLoading = true
        errorMessage = nil

        defer {
            if refreshID == requestID {
                isLoading = false
            }
        }

        do {
            let loaded = try await BattleCatalogService().load(
                remoteURL: remoteURL
            )

            guard refreshID == requestID else {
                return
            }

            catalog = loaded
            errorMessage = nil

        } catch {

            guard refreshID == requestID else {
                return
            }

            let originalError = error.localizedDescription

            if remoteURL != nil,
                let fallback = try? BattleCatalogService()
                    .loadBundled()
            {

                catalog = fallback
                errorMessage = nil

            } else {
                errorMessage = originalError
            }
        }
    }
}
