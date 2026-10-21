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

/// Éléments focusables de l'écran d'authentification
private enum AuthFocusField: Hashable {
    case username
    case password
    case loginButton
}

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @ObservedObject var jellyfinService: JellyfinService

    /// Focus state pour l'écran d'authentification
    @FocusState private var authFocusedField: AuthFocusField?

    // Particules déterministes pour garder un rendu stable entre les écrans de login
    private static let particlePreset: [LoginParticleData] = (0..<15).map { index in
        let value = Double(index + 1)
        return LoginParticleData(
            id: index,
            size: CGFloat(120 + ((index * 29) % 170)),
            xRatio: CGFloat((sin(value * 1.31) + 1.0) * 0.5),
            yRatio: CGFloat((cos(value * 1.91) + 1.0) * 0.5)
        )
    }
    private let particles = particlePreset

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._viewModel = StateObject(wrappedValue: LoginViewModel(jellyfinService: jellyfinService))
    }
    
    var body: some View {
        ZStack {
            // Fond avec gradient animé et particules. Lui seul ignore les zones
            // réservées : le formulaire, lui, doit remonter au-dessus du clavier
            backgroundView
                .ignoresSafeArea()
                #if os(iOS)
                .onTapGesture { dismissKeyboard() }
                #endif

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
                    #if os(iOS)
                    .contentShape(Rectangle())
                    .onTapGesture { dismissKeyboard() }
                    #endif
                }
                #if os(iOS)
                .scrollDismissesKeyboard(.interactively)
                #endif
            }
        }
        .onAppear {
            viewModel.startLogoAnimation()
            viewModel.startDiscovery()
        }
        .onDisappear {
            viewModel.stopDiscovery()
            viewModel.stopQuickConnectPolling()
        }
    }
    
    #if os(iOS)
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif

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
                                    AppTheme.secondary.opacity(0.35),
                                    AppTheme.tertiary.opacity(0.25)
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
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Logo Section
    
    #if os(tvOS)
    private static let logoIconSize: CGFloat = 60
    private static let logoGlowSize: CGFloat = 120
    private static let logoTitleSize: CGFloat = 60
    private static let sectionTitleSize: CGFloat = 40
    private static let sectionSubSize: CGFloat = 20
    private static let fieldLabelSize: CGFloat = 20
    private static let fieldTextSize: CGFloat = 28
    private static let fieldPad: CGFloat = 25
    private static let btnIconSize: CGFloat = 28
    private static let btnTextSize: CGFloat = 28
    private static let cardMaxWidth: CGFloat = 900
    private static let cardPadding: CGFloat = 50
    private static let qcCodeSize: CGFloat = 72
    private static let listTitleSize: CGFloat = 22
    private static let hintSize: CGFloat = 18
    private static let separatorSize: CGFloat = 16
    private static let errorIconSize: CGFloat = 28
    private static let errorTextSize: CGFloat = 20
    private static let errorPad: CGFloat = 25
    #else
    private static let logoIconSize: CGFloat = 40
    private static let logoGlowSize: CGFloat = 80
    private static let logoTitleSize: CGFloat = 34
    private static let sectionTitleSize: CGFloat = 24
    private static let sectionSubSize: CGFloat = 14
    private static let fieldLabelSize: CGFloat = 14
    private static let fieldTextSize: CGFloat = 17
    private static let fieldPad: CGFloat = 14
    private static let btnIconSize: CGFloat = 20
    private static let btnTextSize: CGFloat = 17
    private static let cardMaxWidth: CGFloat = 500
    private static let cardPadding: CGFloat = 24
    private static let qcCodeSize: CGFloat = 40
    private static let listTitleSize: CGFloat = 17
    private static let hintSize: CGFloat = 15
    private static let separatorSize: CGFloat = 13
    private static let errorIconSize: CGFloat = 20
    private static let errorTextSize: CGFloat = 15
    private static let errorPad: CGFloat = 14
    #endif

    private var logoSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.secondary.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: Self.logoGlowSize * 0.5
                        )
                    )
                    .frame(width: Self.logoGlowSize, height: Self.logoGlowSize)
                    .blur(radius: 20)

                Image(systemName: "play.tv.fill")
                    .font(.system(size: Self.logoIconSize, weight: .bold))
                    .foregroundStyle(AppTheme.accentGradient)
                    .glowing(color: .appSecondary, radius: 20)
            }
            .scaleEffect(viewModel.animateLogo ? 1.0 : 0.8)
            .opacity(viewModel.animateLogo ? 1.0 : 0.0)

            Text("app.name".localized)
                .font(.system(size: Self.logoTitleSize, weight: .black, design: .rounded))
                .foregroundStyle(
                        LinearGradient(
                            colors: [.white, AppTheme.tertiary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .glowing(color: .appTertiary, radius: 10)
                .offset(y: viewModel.animateLogo ? 0 : 20)
                .opacity(viewModel.animateLogo ? 1.0 : 0.0)
        }
    }
    
    // MARK: - Connection Card
    
    private var connectionCard: some View {
        VStack(spacing: 0) {
            switch viewModel.connectionStep {
            case .server:
                serverConnectionView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .authentication:
                authenticationView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .quickConnect:
                quickConnectView
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
        .glassCard(cornerRadius: 24, padding: Self.cardPadding)
        .frame(maxWidth: Self.cardMaxWidth)
    }
    
    // MARK: - Server Connection View

    private var serverConnectionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .font(.system(size: Self.sectionTitleSize))
                    .foregroundStyle(AppTheme.secondary)
                    .glowing(color: .appSecondary)

                Text("login.server_connection".localized)
                    .font(.system(size: Self.sectionTitleSize, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("login.server_prompt".localized)
                    .font(.system(size: Self.sectionSubSize))
                    .foregroundStyle(Color.appTextSecondary)
            }

            if Self.usesServerList {
                // iPhone : une seule liste verticale, récents puis découverts
                if !viewModel.mergedServers.isEmpty || viewModel.isDiscovering {
                    serverListSection
                }
            } else {
                // Section serveurs découverts
                if !viewModel.discoveredServers.isEmpty || viewModel.isDiscovering {
                    discoveredServersSection
                }

                // Section serveurs récents
                if !viewModel.recentServers.isEmpty {
                    recentServersSection
                }
            }

            // Séparateur si on a des serveurs
            if !viewModel.discoveredServers.isEmpty || !viewModel.recentServers.isEmpty {
                HStack {
                    Rectangle()
                        .fill(AppTheme.glassStroke)
                        .frame(height: 1)
                    Text("login.or_manual".localized)
                        .font(.system(size: Self.separatorSize, weight: .medium))
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(Color.appTextTertiary)
                    Rectangle()
                        .fill(AppTheme.glassStroke)
                        .frame(height: 1)
                }
                .padding(.vertical, 10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("login.server_url".localized, systemImage: "link")
                    .font(.system(size: Self.fieldLabelSize, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)

                TextField("login.server_placeholder".localized, text: $viewModel.serverURL)
                    .font(.system(size: Self.fieldTextSize, weight: .medium))
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    #if !os(tvOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .padding(Self.fieldPad)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.glassStroke, lineWidth: 2)
                            )
                    )
                    .submitLabel(.continue)
                    .onSubmit {
                        Task { await viewModel.connectToServer() }
                    }
            }

            Button {
                Task { await viewModel.connectToServer() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isConnecting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: Self.btnIconSize))
                        Text("common.continue".localized)
                            .font(.system(size: Self.btnTextSize, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle(isProminent: true))
            .glassButton(prominent: true)
            .disabled(!viewModel.canConnectToServer)
            .opacity(viewModel.serverButtonOpacity)
        }
    }

    // MARK: - Discovered Servers Section

    private var discoveredServersSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundStyle(AppTheme.accent)
                Text("login.discovered_servers".localized)
                    .font(.system(size: Self.listTitleSize, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.appTextPrimary)

                if viewModel.isDiscovering {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.leading, 5)
                }

                Spacer()
            }

            if viewModel.discoveredServers.isEmpty {
                Text("login.searching_servers".localized)
                    .font(.system(size: Self.hintSize))
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(viewModel.discoveredServers) { server in
                            ServerCardButton(server: server) {
                                viewModel.selectServer(server)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 15) // Espace pour scale + shadow
                }
                .scrollClipDisabled() // Permet aux ombres/scale de dépasser
            }
        }
    }

    // MARK: - Server List (iPhone)

    /// Les cartes horizontales (pensées pour la télécommande) sont coupées sur
    /// la largeur d'un iPhone : liste verticale façon Réglages à la place
    private static var usesServerList: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }

    private var serverListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("login.servers".localized)
                    .font(.system(size: Self.listTitleSize, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.appTextPrimary)
                if viewModel.isDiscovering {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.leading, 5)
                }
                Spacer()
            }

            let servers = viewModel.mergedServers
            if servers.isEmpty {
                Text("login.searching_servers".localized)
                    .font(.system(size: Self.hintSize))
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(servers.enumerated()), id: \.element.id) { index, server in
                        if index > 0 {
                            Rectangle()
                                .fill(AppTheme.glassStroke)
                                .frame(height: 1)
                                .padding(.leading, 48)
                        }
                        serverRow(server)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                        )
                )
            }
        }
    }

    private func serverRow(_ server: ServerItem) -> some View {
        let isRecent = viewModel.recentServers.contains { $0.id == server.id }
        return Button {
            viewModel.selectServer(server)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isRecent ? "clock.arrow.circlepath" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: 18))
                    .foregroundStyle(isRecent ? AppTheme.secondary : AppTheme.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(server.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if server.isSecure {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.green)
                        }
                        Text(server.displayURL)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        if isRecent {
                            Text("· " + "login.recent_badge".localized)
                                .fixedSize()
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appTextTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Servers Section

    private var recentServersSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(AppTheme.secondary)
                Text("login.recent_servers".localized)
                    .font(.system(size: Self.listTitleSize, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(viewModel.recentServers) { server in
                        ServerCardButton(server: server) {
                            viewModel.selectServer(server)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 15) // Espace pour scale + shadow
            }
            .scrollClipDisabled() // Permet aux ombres/scale de dépasser
        }
    }

    // MARK: - Authentication View
    
    private var authenticationView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: Self.sectionTitleSize))
                    .foregroundStyle(AppTheme.tertiary)
                    .glowing(color: .appTertiary)

                Text("login.authentication".localized)
                    .font(.system(size: Self.sectionTitleSize, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("login.credentials_prompt".localized)
                    .font(.system(size: Self.sectionSubSize))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 8) {
                Label("login.username".localized, systemImage: "person")
                    .font(.system(size: Self.fieldLabelSize, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)

                TextField("login.username_placeholder".localized, text: $viewModel.username)
                    .textFieldStyle(.plain)
                    .font(.system(size: Self.fieldTextSize, weight: .medium))
                    .textContentType(.username)
                    #if !os(tvOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .padding(Self.fieldPad)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.glassStroke, lineWidth: 2)
                            )
                    )
                    .submitLabel(.next)
                    .focused($authFocusedField, equals: .username)
                    .onSubmit { authFocusedField = .password }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("login.password".localized, systemImage: "lock.fill")
                    .font(.system(size: Self.fieldLabelSize, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)

                SecureField("login.password_placeholder".localized, text: $viewModel.password)
                    .textFieldStyle(.plain)
                    .font(.system(size: Self.fieldTextSize, weight: .medium))
                    .textContentType(.password)
                    .padding(Self.fieldPad)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.glassStroke, lineWidth: 2)
                            )
                    )
                    .submitLabel(.go)
                    .focused($authFocusedField, equals: .password)
                    .onSubmit {
                        Task { await viewModel.authenticate() }
                    }
            }

            HStack(spacing: 14) {
                Button(action: { viewModel.goBackToServer() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: Self.btnIconSize * 0.85))
                        #if os(tvOS)
                        Text("common.back".localized)
                            .font(.system(size: Self.btnTextSize * 0.85, weight: .medium))
                        #endif
                    }
                    .foregroundColor(.white)
                    #if os(tvOS)
                    .frame(maxWidth: .infinity)
                    #endif
                }
                .buttonStyle(GlassButtonStyle(isProminent: false))
                .glassButton(prominent: false)
                #if os(iOS)
                // Sur iPhone, la flèche seule : le bouton Se connecter garde la place
                .accessibilityLabel("common.back".localized)
                #endif

                Button {
                    Task { await viewModel.authenticate() }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isConnecting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: Self.btnIconSize))
                            Text("login.sign_in".localized)
                                .font(.system(size: Self.btnTextSize, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(isProminent: true))
                .glassButton(prominent: true)
                .disabled(!viewModel.canAuthenticate)
                .opacity(viewModel.authButtonOpacity)
                .focused($authFocusedField, equals: .loginButton)
            }

            // Alternative sans mot de passe (si le serveur la propose)
            if viewModel.quickConnectAvailable {
                Button {
                    viewModel.startQuickConnect()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: Self.btnIconSize * 0.85))
                        Text("login.quick_connect".localized)
                            .font(.system(size: Self.btnTextSize * 0.85, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(.appTextSecondary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(isProminent: false))
                .glassButton(prominent: false)
                .padding(.top, 6)
                .transition(.opacity)
            }
        }
        .onAppear {
            // Mettre le focus sur le champ mot de passe si le username est pré-rempli
            // (le mot de passe n'est jamais persisté, il doit être ressaisi)
            if viewModel.credentialsPreFilled {
                // Délai pour laisser la vue se charger et l'animation de transition se terminer
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authFocusedField = .password
                }
            }
        }
    }
    
    // MARK: - Quick Connect View

    private var quickConnectView: some View {
        VStack(spacing: 22) {
            // En-tête
            VStack(spacing: 8) {
                Image(systemName: "qrcode")
                    .font(.system(size: Self.sectionTitleSize))
                    .foregroundStyle(AppTheme.secondary)
                    .glowing(color: .appSecondary)

                Text("login.quick_connect_title".localized)
                    .font(.system(size: Self.sectionTitleSize * 0.8, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("login.quick_connect_instructions".localized)
                    .font(.system(size: Self.sectionSubSize))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Le code, en très grand
            Group {
                if let code = viewModel.quickConnectCode {
                    Text(code)
                        .font(.system(size: Self.qcCodeSize, weight: .bold, design: .monospaced))
                        .foregroundColor(.appTextPrimary)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.appSecondary)
                        .scaleEffect(1.4)
                        .frame(height: Self.qcCodeSize)
                }
            }
            .padding(.horizontal, Self.fieldPad * 1.5)
            .padding(.vertical, Self.fieldPad)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.glassStroke, lineWidth: 2)
                    )
            )
            .glowing(color: .appSecondary, radius: 15)

            // État de la session
            switch viewModel.quickConnectState {
            case .waiting:
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.appTextTertiary)
                    Text("login.quick_connect_waiting".localized)
                        .font(.system(size: Self.sectionSubSize))
                        .foregroundColor(.appTextTertiary)
                }
            case .expired:
                Text("login.quick_connect_expired".localized)
                    .font(.system(size: Self.sectionSubSize, weight: .semibold))
                    .foregroundColor(.appError)
            }

            // Actions
            HStack(spacing: 14) {
                Button(action: { viewModel.cancelQuickConnect() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: Self.btnIconSize * 0.85))
                        Text("common.back".localized)
                            .font(.system(size: Self.btnTextSize * 0.85, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(isProminent: false))
                .glassButton(prominent: false)

                if viewModel.quickConnectState == .expired {
                    Button(action: { viewModel.startQuickConnect() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: Self.btnIconSize * 0.85))
                            Text("login.quick_connect_new_code".localized)
                                .font(.system(size: Self.btnTextSize * 0.85, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true))
                    .glassButton(prominent: true)
                }
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: Self.errorIconSize))
                .foregroundStyle(Color.appError)

            Text(message)
                .font(.system(size: Self.errorTextSize, weight: .medium))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: {
                viewModel.clearError()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: Self.errorIconSize * 0.85))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(Self.errorPad)
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

