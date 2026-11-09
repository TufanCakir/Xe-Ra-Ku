//
//  MenuView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import SwiftUI

// MARK: - Navigation

private enum MenuTab: String, CaseIterable, Identifiable {
    case home, duel, cards, decks, profile

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "HOME"
        case .duel: "DUELL"
        case .cards: "KARTEN"
        case .decks: "DECKS"
        case .profile: "PROFIL"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .duel: "bolt.shield.fill"
        case .cards: "rectangle.stack.fill"
        case .decks: "square.stack.3d.up.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

private enum MenuPalette {
    static let background = Color(red: 0, green: 0, blue: 0)
    static let surface = Color(red: 0.035, green: 0.075, blue: 0.16)
    static let cyan = Color(.blue)
    static let blue = Color(red: 0.15, green: 0.37, blue: 1)
}

// MARK: - Root

struct MenuView: View {
    @State private var selectedTab: MenuTab = .home

    var body: some View {
        ZStack {
            MenuPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Group {
                    switch selectedTab {
                    case .home:
                        homeContent
                    case .duel:
                        OnlineBattleView()
                    case .cards:
                        placeholder(
                            title: "KARTENSAMMLUNG",
                            subtitle: "Entdecke deine Xe-Ra-Ku-Karten.",
                            symbol: "rectangle.stack.fill"
                        )
                    case .decks:
                        placeholder(
                            title: "DECK-BUILDER",
                            subtitle: "Erstelle und verwalte deine Decks.",
                            symbol: "square.stack.3d.up.fill"
                        )
                    case .profile:
                        placeholder(
                            title: "SPIELERPROFIL",
                            subtitle: "Deine Statistiken und Erfolge.",
                            symbol: "person.crop.circle.fill"
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                bottomBar
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Custom Header

    private var header: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("XE-RA-KU")
                    .font(
                        .system(size: 19, weight: .black, design: .monospaced)
                    )
                    .tracking(3)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding()
        .background {
            TechLogoFrame().fill(
                LinearGradient(
                    colors: [.black, .blue, .black],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .overlay {
            TechLogoFrame().stroke(.blue, lineWidth: 1.5)
        }
    }

    // MARK: - Home

    private var homeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BEREIT FÜR DAS DUELL?")
                        .font(
                            .system(
                                size: 24,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                    Text(
                        "Stelle dein Deck zusammen und fordere den Gegner heraus."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                }

                Button {
                    changeTab(.duel)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 30))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DUELL STARTEN")
                                .font(
                                    .system(
                                        size: 17,
                                        weight: .black,
                                        design: .monospaced
                                    )
                                )
                            Text("Gegen die KI antreten")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                    .background {
                        TechLogoFrame().fill(
                            LinearGradient(
                                colors: [.black, .blue, .black],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    .overlay {
                        TechLogoFrame().stroke(.blue, lineWidth: 2)
                    }
                }
                .buttonStyle(.plain)

                Text("ENTDECKEN")
                    .font(
                        .system(size: 12, weight: .black, design: .monospaced)
                    )
                    .tracking(2)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    homeShortcut(
                        title: "KARTEN",
                        subtitle: "Sammlung",
                        symbol: "rectangle.stack.fill",
                        tab: .cards
                    )
                    homeShortcut(
                        title: "DECKS",
                        subtitle: "Bearbeiten",
                        symbol: "square.stack.3d.up.fill",
                        tab: .decks
                    )
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
    }

    private func homeShortcut(
        title: String,
        subtitle: String,
        symbol: String,
        tab: MenuTab
    ) -> some View {
        Button {
            changeTab(tab)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                Text(title)
                    .font(
                        .system(size: 13, weight: .black, design: .monospaced)
                    )
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                TechLogoFrame().fill(
                    LinearGradient(
                        colors: [.black, .blue, .black],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .overlay {
                TechLogoFrame().stroke(.blue, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func placeholder(title: String, subtitle: String, symbol: String)
        -> some View
    {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(subtitle)
        }
        .foregroundStyle(.white)
    }

    // MARK: - Custom Bottom Navigation

    private var bottomBar: some View {
        HStack(spacing: 3) {
            ForEach(MenuTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    changeTab(tab)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(
                                .system(
                                    size: 19,
                                    weight: isSelected ? .bold : .medium
                                )
                            )
                            .symbolEffect(.bounce, value: isSelected)
                        Text(tab.title)
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
                    .foregroundStyle(
                        isSelected ? .white : .white.opacity(0.55)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(MenuPalette.blue.opacity(0.22))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(7)
        .background {
            TechLogoFrame().fill(
                LinearGradient(
                    colors: [.black, .blue, .black],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .overlay {
            TechLogoFrame().stroke(.blue, lineWidth: 1.5)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 5)
        .background(MenuPalette.background)
    }

    private func changeTab(_ tab: MenuTab) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
        }
    }
}

#Preview {
    MenuView()
}
