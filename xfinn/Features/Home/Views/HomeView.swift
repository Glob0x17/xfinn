//
//  HomeView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Refactored with ViewModel pattern - Phase 1
//

import SwiftUI

/// Données pré-calculées pour une particule de fond
private struct ParticleData: Identifiable {
    let id: Int
    let size: CGFloat
    let xRatio: CGFloat  // Ratio 0-1 pour la position X
    let yRatio: CGFloat  // Ratio 0-1 pour la position Y
}

/// Enum consolidé pour la gestion du focus dans HomeView
enum HomeFocus: Hashable {
    case heroPlay
    case heroDetails
    case searchButton
    case librariesButton
    case mediaItem(String)
}

/// Vue d'accueil moderne avec design Liquid Glass
struct HomeView: View {
    // MARK: - Dependencies

    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator

    // MARK: - ViewModel

    @StateObject private var viewModel: HomeViewModel

    // MARK: - UI State (reste dans la vue car purement UI)

    @Namespace private var focusNamespace
    @FocusState private var focus: HomeFocus?
    @State private var showLogoutConfirmation = false
    #if os(iOS)
    @State private var showSettings = false
    #endif

    // Particules déterministes pour éviter les variations visuelles entre affichages
    private static let particlePreset: [ParticleData] = (0..<8).map { index in
        let value = Double(index + 1)
        return ParticleData(
            id: index,
            size: CGFloat(220 + ((index * 37) % 160)),
            xRatio: CGFloat((sin(value * 1.7) + 1.0) * 0.5),
            yRatio: CGFloat((cos(value * 2.1) + 1.0) * 0.5)
        )
    }
    private let particles = particlePreset

