//
//  PicsumImageDetails.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import Foundation

// MARK: PicsumImageDetails

/// This is actually identical to `PicsumListItem` but we will pretend it isn't
struct PicsumImageDetails: Decodable, Equatable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: URL
    let downloadURL: URL

    enum CodingKeys: String, CodingKey {
        case id, author, width, height, url
        case downloadURL = "download_url"
    }
}

extension PicsumImageDetails {
    static let mock: Self = .init(
        id: "16",
        author: "Paul Jarvis",
        width: 2500,
        height: 1667,
        url: URL(string: "https://unsplash.com/photos/gkT4FfgHO5o")!,
        downloadURL: URL(string: "https://picsum.photos/id/16/2500/1667")!
    )
}
