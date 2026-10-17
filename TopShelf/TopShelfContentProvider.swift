//
//  TopShelfContentProvider.swift
//  TopShelf
//
//  Extension Top Shelf tvOS : affiche « À reprendre » sur l'écran d'accueil
//  de l'Apple TV quand xfinn est dans la rangée du haut.
//
//  Volontairement autonome (aucun partage de sources avec l'app) : la session
//  est lue depuis le conteneur app group (miroir écrit par AuthService), la
//  requête et les DTO minimaux sont locaux. Pas de session ou serveur
//  injoignable → contenu vide, l'écran d'accueil affiche l'image par défaut.
//

import TVServices

final class TopShelfContentProvider: TVTopShelfContentProvider {

    private static let appGroupIdentifier = "group.doriang.xfinn"

    override func loadTopShelfContent() async -> TVTopShelfContent? {
        guard let session = SharedSession.load() else { return nil }

        do {
            let items = try await fetchResumeItems(session: session)
            guard !items.isEmpty else { return nil }

            // Télécharger les vignettes nous-mêmes et fournir des URLs de
            // fichiers locaux : le chargeur d'images du système ne suit pas
            // les mêmes règles réseau que l'extension (HTTP local refusé)
            let localImages = await downloadImages(for: items, session: session)

            let shelfItems = items.compactMap { makeShelfItem(from: $0, imageFileURL: localImages[$0.id]) }
            guard !shelfItems.isEmpty else { return nil }

            let section = TVTopShelfItemCollection(items: shelfItems)
            section.title = Self.sectionTitle
            return TVTopShelfSectionedContent(sections: [section])
        } catch {
            return nil
        }
    }

    // MARK: - Session (miroir app group)

    private struct SharedSession {
        let serverURL: String
        let accessToken: String
        let userId: String
        let deviceId: String

        static func load() -> SharedSession? {
            guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
                  let serverURL = defaults.string(forKey: "serverURL"), !serverURL.isEmpty,
                  let accessToken = defaults.string(forKey: "accessToken"), !accessToken.isEmpty,
                  let userId = defaults.string(forKey: "userId"), !userId.isEmpty,
                  let deviceId = defaults.string(forKey: "deviceId"), !deviceId.isEmpty else {
                return nil
            }
            return SharedSession(serverURL: serverURL, accessToken: accessToken,
                                 userId: userId, deviceId: deviceId)
        }
    }

    // MARK: - Requête « à reprendre »

    private struct ResumeItem: Decodable {
        let id: String
        let name: String
        let seriesName: String?
        let runTimeTicks: Int64?
        let userData: ItemUserData?
        let imageTags: [String: String]?
        let parentBackdropItemId: String?

        struct ItemUserData: Decodable {
            let playbackPositionTicks: Int64?
            enum CodingKeys: String, CodingKey {
                case playbackPositionTicks = "PlaybackPositionTicks"
            }
        }

        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case name = "Name"
            case seriesName = "SeriesName"
            case runTimeTicks = "RunTimeTicks"
            case userData = "UserData"
            case imageTags = "ImageTags"
            case parentBackdropItemId = "ParentBackdropItemId"
        }