    // MARK: - Initialization

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._viewModel = StateObject(wrappedValue: HomeViewModel(jellyfinService: jellyfinService))
    }

    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            ZStack {
                // Background avec gradient
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                // Particules flottantes subtiles (positions pré-calculées)
                GeometryReader { geometry in
                    ForEach(particles) { particle in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppTheme.secondary.opacity(0.18),
                                        AppTheme.tertiary.opacity(0.10),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 150
                                )
                            )
                            .frame(width: particle.size)
                            .offset(
                                x: particle.xRatio * geometry.size.width,
                                y: particle.yRatio * geometry.size.height
                            )
                            .blur(radius: 40)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                // Contenu
                GeometryReader { geo in
                ScrollView {
                    #if os(tvOS)
                    let sectionSpacing: CGFloat = 36
                    #else
                    let sectionSpacing: CGFloat = 20
                    #endif
                    VStack(alignment: .leading, spacing: sectionSpacing) {
                        // En-tête moderne
                        headerView
                            .padding(.top, 10)

                        if let featuredItem = featuredItem {
                            featuredHeroView(featuredItem)
                        }

                        // Section "À reprendre"
                        if viewModel.hasResumeItems {
                            MediaCarousel(
                                title: "home.continue_watching".localized,
                                icon: "play.circle.fill",
                                items: viewModel.resumeItems,
                                jellyfinService: jellyfinService,
                                accentColor: .appSecondary,
                                focusNamespace: focusNamespace,
                                isFirstCarousel: true,
                                focus: $focus
                            )
                        }

                        // Section "Récemment ajoutés"
                        if viewModel.hasRecentItems {
                            MediaCarousel(
                                title: "home.recently_added".localized,
                                icon: "sparkles",
                                items: viewModel.recentItems,
                                jellyfinService: jellyfinService,
                                accentColor: .appTertiary,
                                focusNamespace: focusNamespace,
                                isFirstCarousel: !viewModel.hasResumeItems,
                                focus: $focus
                            )
                        }

                        // Section "Favoris"
                        if viewModel.hasFavoriteItems {
                            MediaCarousel(
                                title: "home.favorites".localized,
                                icon: "heart.fill",
                                items: viewModel.favoriteItems,
                                jellyfinService: jellyfinService,
                                accentColor: .appTertiary,
                                focusNamespace: focusNamespace,
                                isFirstCarousel: !viewModel.hasResumeItems && !viewModel.hasRecentItems,
                                focus: $focus
                            )
                        }

                        // Espace pour le bas
                        Color.clear.frame(height: 24)
                    }
                    .frame(width: geo.size.width, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.bottom, 24)
                }
                }
                .animation(AppTheme.standardAnimation, value: viewModel.hasResumeItems)
                .animation(AppTheme.standardAnimation, value: viewModel.hasRecentItems)
                #if os(tvOS)
                .focusScope(focusNamespace)
                .onMoveCommand(perform: handleVerticalRailNavigation)
                #endif
            }
            .toolbar {
                #if os(tvOS)
                let toolbarIconSize: CGFloat = 26
                let toolbarLabelSize: CGFloat = 19
                #else
                let toolbarIconSize: CGFloat = 18
                let toolbarLabelSize: CGFloat = 13
                #endif
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.hasMusicLibrary {
                        Button {
                            navigationCoordinator.navigateToMusicLibrary()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "music.note")
                                    .font(.system(size: toolbarIconSize))
                                Text("music.library_title".localized)
                                    .font(.system(size: toolbarLabelSize, weight: .semibold))
                            }
                            .foregroundColor(.appSecondary)
                        }
                        #if os(tvOS)
                        .focusable(false)
                        #endif
                    }
                }

                #if os(iOS)
                // iOS : réglages (la déconnexion y est, avec confirmation) plutôt qu'un bouton
                // « Déconnexion » exposé en haut de l'accueil
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: toolbarIconSize))
                            .foregroundColor(.appTextSecondary)
                    }
                    .accessibilityLabel("settings.title".localized)
                }
                #else
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLogoutConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: toolbarIconSize))
                            Text("settings.sign_out".localized)
                                .font(.system(size: toolbarLabelSize, weight: .semibold))
                        }
                        .foregroundColor(.appError)
                    }
                    .focusable(false)
                }
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $showSettings) {
                SettingsView(jellyfinService: jellyfinService)
            }
            #endif
            .alert("settings.sign_out_confirm".localized, isPresented: $showLogoutConfirmation) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("settings.sign_out".localized, role: .destructive) {
                    withAnimation(AppTheme.standardAnimation) {
                        jellyfinService.logout()
                    }
                }
            } message: {
                Text("settings.sign_out_message".localized)
            }
            .overlay {
                if viewModel.loadingState.isLoading {
                    modernLoadingView
                } else if viewModel.loadingState.isError {
                    ZStack {
                        AppTheme.backgroundGradient.ignoresSafeArea()
                        ErrorStateView(
                            message: viewModel.errorMessage ?? "error.generic".localized
                        ) {
                            Task { await viewModel.loadContent() }
                        }
                    }
                }
            }
            // Seuls points d'entrée des écrans poussés (voir AppDestinations)
            .navigationDestination(for: MediaItem.self) { item in
                MediaItemDestination(item: item, jellyfinService: jellyfinService)
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppRouteDestination(route: route, jellyfinService: jellyfinService)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // .task gère automatiquement l'annulation quand la vue disparaît
            if !viewModel.hasLoaded, jellyfinService.isAuthenticated {
                await viewModel.loadContent()
            }
        }
    }

    #if os(tvOS)
    private func handleVerticalRailNavigation(_ direction: MoveCommandDirection) {
        guard case .mediaItem(let currentId) = focus else { return }

        switch direction {
        case .down:
            guard let sourceIndex = viewModel.resumeItems.firstIndex(where: { $0.id == currentId }),
                  !viewModel.recentItems.isEmpty else { return }
            let targetIndex = min(sourceIndex, viewModel.recentItems.count - 1)
            focus = .mediaItem(viewModel.recentItems[targetIndex].id)

        case .up:
            guard let sourceIndex = viewModel.recentItems.firstIndex(where: { $0.id == currentId }),
                  !viewModel.resumeItems.isEmpty else { return }
            let targetIndex = min(sourceIndex, viewModel.resumeItems.count - 1)
            focus = .mediaItem(viewModel.resumeItems[targetIndex].id)

        default:
            break
        }
    }
    #endif
    
    // MARK: - Header View
    
    #if os(tvOS)
    private static let headerHPadding: CGFloat = 52
    private static let headerIconSize: CGFloat = 58
    private static let headerTitleSize: CGFloat = 34
    private static let headerSubtitleSize: CGFloat = 18
    private static let headerTaglineSize: CGFloat = 22
    private static let headerIconFontSize: CGFloat = 20
    private static let headerAppIconSize: CGFloat = 26
    private static let headerLabelFontSize: CGFloat = 19
    private static let headerPillHPadding: CGFloat = 24
    #else
    private static let headerHPadding: CGFloat = 16
    private static let headerIconSize: CGFloat = 44
    private static let headerTitleSize: CGFloat = 20
    private static let headerSubtitleSize: CGFloat = 12
    private static let headerTaglineSize: CGFloat = 13
    private static let headerIconFontSize: CGFloat = 14
    private static let headerAppIconSize: CGFloat = 16
    private static let headerLabelFontSize: CGFloat = 13
    private static let headerPillHPadding: CGFloat = 14
    #endif

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "play.tv.fill")
                    .font(.system(size: Self.headerAppIconSize))
                    .foregroundStyle(AppTheme.accentGradient)

                VStack(alignment: .leading, spacing: 2) {
                    Text("app.name".localized)
                        .font(.system(size: Self.headerTitleSize, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, AppTheme.tertiary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    if let user = jellyfinService.currentUser {
                        Text("\("home.hello".localized) \(user.name)")
                            .font(.system(size: Self.headerSubtitleSize, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                    } else {
                        Text("home.welcome".localized)
                            .font(.system(size: Self.headerSubtitleSize, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        navigationCoordinator.navigateToSearch()
                    } label: {
                        headerActionLabel(systemName: "magnifyingglass",
                                          title: "home.search".localized)
                    }
                    #if os(tvOS)
                    .buttonStyle(CustomCardButtonStyle(cornerRadius: 29))
                    .focused($focus, equals: .searchButton)
                    #endif

                    NavigationLink(value: AppRoute.libraries) {
                        headerActionLabel(systemName: "square.grid.2x2.fill",
                                          title: "home.libraries".localized)
                    }
                    #if os(tvOS)
                    .buttonStyle(CustomCardButtonStyle(cornerRadius: 29))
                    .focused($focus, equals: .librariesButton)
                    #endif
                }
            }
            .padding(.horizontal, Self.headerHPadding)

            Text("home.what_to_watch".localized)
                .font(.system(size: Self.headerTaglineSize, weight: .medium))
                .foregroundStyle(Color.appTextTertiary)
                .padding(.horizontal, Self.headerHPadding)
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }

    /// Pastille de navigation icône + libellé : le texte rend la destination
    /// explicite (UI 10-foot, navigation à la télécommande)
    private func headerActionLabel(systemName: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: Self.headerIconFontSize, weight: .semibold))
            // iPhone : icône seule, le libellé ne tient pas à côté du titre
            if UIDevice.current.userInterfaceIdiom != .phone {
                Text(title)
                    .font(.system(size: Self.headerLabelFontSize, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .accessibilityLabel(title)
        .foregroundStyle(Color.appTextPrimary)
        .padding(.horizontal, Self.headerPillHPadding)
        .frame(height: Self.headerIconSize)
        .background(
            Capsule()
                .fill(AppTheme.glassBackground)
                .overlay(
                    Capsule()
                        .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                )
        )
    }

    private var featuredItem: MediaItem? {
        viewModel.resumeItems.first ?? viewModel.recentItems.first
    }

    #if os(tvOS)
    private static let heroHeight: CGFloat = 610
    private static let heroTitleSize: CGFloat = 54
    private static let heroDescSize: CGFloat = 22
    private static let heroDescMaxWidth: CGFloat = 920
    private static let heroBtnTitleSize: CGFloat = 22
    private static let heroBtnIconSize: CGFloat = 19
    private static let heroPadH: CGFloat = 46
    private static let heroPadV: CGFloat = 36
    private static let heroOuterPadH: CGFloat = 52
    #else
    private static let heroHeight: CGFloat = 340
    private static let heroTitleSize: CGFloat = 22
    private static let heroDescSize: CGFloat = 13
    private static let heroDescMaxWidth: CGFloat = 360
    private static let heroBtnTitleSize: CGFloat = 14
    private static let heroBtnIconSize: CGFloat = 12
    private static let heroPadH: CGFloat = 16
    private static let heroPadV: CGFloat = 20
    private static let heroOuterPadH: CGFloat = 16
    #endif

    private func featuredHeroView(_ item: MediaItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Image en background pour ne pas affecter le layout
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: item.id))) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.35), Color.black.opacity(0.25)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        default:
                            Color.clear
                        }
                    }
                }
                .clipped()
                .allowsHitTesting(false)

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.45),
                    .black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                Text(heroSourceText(for: item))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.glassStroke, lineWidth: 1)
                            )
                    )

                Text(item.displayTitle)
                    .font(.system(size: Self.heroTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    if let year = item.productionYear {
                        heroChip(systemName: "calendar", text: String(year))
                    }
                    if let rating = item.communityRating {
                        heroChip(systemName: "star.fill", text: String(format: "%.1f", rating))
                    }
                    heroChip(systemName: "sparkles.tv", text: item.localizedTypeName)
                }

                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.system(size: Self.heroDescSize, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(3)
                        #if os(tvOS)
                        .frame(maxWidth: Self.heroDescMaxWidth, alignment: .leading)
                        #endif
                }

                HStack(spacing: 12) {
                    if item.type == "Series" || item.type == "Season" {
                        NavigationLink(value: item) {
                            heroPrimaryAction(title: "media.play".localized, icon: "play.fill")
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 10))
                        .focused($focus, equals: .heroPlay)
                    } else {
                        Button {
                            navigationCoordinator.navigateTo(item: item, autoPlay: true)
                        } label: {
                            heroPrimaryAction(title: "media.play".localized, icon: "play.fill")
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 10))
                        .focused($focus, equals: .heroPlay)
                    }

                    NavigationLink(value: item) {
                        heroSecondaryAction(title: "tech.details".localized, icon: "info.circle")
                    }
                    .buttonStyle(CustomCardButtonStyle(cornerRadius: 10))
                    .focused($focus, equals: .heroDetails)
                }
            }
            .padding(.horizontal, Self.heroPadH)
            .padding(.vertical, Self.heroPadV)
        }
        .frame(height: Self.heroHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke.opacity(0.6), lineWidth: 1.2)
        )
        .padding(.horizontal, Self.heroOuterPadH)
        #if os(tvOS)
        .focusSection()
        #endif
    }

    private func heroSourceText(for item: MediaItem) -> String {
        if viewModel.resumeItems.contains(item) {
            return "home.continue_watching".localized
        }
        return "home.recently_added".localized
    }

    private func heroChip(systemName: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.35), in: Capsule())
    }

    private func heroPrimaryAction(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: Self.heroBtnIconSize, weight: .bold))
            Text(title)
                .font(.system(size: Self.heroBtnTitleSize, weight: .bold))
        }
        .foregroundStyle(Color.black)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
    }

    private func heroSecondaryAction(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: Self.heroBtnIconSize, weight: .semibold))
            Text(title)
                .font(.system(size: Self.heroBtnTitleSize, weight: .semibold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        )
    }

    // MARK: - Modern Loading View
    
    private var modernLoadingView: some View {
        ZStack {
            // Backdrop blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Spinner avec glass effect
                ZStack {
                    Circle()
                        .fill(AppTheme.glassBackground)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.glassStroke, lineWidth: 2)
                        )
                    
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(2.0)
                        .tint(.appSecondary)
                }
                .glowing(color: .appSecondary, radius: 30)
                
                Text("home.loading_content".localized)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.appTextPrimary)
            }
        }
    }
    
    // MARK: - Load Content (delegated to ViewModel)
    // La logique de chargement est maintenant dans HomeViewModel
}

