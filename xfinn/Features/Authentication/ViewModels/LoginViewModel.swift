//
//  LoginViewModel.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation
import SwiftUI
import Combine

// MARK: - Connection Step

/// Étape de connexion
enum ConnectionStep {
    case server
    case authentication
}

// MARK: - Login ViewModel

/// ViewModel pour la vue de connexion
@MainActor
final class LoginViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// URL du serveur
    @Published var serverURL = ""

    /// Nom d'utilisateur
    @Published var username = ""

    /// Mot de passe
    @Published var password = ""

    /// Indique si une connexion est en cours
    @Published private(set) var isConnecting = false

    /// Étape actuelle de connexion
    @Published private(set) var connectionStep: ConnectionStep = .server

    /// Animation du logo
    @Published var animateLogo = false

    // MARK: - Dependencies

    private let jellyfinService: JellyfinService

    // MARK: - Computed Properties

    /// Indique si le formulaire serveur est valide
    var canConnectToServer: Bool {
        !serverURL.isEmpty && !isConnecting
    }

    /// Indique si le formulaire d'authentification est valide
    var canAuthenticate: Bool {
        !username.isEmpty && !isConnecting
    }

    /// Opacité du bouton de connexion serveur
    var serverButtonOpacity: Double {
        canConnectToServer ? 1.0 : 0.5
    }

    /// Opacité du bouton d'authentification
    var authButtonOpacity: Double {
        canAuthenticate ? 1.0 : 0.5
    }

    /// Rayon du glow pour le bouton serveur
    var serverButtonGlowRadius: CGFloat {
        serverURL.isEmpty ? 0 : 20
    }

    /// Rayon du glow pour le bouton d'authentification
    var authButtonGlowRadius: CGFloat {
        username.isEmpty ? 0 : 20
    }

    // MARK: - Initialization

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        super.init()
    }

    // MARK: - Public Methods

    /// Connecte au serveur Jellyfin
    func connectToServer() async {
        let cleanedURL = serverURL.normalizedJellyfinURL()

        withAnimation(AppTheme.standardAnimation) {
            isConnecting = true
            errorMessage = nil
        }

        do {
            _ = try await jellyfinService.connect(to: cleanedURL)
            withAnimation(AppTheme.standardAnimation) {
                connectionStep = .authentication
                isConnecting = false
            }
        } catch {
            withAnimation(AppTheme.standardAnimation) {
                errorMessage = "error.connect_failed".localized(with: error.localizedDescription)
                isConnecting = false
            }
        }
    }

    /// Authentifie l'utilisateur
    func authenticate() async {
        withAnimation(AppTheme.standardAnimation) {
            isConnecting = true
            errorMessage = nil
        }

        do {
            try await jellyfinService.authenticate(username: username, password: password)
            isConnecting = false
        } catch {
            withAnimation(AppTheme.standardAnimation) {
                errorMessage = "error.auth_error".localized(with: error.localizedDescription)
                isConnecting = false
            }
        }
    }

    /// Retourne à l'étape serveur
    func goBackToServer() {
        withAnimation(AppTheme.standardAnimation) {
            connectionStep = .server
            errorMessage = nil
        }
    }

    /// Efface le message d'erreur
    override func clearError() {
        withAnimation(AppTheme.standardAnimation) {
            errorMessage = nil
        }
    }

    /// Démarre l'animation du logo
    func startLogoAnimation() {
        withAnimation(AppTheme.springAnimation.delay(0.3)) {
            animateLogo = true
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension LoginViewModel {
    /// Crée un ViewModel avec des données de test
    static var preview: LoginViewModel {
        LoginViewModel(jellyfinService: JellyfinService())
    }
}
#endif
