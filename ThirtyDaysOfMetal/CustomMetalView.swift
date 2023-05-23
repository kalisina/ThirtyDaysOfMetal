//
//  CustomMetalView.swift
//  ThirtyDaysOfMetal
//
//  Created by Triumph on 22/05/2023.
//

import SwiftUI
import MetalKit

struct CustomMetalView: UIViewRepresentable {

    func makeCoordinator() -> Renderer {
        Renderer(self)
    }

    func makeUIView(context: UIViewRepresentableContext<CustomMetalView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true

        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported by the GPU")
        }
        mtkView.device = metalDevice

        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size

        mtkView.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)

        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<CustomMetalView>) {}
    
}

struct CustomMetalView_Previews: PreviewProvider {
    static var previews: some View {
        CustomMetalView()
    }
}
