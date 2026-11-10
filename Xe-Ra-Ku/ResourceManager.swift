//
//  ResourceManager.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import Foundation
import Observation

// MARK: - Account Resources

struct CyberAccountResources: Codable, Equatable {

    var level = 1
    var experience = 0
    var coins = 0
    var crystals = 0
    var energy = 100

    var experienceToNextLevel: Int {
        level * 100
    }

    var progress: Double {
        guard experienceToNextLevel > 0 else {
            return 0
        }

        return min(
            1,
            max(
                0,
                Double(experience) / Double(experienceToNextLevel)
            )
        )
    }

    enum CodingKeys: String, CodingKey {
        case level
        case experience
        case coins
        case crystals
        case energy
    }

    init(
        level: Int = 1,
        experience: Int = 0,
        coins: Int = 0,
        crystals: Int = 0,
        energy: Int = 100
    ) {
        self.level = level
        self.experience = experience
        self.coins = coins
        self.crystals = crystals
        self.energy = energy
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(
            keyedBy: CodingKeys.self
        )

        level = try values.decode(
            Int.self,
            forKey: .level
        )

        experience = try values.decode(
            Int.self,
            forKey: .experience
        )

        coins = try values.decode(
            Int.self,
            forKey: .coins
        )

        crystals = try values.decode(
            Int.self,
            forKey: .crystals
        )

        energy =
            try values.decodeIfPresent(
                Int.self,
                forKey: .energy
            ) ?? 100
    }
}

// MARK: - Battle Rewards

struct BattleRewards: Codable, Hashable, Sendable {

    let coins: Int
    let crystals: Int
    let experience: Int

    var isValid: Bool {
        (0...1_000_000).contains(coins)
            && (0...1_000_000).contains(crystals)
            && (0...1_000_000).contains(experience)
    }

    var summary: String {
        "\(coins) Coins · \(crystals) Kristalle · \(experience) EXP"
    }
}

// MARK: - Resource Manager

@MainActor
@Observable
final class ResourceManager {

    private(set) var resources: CyberAccountResources

    private let defaults: UserDefaults
    private let storageKey = "account.resources.v1"
    private let energyTimestampKey = "account.energyUpdatedAt"

    private let configuration: EnergyConfiguration

    private var energyUpdatedAt: Date
    private var rewardedRuns: Set<UUID> = []

    // MARK: - Configuration

    var maximumEnergy: Int {
        configuration.energy.maximum
    }

    var energyInterval: TimeInterval {
        configuration.energy.regenerationInterval
    }

    var regenerationAmount: Int {
        configuration.energy.regenerationAmount
    }

    var isRegenerationEnabled: Bool {
        configuration.energy.enabled
    }

    var battleCostMultiplier: Double {
        configuration.energy.battleCostMultiplier
    }

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.configuration = EnergyConfiguration.load()

        let maximum = configuration.energy.maximum

        let savedTimestamp =
            defaults.object(
                forKey: energyTimestampKey
            ) as? Date

        self.energyUpdatedAt = savedTimestamp ?? .now

        if let data = defaults.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode(
                CyberAccountResources.self,
                from: data
            ),
            (1...1_000_000).contains(saved.level),
            saved.experience >= 0,
            saved.experience < saved.experienceToNextLevel,
            saved.coins >= 0,
            saved.crystals >= 0
        {

            var restored = saved
            restored.energy = min(
                maximum,
                max(0, saved.energy)
            )

            self.resources = restored
        } else {
            self.resources = CyberAccountResources(
                energy: maximum
            )
        }

        refreshEnergy()
        persist()
    }

    // MARK: - Energy Regeneration

    func refreshEnergy(now: Date = .now) {
        let maximum = maximumEnergy

        // Ensure energy stays within configuration limits.
        if resources.energy > maximum {
            resources.energy = maximum
        }

        guard isRegenerationEnabled else {
            energyUpdatedAt = now
            persist()
            return
        }

        // No regeneration while full.
        guard resources.energy < maximum else {
            energyUpdatedAt = now
            persist()
            return
        }

        // Handle clock changes.
        guard now >= energyUpdatedAt else {
            energyUpdatedAt = now
            persist()
            return
        }

        let elapsed = now.timeIntervalSince(
            energyUpdatedAt
        )

        let completedIntervals = floor(
            elapsed / energyInterval
        )

        guard completedIntervals >= 1 else {
            return
        }

        let missingEnergy = maximum - resources.energy

        let intervalsNeeded = Int(
            ceil(
                Double(missingEnergy)
                    / Double(regenerationAmount)
            )
        )

        let intervals = Int(
            min(
                completedIntervals,
                Double(intervalsNeeded)
            )
        )

        let gained = min(
            missingEnergy,
            intervals * regenerationAmount
        )

        guard gained > 0 else {
            return
        }

        resources.energy += gained

        if resources.energy >= maximum {
            energyUpdatedAt = now
        } else {
            energyUpdatedAt =
                energyUpdatedAt
                .addingTimeInterval(
                    Double(intervals) * energyInterval
                )
        }

        persist()
    }

    // MARK: - Spend Energy

    @discardableResult
    func spendEnergy(
        _ cost: Int,
        now: Date = .now
    ) -> Bool {
        refreshEnergy(now: now)

        guard cost > 0 else {
            return false
        }

        let adjustedCost = ceil(
            Double(cost) * battleCostMultiplier
        )

        guard adjustedCost.isFinite,
            adjustedCost >= 1,
            adjustedCost <= Double(maximumEnergy)
        else {
            return false
        }

        let finalCost = Int(adjustedCost)

        guard resources.energy >= finalCost else {
            return false
        }

        let wasFull = resources.energy >= maximumEnergy

        resources.energy -= finalCost

        if wasFull {
            energyUpdatedAt = now
        }

        persist()

        return true
    }

    // MARK: - Energy Information

    var energyProgress: Double {
        guard maximumEnergy > 0 else {
            return 0
        }

        return Double(resources.energy)
            / Double(maximumEnergy)
    }

    func nextEnergyDate(now: Date = .now) -> Date? {
        guard isRegenerationEnabled,
            resources.energy < maximumEnergy
        else {
            return nil
        }

        return energyUpdatedAt.addingTimeInterval(
            energyInterval
        )
    }

    // MARK: - Rewards

    @discardableResult
    func award(
        _ rewards: BattleRewards,
        runID: UUID
    ) -> Bool {
        guard rewards.isValid,
            !rewardedRuns.contains(runID),
            resources.coins <= Int.max - rewards.coins,
            resources.crystals <= Int.max - rewards.crystals,
            resources.experience <= Int.max - rewards.experience
        else {
            return false
        }

        var updated = resources

        updated.coins += rewards.coins
        updated.crystals += rewards.crystals
        updated.experience += rewards.experience

        while updated.experience >= updated.experienceToNextLevel {
            updated.experience -= updated.experienceToNextLevel
            updated.level += 1
        }

        guard let data = try? JSONEncoder().encode(updated)
        else {
            return false
        }

        defaults.set(data, forKey: storageKey)

        rewardedRuns.insert(runID)
        resources = updated

        return true
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(resources)
        else {
            return
        }

        defaults.set(
            data,
            forKey: storageKey
        )

        defaults.set(
            energyUpdatedAt,
            forKey: energyTimestampKey
        )
    }
}
