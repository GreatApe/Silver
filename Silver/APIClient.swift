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
    var image: (_ image: PicsumImage) async throws -> Image
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
            image: { image in
                let imageData = try await fetch(.picsumImage(image))
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
    static func picsumImage(_ image: PicsumImage) -> APIRequest {
        .init(
            method: .get,
            url: .picsumImage(image)
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

extension URL {
    static let picsumList: URL = URL(string: "https://\(picsumHost)/v2/list")!

    static func picsumImage(_ image: PicsumImage) -> URL {
        URL(string: "https://\(picsumHost)/id/\(image.id)/\(image.width)/\(image.height)")!
    }

    static func picsumDetails(id: String) -> URL {
        URL(string: "https://\(picsumHost)/id/\(id)/info")!
    }

    static let picsumHost: String = "picsum.photos"
}
