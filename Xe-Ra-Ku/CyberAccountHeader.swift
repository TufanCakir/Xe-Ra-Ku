//
//  CyberAccountHeader.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct CyberAccountHeader: View {
    let tab: MenuTab
    let onBack: () -> Void

    private var accent: Color { tab.style.accent }

    @Environment(ResourceManager.self)
    private var resourceManager

    private var resources: CyberAccountResources {
        resourceManager.resources
    }

    private var panelFill: Color {
        tab.style.background.opacity(0.85)
    }

    var body: some View {
        VStack(spacing: 12) {
            navigationBar
            accountStats

            CyberEnergyGauge(
                energy: resources.energy,
                maximumEnergy: resourceManager.maximumEnergy,
                regenerationAmount: resourceManager.regenerationAmount,
                regenerationInterval: resourceManager.energyInterval,
                regenerationEnabled: resourceManager.isRegenerationEnabled,
                nextEnergyDate: resourceManager.nextEnergyDate(),
                accent: accent
            )
        }
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(accent.opacity(0.8))
                .frame(height: 1)
        }
        .animation(
            .easeOut(duration: 0.25),
            value: resources
        )
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(accent)
                    .frame(width: 44, height: 44)
                    .background(
                        panelFill,
                        in: CyberPanelShape(cut: 10)
                    )
                    .overlay {
                        CyberPanelShape(cut: 10)
                            .strokeBorder(
                                accent.opacity(0.65),
                                lineWidth: 1
                            )
                    }
                    .contentShape(
                        CyberPanelShape(cut: 10)
                    )
            }
            .accessibilityLabel("Zum Titelbildschirm")

            Spacer(minLength: 8)

            Label(tab.title, systemImage: tab.symbol)
                .font(
                    .system(
                        size: 12,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .tracking(2)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Account Stats

    private var accountStats: some View {
        HStack(spacing: 7) {
            levelPanel

            currencyPanel(
                "COINS",
                value: resources.coins,
                symbol: "circle.hexagongrid.fill",
                tint: .yellow
            )

            currencyPanel(
                "CRYSTALS",
                value: resources.crystals,
                symbol: "diamond.fill",
                tint: accent
            )
        }
    }

    private var levelPanel: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("LVL")
                    .font(
                        .system(
                            size: 9,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(accent)

                Text(resources.level.formatted())
                    .font(
                        .system(
                            size: 18,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Text(
                "\(resources.experience.formatted()) / \(resources.experienceToNextLevel.formatted()) EXP"
            )
            .font(
                .system(
                    size: 8,
                    weight: .bold,
                    design: .monospaced
                )
            )
            .foregroundStyle(.white.opacity(0.7))
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            GeometryReader { geometry in
                Capsule()
                    .fill(.white.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(accent.gradient)
                            .frame(
                                width: geometry.size.width
                                    * min(max(resources.progress, 0), 1)
                            )
                    }
            }
            .frame(height: 4)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 72)
        .background(
            panelFill,
            in: CyberPanelShape(cut: 10)
        )
        .overlay {
            CyberPanelShape(cut: 10)
                .strokeBorder(
                    accent.opacity(0.8),
                    lineWidth: 1
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Account Level \(resources.level), \(resources.experience) von \(resources.experienceToNextLevel) Erfahrungspunkten"
        )
    }

    private func currencyPanel(
        _ title: String,
        value: Int,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)

                Text(title)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .font(
                .system(
                    size: 9,
                    weight: .black,
                    design: .monospaced
                )
            )
            .lineLimit(1)
            .minimumScaleFactor(0.55)

            Text(value.formatted())
                .font(
                    .system(
                        size: 17,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(
            panelFill,
            in: CyberPanelShape(cut: 10)
        )
        .overlay {
            CyberPanelShape(cut: 10)
                .strokeBorder(
                    tint.opacity(0.75),
                    lineWidth: 1
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Energy Gauge

struct CyberEnergyGauge: View {

    let energy: Int
    let maximumEnergy: Int
    let regenerationAmount: Int
    let regenerationInterval: TimeInterval
    let regenerationEnabled: Bool
    let nextEnergyDate: Date?

    var accent: Color = CyberTheme.cyan

    private let segmentCount = 20

    private var safeMaximum: Int {
        max(1, maximumEnergy)
    }

    private var clampedEnergy: Int {
        min(max(energy, 0), safeMaximum)
    }

    private var energyFraction: Double {
        Double(clampedEnergy) / Double(safeMaximum)
    }

    private var energyColor: Color {
        energyFraction < 0.2 ? .orange : accent
    }

    private var regenerationDescription: String {
        guard regenerationEnabled else {
            return "REGENERATION PAUSIERT"
        }

        let seconds = Int(regenerationInterval)

        if seconds % 3600 == 0 {
            return "+\(regenerationAmount) / \(seconds / 3600) Std."
        }

        if seconds % 60 == 0 {
            return "+\(regenerationAmount) / \(seconds / 60) Min."
        }

        return "+\(regenerationAmount) / \(seconds) Sek."
    }

    var body: some View {
        VStack(spacing: 7) {
            header
            energySegments
            footer
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Label("ENERGIE", systemImage: "bolt.fill")

            Spacer(minLength: 8)

            Text("\(clampedEnergy) / \(safeMaximum)")
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .font(.caption2.monospaced().bold())
        .foregroundStyle(energyColor)
    }

    // MARK: - Segments

    private var energySegments: some View {
        HStack(spacing: 3) {
            ForEach(0..<segmentCount, id: \.self) { index in
                energySegment(at: index)
            }
        }
        .frame(height: 13)
    }

    private func energySegment(at index: Int) -> some View {
        let fill = min(
            1.0,
            max(
                0.0,
                energyFraction * Double(segmentCount)
                    - Double(index)
            )
        )

        return GeometryReader { geometry in
            CyberEnergySegment()
                .fill(.white.opacity(0.08))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(energyColor.gradient)
                        .frame(
                            width: geometry.size.width * fill
                        )
                        .clipShape(CyberEnergySegment())
                }
                .overlay {
                    CyberEnergySegment()
                        .strokeBorder(
                            energyColor.opacity(0.35),
                            lineWidth: 0.5
                        )
                }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Text(regenerationDescription)
                .foregroundStyle(.white.opacity(0.6))

            Spacer(minLength: 4)

            if regenerationEnabled,
                clampedEnergy < safeMaximum,
                let nextEnergyDate
            {

                TimelineView(
                    .periodic(
                        from: .now,
                        by: 1
                    )
                ) { context in
                    countdown(
                        until: nextEnergyDate,
                        now: context.date
                    )
                }

            } else {
                Text("\(Int(energyFraction * 100))%")
                    .foregroundStyle(energyColor)
            }
        }
        .font(
            .system(
                size: 9,
                weight: .bold,
                design: .monospaced
            )
        )
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    // MARK: - Countdown

    private func countdown(
        until date: Date,
        now: Date
    ) -> some View {
        let remaining = max(
            0,
            Int(ceil(date.timeIntervalSince(now)))
        )

        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        let formatted: String = {
            if hours > 0 {
                return String(
                    format: "%02d:%02d:%02d",
                    hours,
                    minutes,
                    seconds
                )
            }

            return String(
                format: "%02d:%02d",
                minutes,
                seconds
            )
        }()

        return HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 9))

            Text(formatted)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .foregroundStyle(energyColor)
        .accessibilityLabel(
            "Nächste Energie in \(formatted)"
        )
    }
}

// MARK: - Energy Segment Shape

private struct CyberEnergySegment: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(
            dx: insetAmount,
            dy: insetAmount
        )

        guard r.width > 0, r.height > 0 else {
            return Path()
        }

        return Path { path in
            let slant = r.width * 0.28

            path.move(
                to: CGPoint(x: r.minX + slant, y: r.minY)
            )
            path.addLine(
                to: CGPoint(x: r.maxX, y: r.minY)
            )
            path.addLine(
                to: CGPoint(
                    x: r.maxX - slant,
                    y: r.maxY
                )
            )
            path.addLine(
                to: CGPoint(x: r.minX, y: r.maxY)
            )
            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> CyberEnergySegment {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

#Preview {
    CyberAccountHeader(
        tab: .home,
        onBack: {}
    )
    .environment(
        ResourceManager(
            defaults: UserDefaults(
                suiteName: "CyberAccountHeaderPreview"
            )!
        )
    )
    .preferredColorScheme(.dark)
}
