//
//  ContentView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 08.11.26.
//

import MetalKit
import SwiftUI

enum GraphicsQuality: String, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }

    var fps: Int {
        switch self {
        case .low: 30
        case .normal: 60
        case .high: 120
        }
    }

    var resolutionScale: CGFloat {
        switch self {
        case .low: 0.5
        case .normal: 0.75
        case .high: 1.0
        }
    }
}

struct TechTunnelView: UIViewRepresentable {
    var speed: Float = 1.0
    var intensity: Float = 1.0
    var isAnimated: Bool = true
    var quality: GraphicsQuality = .normal

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)

        guard let device = MTLCreateSystemDefaultDevice() else {
            return view
        }

        view.device = device
        view.colorPixelFormat = .bgra8Unorm

        view.clearColor = MTLClearColor(
            red: 0,
            green: 0,
            blue: 0.03,
            alpha: 1
        )

        view.framebufferOnly = true
        view.isOpaque = true
        view.enableSetNeedsDisplay = false

        let renderer = TechTunnelRenderer(
            device: device,
            pixelFormat: view.colorPixelFormat
        )

        renderer.speed = speed
        renderer.intensity = intensity

        view.delegate = renderer
        context.coordinator.renderer = renderer

        configureGraphics(view, quality: quality)
        view.isPaused = !isAnimated

        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.speed = speed
        context.coordinator.renderer?.intensity = intensity

        configureGraphics(view, quality: quality)

        view.isPaused = !isAnimated
    }

    private func configureGraphics(
        _ view: MTKView,
        quality: GraphicsQuality
    ) {
        let maximumFPS =
            view.window?.windowScene?
            .screen.maximumFramesPerSecond ?? 60

        let targetFPS = min(quality.fps, maximumFPS)

        if view.preferredFramesPerSecond != targetFPS {
            view.preferredFramesPerSecond = targetFPS
        }

        let screenScale =
            view.window?.screen.scale
            ?? view.traitCollection.displayScale

        let scale = screenScale * quality.resolutionScale

        if abs(view.contentScaleFactor - scale) > 0.001 {
            view.contentScaleFactor = scale
        }

        let drawableSize = CGSize(
            width: max(1, (view.bounds.width * scale).rounded()),
            height: max(1, (view.bounds.height * scale).rounded())
        )

        if view.drawableSize != drawableSize {
            view.drawableSize = drawableSize
        }
    }

    final class Coordinator {
        var renderer: TechTunnelRenderer?
    }
}