        /// URL de l'image 16:9 : le Primary de l'épisode (vignette 16:9,
        /// les épisodes n'ont PAS de Backdrop — vérifié : 404), sinon le
        /// backdrop de la série parente, sinon le Primary de l'item
        func imageRemoteURL(serverURL: String) -> URL? {
            if imageTags?["Primary"] != nil {
                return URL(string: "\(serverURL)/Items/\(id)/Images/Primary?maxWidth=800")
            }
            if let parentId = parentBackdropItemId {
                return URL(string: "\(serverURL)/Items/\(parentId)/Images/Backdrop?maxWidth=800")
            }
            return URL(string: "\(serverURL)/Items/\(id)/Images/Primary?maxWidth=800")
        }
    }

    private struct ResumeResponse: Decodable {
        let items: [ResumeItem]
        enum CodingKeys: String, CodingKey {
            case items = "Items"
        }
    }

    private func fetchResumeItems(session: SharedSession) async throws -> [ResumeItem] {
        guard var components = URLComponents(string: "\(session.serverURL)/Users/\(session.userId)/Items/Resume") else {
            return []
        }
        components.queryItems = [
            URLQueryItem(name: "Limit", value: "8"),
            URLQueryItem(name: "MediaTypes", value: "Video")
        ]
        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let authHeader = "MediaBrowser Client=\"xfinn\", Device=\"Apple TV\", DeviceId=\"\(session.deviceId)\", Version=\"1.0.0\", Token=\"\(session.accessToken)\""
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return []
        }

        return try JSONDecoder().decode(ResumeResponse.self, from: data).items
    }

    // MARK: - Mapping Top Shelf

    private func makeShelfItem(from item: ResumeItem, imageFileURL: URL?) -> TVTopShelfSectionedItem? {
        let shelfItem = TVTopShelfSectionedItem(identifier: item.id)

        // "Série – Épisode" pour les épisodes, sinon le titre
        if let seriesName = item.seriesName, !seriesName.isEmpty {
            shelfItem.title = "\(seriesName) – \(item.name)"
        } else {
            shelfItem.title = item.name
        }

        // Barre de progression de reprise
        if let position = item.userData?.playbackPositionTicks,
           let duration = item.runTimeTicks, duration > 0 {
            shelfItem.playbackProgress = min(1, max(0, Double(position) / Double(duration)))
        }

        // Vignette 16:9 téléchargée localement (conteneur app group)
        shelfItem.imageShape = .hdtv
        if let imageFileURL {
            shelfItem.setImageURL(imageFileURL, for: [.screenScale1x, .screenScale2x])
        }

        // Ouvrir la fiche dans l'app (deep link xfinn://item/{id})
        if let actionURL = URL(string: "xfinn://item/\(item.id)") {
            shelfItem.displayAction = TVTopShelfAction(url: actionURL)
            shelfItem.playAction = TVTopShelfAction(url: actionURL)
        }

        return shelfItem
    }

    // MARK: - Téléchargement des vignettes

    /// Télécharge les vignettes en parallèle dans le conteneur app group et
    /// retourne [itemId: URL de fichier local]. Un échec individuel = pas
    /// d'image pour cet item, jamais d'échec global.
    private func downloadImages(for items: [ResumeItem], session: SharedSession) async -> [String: URL] {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else { return [:] }

        let imagesDir = container.appendingPathComponent("TopShelfImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        // Purger les vignettes des items qui ne sont plus dans la liste
        let validNames = Set(items.map { "\($0.id).jpg" })
        if let existing = try? FileManager.default.contentsOfDirectory(atPath: imagesDir.path) {
            for file in existing where !validNames.contains(file) {
                try? FileManager.default.removeItem(at: imagesDir.appendingPathComponent(file))
            }
        }

        return await withTaskGroup(of: (String, URL)?.self) { group in
            for item in items {
                group.addTask {
                    let destination = imagesDir.appendingPathComponent("\(item.id).jpg")

                    // Déjà téléchargée lors d'un rafraîchissement précédent
                    if FileManager.default.fileExists(atPath: destination.path) {
                        return (item.id, destination)
                    }

                    guard let remoteURL = item.imageRemoteURL(serverURL: session.serverURL) else {
                        return nil
                    }

                    var request = URLRequest(url: remoteURL)
                    request.timeoutInterval = 8

                    guard let (data, response) = try? await URLSession.shared.data(for: request),
                          let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode),
                          !data.isEmpty else {
                        return nil
                    }

                    guard (try? data.write(to: destination)) != nil else { return nil }
                    return (item.id, destination)
                }
            }

            var result: [String: URL] = [:]
            for await entry in group {
                if let (id, url) = entry {
                    result[id] = url
                }
            }
            return result
        }
    }

    // MARK: - Localisation minimale (pas de bundle .strings dans l'extension)

    private static var sectionTitle: String {
        let language = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        switch language {
        case "fr": return "À reprendre"
        case "es": return "Continuar viendo"
        case "pt": return "Continuar a ver"
        default: return "Continue Watching"
        }
    }
}
