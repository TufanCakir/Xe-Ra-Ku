//
//  EventView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct EventView: View {
    @Environment(ResourceManager.self)
    private var resourceManager

    let events: [BattleEventDefinition]

    var title = "EVENTS"
    var mode: BattleMode = .event
    var onStartEvent: (BattleEventDefinition) -> Void = { _ in }

    private var tab: MenuTab {
        mode == .event ? .events : .duel
    }

    private var accent: Color {
        tab.style.accent
    }

    private var accountLevel: Int {
        resourceManager.resources.level
    }

    private var energy: Int {
        resourceManager.resources.energy
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView {
                LazyVStack(
                    alignment: .leading,
                    spacing: 10
                ) {
                    BattleCatalogHeading(
                        title: title,
                        accountLevel: accountLevel,
                        energy: energy,
                        accent: accent
                    )

                    if events.isEmpty {
                        emptyContent
                    } else {
                        ForEach(events) { event in
                            BattleCatalogCard(
                                definition: event,
                                accountLevel: accountLevel,
                                energy: energy,
                                now: context.date,
                                accent: accent,
                                onStart: {
                                    onStartEvent(event)
                                }
                            )
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label(
                "Keine Kämpfe verfügbar",
                systemImage: "calendar.badge.exclamationmark"
            )
        } description: {
            Text(
                "Hier erscheinen neue Herausforderungen, sobald sie verfügbar sind."
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Catalog Heading

private struct BattleCatalogHeading: View {
    let title: String
    let accountLevel: Int
    let energy: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .cyberPanel(accent: accent, cut: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(
                        .system(
                            size: 17,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.white)

                Text("ACCOUNT LVL \(accountLevel)")
                    .font(
                        .system(
                            size: 9,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(accent)
            }

            Spacer(minLength: 0)

            Label("\(energy)", systemImage: "bolt.fill")
                .font(
                    .system(
                        size: 11,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .foregroundStyle(accent)
                .monospacedDigit()
        }
        .padding(.bottom, 6)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Battle Card

private struct BattleCatalogCard: View {
    let definition: BattleEventDefinition
    let accountLevel: Int
    let energy: Int
    let now: Date
    let accent: Color
    let onStart: () -> Void

    private var isUnlocked: Bool {
        accountLevel >= definition.requiredAccountLevel
    }

    private var hasEnergy: Bool {
        energy >= definition.energyCost
    }

    private var isAvailable: Bool {
        definition.isAvailable(
            accountLevel: accountLevel,
            now: now
        )
    }

    private var canStart: Bool {
        isAvailable && hasEnergy
    }

    private var statusTitle: String {
        if let end = definition.endsAt, now >= end {
            return "BEENDET"
        }

        if let start = definition.startsAt, now < start {
            return "DEMNÄCHST"
        }

        if !isUnlocked {
            return "GESPERRT · AB LEVEL \(definition.requiredAccountLevel)"
        }

        if !hasEnergy {
            return "ENERGIE FEHLT"
        }

        return "BEREIT"
    }

    private var statusSymbol: String {
        canStart
            ? "checkmark.circle.fill"
            : "lock.fill"
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            header

            separator

            information

            BattleRewardLabel(
                rewards: definition.rewards
            )

            startButton
        }
        .padding(14)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background {
            CyberPanelShape(cut: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            definition.appearance.top,
                            definition.appearance.bottom,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            CyberPanelShape(cut: 16)
                .strokeBorder(
                    definition.appearance.accent.opacity(0.65),
                    lineWidth: 1
                )
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(definition.title.uppercased())
                    .font(
                        .system(
                            size: 15,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(definition.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Image(
                systemName: canStart
                    ? "bolt.shield.fill"
                    : "lock.fill"
            )
            .font(
                .system(
                    size: 17,
                    weight: .bold
                )
            )
            .foregroundStyle(
                definition.appearance.accent
            )
        }
    }

    // MARK: Information

    private var information: some View {
        VStack(
            alignment: .leading,
            spacing: 9
        ) {
            HStack(spacing: 6) {
                Image(systemName: "star.circle.fill")

                Text(
                    "AB LEVEL \(definition.requiredAccountLevel)"
                )
            }
            .font(
                .system(
                    size: 10,
                    weight: .bold,
                    design: .monospaced
                )
            )
            .foregroundStyle(
                isUnlocked ? accent : .orange
            )

            BattleAvailabilityLabel(
                definition: definition,
                accountLevel: accountLevel,
                now: now,
                accent: accent
            )

            HStack {
                Label(
                    "\(definition.energyCost) ENERGIE",
                    systemImage: "bolt.fill"
                )

                Spacer()

                Text("\(energy) VERFÜGBAR")
            }
            .font(
                .system(
                    size: 10,
                    weight: .bold,
                    design: .monospaced
                )
            )
            .foregroundStyle(
                hasEnergy ? accent : .orange
            )
            .monospacedDigit()
        }
    }

    // MARK: Start Button

    private var startButton: some View {
        Button {
            guard canStart else { return }
            onStart()
        } label: {
            HStack(spacing: 8) {
                Image(
                    systemName: canStart
                        ? "play.fill"
                        : "lock.fill"
                )

                Text(
                    canStart
                        ? "KAMPF STARTEN"
                        : statusTitle
                )

                Spacer(minLength: 0)

                if canStart {
                    Image(systemName: "chevron.right")
                }
            }
            .font(
                .system(
                    size: 11,
                    weight: .black,
                    design: .monospaced
                )
            )
            .foregroundStyle(
                canStart
                    ? .white
                    : .white.opacity(0.45)
            )
            .padding(.horizontal, 13)
            .frame(
                maxWidth: .infinity,
                minHeight: 44
            )
            .background {
                CyberPanelShape(cut: 10)
                    .fill(
                        canStart
                            ? accent.opacity(0.22)
                            : CyberTheme.navy.opacity(0.65)
                    )
            }
            .overlay {
                CyberPanelShape(cut: 10)
                    .strokeBorder(
                        accent.opacity(
                            canStart ? 0.8 : 0.2
                        )
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!canStart)
        .accessibilityLabel(
            canStart
                ? "Kampf starten: \(definition.title)"
                : "\(definition.title): \(statusTitle)"
        )
    }

    private var separator: some View {
        Rectangle()
            .fill(accent.opacity(0.3))
            .frame(height: 1)
    }
}

// MARK: - Availability

private struct BattleAvailabilityLabel: View {
    let definition: BattleEventDefinition
    let accountLevel: Int
    let now: Date
    let accent: Color

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            if let end = definition.endsAt, now >= end {
                status(
                    "BEENDET",
                    symbol: "clock.badge.xmark",
                    color: .orange
                )
            } else if let start = definition.startsAt, now < start {
                status(
                    "DEMNÄCHST",
                    symbol: "calendar.badge.clock",
                    color: .orange
                )

                Text(
                    "Start: \(start.formatted(date: .abbreviated, time: .shortened))"
                )
            } else if accountLevel < definition.requiredAccountLevel {
                status(
                    "Noch \(definition.requiredAccountLevel - accountLevel) Level",
                    symbol: "lock.fill",
                    color: .orange
                )
            } else {
                status(
                    "BEREIT",
                    symbol: "checkmark.circle.fill",
                    color: accent
                )
            }

            if let end = definition.endsAt, now < end {
                Text(
                    "Ende: \(end.formatted(date: .abbreviated, time: .shortened))"
                )
            }
        }
        .font(
            .system(
                size: 10,
                weight: .medium,
                design: .monospaced
            )
        )
        .foregroundStyle(.white.opacity(0.75))
    }

    private func status(
        _ title: String,
        symbol: String,
        color: Color
    ) -> some View {
        Label(title, systemImage: symbol)
            .foregroundStyle(color)
    }
}

// MARK: - Preview

#Preview {
    EventView(
        events: [],
        title: "EVENTS"
    )
    .environment(ResourceManager())
    .preferredColorScheme(.dark)
}
