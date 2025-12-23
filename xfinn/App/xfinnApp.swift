//
//  xfinnApp.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

@main
struct xfinnApp: App {
    @StateObject private var jellyfinService = JellyfinService()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ContentView(jellyfinService: jellyfinService)
                .environmentObject(navigationCoordinator)
        }
    }
}

