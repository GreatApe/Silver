//
//  ImageListView.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import SwiftUI
import ComposableArchitecture

struct ImageListView: View {
    @Bindable
    var store: StoreOf<ImageListFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List {
                switch store.status {
                case .idle, .loadedList:
                    listView
                case .loadingList:
                    ProgressView()
                case .failedToLoadList:
                    Text("Failed to load")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(store.title)
            .onAppear {
                store.send(.viewAppeared)
            }
        } destination: { detailsStore in
            ImageDetailsView(store: detailsStore)
        }
        .refreshable {
            Task {
                await store.send(.pulledToRefresh).finish()
            }
        }
        .animation(.default, value: store.status)
    }

    @Shared(.favorites) var favorites: Set<PicsumImageURL.ID> = []

    private var listView: some View {
        ForEach(store.sections) { section in
            Section(section.author) {
                ForEach(section.rows) { row in
                    Button {
                        store.send(.rowTapped(row.id))
                    } label: {
                        let width = store.thumbnailWidth
                        let height = store.thumbnailHeight
                        let isFavorite = favorites.contains(row.id)
                        ThumbnailRowView(row: row, isFavorite: isFavorite, width: width, height: height)
                    }
                }
            }
        }
    }
}

struct ThumbnailRowView: View {
    let row: PicsumListItem
    let isFavorite: Bool
    let width: Int
    let height: Int

    var body: some View {
        HStack {
            let url = row.downloadURL.filling(width: width, height: height)
            AsyncImage(url: .picsumImage(url)) { image in
                image
                    .resizable()
                    .frame(width: CGFloat(width), height: CGFloat(height))
                    .overlay(alignment: .topLeading) {
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.system(size: 20))
                                .padding(5)
                        }
                    }
            } placeholder: {
                ProgressView()
                    .frame(width: CGFloat(width), height: CGFloat(height))
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Width: \(row.downloadURL.width)")
                Text("Height: \(row.downloadURL.height)")
            }
        }
    }
}
