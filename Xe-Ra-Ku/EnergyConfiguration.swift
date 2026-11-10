//
//  EnergyConfiguration.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 11.11.26.
//

import Foundation

struct EnergyConfiguration: Codable, Sendable {
    let energy: Settings

    struct Settings: Codable, Sendable {
        let maximum: Int
        let regenerationInterval: TimeInterval
        let regenerationAmount: Int
        let battleCostMultiplier: Double
        let enabled: Bool
    }

    static let fallback = EnergyConfiguration(
        energy: Settings(
            maximum: 100,
            regenerationInterval: 300,
            regenerationAmount: 1,
            battleCostMultiplier: 1,
            enabled: true
        )
    )

    static func load() -> EnergyConfiguration {
        guard
            let url = Bundle.main.url(
                forResource: "energy_config",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let configuration = try? JSONDecoder().decode(
                EnergyConfiguration.self,
                from: data
            )
        else {
            return .fallback
        }

        let settings = configuration.energy

        guard
            (1...10_000).contains(settings.maximum),
            settings.regenerationInterval >= 1,
            settings.regenerationInterval.isFinite,
            (1...settings.maximum).contains(settings.regenerationAmount),
            settings.battleCostMultiplier.isFinite,
            settings.battleCostMultiplier > 0
        else {
            return .fallback
        }

        return configuration
    }
}
