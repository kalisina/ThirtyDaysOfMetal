//
//  Renderer.swift
//  ThirtyDaysOfMetal
//
//  Created by Triumph on 22/05/2023.
//


import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
    var parent: CustomMetalView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!

    init(_ parent: CustomMetalView) {
        self.parent = parent
        guard let metalDevice = MTLCreateSystemDefaultDevice() else { fatalError("metal not supported by the GPU") }
        self.metalDevice = metalDevice
        print("Device name: ", metalDevice.name)

        guard let buffer = metalDevice.makeBuffer(length: 16) else { fatalError("cannot create buffer") }

        print("Buffer is \(buffer.length) bytes in length")

        guard let metalCommandQueue = metalDevice.makeCommandQueue() else { fatalError("cannot create metal commandQueue") }

        self.metalCommandQueue = metalCommandQueue

        let commandBuffer = metalCommandQueue.makeCommandBuffer()!

        guard let sourceBuffer = metalDevice.makeBuffer(length: 16) else { fatalError("sourceBuffer error") }
        guard let destinationBuffer = metalDevice.makeBuffer(length: 16) else { fatalError("destinationBuffer error") }

        let points = sourceBuffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: 2)
        points[0] = SIMD2<Float>(10,10)
        points[1] = SIMD2<Float>(100, 100)

        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitCommandEncoder.copy(from: sourceBuffer, sourceOffset: 0, to: destinationBuffer, destinationOffset: 0, size: MemoryLayout<SIMD2<Float>>.stride * 2)

        blitCommandEncoder.endEncoding()

        commandBuffer.addCompletedHandler { completedCommandBuffer in
            let outPoints = destinationBuffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: 2)
            let p1 = outPoints[1]
            print("p1 in destination buffer is \(p1)")
        }

        commandBuffer.commit()

        guard let library = metalDevice.makeDefaultLibrary() else { fatalError("unable to create default shader library") }

        for name in library.functionNames {
            let function = library.makeFunction(name: name)!
            print(function)
        }

    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        let commandBuffer = metalCommandQueue.makeCommandBuffer()!
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("could not get currentRenderPassDescriptor from MTKView")
            return
        }

        let renderPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderPassEncoder?.endEncoding()

        guard let drawable = view.currentDrawable else {
            print("cannot get view.currentDrawable")
            return
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
