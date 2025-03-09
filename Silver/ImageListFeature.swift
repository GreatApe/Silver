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

//        enum Page: Hashable {
//            case details(Thumbnail)
//        }
    }

    enum Action {
        case viewAppeared
        case pulledToRefresh
        case rowTapped(PicsumImageURL.ID)

        // System:

        case loadedList([PicsumListItem])
        case setStatus(State.Status)
    }

    @Dependency(\.apiClient) private var apiClient
    @Shared(.inMemory("favorites")) var favorites: Set<PicsumImageURL.ID> = ["16"]

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .viewAppeared:
                return loadList()

            case .pulledToRefresh:
                return loadList()

            case .rowTapped(let id):
                $favorites.withLock {
                    if $0.remove(id) == nil {
                        $0.insert(id)
                    }
                }
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
