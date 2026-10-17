//
//  DeepLink.swift
//  xfinn
//
//  Parsing des URLs xfinn:// (extension Top Shelf → app).
//  Logique pure, testée dans xfinnTests/DeepLinkTests.
//

import Foundation

enum DeepLink: Equatable {
    /// Ouvre la fiche d'un média : xfinn://item/{id}
    case item(id: String)

    /// URL du scheme pour un item (utilisée par l'extension Top Shelf)
    static func itemURL(id: String) -> URL? {
        URL(string: "xfinn://item/\(id)")
    }

    init?(url: URL) {
        guard url.scheme == "xfinn" else { return nil }

        // xfinn://item/{id} : "item" est le host, l'id le premier composant du path
        guard url.host == "item" else { return nil }

        let id = url.pathComponents.dropFirst().first ?? ""
        guard !id.isEmpty else { return nil }

        self = .item(id: id)
    }
}
