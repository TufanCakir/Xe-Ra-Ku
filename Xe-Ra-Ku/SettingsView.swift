//
//  SettingsView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @AppStorage("graphicsQuality")
    private var graphicsQuality = GraphicsQuality.normal.rawValue

    @AppStorage("tunnelSpeed")
    private var storedSpeed = 1.0

    @AppStorage("tunnelIntensity")
    private var storedIntensity = 1.0

    @AppStorage("tunnelAnimationEnabled")
    private var isAnimated = true

    @State private var showResetConfirmation = false

    private let accent = MenuTab.settings.style.accent

    private var selectedQuality: GraphicsQuality {
        GraphicsQuality(rawValue: graphicsQuality) ?? .normal
    }

    private var animationActive: Bool {
        isAnimated && !reduceMotion
    }

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                heading
                graphicsSection
                tunnelSection
                presetsSection
                aboutSection
            }
            .padding(14)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(.white)
        .tint(accent)
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Einstellungen zurücksetzen?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Zurücksetzen",
                role: .destructive
            ) {
                resetSettings()
            }

            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text(
                "Grafikqualität und Tunnel-Einstellungen werden auf die Standardwerte zurückgesetzt."
            )
        }
    }

    // MARK: - Header

    private var heading: some View {
        HStack(spacing: 10) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .cyberPanel(accent: accent, cut: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("SYSTEM // KONFIGURATION")
                    .font(
                        .system(
                            size: 9,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .tracking(1.5)
                    .foregroundStyle(accent)

                Text("EINSTELLUNGEN")
                    .font(
                        .system(
                            size: 20,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Graphics

    private var graphicsSection: some View {
        section(
            "GRAFIK",
            symbol: "square.3.layers.3d"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("GRAFIKQUALITÄT")
                    .font(
                        .system(
                            size: 10,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.white.opacity(0.7))

                Picker(
                    "Grafikqualität",
                    selection: $graphicsQuality
                ) {
                    ForEach(GraphicsQuality.allCases) { quality in
                        Text(quality.title)
                            .tag(quality.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                separator

                valueRow(
                    "BILDRATE",
                    value: "\(selectedQuality.fps) FPS"
                )

                valueRow(
                    "AUFLÖSUNG",
                    value: "\(Int(selectedQuality.resolutionScale * 100)) %"
                )
            }
        }
    }

    // MARK: - Tunnel

    private var tunnelSection: some View {
        section(
            "TECH-TUNNEL",
            symbol: "cpu"
        ) {
            VStack(spacing: 14) {
                Toggle(isOn: $isAnimated) {
                    Label(
                        "ANIMATION",
                        systemImage: "play.circle"
                    )
                    .font(
                        .system(
                            size: 11,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                }
                .disabled(reduceMotion)

                if reduceMotion {
                    Label(
                        "Durch „Bewegung reduzieren“ deaktiviert.",
                        systemImage: "accessibility"
                    )
                    .font(
                        .system(
                            size: 10,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.white.opacity(0.6))
                }

                separator

                VStack(spacing: 6) {
                    valueRow(
                        "GESCHWINDIGKEIT",
                        value: String(
                            format: "%.1f×",
                            storedSpeed
                        )
                    )

                    Slider(
                        value: $storedSpeed,
                        in: 0.1...4,
                        step: 0.1
                    )
                    .accessibilityLabel(
                        "Tunnelgeschwindigkeit"
                    )
                }

                VStack(spacing: 6) {
                    valueRow(
                        "LICHTINTENSITÄT",
                        value: String(
                            format: "%.1f×",
                            storedIntensity
                        )
                    )

                    Slider(
                        value: $storedIntensity,
                        in: 0.2...2,
                        step: 0.1
                    )
                    .accessibilityLabel(
                        "Lichtintensität"
                    )
                }
            }
            .disabled(!animationActive)
        }
    }

    // MARK: - Presets

    private var presetsSection: some View {
        section(
            "VOREINSTELLUNGEN",
            symbol: "slider.horizontal.3"
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 7) {
                    preset(
                        "RUHIG",
                        symbol: "moon.stars",
                        speed: 0.4,
                        intensity: 0.6
                    )

                    preset(
                        "NORMAL",
                        symbol: "bolt",
                        speed: 1,
                        intensity: 1
                    )

                    preset(
                        "WARP",
                        symbol: "bolt.fill",
                        speed: 3.5,
                        intensity: 1.8
                    )
                }

                Button {
                    showResetConfirmation = true
                } label: {
                    Label(
                        "EINSTELLUNGEN ZURÜCKSETZEN",
                        systemImage: "arrow.counterclockwise"
                    )
                    .font(
                        .system(
                            size: 10,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .cyberPanel(
                        accent: accent,
                        cut: 10
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        section(
            "XE-RA-KU",
            symbol: "info.circle"
        ) {
            VStack(spacing: 10) {
                valueRow(
                    "VERSION",
                    value: appVersion
                )

                valueRow(
                    "BUILD",
                    value: buildNumber
                )
            }
        }
    }

    // MARK: - Components

    private var separator: some View {
        Rectangle()
            .fill(accent.opacity(0.25))
            .frame(height: 1)
    }

    private func section<Content: View>(
        _ title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 13
        ) {
            Label(title, systemImage: symbol)
                .font(
                    .system(
                        size: 11,
                        weight: .black,
                        design: .monospaced
                    )
                )
                .tracking(0.8)
                .foregroundStyle(accent)

            content()
        }
        .padding(14)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .cyberPanel(
            accent: accent,
            cut: 14
        )
    }

    private func valueRow(
        _ title: String,
        value: String
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .foregroundStyle(.white.opacity(0.7))

            Spacer(minLength: 4)

            Text(value)
                .foregroundStyle(accent)
                .monospacedDigit()
        }
        .font(
            .system(
                size: 10,
                weight: .bold,
                design: .monospaced
            )
        )
    }

    private func preset(
        _ title: String,
        symbol: String,
        speed: Double,
        intensity: Double
    ) -> some View {
        let selected =
            abs(storedSpeed - speed) < 0.05
            && abs(storedIntensity - intensity) < 0.05

        return Button {
            withAnimation(
                reduceMotion
                    ? nil
                    : .easeInOut(duration: 0.2)
            ) {
                storedSpeed = speed
                storedIntensity = intensity
                isAnimated = true
            }
        } label: {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )

                Text(title)
                    .font(
                        .system(
                            size: 9,
                            weight: .black,
                            design: .monospaced
                        )
                    )
            }
            .foregroundStyle(
                selected ? CyberTheme.navy : accent
            )
            .frame(
                maxWidth: .infinity,
                minHeight: 64
            )
            .background {
                CyberPanelShape(cut: 10)
                    .fill(
                        selected
                            ? accent
                            : CyberTheme.navy.opacity(0.9)
                    )
            }
            .overlay {
                CyberPanelShape(cut: 10)
                    .strokeBorder(
                        accent.opacity(
                            selected ? 1 : 0.4
                        )
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reset

    private func resetSettings() {
        graphicsQuality = GraphicsQuality.normal.rawValue
        storedSpeed = 1
        storedIntensity = 1
        isAnimated = true
    }
}

#Preview {
    SettingsView()
}
