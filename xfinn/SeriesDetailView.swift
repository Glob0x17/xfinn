//
//  SeriesDetailView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

/// Vue de détail d'une série avec design Liquid Glass
struct SeriesDetailView: View {
    let series: MediaItem
    @ObservedObject var jellyfinService: JellyfinService
    
    @State private var seasons: [MediaItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 50) {
                    // Hero section avec backdrop
                    heroSection
                    
                    // Liste des saisons
                    if isLoading {
                        loadingView
                    } else if seasons.isEmpty {
                        emptyStateView
                    } else {
                        seasonsSection
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            if !hasLoaded {
                Task {
                    await loadSeasons()
                }
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Backdrop image
            AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: series.id, imageType: "Backdrop"))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 400)
                        .clipped()
                case .failure, .empty:
                    Rectangle()
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
                        .frame(height: 400)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Contenu des informations
            VStack(alignment: .leading, spacing: 20) {
                // Badge série
                HStack(spacing: 10) {
                    Image(systemName: "tv")
                        .font(.system(size: 18))
                    Text("Série TV")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(.appAccent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppTheme.glassBackground)
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1.5)
                        )
                )
                
                // Titre
                Text(series.name)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, AppTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Métadonnées
                HStack(spacing: 20) {
                    if let year = series.productionYear {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 20))
                            Text(String(year))
                                .font(.system(size: 24, weight: .medium))
                        }
                        .foregroundColor(.appTextSecondary)
                    }
                    
                    if let rating = series.communityRating {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
                
                // Synopsis
                if let overview = series.overview, !overview.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Synopsis")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                        
                        Text(overview)
                            .font(.system(size: 22))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(4)
                    }
                    .padding(25)
                    .background(AppTheme.glassBackground)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, 60)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(AppTheme.glassBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.glassStroke, lineWidth: 2)
                    )
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.8)
                    .tint(.appPrimary)
            }
            .glowing(color: .appPrimary, radius: 25)
            
            Text("Chargement des saisons...")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "tv.slash")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.appTextTertiary)
            
            VStack(spacing: 12) {
                Text("Aucune saison")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                
                Text("Cette série ne contient aucune saison")
                    .font(.system(size: 22))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Seasons Section
    
    private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            // En-tête
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.glassBackground)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                        )
                    
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 24))
                        .foregroundColor(.appAccent)
                }
                .glowing(color: .appAccent, radius: 10)
                
                Text("Saisons")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                
                Spacer()
                
                Text("\(seasons.count)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.appAccent)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1.5)
                            )
                    )
            }
            .padding(.horizontal, 60)
            
            // Grille de saisons - VERSION GRILLE pour tvOS
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 30),
                    GridItem(.flexible(), spacing: 30),
                    GridItem(.flexible(), spacing: 30)
                ],
                spacing: 30
            ) {
                ForEach(seasons) { season in
                    NavigationLink {
                        SeasonEpisodesView(season: season, jellyfinService: jellyfinService)
                    } label: {
                        SeasonCard(season: season, jellyfinService: jellyfinService)
                    }
                    .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                }
            }
            .padding(.horizontal, 60)
        }
    }
    
    // MARK: - Load Seasons
    
    @MainActor
    private func loadSeasons() async {
        guard !hasLoaded else {
            return
        }
        
        hasLoaded = true
        isLoading = true
        
        do {
            let loadedSeasons = try await jellyfinService.getItems(
                parentId: series.id,
                includeItemTypes: ["Season"]
            )
            
            withAnimation(AppTheme.standardAnimation) {
                self.seasons = loadedSeasons
                self.isLoading = false
            }
        } catch {
            print("[SeriesDetailView] Erreur chargement saisons: \(error.localizedDescription)")
            self.hasLoaded = false
            self.isLoading = false
        }
    }
}

// MARK: - Season Card

