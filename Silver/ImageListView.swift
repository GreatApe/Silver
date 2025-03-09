//
//  ImageListView.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import SwiftUI
import ComposableArchitecture

extension SharedKey where Self == InMemoryKey<Set<PicsumImageURL.ID>> {
    static var favorites: Self {
        inMemory("favorites")
    }
}

struct ImageListView: View {
    let store: StoreOf<ImageListFeature>

    var body: some View {
//        NavigationStack(path: <#T##Binding<Store<StackState<ObservableState>, StackAction<ObservableState, Action>>>#>, root: <#T##() -> View#>, destination: <#T##(Store<ObservableState, Action>) -> View#>)
        ZStack {
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
    }

    @Shared(.favorites) var favorites: Set<PicsumImageURL.ID> = ["16"]

    private var listView: some View {
        List {
            ForEach(store.sections) { section in
                Section(section.author) {
                    ForEach(section.rows, id: \.image.id) { row in
                        Button {
                            store.send(.rowTapped(row.image.id))
                        } label: {
                            ThumbnailRowView(row: row, width: store.thumbnailWidth, height: store.thumbnailHeight)
                                .border(favorites.contains(row.image.id) ? .green : .red)
                        }
                    }
                }
            }
        }
        .refreshable {
            await store.send(.pulledToRefresh).finish()
        }
    }
}

struct ThumbnailRowView: View {
    let row: ThumbnailRowModel
    let width: Int
    let height: Int

    var body: some View {
        HStack {
            let url = row.image.downloadURL.filling(width: width, height: height)
            AsyncImage(url: .picsumImage(url)) { image in
                image
                    .resizable()
                    .frame(width: CGFloat(width), height: CGFloat(height))
                    .overlay(alignment: .topLeading) {
                        if row.favorite {
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
                Text("Width: \(row.image.downloadURL.width)")
                Text("Height: \(row.image.downloadURL.height)")
            }
        }
    }
}
