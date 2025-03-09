//
//  PicsumListItem.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import Foundation

// MARK: PicsumListItem

struct PicsumListItem: Decodable, Identifiable, Equatable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let downloadURL: PicsumImageURL

    enum CodingKeys: String, CodingKey {
        case id, author, width, height
        case downloadURL = "download_url"
    }
}