// MARK: - Media Carousel

/// Carrousel horizontal moderne avec glass effect
struct MediaCarousel: View {
    let title: String
    let icon: String
    let items: [MediaItem]
    let jellyfinService: JellyfinService
    let accentColor: Color
    let focusNamespace: Namespace.ID
    let isFirstCarousel: Bool
    @FocusState.Binding var focus: HomeFocus?
    
    #if os(tvOS)
    private static let sectionTitleSize: CGFloat = 31
    private static let sectionIconSize: CGFloat = 18
    private static let badgeSize: CGFloat = 17
    private static let carouselHPad: CGFloat = 52
    private static let cardSpacing: CGFloat = 18
    #else
    private static let sectionTitleSize: CGFloat = 18
    private static let sectionIconSize: CGFloat = 14
    private static let badgeSize: CGFloat = 12
    private static let carouselHPad: CGFloat = 16
    private static let cardSpacing: CGFloat = 10
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête de section
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: Self.sectionIconSize, weight: .semibold))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: Self.sectionTitleSize, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                // Badge de compteur
                Text("\(items.count)")
                    .font(.system(size: Self.badgeSize, weight: .semibold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                Capsule()
                                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                            )
                    )
            }
            .padding(.horizontal, Self.carouselHPad)

            // Carrousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.cardSpacing) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        NavigationLink(value: item) {
                            ModernMediaCard(
                                item: item,
                                jellyfinService: jellyfinService,
                                accentColor: accentColor
                            )
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                        .focused($focus, equals: .mediaItem(item.id))
                        #if os(tvOS)
                        .prefersDefaultFocus(isFirstCarousel && index == 0, in: focusNamespace)
                        #endif
                    }
                }
                .padding(.horizontal, Self.carouselHPad)
                .padding(.vertical, 8)
            }
            #if os(tvOS)
            .scrollClipDisabled()
            #endif
        }
    }
}

