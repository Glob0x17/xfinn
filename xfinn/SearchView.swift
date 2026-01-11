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
                    .padding(.top, 40)
                    .padding(.horizontal, 60)
                
                // Filtres
                filterBar
                    .padding(.top, 30)
                    .padding(.horizontal, 60)
                
                // Résultats
                if viewModel.isSearching {
                    loadingView
                } else if viewModel.isSearchEmpty {
                    emptyStateView
                } else if viewModel.hasNoResults {
                    noResultsView
                } else {
                    resultsGrid
                }
            }
        }
    }
    
    // MARK: - Search Header
    
    private var searchHeader: some View {
        HStack(spacing: 20) {
            // Bouton retour
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 60, height: 60)
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
                    .font(.system(size: 24))
                    .foregroundColor(.appTextSecondary)
                
                TextField("search.placeholder".localized, text: $viewModel.searchQuery)
                    .font(.system(size: 26, weight: .medium))
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
                            .font(.system(size: 22))
                            .foregroundColor(.appTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
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
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.appPrimary)
            }
            
            VStack(spacing: 12) {
                Text("search.empty_title".localized)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("search.empty_message".localized)
                    .font(.system(size: 22))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.appTextTertiary)
            
            VStack(spacing: 12) {
                Text("search.no_results".localized)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("search.no_results_message".localized)
                    .font(.system(size: 22))
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 30) {
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
                    .tint(.appPrimary)
            }
            .glowing(color: .appPrimary, radius: 25)
            
            Text("search.searching".localized)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.appTextSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Results Grid
    
    private var resultsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 350, maximum: 450), spacing: 30)
                ],
                spacing: 30
            ) {
                ForEach(viewModel.filteredResults) { item in
                    NavigationLink {
                        if item.type == "Series" {
                            SeriesDetailView(series: item, jellyfinService: jellyfinService)
                        } else if item.type == "Season" {
                            SeasonEpisodesView(season: item, jellyfinService: jellyfinService)
                        } else {
                            MediaDetailView(item: item, jellyfinService: jellyfinService)
                        }
                    } label: {
                        SearchResultCard(
                            item: item,
                            jellyfinService: jellyfinService
                        )
                    }
                    .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                }
            }
            .padding(60)
        }
    }
    
}

// MARK: - Filter Pill

struct FilterPill: View {
    let filter: SearchFilter
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: filter.icon)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(filter.displayName)
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .appTextSecondary)
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AppTheme.primary : AppTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? AppTheme.accent : AppTheme.glassStroke,
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
                            .font(.system(size: 40))
                            .foregroundColor(.appTextTertiary)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(width: 120, height: 180)
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
                .foregroundColor(.appPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.primary.opacity(0.2))
                )
                
                // Titre
                Text(item.displayTitle)
                    .font(.system(size: 24, weight: .bold))
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
                .font(.system(size: 24))
                .foregroundColor(.appTextTertiary)
                .padding(.trailing, 10)
        }
        .padding(20)
        .frame(minHeight: 220) // Hauteur minimale pour éviter la compression
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
        default: return "square.stack"
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(jellyfinService: JellyfinService())
    }
}
