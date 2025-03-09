//
//  APIClient.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Dependencies
import DependenciesMacros

// MARK: APIClient

@DependencyClient
struct APIClient {
    var imageList: () async throws -> [PicsumListItem]
    var image: (_ id: String, _ x: Int, _ y: Int) async throws -> Image
    var details: (_ id: String) async throws -> PicsumImageDetails
}

// MARK: APIClient live

extension APIClient: DependencyKey {
    static var liveValue: APIClient {
        let session = URLSession(configuration: .default)
        let decoder = JSONDecoder()

        // Helper functions

        func fetch(_ apiRequest: APIRequest<Data>) async throws -> Data {
            try await fetchData(apiRequest)
        }

        func fetch<T: Decodable>(_ apiRequest: APIRequest<T>) async throws -> T {
            let data = try await fetchData(apiRequest)
            return try decoder.decode(T.self, from: data)
        }

        func fetchData<T: Decodable>(_ apiRequest: APIRequest<T>) async throws -> Data {
            var request = URLRequest(url: apiRequest.url)

            switch apiRequest.method {
            case .get:
                request.httpMethod = "GET"
            case .post:
                request.httpMethod = "POST"
                // TODO: Encode body if needed
            }

            return try await session.data(for: request).0
        }

        return .init(
            imageList: {
                try await fetch(.picsumList)
            },
            image: { id, x, y in
                let imageData = try await fetch(.picsumImage(id: id, x: x, y: y))
                guard let uiImage = UIImage(data: imageData) else {
                    throw ClientError.failedToCreateUIImage
                }
                return .init(uiImage: uiImage)
            },
            details: { id in
                try await fetch(.picsumDetails(id: id))
            }
        )
    }

    enum ClientError: Error {
        case failedToCreateUIImage
    }
}

// MARK: DependencyValue

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

// MARK: APIRequest

struct APIRequest<T: Decodable> {
    let method: Method
    let url: URL
    let responseType: T.Type

    init(method: Method, url: URL, responseType: T.Type = T.self) {
        self.method = method
        self.url = url
        self.responseType = responseType
    }

    enum Method {
        case get
        case post
    }
}

extension APIRequest<[PicsumListItem]> {
    static var picsumList: APIRequest {
        .init(
            method: .get,
            url: .picsumList
        )
    }
}

extension APIRequest<Data> {
    static func picsumImage(id: String, x: Int, y: Int) -> APIRequest {
        .init(
            method: .get,
            url: .picsumImage(id: id, x: x, y: y)
        )
    }
}

extension APIRequest<PicsumImageDetails> {
    static func picsumDetails(id: String) -> APIRequest {
        .init(
            method: .get,
            url: .picsumDetails(id: id)
        )
    }
}

// MARK: URLs

private extension URL {
    static let picsumList: URL = URL(string: "https://picsum.photos/v2/list")!

    static func picsumImage(id: String, x: Int, y: Int) -> URL {
        URL(string: "https://picsum.photos/id/\(id)/\(x)/\(y)")!
    }

    static func picsumDetails(id: String) -> URL {
        URL(string: "https://picsum.photos/id/\(id)/info")!
    }
}
