//
//  Renderer.swift
//  ThirtyDaysOfMetal
//
//  Created by Triumph on 22/05/2023.
//


import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
    var parent: CustomMetalView
    
    init(_ parent: CustomMetalView) {
        self.parent = parent
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
    }
}
