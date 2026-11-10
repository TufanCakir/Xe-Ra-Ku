//
//  CyberDesignSystem.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 10.11.26.
//

import SwiftUI

// MARK: - Cyber Theme

enum CyberTheme {
    static let navy = Color(
        red: 0.015,
        green: 0.035,
        blue: 0.09
    )

    static let blue = Color(
        red: 0.08,
        green: 0.28,
        blue: 0.72
    )

    static let cyan = Color(
        red: 0.25,
        green: 0.87,
        blue: 1
    )

    static let duel = cyan

    static let event = Color(
        red: 1,
        green: 0.67,
        blue: 0.2
    )

    static let cards = Color(
        red: 0.53,
        green: 0.59,
        blue: 1
    )

    static let decks = Color(
        red: 0.75,
        green: 0.45,
        blue: 1
    )

    static let settings = Color(
        red: 0.58,
        green: 0.72,
        blue: 0.82
    )

    // MARK: Backgrounds

    static let duelBackground = Color(
        red: 0.015,
        green: 0.055,
        blue: 0.11
    )

    static let eventBackground = Color(
        red: 0.09,
        green: 0.035,
        blue: 0.065
    )

    static let cardsBackground = Color(
        red: 0.035,
        green: 0.035,
        blue: 0.105
    )

    static let decksBackground = Color(
        red: 0.055,
        green: 0.025,
        blue: 0.09
    )

    static let settingsBackground = Color(
        red: 0.025,
        green: 0.035,
        blue: 0.055
    )
}

// MARK: - Cyber Panel Shape

struct CyberPanelShape: InsettableShape {
    var cut: CGFloat = 12
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(
            dx: insetAmount,
            dy: insetAmount
        )

        guard r.width > 0, r.height > 0 else {
            return Path()
        }

        let corner = min(
            max(0, cut - insetAmount),
            r.width / 4,
            r.height / 3
        )

        return Path { path in
            path.move(
                to: CGPoint(
                    x: r.minX + corner,
                    y: r.minY
                )
            )

            path.addLine(
                to: CGPoint(x: r.maxX, y: r.minY)
            )

            path.addLine(
                to: CGPoint(
                    x: r.maxX,
                    y: r.maxY - corner
                )
            )

            path.addLine(
                to: CGPoint(
                    x: r.maxX - corner,
                    y: r.maxY
                )
            )

            path.addLine(
                to: CGPoint(x: r.minX, y: r.maxY)
            )

            path.addLine(
                to: CGPoint(
                    x: r.minX,
                    y: r.minY + corner
                )
            )

            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> CyberPanelShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

// MARK: - Cyber Background

struct CyberBackground: View {
    var accent: Color = CyberTheme.cyan
    var showGrid = true
    var background: Color = CyberTheme.navy
    var glow: Color? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        background,
                        glow ?? accent.opacity(0.14),
                        background,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if showGrid {
                    gridLayer
                }

                decorativePanel(
                    size: geometry.size
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var gridLayer: some View {
        Canvas { context, size in
            var horizontal = Path()
            var vertical = Path()

            let spacing: CGFloat = 48

            for x in stride(
                from: CGFloat(0),
                through: size.width,
                by: spacing
            ) {
                vertical.move(
                    to: CGPoint(x: x, y: 0)
                )
                vertical.addLine(
                    to: CGPoint(x: x, y: size.height)
                )
            }

            for y in stride(
                from: CGFloat(0),
                through: size.height,
                by: spacing
            ) {
                horizontal.move(
                    to: CGPoint(x: 0, y: y)
                )
                horizontal.addLine(
                    to: CGPoint(x: size.width, y: y)
                )
            }

            context.stroke(
                vertical,
                with: .color(accent.opacity(0.045)),
                lineWidth: 0.5
            )

            context.stroke(
                horizontal,
                with: .color(accent.opacity(0.065)),
                lineWidth: 0.5
            )
        }
    }

    private func decorativePanel(
        size: CGSize
    ) -> some View {
        CyberPanelShape(cut: 28)
            .fill(accent.opacity(0.045))
            .frame(
                width: size.width * 0.85,
                height: 140
            )
            .rotationEffect(.degrees(-12))
            .offset(
                x: size.width * 0.28,
                y: -size.height * 0.3
            )
    }
}

// MARK: - Cyber Panel Modifier

struct CyberPanelModifier: ViewModifier {
    var accent: Color = CyberTheme.cyan
    var cut: CGFloat = 12
    var prominent = false

    func body(content: Content) -> some View {
        let shape = CyberPanelShape(cut: cut)

        content
            .background {
                shape.fill(
                    LinearGradient(
                        colors: [
                            prominent
                                ? accent.opacity(0.20)
                                : CyberTheme.navy.opacity(0.96),
                            CyberTheme.navy,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                shape.strokeBorder(
                    accent.opacity(
                        prominent ? 0.8 : 0.4
                    ),
                    lineWidth: prominent ? 1.5 : 1
                )
            }
            .contentShape(shape)
    }
}

extension View {
    func cyberPanel(
        accent: Color = CyberTheme.cyan,
        cut: CGFloat = 12,
        prominent: Bool = false
    ) -> some View {
        modifier(
            CyberPanelModifier(
                accent: accent,
                cut: cut,
                prominent: prominent
            )
        )
    }
}

// MARK: - Cyber Action Button

struct CyberActionButton: View {
    let title: String
    var subtitle: String? = nil
    var symbol: String = "bolt.fill"
    var accent: Color = CyberTheme.cyan
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(
                        .system(
                            size: 22,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(accent)
                    .frame(width: 30)

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(title)
                        .font(
                            .system(
                                size: 14,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if let subtitle {
                        Text(subtitle)
                            .font(
                                .system(
                                    size: 10,
                                    weight: .medium,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(
                                .white.opacity(0.65)
                            )
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 12,
                            weight: .black
                        )
                    )
                    .foregroundStyle(accent)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(
                maxWidth: .infinity,
                minHeight: 66
            )
            .cyberPanel(
                accent: accent,
                cut: 16,
                prominent: true
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            subtitle.map { "\(title), \($0)" } ?? title
        )
    }
}
