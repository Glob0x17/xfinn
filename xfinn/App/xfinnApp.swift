//
//  xfinnApp.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

@main
struct xfinnApp: App {
    @StateObject private var jellyfinService: JellyfinService
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    /// Langue choisie dans les réglages : la changer reconstruit l'interface
    @AppStorage("appLanguage") private var appLanguage: String?
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    init() {
        // Cache HTTP global : profite à tous les AsyncImage (posters/backdrops),
        // dont la session interne n'est pas injectable. Les URLs d'images
        // Jellyfin sont stables et sans token → très bien cachables.
        URLCache.shared = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )

        self._jellyfinService = StateObject(wrappedValue: JellyfinService())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(jellyfinService: jellyfinService)
                .environmentObject(navigationCoordinator)
                .environment(\.locale, AppLanguage.locale)
                // Les textes sont résolus à l'affichage : reconstruire l'arbre les retraduit tous
                .id(appLanguage ?? "system")
        }
    }
}

