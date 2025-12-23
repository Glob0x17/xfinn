//
//  LoginView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var jellyfinService: JellyfinService
    
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var connectionStep: ConnectionStep = .server
    @State private var animateLogo = false
    
    enum ConnectionStep {
        case server
        case authentication
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
            withAnimation(AppTheme.springAnimation.delay(0.3)) {
                animateLogo = true
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Gradient de base
            AppTheme.backgroundGradient
            
            // Particules flottantes
            GeometryReader { geometry in
                ForEach(0..<15, id: \.self) { index in
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
                        .frame(width: CGFloat.random(in: 100...300))
                        .blur(radius: 60)
                        .offset(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
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
            .scaleEffect(animateLogo ? 1.0 : 0.8)
            .opacity(animateLogo ? 1.0 : 0.0)
            
            // Titre avec gradient
            Text("XFINN")
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, AppTheme.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .glowing(color: .appAccent, radius: 15)
                .offset(y: animateLogo ? 0 : 20)
                .opacity(animateLogo ? 1.0 : 0.0)
            
            Text("Votre passerelle vers l'entertainment")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
                .offset(y: animateLogo ? 0 : 20)
                .opacity(animateLogo ? 1.0 : 0.0)
        }
    }
    
    // MARK: - Connection Card
    
    private var connectionCard: some View {
        VStack(spacing: 0) {
            if connectionStep == .server {
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
            if let error = errorMessage {
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
                
                Text("Connexion au serveur")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("Entrez l'adresse de votre serveur Jellyfin")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.bottom, 20)
            
            // Champ URL
            VStack(alignment: .leading, spacing: 12) {
                Label("URL du serveur", systemImage: "link")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                #if os(tvOS)
                TextField("192.168.1.100 ou jellyfin.local", text: $serverURL)
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
                    .onSubmit { connectToServer() }
                #else
                TextField("192.168.1.100 ou jellyfin.local", text: $serverURL)
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
                    .onSubmit { connectToServer() }
                #endif
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tapez simplement l'adresse IP ou le nom de domaine")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appTextTertiary)
                    Text("Le port 8096 sera ajouté automatiquement")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
            
            // Bouton de connexion
            Button(action: connectToServer) {
                HStack(spacing: 15) {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 28))
                        Text("Continuer")
                            .font(.system(size: 28, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .glassButton(prominent: true)
            .disabled(serverURL.isEmpty || isConnecting)
            .opacity((serverURL.isEmpty || isConnecting) ? 0.5 : 1.0)
            .glowing(color: .appPrimary, radius: serverURL.isEmpty ? 0 : 20)
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
                
                Text("Authentification")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Text("Connectez-vous avec vos identifiants")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.bottom, 20)
            
            // Champ nom d'utilisateur
            VStack(alignment: .leading, spacing: 12) {
                Label("Nom d'utilisateur", systemImage: "person")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                TextField("Votre nom d'utilisateur", text: $username)
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
                Label("Mot de passe", systemImage: "lock.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                
                SecureField("Votre mot de passe", text: $password)
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
                    .onSubmit { authenticate() }
            }
            
            // Boutons
            HStack(spacing: 20) {
                // Bouton retour
                Button(action: { 
                    withAnimation(AppTheme.standardAnimation) {
                        connectionStep = .server
                        errorMessage = nil
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 24))
                        Text("Retour")
                            .font(.system(size: 24, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .glassButton(prominent: false)
                
                // Bouton connexion
                Button(action: authenticate) {
                    HStack(spacing: 15) {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                            Text("Se connecter")
                                .font(.system(size: 28, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .glassButton(prominent: true)
                .disabled(username.isEmpty || isConnecting)
                .opacity((username.isEmpty || isConnecting) ? 0.5 : 1.0)
                .glowing(color: .appAccent, radius: username.isEmpty ? 0 : 20)
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
                withAnimation(AppTheme.standardAnimation) {
                    errorMessage = nil
                }
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
    
    // MARK: - Actions
    
    private func connectToServer() {
        let cleanedURL = serverURL.normalizedJellyfinURL()
        
        withAnimation(AppTheme.standardAnimation) {
            isConnecting = true
            errorMessage = nil
        }
        
        Task {
            do {
                let _ = try await jellyfinService.connect(to: cleanedURL)
                await MainActor.run {
                    withAnimation(AppTheme.standardAnimation) {
                        connectionStep = .authentication
                        isConnecting = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(AppTheme.standardAnimation) {
                        errorMessage = "Impossible de se connecter: \(error.localizedDescription)"
                        isConnecting = false
                    }
                }
            }
        }
    }
    
    private func authenticate() {
        withAnimation(AppTheme.standardAnimation) {
            isConnecting = true
            errorMessage = nil
        }
        
        Task {
            do {
                try await jellyfinService.authenticate(username: username, password: password)
                await MainActor.run {
                    isConnecting = false
                }
            } catch {
                await MainActor.run {
                    withAnimation(AppTheme.standardAnimation) {
                        errorMessage = "Échec de l'authentification: \(error.localizedDescription)"
                        isConnecting = false
                    }
                }
            }
        }
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


