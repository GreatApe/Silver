//
//  ImageListFeature.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 10/03/2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ImageListFeature {
    @ObservableState
    struct State: Equatable {
        var status: Status = .idle
        var thumbnailWidth: Int = 100
        var thumbnailHeight: Int = 70

        var sections: [ThumbnailSection] = []

        var path = StackState<ImageDetailsFeature.State>()

        // Helpers

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
    }

    enum Action {
        case viewAppeared
        case pulledToRefresh
        case rowTapped(PicsumImageURL.ID)

        // System:
        case loadedList([PicsumListItem])
        case setStatus(State.Status)

        // Navigation
        case path(StackActionOf<ImageDetailsFeature>)
    }

    @Dependency(\.apiClient) private var apiClient
    @Shared(.favorites) var favorites: Set<PicsumImageURL.ID> = []

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .viewAppeared:
                return loadList()

            case .pulledToRefresh:
                return loadList()

            case .rowTapped(let id):
                guard let image = state.sections.flatMap(\.rows).first(where: { $0.id == id }) else {
                    assertionFailure("Should not be possible")
                    return .none
                }

                state.path.append(.init(author: image.author, url: image.downloadURL))
                return .none

            case .loadedList(let images):
                state.sections = images.thumbnailSections()
                return .none

            case .setStatus(let status):
                state.status = status
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            ImageDetailsFeature()
        }
    }

    private func loadList() -> Effect<Action> {
        .run { send in
            await send(.setStatus(.loadingList))
            let images = try await apiClient.imageList()
            await send(.loadedList(images))
            await send(.setStatus(.loadedList))
        } catch: { error, send in
            await send(.setStatus(.failedToLoadList))
        }
    }
}

extension SharedKey where Self == InMemoryKey<Set<PicsumImageURL.ID>> {
    static var favorites: Self {
        inMemory("favorites")
    }
}

extension [PicsumListItem] {
    func thumbnailSections() -> [ThumbnailSection] {
        return Dictionary(grouping: self, by: \.author)
            .sorted { $0.key < $1.key }
            .map(ThumbnailSection.init)
    }
}

struct ThumbnailSection: Identifiable, Equatable {
    var id: String { author }
    let author: String
    let rows: [PicsumListItem]
}
