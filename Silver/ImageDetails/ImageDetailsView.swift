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
    @State private var detailsHeight: CGFloat = 0
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack {
                imageView

                switch store.status {
                case .idle:
                    EmptyView()
                case .loadingDetails:
                    Text("Loading details...")
                case .loadedDetails:
                    detailsView
                case .failedToLoad:
                    Text("Failed to load details")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(store.author)
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width in
            detailsHeight = width / store.url.aspectRatio
        }
        .onAppear {
            store.send(.viewAppeared)
        }
        .refreshable {
            await store.send(.pulledToRefresh).finish()
        }
    }

    private var imageView: some View {
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
                .frame(maxWidth: .infinity)
                .frame(height: detailsHeight)
                .background(.gray)
        }
    }

    @ViewBuilder
    private var detailsView: some View {
        if let details = store.details {
            VStack(spacing: 15) {
                DetailsItem(key: "ID:", value: details.id)
                DetailsItem(key: "Author:", value: details.author)
                DetailsItem(key: "Width:", value: String(details.width))
                DetailsItem(key: "Height:", value: String(details.height))

                Button(details.url.absoluteString) {
                    openURL(details.url)
                }
            }
            .font(.title3)
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
}

struct DetailsItem: View {
    let key: String
    let value: String

    var body: some View {
        HStack {
            Text(key)
                .bold()

            Spacer()

            Text(value)
        }
    }
}
