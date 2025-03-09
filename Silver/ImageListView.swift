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
            ForEach(store.images) { thumbnail in
                HStack {
                    Text("Author: \(thumbnail.author)")

                    Spacer()

                    AsyncImage(url: .picsumImage(thumbnail.image)) { image in
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

        var images: IdentifiedArrayOf<Thumbnail> = []

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

        case loadedList(IdentifiedArrayOf<Thumbnail>)
        case setStatus(State.Status)
    }

    @Dependency(\.apiClient) private var apiClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .viewAppeared:
                return loadList(width: state.thumbnailWidth, height: state.thumbnailHeight)

            case .pulledToRefresh:
                return loadList(width: state.thumbnailWidth, height: state.thumbnailHeight)

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

    private func loadList(width: Int, height: Int) -> Effect<Action> {
        .run { send in
            await send(.setStatus(.loadingList))
            let images = try await apiClient.imageList()
                .map { Thumbnail(author: $0.author, image: $0.downloadURL.filling(width: width, height: height)) }
            await send(.loadedList(IdentifiedArray(images) { $1 }))
        } catch: { error, send in
            await send(.setStatus(.failedToLoadList))
        }
    }
}
