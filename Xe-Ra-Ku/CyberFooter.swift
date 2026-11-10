//
//  CyberFooter.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 10.11.26.
//

import SwiftUI

struct CyberFooter: View {
    @Binding var selection: MenuTab

    @Namespace private var namespace

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private var currentAccent: Color {
        selection.style.accent
    }

    private var selectionAnimation: Animation? {
        reduceMotion
            ? nil
            : .spring(
                response: 0.32,
                dampingFraction: 0.86
            )
    }

    var body: some View {
        VStack(spacing: 0) {
            topBorder

            HStack(spacing: 4) {
                ForEach(MenuTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
        .animation(
            selectionAnimation,
            value: selection
        )
    }

    // MARK: - Top Border

    private var topBorder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        currentAccent.opacity(0.8),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .allowsHitTesting(false)
    }

    // MARK: - Tab Button

    private func tabButton(
        _ tab: MenuTab
    ) -> some View {
        let active = selection == tab
        let accent = tab.style.accent

        return Button {
            guard selection != tab else { return }

            selection = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.symbol)
                    .font(
                        .system(
                            size: 19,
                            weight: active ? .bold : .medium
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(height: 23)

                Text(tab.title)
                    .font(
                        .system(
                            size: 8,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(height: 12)
            }
            .foregroundStyle(
                active
                    ? accent
                    : .white.opacity(0.55)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                if active {
                    CyberPanelShape(cut: 9)
                        .fill(accent.opacity(0.15))
                        .overlay {
                            CyberPanelShape(cut: 9)
                                .strokeBorder(
                                    accent.opacity(0.85),
                                    lineWidth: 1
                                )
                        }
                        .matchedGeometryEffect(
                            id: "activeTab",
                            in: namespace
                        )
                }
            }
            .overlay(alignment: .top) {
                if active {
                    Capsule()
                        .fill(accent)
                        .frame(width: 20, height: 2)
                        .offset(y: -1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(
            active ? .isSelected : []
        )
        .accessibilityHint(
            active
                ? "Aktuell ausgewählt"
                : "Tab öffnen"
        )
    }
}

#Preview {
    MenuView()
        .environment(ResourceManager())
        .preferredColorScheme(.dark)
}
