//
//  CyberBattleOverlay.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 10.11.26.
//

import SwiftUI

struct CyberBattleOverlay: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color

    let primaryTitle: String
    let primarySymbol: String
    let primaryAction: () -> Void

    var secondaryTitle: String? = nil
    var secondaryAction: () -> Void = {}

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.88)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    header

                    Rectangle()
                        .fill(accent.opacity(0.45))
                        .frame(height: 1)

                    Image(systemName: symbol)
                        .font(
                            .system(
                                size: 42,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(accent)
                        .frame(height: 58)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(
                            .system(
                                size: 20,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(
                                .system(
                                    size: 11,
                                    weight: .medium,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                    }

                    Rectangle()
                        .fill(accent.opacity(0.25))
                        .frame(height: 1)

                    VStack(spacing: 9) {
                        actionButton(
                            primaryTitle,
                            symbol: primarySymbol,
                            prominent: true,
                            action: primaryAction
                        )

                        if let secondaryTitle {
                            actionButton(
                                secondaryTitle,
                                symbol: "arrow.uturn.backward",
                                prominent: false,
                                action: secondaryAction
                            )
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: 340)
                .background {
                    CyberPanelShape(cut: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accent.opacity(0.17),
                                    CyberTheme.navy,
                                    CyberTheme.navy,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    CyberPanelShape(cut: 18)
                        .strokeBorder(
                            accent.opacity(0.8),
                            lineWidth: 1.5
                        )
                }
                .padding(.horizontal, 16)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.shield.fill")
                .foregroundStyle(accent)

            Text("XE-RA-KU // SYSTEM")
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            Image(systemName: "circle.hexagongrid.fill")
                .foregroundStyle(accent.opacity(0.7))
        }
        .font(
            .system(
                size: 9,
                weight: .black,
                design: .monospaced
            )
        )
    }

    // MARK: - Button

    private func actionButton(
        _ title: String,
        symbol: String,
        prominent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(
                        .system(
                            size: 13,
                            weight: .bold
                        )
                    )

                Text(title)
                    .font(
                        .system(
                            size: 11,
                            weight: .black,
                            design: .monospaced
                        )
                    )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 10,
                            weight: .bold
                        )
                    )
            }
            .foregroundStyle(
                prominent
                    ? CyberTheme.navy
                    : .white
            )
            .padding(.horizontal, 14)
            .frame(
                maxWidth: .infinity,
                minHeight: 46
            )
            .background {
                CyberPanelShape(cut: 10)
                    .fill(
                        prominent
                            ? accent
                            : CyberTheme.navy.opacity(0.8)
                    )
            }
            .overlay {
                CyberPanelShape(cut: 10)
                    .strokeBorder(
                        accent.opacity(
                            prominent ? 1 : 0.5
                        ),
                        lineWidth: 1
                    )
            }
            .contentShape(
                CyberPanelShape(cut: 10)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        CyberTheme.navy
            .ignoresSafeArea()

        CyberBattleOverlay(
            title: "SIEG",
            subtitle: "Du hast deinen Gegner besiegt!",
            symbol: "trophy.fill",
            accent: .green,
            primaryTitle: "ZUR AUSWAHL",
            primarySymbol: "square.grid.2x2.fill",
            primaryAction: {},
            secondaryTitle: "NOCH EINMAL",
            secondaryAction: {}
        )
    }
    .preferredColorScheme(.dark)
}
