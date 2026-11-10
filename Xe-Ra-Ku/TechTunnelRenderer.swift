// TechTunnelRenderer.swift — Xe-Ra-Ku
import Foundation
import Metal
import MetalKit
import QuartzCore
import simd

private struct TechUniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var speed: Float
    var intensity: Float
    var padding: Float = 0
}

final class TechTunnelRenderer: NSObject, MTKViewDelegate {
    var speed: Float = 1
    var intensity: Float = 1

    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let startTime = CACurrentMediaTime()

    init(device: MTLDevice, pixelFormat: MTLPixelFormat) {
        guard let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "techVertex"),
              let fragment = library.makeFunction(name: "techFragment") else {
            fatalError("Metal shader functions or command queue unavailable")
        }
        commandQueue = queue
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        do {
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Metal pipeline creation failed: \(error)")
        }
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pass = view.currentRenderPassDescriptor,
              let buffer = commandQueue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }

        var uniforms = TechUniforms(
            resolution: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            time: Float(CACurrentMediaTime() - startTime),
            speed: speed,
            intensity: intensity
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<TechUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