struct SeasonCard: View {
    let season: MediaItem
    let jellyfinService: JellyfinService
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster de la saison
            ZStack {
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
                
                AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: season.id))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        VStack(spacing: 15) {
                            Image(systemName: "tv")
                                .font(.system(size: 60))
                                .foregroundColor(.appTextTertiary)
                            Text(season.name)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(width: 300, height: 450)
            .clipped()
            
            // Informations
            VStack(alignment: .leading, spacing: 12) {
                Text(season.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                
                if let indexNumber = season.indexNumber {
                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.system(size: 14))
                        Text("Saison \(indexNumber)")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.appTextSecondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(AppTheme.glassBackground)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
        .frame(width: 300)
    }
}

// MARK: - Season Episodes View

struct SeasonEpisodesView: View {
    let season: MediaItem
    @ObservedObject var jellyfinService: JellyfinService
    
    @State private var episodes: [MediaItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if episodes.isEmpty {
                emptyStateView
            } else {
                episodesContent
            }
        }
        .navigationTitle(season.name)
        .onAppear {
            if !hasLoaded {
                Task {
                    await loadEpisodes()
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(AppTheme.glassBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.glassStroke, lineWidth: 2)
                    )
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.8)
                    .tint(.appPrimary)
            }
            .glowing(color: .appPrimary, radius: 25)
            
            Text("Chargement des épisodes...")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "film.slash")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.appTextTertiary)
            
            VStack(spacing: 12) {
                Text("Aucun épisode")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                
                Text("Cette saison ne contient aucun épisode")
                    .font(.system(size: 22))
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
    
    // MARK: - Episodes Content
    
    private var episodesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // En-tête
                VStack(alignment: .leading, spacing: 10) {
                    Text(season.name)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    
                    Text("\(episodes.count) épisode\(episodes.count > 1 ? "s" : "")")
                        .font(.system(size: 24))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
                
                // Liste des épisodes
                LazyVStack(spacing: 30) {
                    ForEach(episodes) { episode in
                        NavigationLink {
                            MediaDetailView(item: episode, jellyfinService: jellyfinService)
                        } label: {
                            ModernEpisodeRow(episode: episode, jellyfinService: jellyfinService)
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 60)
            }
        }
    }
    
    // MARK: - Load Episodes
    
    @MainActor
    private func loadEpisodes() async {
        guard !hasLoaded else {
            return
        }
        
        hasLoaded = true
        isLoading = true
        
        do {
            let loadedEpisodes = try await jellyfinService.getItems(
                parentId: season.id,
                includeItemTypes: ["Episode"]
            )
            
            withAnimation(AppTheme.standardAnimation) {
                self.episodes = loadedEpisodes
                self.isLoading = false
            }
        } catch {
            self.hasLoaded = false
            self.isLoading = false
        }
    }
}

// MARK: - Modern Episode Row

struct ModernEpisodeRow: View {
    let episode: MediaItem
    let jellyfinService: JellyfinService
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 30) {
            // Vignette de l'épisode
            ZStack(alignment: .bottomLeading) {
                // Background
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
                
                // Image
                AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: episode.id, imageType: "Primary"))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        VStack(spacing: 10) {
                            Image(systemName: "film")
                                .font(.system(size: 40))
                                .foregroundColor(.appTextTertiary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Durée et badge "Vu"
                HStack {
                    if episode.userData?.played == true {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Vu")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.success.opacity(0.9))
                        )
                    }
                    
                    Spacer()
                    
                    if let duration = episode.duration {
                        Text(formatDuration(duration))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.7))
                            )
                    }
                }
                .padding(15)
            }
            .frame(width: 500, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(AppTheme.glassStroke, lineWidth: 1.5)
            )
            
            // Informations de l'épisode
            VStack(alignment: .leading, spacing: 15) {
                // Numéro d'épisode
                if let episodeNumber = episode.indexNumber {
                    Text("Épisode \(episodeNumber)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appTextTertiary)
                }
                
                // Titre
                Text(episode.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                
                // Synopsis
                if let overview = episode.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.system(size: 20))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(3)
                }
                
                // Barre de progression
                if let userData = episode.userData,
                   userData.playbackPositionTicks > 0,
                   let duration = episode.duration {
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            // Progress
                            Capsule()
                                .fill(AppTheme.primary)
                                .frame(width: 450 * (userData.playbackPosition / duration), height: 6)
                        }
                        .frame(width: 450)
                        
                        Text("Reprendre à \(formatDuration(userData.playbackPosition))")
                            .font(.system(size: 16))
                            .foregroundColor(.appTextTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 24))
                .foregroundColor(.appTextTertiary)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.glassBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

#Preview {
    NavigationStack {
        SeriesDetailView(
            series: MediaItem(
                id: "1",
                name: "Série Test",
                type: "Series",
                overview: "Une série de test",
                productionYear: 2023,
                indexNumber: nil,
                parentIndexNumber: nil,
                communityRating: 8.5,
                officialRating: nil,
                runTimeTicks: nil,
                userData: nil,
                seriesName: nil,
                seriesId: nil,
                seasonId: nil,
                mediaStreams: nil
            ),
            jellyfinService: JellyfinService()
        )
    }
}
