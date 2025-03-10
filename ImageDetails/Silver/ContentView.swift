//
//  ContentView.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        ImageListView(store: Store(initialState: .init()) {
            ImageListFeature()
        })
    }
}

#Preview {
    ContentView()
}
