//
//  ContentView.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import SwiftUI
import Dependencies

struct ContentView: View {
    @State private var image = Image(systemName: "globe")

    var body: some View {
        VStack {
            image
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .task {
            do {
                @Dependency(\.apiClient) var apiClient
//                let list = try await apiClient.imageList()
                image = try await apiClient.image(id: "16", x: 200, y: 200)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
