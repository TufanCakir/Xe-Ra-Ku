//
//  TechGameLogo.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct TechGameLogo: View {

    var title: String = "XE-RA-KU"

    var body: some View {
        Image(.xeRaKuLogo)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(title)
    }
}

// MARK: - Custom Shape

struct TechLogoFrame: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cut: CGFloat = 20
        let inset: CGFloat = 2

        path.move(
            to: CGPoint(
                x: rect.minX + cut,
                y: rect.minY + inset
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - cut,
                y: rect.minY + inset
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - inset,
                y: rect.minY + cut
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - inset,
                y: rect.maxY - cut
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - cut,
                y: rect.maxY - inset
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + cut,
                y: rect.maxY - inset
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + inset,
                y: rect.maxY - cut
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + inset,
                y: rect.minY + cut
            )
        )

        path.closeSubpath()

        return path
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        TechGameLogo()
            .padding(20)
    }
}
