//
//  HomeView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

/// Données pré-calculées pour une particule de fond
private struct ParticleData: Identifiable {
    let id: Int
    let size: CGFloat
    let xRatio: CGFloat  // Ratio 0-1 pour la position X
    let yRatio: CGFloat  // Ratio 0-1 pour la position Y
}

/// Vue d'accueil moderne avec design Liquid Glass
struct HomeView: View {
    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator

    @State private var resumeItems: [MediaItem] = []
    @State private var recentItems: [MediaItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    @State private var selectedTab = 0
    @State private var showSearchView = false

    @Namespace private var focusNamespace
    @FocusState private var focusedItem: String?

    // Focus explicite pour le bouton de recherche
    @FocusState private var isSearchButtonFocused: Bool
    @FocusState private var isLibraryButtonFocused: Bool

    // Particules pré-calculées pour éviter les re-renders
    private let particles: [ParticleData] = (0..<8).map { index in
        ParticleData(
            id: index,
            size: CGFloat.random(in: 200...400),
            xRatio: CGFloat.random(in: 0...1),
            yRatio: CGFloat.random(in: 0...1)
        )
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
                                        AppTheme.primary.opacity(0.15),
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
                
                // Contenu
                ScrollView {
                    VStack(alignment: .leading, spacing: 60) {
                        // En-tête moderne
                        headerView
                            .padding(.top, 20)
                        
                        // Section "À reprendre"
                        if !resumeItems.isEmpty {
                            MediaCarousel(
                                title: "À reprendre",
                                icon: "play.circle.fill",
                                items: resumeItems,
                                jellyfinService: jellyfinService,
                                accentColor: .appPrimary,
                                focusNamespace: focusNamespace,
                                isFirstCarousel: true,
                                focusedItem: $focusedItem
                            )
                        }
                        
                        // Section "Récemment ajoutés"
                        if !recentItems.isEmpty {
                            MediaCarousel(
                                title: "Récemment ajoutés",
                                icon: "sparkles",
                                items: recentItems,
                                jellyfinService: jellyfinService,
                                accentColor: .appSecondary,
                                focusNamespace: focusNamespace,
                                isFirstCarousel: resumeItems.isEmpty,
                                focusedItem: $focusedItem
                            )
                        }
                        
                        // Espace pour le bas
                        Color.clear
                            .frame(height: 40)
                    }
                }
                .focusScope(focusNamespace)
            }
            .toolbar {
                // Toolbar simplifiée avec juste le bouton de déconnexion
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(AppTheme.standardAnimation) {
                            jellyfinService.logout()
                        }
                    } label: {
                        Image(systemName: "power")
                            .font(.system(size: 26))
                            .foregroundColor(.appError)
                    }
                    #if os(tvOS)
                    .focusable(false) // Désactiver le focus par défaut sur tvOS
                    #endif
                }
            }
            .overlay {
                if isLoading {
                    modernLoadingView
                }
            }
            .navigationDestination(isPresented: $showSearchView) {
                SearchView(jellyfinService: jellyfinService)
            }
            .navigationDestination(for: MediaItem.self) { item in
                MediaDetailView(item: item, jellyfinService: jellyfinService)
                    .id(item.id) // 🔥 Force SwiftUI à recréer la vue quand l'ID change
            }
        }
        .onAppear {
            if !hasLoaded, jellyfinService.isAuthenticated {
                Task {
                    await loadContent()
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 30) {
            // 🎯 Ligne du haut : Logo + Bouton recherche (toujours accessible)
            HStack(spacing: 15) {
                // Logo XFINN
                HStack(spacing: 15) {
                    Image(systemName: "play.tv.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("XFINN")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, AppTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Spacer()
                
                // 🔍 Bouton de recherche + Bouton bibliothèques côte à côte
                HStack(spacing: 20) {
                    // Bouton de recherche
                    Button {
                        showSearchView = true
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                            Text("Rechercher")
                                .font(.system(size: 22, weight: .semibold))
                        }
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.glassBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                    .focused($isSearchButtonFocused)
                    
                    // Bouton bibliothèques (mini version)
                    NavigationLink {
                        LibraryView(jellyfinService: jellyfinService)
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 24))
                            Text("Bibliothèques")
                                .font(.system(size: 22, weight: .semibold))
                        }
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.glassBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                    .focused($isLibraryButtonFocused)
                }
            }
            .padding(.horizontal, 60)
            #if os(tvOS)
            .focusSection() // Section de focus dédiée aux boutons du header
            #endif
            
            // Ligne message de bienvenue
            HStack(alignment: .top, spacing: 20) {
                // Message de bienvenue
                HStack(spacing: 15) {
                    if let user = jellyfinService.currentUser {
                        // Avatar glass
                        ZStack {
                            Circle()
                                .fill(AppTheme.glassBackground)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.glassStroke, lineWidth: 2)
                                )
                            
                            Text(String(user.name.prefix(1)).uppercased())
                                .font(.system(size: 35, weight: .bold))
                                .foregroundStyle(Color.appTextPrimary)
                        }
                        .glowing(color: .appPrimary, radius: 15)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bonjour,")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                            
                            Text(user.name)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, AppTheme.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bienvenue")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(Color.appTextPrimary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 60)
            
            // Sous-titre
            Text("Que souhaitez-vous regarder aujourd'hui ?")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color.appTextTertiary)
                .padding(.horizontal, 60)
        }
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
                        .tint(.appPrimary)
                }
                .glowing(color: .appPrimary, radius: 30)
                
                Text("Chargement du contenu...")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.appTextPrimary)
            }
        }
    }
    
    // MARK: - Load Content
    
    
    private func loadContent() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = true
        
        // Charger les données en parallèle
        async let resumeTask: Void = loadResumeItems()
        async let recentTask: Void = loadRecentItems()
        
        await resumeTask
        await recentTask
        
        await MainActor.run {
            withAnimation(AppTheme.standardAnimation) {
                isLoading = false
            }
        }
    }
    
    private func loadResumeItems() async {
        do {
            resumeItems = try await jellyfinService.getResumeItems(limit: 10)
        } catch {
            print("[HomeView] Erreur chargement items à reprendre: \(error.localizedDescription)")
        }
    }

    private func loadRecentItems() async {
        do {
            recentItems = try await jellyfinService.getLatestItems(limit: 10)
        } catch {
            print("[HomeView] Erreur chargement items récents: \(error.localizedDescription)")
        }
    }
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
    @FocusState.Binding var focusedItem: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // En-tête de section
            HStack(spacing: 15) {
                // Icône avec glass background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.glassBackground)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
                .glowing(color: accentColor, radius: 10)
                
                Text(title)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                
                Spacer()
                
                // Badge de compteur
                Text("\(items.count)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                Capsule()
                                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                            )
                    )
            }
            .padding(.horizontal, 60)
            
            // Carrousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            if item.type == "Series" {
                                SeriesDetailView(series: item, jellyfinService: jellyfinService)
                            } else if item.type == "Season" {
                                SeasonEpisodesView(season: item, jellyfinService: jellyfinService)
                            } else {
                                MediaDetailView(item: item, jellyfinService: jellyfinService)
                            }
                        } label: {
                            ModernMediaCard(
                                item: item,
                                jellyfinService: jellyfinService,
                                accentColor: accentColor
                            )
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                        .focused($focusedItem, equals: item.id)
                        .prefersDefaultFocus(isFirstCarousel && index == 0, in: focusNamespace)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 5) // Pour le shadow
            }
        }
    }
}