// MARK: - Modern Media Card

/// Carte de média moderne avec design Liquid Glass
struct ModernMediaCard: View {
    #if os(tvOS)
    private static let cardWidth: CGFloat = 360
    private static let imageHeight: CGFloat = 530
    private static let contentPadding: CGFloat = 18
    private static let cardTitleSize: CGFloat = 22
    private static let cardMetaSize: CGFloat = 16
    private static let cardMetaIconSize: CGFloat = 14
    private static let cardPlayIconSize: CGFloat = 24
    #else
    private static let cardWidth: CGFloat = 200
    private static let imageHeight: CGFloat = 280
    private static let contentPadding: CGFloat = 12
    private static let cardTitleSize: CGFloat = 14
    private static let cardMetaSize: CGFloat = 12
    private static let cardMetaIconSize: CGFloat = 11
    private static let cardPlayIconSize: CGFloat = 18
    #endif

    let item: MediaItem
    let jellyfinService: JellyfinService
    let accentColor: Color

    /// UserData avec overrides locaux (marquer vu/favori sans re-fetch)
    private var effectiveUserData: UserData? {
        jellyfinService.effectiveUserData(for: item)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image avec overlay
            ZStack(alignment: .bottomLeading) {
                // Background placeholder
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Image chargée
                AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: item.id))) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(accentColor)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.2)
                            VStack(spacing: 10) {
                                Image(systemName: "film")
                                    .font(.system(size: 50))
                                    .foregroundStyle(Color.appTextTertiary)
                                Text("home.image_unavailable".localized)
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextTertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Overlay gradient en bas
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .frame(maxHeight: .infinity, alignment: .bottom)
                
                // Barre de progression pour les médias en cours
                if let userData = effectiveUserData,
                   userData.playbackPositionTicks > 0,
                   let duration = item.duration {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Progress bar glass
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            // Progress
                            Capsule()
                                .fill(accentColor)
                                .frame(
                                    width: (Self.cardWidth - (Self.contentPadding * 2)) * (duration > 0 ? userData.playbackPosition / duration : 0),
                                    height: 6
                                )
                        }
                        .padding(.horizontal, Self.contentPadding)
                        .padding(.bottom, 15)
                    }
                }
            }
            .frame(width: Self.cardWidth, height: Self.imageHeight)
            .overlay(alignment: .topTrailing) {
                MediaCardBadges(userData: effectiveUserData)
                    .padding(8)
            }
            .clipped()
            
            // Informations avec glass background
            VStack(alignment: .leading, spacing: 6) {
                // Titre
                Text(item.displayTitle)
                    .font(.system(size: Self.cardTitleSize, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Métadonnées
                HStack(spacing: 10) {
                    // Année
                    if let year = item.productionYear {
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: Self.cardMetaIconSize))
                            Text(String(year))
                                .font(.system(size: Self.cardMetaSize, weight: .medium))
                        }
                        .foregroundStyle(Color.appTextSecondary)
                    }

                    // Séparateur
                    if item.productionYear != nil && item.communityRating != nil {
                        Circle()
                            .fill(Color.appTextTertiary)
                            .frame(width: 3, height: 3)
                    }

                    // Note
                    if let rating = item.communityRating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: Self.cardMetaIconSize))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: Self.cardMetaSize, weight: .medium))
                                .foregroundStyle(Color.appTextPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    // Icône lecture
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: Self.cardPlayIconSize))
                        .foregroundColor(accentColor)
                }
            }
            .padding(Self.contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 0) // Pas de coins arrondis ici car déjà dans le parent
                    .fill(AppTheme.glassBackground)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
        .frame(width: Self.cardWidth)
        .mediaContextMenu(item: item, jellyfinService: jellyfinService)
    }
}

#Preview {
    HomeView(jellyfinService: JellyfinService())
}
