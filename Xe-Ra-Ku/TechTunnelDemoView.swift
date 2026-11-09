//
//  TechTunnelDemoView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct TechTunnelDemoView: View {

    // MARK: - Persistent Settings

    @AppStorage("graphicsQuality")
    private var graphicsQuality = GraphicsQuality.normal.rawValue

    @AppStorage("tunnelSpeed")
    private var storedSpeed = 1.0

    @AppStorage("tunnelIntensity")
    private var storedIntensity = 1.0

    // MARK: - State

    @State private var isAnimated = true
    @State private var showsControls = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Computed Properties

    private var selectedQuality: GraphicsQuality {
        GraphicsQuality(rawValue: graphicsQuality) ?? .normal
    }

    private var speed: Float {
        Float(storedSpeed)
    }

    private var intensity: Float {
        Float(storedIntensity)
    }

    private var effectiveAnimation: Bool {
        isAnimated && !reduceMotion
    }

    // MARK: - App Version

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            TechTunnelView(
                speed: speed,
                intensity: intensity,
                isAnimated: effectiveAnimation,
                quality: selectedQuality
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)

            // Centered game logo
            VStack(spacing: 36) {
                TechGameLogo(
                    title: "XE-RA-KU",
                )

                onlineButton
            }
            .padding(.horizontal)

            // Existing header and controls
            VStack(spacing: 0) {
                header

                Spacer(minLength: 20)

                if showsControls {
                    controlsPanel
                        .transition(
                            .move(edge: .bottom)
                                .combined(with: .opacity)
                        )
                }

                footer
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .preferredColorScheme(.dark)
        .animation(
            reduceMotion ? nil : .smooth(duration: 0.35),
            value: showsControls
        )
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Text(
                "© \(String(Calendar.current.component(.year, from: .now))) Tufan Cakir"
            )
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.white)

            Text("All rights reserved.")
                .font(.system(size: 20))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("VERSION \(appVersion)")
                .font(
                    .system(
                        size: 12,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .tracking(2)
                .foregroundStyle(.white)

            Spacer()

            Button {
                showsControls.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial)
                    .clipShape(.circle)
            }
            .accessibilityLabel(
                showsControls
                    ? "Controls ausblenden"
                    : "Controls anzeigen"
            )
        }
    }

    private var onlineButton: some View {
        Button {
            // TODO: Online-Duell oder Lobby öffnen
        } label: {
            HStack(spacing: 0) {
                Text("SYSTEM HOCHFAHREN")
                    .font(
                        .system(
                            size: 20,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .tracking(3)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .background {
                TechLogoFrame()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black,
                                Color.blue,
                                Color.black,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .overlay {
                TechLogoFrame()
                    .stroke(.blue, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Controls

    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 20) {

            panelHeader

            Divider()
                .overlay(.cyan.opacity(0.3))

            graphicsControl

            speedControl

            intensityControl

            animationControl

            presetsControl

            resetButton
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            .cyan.opacity(0.25),
                            lineWidth: 1
                        )
                }
        }
    }

    private var panelHeader: some View {
        HStack {
            Label("Tunnel Controls", systemImage: "cpu")
                .font(.headline)

            Spacer()

            Text("\(selectedQuality.fps) FPS")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.cyan.opacity(0.12))
                .clipShape(.capsule)
        }
    }

    // MARK: - Graphics

    private var graphicsControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Grafikqualität", systemImage: "square.3.layers.3d")
                .font(.subheadline.weight(.medium))

            Picker("Grafikqualität", selection: $graphicsQuality) {
                ForEach(GraphicsQuality.allCases) { quality in
                    Text(quality.title)
                        .tag(quality.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .tint(.cyan)

            HStack {
                Text("Ziel: \(selectedQuality.fps) FPS")

                Spacer()

                Text(
                    "Auflösung: \(Int(selectedQuality.resolutionScale * 100)) %"
                )
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Speed

    private var speedControl: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Geschwindigkeit", systemImage: "speedometer")

                Spacer()

                Text("\(storedSpeed, specifier: "%.1f")×")
                    .monospacedDigit()
                    .foregroundStyle(.cyan)
            }
            .font(.subheadline.weight(.medium))

            Slider(
                value: $storedSpeed,
                in: 0.1...4,
                step: 0.1
            ) {
                Text("Geschwindigkeit")
            } minimumValueLabel: {
                Image(systemName: "tortoise")
            } maximumValueLabel: {
                Image(systemName: "hare")
            }
            .tint(.cyan)
        }
    }

    // MARK: - Intensity

    private var intensityControl: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Lichtintensität", systemImage: "sun.max")

                Spacer()

                Text("\(storedIntensity, specifier: "%.1f")×")
                    .monospacedDigit()
                    .foregroundStyle(.cyan)
            }
            .font(.subheadline.weight(.medium))

            Slider(
                value: $storedIntensity,
                in: 0.2...2,
                step: 0.1
            ) {
                Text("Lichtintensität")
            } minimumValueLabel: {
                Image(systemName: "sun.min")
            } maximumValueLabel: {
                Image(systemName: "sun.max.fill")
            }
            .tint(.cyan)
        }
    }

    // MARK: - Animation

    private var animationControl: some View {
        Toggle(isOn: $isAnimated) {
            Label("Animation", systemImage: "play.circle")
                .font(.subheadline.weight(.medium))
        }
        .tint(.cyan)
        .disabled(reduceMotion)
    }

    // MARK: - Presets

    private var presetsControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Presets", systemImage: "sparkles")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 10) {
                presetButton(
                    "Calm",
                    icon: "moon.stars",
                    speed: 0.4,
                    intensity: 0.6
                )

                presetButton(
                    "Normal",
                    icon: "bolt",
                    speed: 1,
                    intensity: 1
                )

                presetButton(
                    "Warp",
                    icon: "bolt.fill",
                    speed: 3.5,
                    intensity: 1.8
                )
            }
        }
    }

    private func presetButton(
        _ title: String,
        icon: String,
        speed: Double,
        intensity: Double
    ) -> some View {
        Button {
            storedSpeed = speed
            storedIntensity = intensity
            isAnimated = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.cyan.opacity(0.12))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        .cyan.opacity(0.2),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            storedSpeed = 1
            storedIntensity = 1
            graphicsQuality = GraphicsQuality.normal.rawValue
            isAnimated = true
        } label: {
            Label(
                "Einstellungen zurücksetzen",
                systemImage: "arrow.counterclockwise"
            )
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.cyan)
    }
}

#Preview {
    TechTunnelDemoView()
}
