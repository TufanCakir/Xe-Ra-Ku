//
//  BattleFieldMetalView.swift
//  Xe-Ra-Ku
//
//  Created by Tufan Cakir on 09.11.26.
//

import MetalKit
import QuartzCore
import SwiftUI

struct BattleFieldMetalView: UIViewRepresentable {

    var intensity: Float = 1.0

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)

        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 1
        )

        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.framebufferOnly = true
        view.isUserInteractionEnabled = false

        guard let device = view.device else {
            return view
        }

        let renderer = BattleFieldRenderer(
            device: device,
            pixelFormat: view.colorPixelFormat
        )

        renderer.intensity = intensity

        context.coordinator.renderer = renderer
        view.delegate = renderer

        return view
    }

    func updateUIView(
        _ uiView: MTKView,
        context: Context
    ) {
        context.coordinator.renderer?.intensity = intensity
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var renderer: BattleFieldRenderer?
    }
}

// MARK: - Renderer

final class BattleFieldRenderer: NSObject, MTKViewDelegate {

    struct Uniforms {
        var resolution: SIMD2<Float>
        var time: Float
        var intensity: Float
    }

    var intensity: Float = 1.0

    private let commandQueue: MTLCommandQueue?
    private let pipeline: MTLRenderPipelineState?
    private let startTime = CACurrentMediaTime()

    init(device: MTLDevice, pixelFormat: MTLPixelFormat) {

        commandQueue = device.makeCommandQueue()

        if let library = device.makeDefaultLibrary(),
            let vertex = library.makeFunction(
                name: "battleFieldVertex"
            ),
            let fragment = library.makeFunction(
                name: "battleFieldFragment"
            )
        {

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertex
            descriptor.fragmentFunction = fragment
            descriptor.colorAttachments[0].pixelFormat = pixelFormat

            pipeline = try? device.makeRenderPipelineState(
                descriptor: descriptor
            )
        } else {
            pipeline = nil
        }

        super.init()
    }

    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {}

    func draw(in view: MTKView) {
        guard
            let pipeline,
            let commandQueue,
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let buffer = commandQueue.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(
                descriptor: descriptor
            )
        else {
            return
        }

        var uniforms = Uniforms(
            resolution: SIMD2<Float>(
                Float(view.drawableSize.width),
                Float(view.drawableSize.height)
            ),
            time: Float(CACurrentMediaTime() - startTime),
            intensity: intensity
        )

        encoder.setRenderPipelineState(pipeline)

        encoder.setFragmentBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            index: 0
        )

        encoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: 3
        )

        encoder.endEncoding()

        buffer.present(drawable)
        buffer.commit()
    }
}
