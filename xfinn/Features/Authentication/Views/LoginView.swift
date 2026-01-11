//
//  LoginView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

/// Données pré-calculées pour une particule de fond
private struct LoginParticleData: Identifiable {
    let id: Int
    let size: CGFloat
    let xRatio: CGFloat
    let yRatio: CGFloat
}

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @ObservedObject var jellyfinService: JellyfinService

    // Particules pré-calculées pour éviter les re-renders
    private let particles: [LoginParticleData] = (0..<15).map { index in
        LoginParticleData(
            id: index,
            size: CGFloat.random(in: 100...300),
            xRatio: CGFloat.random(in: 0...1),
            yRatio: CGFloat.random(in: 0...1)
        )
    }

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._viewModel = StateObject(wrappedValue: LoginViewModel(jellyfinService: jellyfinService))
    }
    
    var body: some View {
        ZStack {
            // Fond avec gradient animé et particules
            backgroundView
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 20)
                        
                        // Logo animé - plus compact
                        logoSection
                            .padding(.bottom, 25)
                        
                        // Carte de connexion avec glass effect
                        connectionCard
                            .padding(.horizontal, min(100, geometry.size.width * 0.1))
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .frame(width: geometry.size.width)
                    .frame(minHeight: geometry.size.height, alignment: .center)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.startLogoAnimation()
        }
    }
    
    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            // Gradient de base
            AppTheme.backgroundGradient

            // Particules flottantes (positions pré-calculées)
            GeometryReader { geometry in
                ForEach(particles) { particle in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.3),
                                    AppTheme.accent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: particle.size)
                        .blur(radius: 60)
                        .offset(
                            x: particle.xRatio * geometry.size.width,
                            y: particle.yRatio * geometry.size.height
                        )
                        .opacity(0.4)
                }
            }
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 15) {
            // Icône avec effet glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                Image(systemName: "play.tv.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .glowing(color: .appPrimary, radius: 30)
            }
            .scaleEffect(viewModel.animateLogo ? 1.0 : 0.8)
            .opacity(viewModel.animateLogo ? 1.0 : 0.0)
            
            // Titre avec gradient
            Text("app.name".localized)
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, AppTheme.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .glowing(color: .appAccent, radius: 15)
                .offset(y: viewModel.animateLogo ? 0 : 20)
                .opacity(viewModel.animateLogo ? 1.0 : 0.0)
        }
    }
    
    // MARK: - Connection Card
    
    private var connectionCard: some View {
        VStack(spacing: 0) {
            if viewModel.connectionStep == .server {
                serverConnectionView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                authenticationView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }

            // Message d'erreur
            if let error = viewModel.errorMessage {
                errorBanner(message: error)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .glassCard(cornerRadius: 30, padding: 50)
        .frame(maxWidth: 900)
    }
    
    // MARK: - Server Connection View
    
    private var serverConnectionView: some View {
        VStack(spacing: 35) {
            // En-tête
            VStack(spacing: 12) {
                Image(systemName: "server.rack")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.primary)
                    .glowing(color: .appPrimary)
                
                Text("login.server_connection".localized)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("login.server_prompt".localized)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.bottom, 20)
            
            // Champ URL
            VStack(alignment: .leading, spacing: 12) {
                Label("login.server_url".localized, systemImage: "link")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                #if os(tvOS)
                TextField("login.server_placeholder".localized, text: $viewModel.serverURL)
                    .font(.system(size: 28, weight: .medium))
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(AppTheme.glassStroke, lineWidth: 2)
                            )
                    )
                    .submitLabel(.continue)
                    .onSubmit {
                        Task { await viewModel.connectToServer() }
                    }
                #else
                TextField("login.server_placeholder".localized, text: $viewModel.serverURL)
                    .textFieldStyle(.plain)
                    .font(.system(size: 28, weight: .medium))
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(AppTheme.glassStroke, lineWidth: 2)
                            )
                    )
                    .submitLabel(.continue)
                    .onSubmit {
                        Task { await viewModel.connectToServer() }
                    }
                #endif
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("login.server_hint".localized)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appTextTertiary)
                    Text("login.port_hint".localized)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
            
            // Bouton de connexion
            Button {
                Task { await viewModel.connectToServer() }
            } label: {
                HStack(spacing: 15) {
                    if viewModel.isConnecting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 28))
                        Text("common.continue".localized)
                            .font(.system(size: 28, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .glassButton(prominent: true)
            .disabled(!viewModel.canConnectToServer)
            .opacity(viewModel.serverButtonOpacity)
            .glowing(color: .appPrimary, radius: viewModel.serverButtonGlowRadius)
        }
    }
    
    // MARK: - Authentication View
    
    private var authenticationView: some View {
        VStack(spacing: 35) {
            // En-tête
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.accent)
                    .glowing(color: .appAccent)
                
                Text("login.authentication".localized)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("login.credentials_prompt".localized)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.bottom, 20)
            
            // Champ nom d'utilisateur
            VStack(alignment: .leading, spacing: 12) {
                Label("login.username".localized, systemImage: "person")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)

                TextField("login.username_placeholder".localized, text: $viewModel.username)
                    .textFieldStyle(.plain)
                    .font(.system(size: 28, weight: .medium))
                    .textContentType(.username)
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(AppTheme.glassStroke, lineWidth: 2)
                            )
                    )
                    .submitLabel(.next)
            }

            // Champ mot de passe
            VStack(alignment: .leading, spacing: 12) {
                Label("login.password".localized, systemImage: "lock.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)

                SecureField("login.password_placeholder".localized, text: $viewModel.password)
                    .textFieldStyle(.plain)
                    .font(.system(size: 28, weight: .medium))
                    .textContentType(.password)
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(AppTheme.glassStroke, lineWidth: 2)
                            )
                    )
                    .submitLabel(.go)
                    .onSubmit {
                        Task { await viewModel.authenticate() }
                    }
            }

            // Boutons
            HStack(spacing: 20) {
                // Bouton retour
                Button(action: {
                    viewModel.goBackToServer()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 24))
                        Text("common.back".localized)
                            .font(.system(size: 24, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .glassButton(prominent: false)

                // Bouton connexion
                Button {
                    Task { await viewModel.authenticate() }
                } label: {
                    HStack(spacing: 15) {
                        if viewModel.isConnecting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                            Text("login.sign_in".localized)
                                .font(.system(size: 28, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .glassButton(prominent: true)
                .disabled(!viewModel.canAuthenticate)
                .opacity(viewModel.authButtonOpacity)
                .glowing(color: .appAccent, radius: viewModel.authButtonGlowRadius)
            }
        }
    }
    
    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.appError)

            Text(message)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: {
                viewModel.clearError()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppTheme.error.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(AppTheme.error, lineWidth: 2)
                )
        )
        .padding(.top, 20)
    }
}

