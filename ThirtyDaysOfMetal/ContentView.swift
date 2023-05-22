//
//  ContentView.swift
//  ThirtyDaysOfMetal
//
//  Created by Triumph on 22/05/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            CustomMetalView()               
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
