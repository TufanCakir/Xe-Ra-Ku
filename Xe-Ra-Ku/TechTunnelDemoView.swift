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
    @AppStorage("tunnelAnimationEnabled") private var isAnimated = true
    @State private var showSettings = false
    @State private var showMenu = false
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
        NavigationStack {
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
                        title: "XE-RA-KU"
                    )
                    onlineButton
                }
                .padding(.horizontal)
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 20)
                    footer.padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .preferredColorScheme(.dark)
            .navigationDestination(isPresented: $showMenu) {
                MenuView()
                    .navigationBarBackButtonHidden()
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
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
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial)
                    .clipShape(.circle)
            }
            .accessibilityLabel("Einstellungen")
        }
    }
    private var onlineButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.5)) {
                showMenu = true
            }
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
                CyberPanelShape(cut: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                CyberTheme.navy,
                                CyberTheme.blue,
                                CyberTheme.navy,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                CyberPanelShape(cut: 24).stroke(
                    CyberTheme.blue,
                    lineWidth: 2
                )
            )
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    TechTunnelDemoView()
}
