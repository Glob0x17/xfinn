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
    case quickConnect
}

/// État de l'écran Quick Connect
enum QuickConnectState {
    case waiting
    case expired
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

    /// Indique si les credentials ont été pré-remplis (pour le focus automatique)
    @Published private(set) var credentialsPreFilled = false

    /// Serveurs découverts sur le réseau
    @Published private(set) var discoveredServers: [ServerItem] = []

    /// Serveurs récemment utilisés
    @Published private(set) var recentServers: [ServerItem] = []

    /// Indique si la recherche de serveurs est en cours
    @Published private(set) var isDiscovering = false

    /// Quick Connect disponible sur le serveur connecté
    @Published private(set) var quickConnectAvailable = false

    /// Code Quick Connect à afficher (nil tant que non initié)
    @Published private(set) var quickConnectCode: String?

    /// État de la session Quick Connect en cours
    @Published private(set) var quickConnectState: QuickConnectState = .waiting

    /// Secret de la session Quick Connect — en mémoire uniquement, jamais persisté
    private var quickConnectSecret: String?

    private static let quickConnectPollingTaskId = "quickConnectPolling"
    private static let quickConnectPollInterval: Duration = .seconds(3)
    private static let quickConnectTimeout: TimeInterval = 300


    // MARK: - Dependencies

    private let jellyfinService: JellyfinService
    private let discoveryService: ServerDiscoveryService
    private let recentServersService: any RecentServersProtocol

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

    // MARK: - Initialization

    /// Initialise le LoginViewModel avec injection de dépendances
    /// - Parameters:
    ///   - jellyfinService: Service Jellyfin principal
    ///   - discoveryService: Service de découverte (défaut: ServerDiscoveryService)
    ///   - recentServersService: Service des serveurs récents (défaut: singleton)
    /// - Note: discoveryService uses concrete type to support Combine @Published bindings
    init(
        jellyfinService: JellyfinService,
        discoveryService: ServerDiscoveryService = ServerDiscoveryService(),
        recentServersService: any RecentServersProtocol = RecentServersService.shared
    ) {
        self.jellyfinService = jellyfinService
        self.discoveryService = discoveryService
        self.recentServersService = recentServersService
        super.init()
        setupDiscoveryBindings()
        loadRecentServers()
    }

    private func setupDiscoveryBindings() {
        // Observer les serveurs découverts
        discoveryService.$discoveredServers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (servers: [ServerItem]) in
                self?.discoveredServers = servers
            }
            .store(in: &cancellables)

