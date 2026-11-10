//
//  CyberBattleControls.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 10.11.26.
//

import SwiftUI

struct CyberBattleControlButton: View {
    let title: String
    let symbol: String

    var isActive = false
    var isDestructive = false
    var color: Color = CyberTheme.cyan
    var fillsWidth = false

    let action: () -> Void

    private var accent: Color {
        isDestructive ? .red : color
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))

                Text(title)
                    .font(
                        .system(
                            size: 11,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isActive ? CyberTheme.navy : accent)
            .padding(.horizontal, 12)
            .frame(
                maxWidth: fillsWidth ? .infinity : nil,
                minHeight: 44
            )
            .background {
                CyberPanelShape(cut: 9)
                    .fill(
                        isActive
                            ? accent
                            : CyberTheme.navy.opacity(0.92)
                    )
            }
            .overlay {
                CyberPanelShape(cut: 9)
                    .stroke(accent.opacity(0.8), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isActive)
    }
}

struct CyberBattlePlaybackControls: View {

    let autoMode: Bool
    let speed: Double

    var accent: Color = CyberTheme.cyan

    let onToggleAuto: () -> Void
    let onCycleSpeed: () -> Void

    var body: some View {
        HStack(spacing: 8) {

            CyberBattleControlButton(
                title: "AUTO",
                symbol: "arrow.triangle.2.circlepath",
                isActive: autoMode,
                color: accent,
                action: onToggleAuto
            )
            .accessibilityLabel(
                autoMode
                    ? "Automatik ausschalten"
                    : "Automatik einschalten"
            )

            CyberBattleControlButton(
                title: "\(speed.formatted())×",
                symbol: "forward.end.fill",
                color: accent,
                action: onCycleSpeed
            )
            .accessibilityLabel("Geschwindigkeit ändern")
        }
    }
}

#Preview {
    OnlineBattleView()
}
