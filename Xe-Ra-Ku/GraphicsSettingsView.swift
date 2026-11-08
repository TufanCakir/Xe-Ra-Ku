//
//  GraphicsSettingsView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

struct GraphicsSettingsView: View {
    @AppStorage("graphicsQuality")
    private var graphicsQuality = GraphicsQuality.normal.rawValue

    var body: some View {
        Form {
            Section("Grafik") {
                Picker("Grafikqualität", selection: $graphicsQuality) {
                    ForEach(GraphicsQuality.allCases) { quality in
                        Text(quality.title)
                            .tag(quality.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                LabeledContent(
                    "FPS",
                    value: "\(selectedQuality.fps)"
                )

                LabeledContent(
                    "Auflösung",
                    value: "\(Int(selectedQuality.resolutionScale * 100)) %"
                )
            } header: {
                Text("Render-Einstellungen")
            } footer: {
                Text(
                    "Die tatsächliche Bildrate hängt vom Gerät und der GPU-Leistung ab."
                )
            }
        }
        .navigationTitle("Grafik")
    }

    private var selectedQuality: GraphicsQuality {
        GraphicsQuality(rawValue: graphicsQuality) ?? .normal
    }
}
