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

                image = try await apiClient.image(.init(id: "16", width: 300, height: 200))
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
