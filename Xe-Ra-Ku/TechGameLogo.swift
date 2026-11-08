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
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let scale = min(
                    geometry.size.width / 640,
                    geometry.size.height / 100
                )

                XeRaKuLogoShape()
                    .fill(.white, style: FillStyle(eoFill: true))
                    .frame(
                        width: 640 * scale,
                        height: 100 * scale
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
            }
            .frame(height: 100)
        }
        .frame(maxWidth: 640)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), Legendary Duels")
    }
}

// MARK: - Custom Vector Logo

struct XeRaKuLogoShape: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let sx = rect.width / 640
        let sy = rect.height / 100

        func polygon(_ points: [CGPoint]) {
            guard let first = points.first else { return }

            path.move(
                to: CGPoint(
                    x: first.x * sx,
                    y: first.y * sy
                )
            )

            for point in points.dropFirst() {
                path.addLine(
                    to: CGPoint(
                        x: point.x * sx,
                        y: point.y * sy
                    )
                )
            }

            path.closeSubpath()
        }

        func add(
            _ coords: [(CGFloat, CGFloat)]
        ) {
            polygon(
                coords.map {
                    CGPoint(x: $0.0, y: $0.1)
                }
            )
        }

        // MARK: X
        add([
            (0, 5), (22, 5),
            (55, 39), (88, 5),
            (110, 5), (68, 50),
            (110, 95), (86, 95),
            (55, 62), (15, 100),
            (0, 100), (43, 50),
        ])

        // MARK: E
        add([
            (115, 5), (205, 5),
            (192, 19), (134, 19),
            (134, 40), (181, 40),
            (168, 54), (134, 54),
            (134, 80), (194, 80),
            (208, 95), (115, 95),
        ])

        // MARK: Hyphen
        add([
            (214, 43), (240, 43),
            (240, 55), (214, 55),
        ])

        // MARK: R
        add([
            (248, 5), (323, 5),
            (341, 24), (341, 39),
            (323, 57), (310, 57),
            (347, 95), (320, 95),
            (284, 57), (268, 57),
            (268, 95), (248, 95),
        ])

        // R inner cutout
        add([
            (268, 20), (315, 20),
            (322, 28), (322, 35),
            (315, 43), (268, 43),
        ])

        // MARK: A
        add([
            (350, 95), (397, 5),
            (412, 5), (462, 95),
            (440, 95), (428, 72),
            (380, 72), (370, 95),
        ])

        // A inner cutout
        add([
            (388, 56), (404, 27),
            (420, 56),
        ])

        // MARK: Hyphen
        add([
            (466, 43), (488, 43),
            (488, 55), (466, 55),
        ])

        // MARK: K
        add([
            (495, 5), (515, 5),
            (515, 42), (555, 5),
            (582, 5), (537, 48),
            (585, 95), (556, 95),
            (515, 55), (515, 95),
            (495, 95),
        ])

        // MARK: U
        add([
            (585, 5), (605, 5),
            (605, 72), (614, 80),
            (625, 72), (625, 5),
            (640, 5), (640, 78),
            (624, 95), (602, 95),
            (585, 78),
        ])

        return path
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
