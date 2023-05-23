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
    var computePipelineState: MTLComputePipelineState!
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!

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

        // Library object is created a compile time and holds reference to the Shaders functions
        guard let library = metalDevice.makeDefaultLibrary() else { fatalError("unable to create default shader library") }

        for name in library.functionNames {
            let function = library.makeFunction(name: name)!
            print(function)
        }

        let kernelFunction = library.makeFunction(name: "add_two_values")!

        do {
            computePipelineState = try metalDevice.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("error: ", error.localizedDescription)
        }

        let threadsPerThreadgroup = MTLSize(width: 32, height: 1, depth: 1)
        let threadgroupCount = MTLSize(width: 8, height: 1, depth: 1)

        let elementCount = 256
        let inputBufferA = metalDevice.makeBuffer(length: MemoryLayout<Float>.stride * elementCount, options: .storageModeShared)!
        let inputBufferB = metalDevice.makeBuffer(length: MemoryLayout<Float>.stride * elementCount, options: .storageModeShared)!
        let outputBuffer = metalDevice.makeBuffer(length: MemoryLayout<Float>.stride * elementCount, options: .storageModeShared)!

        let inputsA = inputBufferA.contents().assumingMemoryBound(to: Float.self)
        let inputsB = inputBufferB.contents().assumingMemoryBound(to: Float.self)
        for i in 0..<elementCount {
            inputsA[i] = Float(i)
            inputsB[i] = Float(elementCount - i)
        }

        let commandBuffer2 = metalCommandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer2.makeComputeCommandEncoder()!
        commandEncoder.setComputePipelineState(computePipelineState)

        // Each buffer parameter is “bound” by calling the setBuffer(:offset:index:) method.
        // Note that the index parameter of each buffer argument matches the index in the buffer attribute in the shader code.
        commandEncoder.setBuffer(inputBufferA, offset: 0, index: 0)
        commandEncoder.setBuffer(inputBufferB, offset: 0, index: 1)
        commandEncoder.setBuffer(outputBuffer, offset: 0, index: 2)

        commandEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()

        commandBuffer2.addCompletedHandler { _ in
            let outputs = outputBuffer.contents().assumingMemoryBound(to: Float.self)
            for i in 0..<elementCount {
                print("Output element \(i) is \(outputs[i])")
            }
        }
        commandBuffer2.commit()

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")!
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")!
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            renderPipelineState = try metalDevice.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("error: ", error.localizedDescription)
        }

        var positions = [
            SIMD2<Float>( -0.8, 0.4 ),
            SIMD2<Float>( 0.4, -0.8 ),
            SIMD2<Float>( 0.8, 0.8 )
        ]

        vertexBuffer = metalDevice.makeBuffer(bytes: &positions, length: MemoryLayout<SIMD2<Float>>.stride * positions.count, options: .storageModeShared)

        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderCommandEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else { return }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
