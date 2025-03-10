//
//  ImageDetailsFeature.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 10/03/2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ImageDetailsFeature {
    @ObservableState
    struct State: Equatable {
        let author: String
        let url: PicsumImageURL
        var status: Status = .idle
        var details: PicsumImageDetails? = nil

        enum Status: Equatable {
            case idle
            case loadingDetails
            case loadedDetails
            case failedToLoad
        }
    }

    enum Action {
        case viewAppeared
        case favoriteTapped
        case pulledToRefresh

        // System:

        case loadedDetails(PicsumImageDetails)
        case setStatus(State.Status)
    }

    @Dependency(\.apiClient) private var apiClient
    @Shared(.favorites) var favorites: Set<PicsumImageURL.ID> = []

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .viewAppeared:
                return loadDetails(id: state.url.id)

            case .favoriteTapped:
                let id = state.url.id
                $favorites.withLock {
                    if $0.remove(id) == nil {
                        $0.insert(id)
                    }
                }
                return .none

            case .pulledToRefresh:
                return loadDetails(id: state.url.id)

            case .loadedDetails(let details):
                state.details = details
                return .none

            case .setStatus(let status):
                state.status = status
                return .none
            }
        }
    }

    private func loadDetails(id: PicsumImageURL.ID) -> Effect<Action> {
        .run { send in
            await send(.setStatus(.loadingDetails))
            let details = try await apiClient.details(id: id)
            await send(.loadedDetails(details))
            await send(.setStatus(.loadedDetails))
        } catch: { error, send in
            await send(.setStatus(.failedToLoad))
        }
    }
}