#Preview {
    LoginView(jellyfinService: JellyfinService())
}

// MARK: - String Extension pour normaliser l'URL Jellyfin

extension String {
    /// Normalise une URL Jellyfin saisie par l'utilisateur
    /// Exemples:
    /// - "192.168.1.10" → "http://192.168.1.10:8096"
    /// - "jellyfin.local" → "http://jellyfin.local:8096"
    /// - "http://192.168.1.10" → "http://192.168.1.10:8096"
    /// - "https://jellyfin.example.com:8920" → "https://jellyfin.example.com:8920" (inchangée)
    func normalizedJellyfinURL() -> String {
        var url = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Si l'URL est vide, retourner telle quelle
        guard !url.isEmpty else { return url }
        
        // Vérifier si l'URL contient déjà un schéma (http:// ou https://)
        let hasScheme = url.lowercased().hasPrefix("http://") || url.lowercased().hasPrefix("https://")
        
        // Si pas de schéma, ajouter http://
        if !hasScheme {
            url = "http://" + url
        }
        
        // Parser l'URL pour vérifier si elle a déjà un port
        guard let urlComponents = URLComponents(string: url) else {
            // Si l'URL ne peut pas être parsée, retourner telle quelle
            return url
        }
        
        // Si l'URL a déjà un port personnalisé, ne rien changer
        if urlComponents.port != nil {
            return url
        }
        
        // Sinon, ajouter le port par défaut de Jellyfin (8096)
        var newComponents = urlComponents
        newComponents.port = 8096
        
        return newComponents.url?.absoluteString ?? url
    }
}