// MARK: - Modern Media Card

/// Carte de média moderne avec design Liquid Glass
struct ModernMediaCard: View {
    let item: MediaItem
    let jellyfinService: JellyfinService
    let accentColor: Color
    
    @Environment(\.isFocused) private var isFocused: Bool
    
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
                                .tint(.appPrimary)
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
                                Text("Image\nindisponible")
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
                if let userData = item.userData,
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
                                .frame(width: (400 - 40) * (userData.playbackPosition / duration), height: 6)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 15)
                    }
                }
            }
            .frame(width: 400, height: 600)
            .clipped()
            
            // Informations avec glass background
            VStack(alignment: .leading, spacing: 10) {
                // Titre
                Text(item.displayTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                // Métadonnées
                HStack(spacing: 15) {
                    // Année
                    if let year = item.productionYear {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                            Text(String(year))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(Color.appTextSecondary)
                    }
                    
                    // Séparateur
                    if item.productionYear != nil && item.communityRating != nil {
                        Circle()
                            .fill(Color.appTextTertiary)
                            .frame(width: 4, height: 4)
                    }
                    
                    // Note
                    if let rating = item.communityRating {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.appTextPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    // Icône lecture
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
            }
            .padding(20)
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
        .frame(width: 400)
    }
}

// MARK: - Legacy Carousel Media Card (pour compatibilité)

/// Carte de média pour le carrousel (version legacy)
struct CarouselMediaCard: View {
    let item: MediaItem
    let jellyfinService: JellyfinService
    
    var body: some View {
        ModernMediaCard(
            item: item,
            jellyfinService: jellyfinService,
            accentColor: .appPrimary
        )
    }
}

#Preview {
    HomeView(jellyfinService: JellyfinService())
}