        // Observer l'état de recherche
        discoveryService.$isSearching
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (searching: Bool) in
                self?.isDiscovering = searching
            }
            .store(in: &cancellables)
    }

    private func loadRecentServers() {
        recentServers = recentServersService.getRecentServers()
    }

    // MARK: - Public Methods

    /// Démarre la découverte des serveurs sur le réseau
    func startDiscovery() {
        discoveryService.startDiscovery()
    }

    /// Arrête la découverte des serveurs
    func stopDiscovery() {
        discoveryService.stopDiscovery()
    }

    /// Serveurs récents puis découverts, sans doublon (même identifiant
    /// Jellyfin ou même adresse) : liste unique de l'écran iPhone
    var mergedServers: [ServerItem] {
        var merged = recentServers
        for server in discoveredServers where !merged.contains(where: {
            $0.id == server.id || $0.displayURL == server.displayURL
        }) {
            merged.append(server)
        }
        return merged
    }

    /// Sélectionne un serveur (découvert ou récent) pour la connexion
    func selectServer(_ server: ServerItem) {
        serverURL = server.url
        Task {
            await connectToServer()
        }
    }

    /// Connecte au serveur Jellyfin en essayant plusieurs variantes d'URL
    func connectToServer() async {
        let urlVariants = serverURL.jellyfinURLVariants()

        withAnimation(AppTheme.standardAnimation) {
            isConnecting = true
            errorMessage = nil
        }

        var lastError: Error?

        // Essayer chaque variante d'URL jusqu'à ce qu'une fonctionne
        for urlVariant in urlVariants {
            do {
                _ = try await jellyfinService.connect(to: urlVariant)
                // Connexion réussie !
                // Charger les credentials sauvegardés pour ce serveur
                loadSavedCredentials(forServer: urlVariant)

                // Vérifier la disponibilité de Quick Connect en arrière-plan
                quickConnectAvailable = false
                Task { [weak self] in
                    guard let self else { return }
                    let enabled = await self.jellyfinService.isQuickConnectEnabled()
                    withAnimation(AppTheme.standardAnimation) {
                        self.quickConnectAvailable = enabled
                    }
                }

                withAnimation(AppTheme.standardAnimation) {
                    connectionStep = .authentication
                    isConnecting = false
                }
                #if DEBUG
                print("[LoginViewModel] Connected successfully to: \(urlVariant)")
                #endif
                return
            } catch {
                #if DEBUG
                print("[LoginViewModel] Failed to connect to \(urlVariant): \(error.localizedDescription)")
                #endif
                lastError = error
                // Continuer avec la prochaine variante
            }
        }

        // Toutes les variantes ont échoué
        withAnimation(AppTheme.standardAnimation) {
            errorMessage = "error.connect_failed".localized(with: lastError?.localizedDescription ?? "Unknown error")
            isConnecting = false
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

            recordSuccessfulLogin(username: username)

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
        stopQuickConnectPolling()
        withAnimation(AppTheme.standardAnimation) {
            connectionStep = .server
            errorMessage = nil
        }
    }

    // MARK: - Quick Connect

    /// Passe à l'écran Quick Connect et démarre une session (code + polling)
    func startQuickConnect() {
        withAnimation(AppTheme.standardAnimation) {
            connectionStep = .quickConnect
            quickConnectState = .waiting
            quickConnectCode = nil
            errorMessage = nil
        }

        taskManager.run(id: Self.quickConnectPollingTaskId) { [weak self] in
            await self?.runQuickConnectSession()
        }
    }

    /// Annule la session Quick Connect et revient à l'étape d'authentification
    func cancelQuickConnect() {
        stopQuickConnectPolling()
        withAnimation(AppTheme.standardAnimation) {
            connectionStep = .authentication
            errorMessage = nil
        }
    }

    /// Arrête le polling et purge le code/secret (appelé aussi à l'onDisappear)
    func stopQuickConnectPolling() {
        taskManager.cancel(id: Self.quickConnectPollingTaskId)
        quickConnectSecret = nil
        quickConnectCode = nil
    }

    /// Session complète : initiate → polling → authentification
    private func runQuickConnectSession() async {
        do {
            let session = try await jellyfinService.initiateQuickConnect()
            quickConnectSecret = session.secret
            withAnimation(AppTheme.standardAnimation) {
                quickConnectCode = session.formattedCode
            }

            let deadline = Date().addingTimeInterval(Self.quickConnectTimeout)

            while !Task.isCancelled {
                try await Task.sleep(for: Self.quickConnectPollInterval)
                guard !Task.isCancelled, let secret = quickConnectSecret else { return }

                if Date() > deadline {
                    throw JellyfinError.quickConnectExpired
                }

                do {
                    if try await jellyfinService.checkQuickConnect(secret: secret) {
                        try await finishQuickConnect(secret: secret)
                        return
                    }
                } catch JellyfinError.quickConnectExpired {
                    throw JellyfinError.quickConnectExpired
                } catch {
                    // Erreur réseau transitoire : on continue le polling
                    #if DEBUG
                    print("[LoginViewModel] Quick Connect poll error: \(error.localizedDescription)")
                    #endif
                }
            }
        } catch is CancellationError {
            // Annulation normale (retour, disparition de la vue)
        } catch {
            quickConnectSecret = nil
            withAnimation(AppTheme.standardAnimation) {
                quickConnectState = .expired
            }
        }
    }

    /// Échange le secret approuvé contre une session et finalise le login
    private func finishQuickConnect(secret: String) async throws {
        try await jellyfinService.authenticateWithQuickConnect(secret: secret)
        quickConnectSecret = nil
        quickConnectCode = nil

        // Le username vient du compte qui a approuvé le code
        let approvedUsername = jellyfinService.currentUser?.name ?? ""
        recordSuccessfulLogin(username: approvedUsername)
    }

    // MARK: - Post-login bookkeeping

    /// Comptabilité commune aux deux chemins de login (mot de passe et Quick
    /// Connect) : arrêt de la découverte, username en Keychain, serveurs récents
    private func recordSuccessfulLogin(username: String) {
        stopDiscovery()

        guard let serverURL = KeychainService.shared.serverURL else { return }

        if !username.isEmpty {
            KeychainService.shared.saveUsername(username, forServer: serverURL)
        }

        let serverName = jellyfinService.serverInfo?.serverName ?? "Jellyfin Server"
        let serverId = jellyfinService.serverInfo?.id ?? UUID().uuidString
        recentServersService.addRecentServer(
            id: serverId,
            name: serverName,
            url: serverURL
        )
        loadRecentServers()

        #if DEBUG
        print("[LoginViewModel] Credentials and server saved: \(serverURL.redactedForLogs)")
        #endif
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

    // MARK: - Private Methods

    /// Pré-remplit le nom d'utilisateur sauvegardé pour un serveur
    /// Le mot de passe n'est jamais persisté et doit être ressaisi
    private func loadSavedCredentials(forServer serverURL: String) {
        credentialsPreFilled = false
        password = ""

        if let savedUsername = KeychainService.shared.getUsername(forServer: serverURL) {
            username = savedUsername
            credentialsPreFilled = true
            #if DEBUG
            print("[LoginViewModel] Loaded saved username for: \(serverURL.redactedForLogs)")
            #endif
        } else if let lastUsername = KeychainService.shared.lastUsername {
            // Fallback: utiliser le dernier username connu
            username = lastUsername
            #if DEBUG
            print("[LoginViewModel] Loaded last username: \(lastUsername)")
            #endif
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
