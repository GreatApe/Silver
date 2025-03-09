//
//  ImageListView.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import SwiftUI
import ComposableArchitecture

struct ImageListView: View {
    let store: StoreOf<ImageListFeature>

    var body: some View {
//        NavigationStack(path: <#T##Binding<Store<StackState<ObservableState>, StackAction<ObservableState, Action>>>#>, root: <#T##() -> View#>, destination: <#T##(Store<ObservableState, Action>) -> View#>)
        listView
            .navigationTitle(store.title)
            .onAppear {
                store.send(.viewAppeared)
            }
    }

    private var listView: some View {
        List {
            ForEach(store.sections) { section in
                Section(section.author) {
                    ForEach(section.rows, id: \.image.id) { row in
                        ThumbnailRowView(row: row, width: store.thumbnailWidth, height: store.thumbnailHeight)
                    }
                }
            }
        }
        .scrollIndicators(.never)
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
                            Image(systemName: "star")
                                .foregroundStyle(.yellow)
                                .font(.system(size: 20))
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

@Reducer
struct ImageListFeature {
    @ObservableState
    struct State: Equatable {
        var status: Status = .idle
        var thumbnailWidth: Int = 100
        var thumbnailHeight: Int = 70

        var sections: [ThumbnailSection] = []

        // Computed

        var title: String {
            switch status {
            case .idle, .loadedList:
                "\(sections.count) authors, \(sections.flatMap(\.rows).count) images"
            case .loadingList:
                "Loading"
            case .failedToLoadList:
                "Error"
            }
        }

        enum Status {
            case idle
            case loadingList
            case loadedList
            case failedToLoadList
        }

//        enum Page: Hashable {
//            case details(Thumbnail)
//        }
    }

    enum Action {
        case viewAppeared
        case pulledToRefresh
        case imageTapped(PicsumImageURL.ID)

        // System:

        case loadedList([PicsumListItem])
        case setStatus(State.Status)
    }

    @Dependency(\.apiClient) private var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .viewAppeared:
                return loadList()

            case .pulledToRefresh:
                return loadList()

            case .imageTapped(let id):
                return .none

            case .loadedList(let images):
                state.sections = images.thumbnailSections(favorites: ["16"])
                state.status = .loadedList
                return .none

            case .setStatus(let status):
                state.status = status
                return .none
            }
        }
    }

    private func loadList() -> Effect<Action> {
        .run { send in
            await send(.setStatus(.loadingList))
            let images = try await apiClient.imageList()
            await send(.loadedList(images))
        } catch: { error, send in
            await send(.setStatus(.failedToLoadList))
        }
    }
}

extension [PicsumListItem] {
    func thumbnailSections(favorites: Set<PicsumImageURL.ID>) -> [ThumbnailSection] {
        let rows = map { ThumbnailRowModel(image: $0, favorite: favorites.contains($0.id)) }
        return Dictionary(grouping: rows, by: \.image.author)
            .sorted { $0.key < $1.key }
            .map(ThumbnailSection.init)
    }
}

struct ThumbnailSection: Identifiable, Equatable {
    var id: String { author }
    let author: String
    var rows: [ThumbnailRowModel]
}

struct ThumbnailRowModel: Equatable {
    let image: PicsumListItem
    var favorite: Bool
}
