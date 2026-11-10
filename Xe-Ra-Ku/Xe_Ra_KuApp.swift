//
//  Xe_Ra_KuApp.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import SwiftUI

@main
struct Xe_Ra_KuApp: App {
    @State private var resourceManager = ResourceManager()

    var body: some Scene {
        WindowGroup {
            TechTunnelDemoView()
                .environment(resourceManager)
        }
    }
}
