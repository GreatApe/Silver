//
//  ImageDetailsView.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 10/03/2025.
//

import SwiftUI
import ComposableArchitecture

struct ImageDetailsView: View {
    let store: StoreOf<ImageDetailsFeature>

    @Shared(.favorites) var favorites: Set<PicsumImageURL.ID> = []

    var body: some View {
        ScrollView {
            VStack {
                AsyncImage(url: .picsumImage(store.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(alignment: .topLeading) {
                            Button {
                                store.send(.favoriteTapped)
                            } label: {
                                if favorites.contains(store.url.id) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.system(size: 50))
                                        .padding(5)
                                } else {
                                    Image(systemName: "star")
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 50))
                                        .padding(5)
                                }
                            }
                        }
                } placeholder: {
                    ProgressView()
                        .frame(height: 500)
                }
            }
        }
    }
}
