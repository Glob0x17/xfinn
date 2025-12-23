//
//  ContentView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

/// Point d'entrée principal de l'application
/// Gère l'affichage de LoginView ou HomeView selon l'état d'authentification
struct ContentView: View {
    @ObservedObject var jellyfinService: JellyfinService
    
    var body: some View {
        Group {
            if jellyfinService.isAuthenticated {
                // Utilisateur connecté : afficher la page d'accueil
                HomeView(jellyfinService: jellyfinService)
            } else {
                // Utilisateur non connecté : afficher le login
                LoginView(jellyfinService: jellyfinService)
            }
        }
    }
}

#Preview {
    ContentView(jellyfinService: JellyfinService())
        .environmentObject(NavigationCoordinator())
}
