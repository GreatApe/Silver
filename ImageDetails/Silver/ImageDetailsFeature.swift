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
        let url: PicsumImageURL
        var details: PicsumImageDetails? = nil
    }

    enum Action {
        case viewAppeared
        case favoriteTapped

        // System:

        case loadedDetails(PicsumImageDetails)
    }

    @Dependency(\.apiClient) private var apiClient
    @Shared(.favorites) var favorites: Set<PicsumImageURL.ID> = []

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .viewAppeared:
                return .none

            case .favoriteTapped:
                let id = state.url.id
                $favorites.withLock {
                    if $0.remove(id) == nil {
                        $0.insert(id)
                    }
                }
                return .none

            case .loadedDetails(let details):
                state.details = details
                return .none
            }
        }
    }
}

