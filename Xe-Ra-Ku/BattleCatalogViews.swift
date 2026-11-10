//
//  BattleCatalogViews.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

// MARK: - Character Picker

struct BattleCharacterPicker: View {
    let characters: [BattleCharacterDefinition]
    let accountLevel: Int
    let selectedID: String?
    let onSelect: (BattleCharacterDefinition) -> Void
    let style: CyberNavigationStyle

    var body: some View {
        LazyVStack(spacing: 9) {
            ForEach(characters) { character in
                characterRow(character)
            }
        }
    }

    private func characterRow(
        _ character: BattleCharacterDefinition
    ) -> some View {
        let unlocked = character.isUnlocked(
            accountLevel: accountLevel
        )
        let selected = unlocked && selectedID == character.id

        return Button {
            guard unlocked else { return }
            onSelect(character)
        } label: {
            HStack(spacing: 12) {
                Image(character.portraitAsset)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .opacity(unlocked ? 1 : 0.45)

                VStack(alignment: .leading, spacing: 5) {
                    Text(character.name.uppercased())
                        .font(
                            .system(
                                size: 12,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    HStack(spacing: 5) {
                        Image(
                            systemName: unlocked
                                ? "checkmark.shield.fill"
                                : "lock.fill"
                        )

                        Text(
                            unlocked
                                ? "FREIGESCHALTET"
                                : "AB LEVEL \(character.requiredAccountLevel)"
                        )
                    }
                    .font(
                        .system(
                            size: 9,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        unlocked
                            ? style.accent
                            : .orange
                    )
                }

                Spacer(minLength: 6)

                Image(
                    systemName: unlocked
                        ? (selected
                            ? "checkmark.circle.fill"
                            : "circle")
                        : "lock.fill"
                )
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    unlocked
                        ? style.accent
                        : .white.opacity(0.35)
                )
            }
            .foregroundStyle(.white)
            .padding(12)
            .background {
                CyberPanelShape(cut: 12)
                    .fill(
                        selected
                            ? style.accent.opacity(0.22)
                            : style.background.opacity(0.9)
                    )
            }
            .overlay {
                CyberPanelShape(cut: 12)
                    .strokeBorder(
                        style.accent.opacity(
                            selected ? 0.95 : 0.3
                        ),
                        lineWidth: selected ? 1.5 : 1
                    )
            }
            .contentShape(CyberPanelShape(cut: 12))
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityAddTraits(
            selected ? .isSelected : []
        )
    }
}

// MARK: - Enemy Picker

struct BattleEnemyPicker: View {
    let enemies: [BattleEnemyDefinition]
    let accountLevel: Int
    let onSelect: (BattleEnemyDefinition) -> Void
    let style: CyberNavigationStyle

    var body: some View {
        LazyVStack(spacing: 9) {
            ForEach(enemies) { enemy in
                enemyRow(enemy)
            }
        }
    }

    private func enemyRow(
        _ enemy: BattleEnemyDefinition
    ) -> some View {
        let unlocked = enemy.isUnlocked(
            accountLevel: accountLevel
        )

        return Button {
            guard unlocked else { return }
            onSelect(enemy)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(style.accent)
                    .frame(width: 42, height: 42)
                    .background(
                        style.accent.opacity(0.12),
                        in: CyberPanelShape(cut: 9)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(enemy.name.uppercased())
                        .font(
                            .system(
                                size: 12,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(
                        "LP \(enemy.lifePoints) · STUFE \(enemy.difficulty)"
                    )
                    .font(
                        .system(
                            size: 10,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.white.opacity(0.65))

                    if !unlocked {
                        Label(
                            "AB LEVEL \(enemy.requiredAccountLevel)",
                            systemImage: "lock.fill"
                        )
                        .font(
                            .system(
                                size: 9,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.orange)
                    }
                }

                Spacer(minLength: 4)

                Image(
                    systemName: unlocked
                        ? "chevron.right"
                        : "lock.fill"
                )
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(
                    unlocked
                        ? style.accent
                        : .white.opacity(0.35)
                )
            }
            .foregroundStyle(.white)
            .padding(12)
            .background {
                CyberPanelShape(cut: 12)
                    .fill(style.background.opacity(0.9))
            }
            .overlay {
                CyberPanelShape(cut: 12)
                    .strokeBorder(
                        style.accent.opacity(
                            unlocked ? 0.4 : 0.2
                        ),
                        lineWidth: 1
                    )
            }
            .contentShape(CyberPanelShape(cut: 12))
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}

// MARK: - Selection Navigation

private enum BattleSelectionTab:
    String, CaseIterable, Identifiable
{

    case characters
    case enemies

    var id: Self { self }

    var title: String {
        switch self {
        case .characters: "CHARAKTERE"
        case .enemies: "GEGNER"
        }
    }

    var symbol: String {
        switch self {
        case .characters: "person.crop.square"
        case .enemies: "shield.lefthalf.filled"
        }
    }
}

// MARK: - Battle Selection View

struct BattleSelectionView: View {
    let catalog: BattleCatalog
    let accountLevel: Int
    let selectedCharacterID: String?
    let onSelectCharacter: (BattleCharacterDefinition) -> Void
    let onSelectEnemy: (BattleEnemyDefinition) -> Void
    let style: CyberNavigationStyle

    @State private var selectedTab: BattleSelectionTab = .characters
    @Namespace private var selectionNamespace

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private var navigationAnimation: Animation? {
        reduceMotion
            ? nil
            : .smooth(duration: 0.25)
    }

    var body: some View {
        ZStack {
            CyberBackground(
                accent: style.accent,
                showGrid: style.showGrid,
                background: style.background,
                glow: style.backgroundGlow
            )

            VStack(spacing: 0) {
                header
                selectionContent
                navigationBar
            }
        }
        .foregroundStyle(.white)
        .tint(style.accent)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("XE-RA-KU / AUSWAHL")
                    .font(
                        .system(
                            size: 10,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(style.accent)

                Text(selectedTab.title)
                    .font(
                        .system(
                            size: 22,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 4)

            Label(
                "LV \(accountLevel)",
                systemImage: "star.fill"
            )
            .font(
                .system(
                    size: 11,
                    weight: .bold,
                    design: .monospaced
                )
            )
            .foregroundStyle(style.accent)
            .lineLimit(1)
        }
        .padding(16)
    }

    // MARK: - Content

    private var selectionContent: some View {
        ScrollView {
            Group {
                switch selectedTab {
                case .characters:
                    BattleCharacterPicker(
                        characters: catalog.characters,
                        accountLevel: accountLevel,
                        selectedID: selectedCharacterID,
                        onSelect: onSelectCharacter,
                        style: style
                    )

                case .enemies:
                    BattleEnemyPicker(
                        enemies: catalog.enemies,
                        accountLevel: accountLevel,
                        onSelect: onSelectEnemy,
                        style: style
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack(spacing: 6) {
            ForEach(BattleSelectionTab.allCases) { tab in
                navigationButton(tab)
            }
        }
        .padding(7)
        .background {
            CyberPanelShape(cut: 16)
                .fill(style.background.opacity(0.96))
        }
        .overlay {
            CyberPanelShape(cut: 16)
                .strokeBorder(
                    style.accent.opacity(0.35),
                    lineWidth: 1
                )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private func navigationButton(
        _ tab: BattleSelectionTab
    ) -> some View {
        let selected = selectedTab == tab

        return Button {
            guard selectedTab != tab else { return }

            withAnimation(navigationAnimation) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: tab.symbol)

                Text(tab.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .font(
                .system(
                    size: 12,
                    weight: .black,
                    design: .monospaced
                )
            )
            .foregroundStyle(
                selected
                    ? .white
                    : .white.opacity(0.55)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background {
                if selected {
                    CyberPanelShape(cut: 11)
                        .fill(style.accent.opacity(0.25))
                        .overlay {
                            CyberPanelShape(cut: 11)
                                .strokeBorder(
                                    style.accent.opacity(0.85),
                                    lineWidth: 1
                                )
                        }
                        .matchedGeometryEffect(
                            id: "selection",
                            in: selectionNamespace
                        )
                }
            }
            .contentShape(CyberPanelShape(cut: 11))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            selected ? .isSelected : []
        )
    }
}
