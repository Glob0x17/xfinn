//
//  SearchView.swift
//  xfinn
//
//  Created by Dorian Galiana on 22/12/2024.
//

import SwiftUI

/// Vue de recherche moderne avec design Liquid Glass
struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    @ObservedObject var jellyfinService: JellyfinService
    @Environment(\.dismiss) private var dismiss
    @State private var showMusicPlayer = false
    
    private enum SearchUIState: Equatable {
        case searching
        case empty
        case noResults
        case results
    }

    private var currentUIState: SearchUIState {
        if viewModel.isSearching { return .searching }
        if viewModel.isSearchEmpty { return .empty }
        if viewModel.hasNoResults { return .noResults }
        return .results
    }

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._viewModel = StateObject(wrappedValue: SearchViewModel(jellyfinService: jellyfinService))
    }
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header avec barre de recherche
                searchHeader
                    .padding(.top, AppTheme.sp(40))
                    .padding(.horizontal, AppTheme.sp(60))
                
                // Filtres
                filterBar
                    .padding(.top, AppTheme.sp(30))
                    .padding(.horizontal, AppTheme.sp(60))
                
                // Résultats
                Group {
                    if viewModel.isSearching {
                        loadingView
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorStateView(message: errorMessage) {
                            Task { await viewModel.performSearch() }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else if viewModel.isSearchEmpty {
                        emptyStateView
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else if viewModel.hasNoResults {
                        noResultsView
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        resultsGrid
                            .transition(.opacity)
                    }
                }
                .animation(AppTheme.standardAnimation, value: currentUIState)
            }
        }
        .fullScreenCover(isPresented: $showMusicPlayer) {
            MusicPlayerView(
                playerManager: jellyfinService.playerManager,
                jellyfinService: jellyfinService
            )
        }
    }

    // MARK: - Search Header
    
    private var searchHeader: some View {
        HStack(spacing: 20) {
            // Bouton retour
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: AppTheme.fs(30), weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .frame(width: AppTheme.dm(60), height: AppTheme.dm(60))
                    .background(
                        Circle()
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                            )
                    )
            }
            .buttonStyle(CustomCardButtonStyle(cornerRadius: 30))
            
            // Barre de recherche
            HStack(spacing: 15) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppTheme.fs(24)))
                    .foregroundColor(.appTextSecondary)

                TextField("search.placeholder".localized, text: $viewModel.searchQuery)
                    .font(.system(size: AppTheme.fs(26), weight: .medium))
                    .foregroundColor(.appTextPrimary)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit {
                        Task {
                            await viewModel.performSearch()
                        }
                    }

                if !viewModel.isSearchEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: AppTheme.fs(22)))
                            .foregroundColor(.appTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.sp(25))
            .padding(.vertical, AppTheme.sp(20))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                    )
            )
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        filter: filter,
                        isSelected: viewModel.selectedFilter == filter,
                        action: {
                            viewModel.updateFilter(filter)
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.secondary.opacity(0.24),
                                AppTheme.tertiary.opacity(0.14),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: AppTheme.dm(200), height: AppTheme.dm(200))
                    .blur(radius: 30)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppTheme.fs(80), weight: .light))
                    .foregroundColor(.appSecondary)
            }

            VStack(spacing: 12) {
                Text("search.empty_title".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("search.empty_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            Spacer()

            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.system(size: AppTheme.fs(80), weight: .light))
                .foregroundColor(.appTextTertiary)

            VStack(spacing: 12) {
                Text("search.no_results".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("search.no_results_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            Spacer()
            
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
                    .tint(.appSecondary)
            }
            .glowing(color: .appSecondary, radius: 25)
            
            Text("search.searching".localized)
                .font(.system(size: AppTheme.fs(24), weight: .medium))
                .foregroundColor(.appTextSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Results Grid
    
    private var resultsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: AppTheme.dm(350), maximum: AppTheme.dm(450)), spacing: AppTheme.sp(30))
                ],
                spacing: AppTheme.sp(40)
            ) {
                ForEach(viewModel.filteredResults) { item in
                    if item.type == "Audio" {
                        // Pour les pistes audio, on joue directement
                        Button {
                            playTrack(item)
                        } label: {
                            SearchResultCard(
                                item: item,
                                jellyfinService: jellyfinService
                            )
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                    } else {
                        NavigationLink(value: item) {
                            SearchResultCard(
                                item: item,
                                jellyfinService: jellyfinService
                            )
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                    }
                }
            }
            .padding(AppTheme.sp(60))
            .padding(.top, 20)
        }
        #if os(tvOS)
        .scrollClipDisabled()
        #endif
        .contentMargins(.top, 20, for: .scrollContent)
    }
    
}

// MARK: - Filter Pill

struct FilterPill: View {
    let filter: SearchFilter
    let isSelected: Bool
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: filter.icon)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(filter.displayName)
                    .font(.system(size: AppTheme.fs(20), weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .appTextSecondary)
            .padding(.horizontal, AppTheme.sp(25))
            .padding(.vertical, 15)
            .background(
                    RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AppTheme.secondary.opacity(0.75) : AppTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? AppTheme.tertiary : AppTheme.glassStroke,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let item: MediaItem
    let jellyfinService: JellyfinService
    
    var body: some View {
        HStack(spacing: 20) {
            // Poster
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: item.id, imageType: "Primary"))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Image(systemName: "film")
                            .font(.system(size: AppTheme.fs(40)))
                            .foregroundColor(.appTextTertiary)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(width: AppTheme.dm(120), height: AppTheme.dm(180))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Informations
            VStack(alignment: .leading, spacing: 12) {
                // Type badge
                HStack(spacing: 8) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 14))
                    Text(item.type)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.appSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.secondary.opacity(0.2))
                )
                
                // Titre
                Text(item.displayTitle)
                    .font(.system(size: AppTheme.fs(24), weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Métadonnées (sur une seule ligne avec largeur suffisante)
                HStack(spacing: 15) {
                    if let year = item.productionYear {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                            Text(String(year))
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.appTextSecondary)
                    }
                    
                    if let rating = item.communityRating {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: AppTheme.fs(24)))
                .foregroundColor(.appTextTertiary)
                .padding(.trailing, 10)
        }
        .padding(AppTheme.sp(20))
        .frame(minHeight: AppTheme.dm(220)) // Hauteur minimale pour éviter la compression
        .background(AppTheme.glassBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }
    
    private var typeIcon: String {
        switch item.type {
        case "Movie": return "film"
        case "Series": return "tv"
        case "Episode": return "list.bullet"
        case "MusicAlbum": return "music.note.list"
        case "MusicArtist": return "music.mic"
        case "Audio": return "music.note"
        default: return "square.stack"
        }
    }
}

// MARK: - SearchView Extension (Music Playback)

extension SearchView {
    /// Joue une piste audio directement depuis la recherche
    private func playTrack(_ track: MediaItem) {
        Task {
            await jellyfinService.playerManager.startPlayback(
                item: track,
                quality: jellyfinService.preferredQuality,
                resumePosition: nil,
                subtitleIndex: nil,
                jellyfinService: jellyfinService,
                mode: .audio,
                playlist: [track],
                playlistIndex: 0
            )

            await MainActor.run {
                showMusicPlayer = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(jellyfinService: JellyfinService())
    }
}
