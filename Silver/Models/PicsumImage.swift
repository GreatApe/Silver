//
//  PicsumImageURL.swift
//  Silver
//
//  Created by Gustaf Kugelberg on 09/03/2025.
//

import Foundation

struct PicsumImageURL: Identifiable, Equatable {
    let id: String
    let width: Int
    let height: Int

    var aspectRatio: CGFloat {
        CGFloat(width) / CGFloat(height)
    }
}

extension PicsumImageURL {
    func filling(width: Int, height: Int) -> PicsumImageURL {
        .init(id: id, width: width, height: height)
    }
}

extension PicsumImageURL: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let url = try container.decode(URL.self)
        guard let host = url.host() else { throw DecodingError.missingHost(url) }
        guard host == URL.picsumHost else { throw DecodingError.incorrectHost(host) }
        let components = url.pathComponents
        guard components.count == 5 else { throw DecodingError.missingComponents(components) }
        guard components[1] == "id" else { throw DecodingError.missingIDKey(components[1]) }
        let id = components[2]
        guard let width = Int(components[3]) else { throw DecodingError.missingWidth(components[3]) }
        guard let height = Int(components[4]) else { throw DecodingError.missingHeight(components[4]) }

        self.init(id: id, width: width, height: height)
    }

    enum DecodingError: Error {
        case missingHost(URL)
        case incorrectHost(String)
        case missingComponents([String])
        case missingIDKey(String)
        case missingWidth(String)
        case missingHeight(String)
    }
}