// MARK: - Server Card Button

/// Bouton carte pour afficher un serveur (découvert ou récent)
struct ServerCardButton: View {
    let server: ServerItem
    let action: () -> Void

    #if os(tvOS)
    private static let iconSize: CGFloat = 24
    private static let nameSize: CGFloat = 20
    private static let urlSize: CGFloat = 14
    private static let pad: CGFloat = 20
    private static let size = CGSize(width: 220, height: 120)
    #else
    private static let iconSize: CGFloat = 18
    private static let nameSize: CGFloat = 16
    private static let urlSize: CGFloat = 12
    private static let pad: CGFloat = 14
    private static let size = CGSize(width: 180, height: 96)
    #endif

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: serverIcon)
                        .font(.system(size: Self.iconSize))
                        .foregroundStyle(iconColor)

                    Spacer()

                    if server.isSecure {
                        Image(systemName: "lock.fill")
                            .font(.system(size: Self.urlSize))
                            .foregroundStyle(Color.green)
                    }
                }

                Text(server.name)
                    .font(.system(size: Self.nameSize, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)

                Text(server.displayURL)
                    .font(.system(size: Self.urlSize))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(1)
            }
            .padding(Self.pad)
            .frame(width: Self.size.width, height: Self.size.height)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(AppTheme.glassStroke, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(CustomCardButtonStyle(cornerRadius: 15))
    }

    private var serverIcon: String {
        switch server.source {
        case .discovered:
            return "antenna.radiowaves.left.and.right"
        case .recent:
            return "clock"
        case .manual:
            return "server.rack"
        }
    }

    private var iconColor: Color {
        switch server.source {
        case .discovered:
            return AppTheme.tertiary
        case .recent:
            return AppTheme.secondary
        case .manual:
            return Color.appTextSecondary
        }
    }
}

#Preview {
    LoginView(jellyfinService: JellyfinService())
}
