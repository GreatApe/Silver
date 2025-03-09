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
            ForEach(store.images) { image in
                HStack {
                    Text("Author: \(image.author)")

                    Spacer()

                    let url = image.downloadURL.filling(width: store.thumbnailWidth, height: store.thumbnailHeight)
                    AsyncImage(url: .picsumImage(url)) { image in
                        image
                            .resizable()
                            .frame(width: CGFloat(store.thumbnailWidth), height: CGFloat(store.thumbnailHeight))
                    } placeholder: {
                        ProgressView()
                            .frame(width: CGFloat(store.thumbnailWidth), height: CGFloat(store.thumbnailHeight))
                    }

                }
            }
        }
        .swipeActions(edge: .trailing) {
            Image(systemName: "star")
        }
        .scrollIndicators(.never)
        .refreshable {
            await store.send(.pulledToRefresh).finish()
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

        var images: [PicsumListItem] = []

        // Computed

//        var thumbnailURLs: [PicsumImageURL] {
//            images.map { image in
//                image.downloadURL.filling(width: thumbnailWidth, height: thumbnailHeight)
//            }
//        }

        var title: String {
            switch status {
            case .idle, .loadedList:
                "\(images.count) images"
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
                state.images = images
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
