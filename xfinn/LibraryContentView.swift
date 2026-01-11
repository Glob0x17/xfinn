//
//  LibraryContentView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

/// Vue du contenu d'une bibliothèque avec design Liquid Glass
struct LibraryContentView: View {
    let library: LibraryItem
    @ObservedObject var jellyfinService: JellyfinService
    
    @State private var items: [MediaItem] = []
    @State private var isLoading = true
    
    init(library: LibraryItem, jellyfinService: JellyfinService) {
        self.library = library
        self.jellyfinService = jellyfinService
        #if DEBUG
        print("🔵 LibraryContentView INIT for: \(library.name) [ID: \(library.id)]")
        #endif
    }

    var body: some View {
        #if DEBUG
        let _ = print("🎨 LibraryContentView body evaluated - isLoading: \(isLoading), items count: \(items.count)")
        #endif

        return ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if items.isEmpty {
                emptyStateView
            } else {
                contentGrid
            }
        }
        .navigationTitle(library.name)
        .task {
            // Charger à chaque fois (task se relance quand la vue change grâce à .id())
            #if DEBUG
            print("📡 Task started for: \(library.name) [ID: \(library.id)]")
            #endif
            await loadContent()
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
            
            Text("library.loading_content".localized)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "film.stack")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.appTextTertiary)
            
            VStack(spacing: 12) {
                Text("library.no_content".localized)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("library.empty_message".localized)
                    .font(.system(size: 22))
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
    
    // MARK: - Content Grid
    
    private var contentGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // En-tête
                VStack(alignment: .leading, spacing: 10) {
                    Text(library.name)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    
                    Text("library.items_count".localized(with: items.count))
                        .font(.system(size: 24))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
                
                // Grille de médias
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 350, maximum: 450), spacing: 30)
                    ],
                    spacing: 30
                ) {
                    ForEach(items) { item in
                        NavigationLink {
                            // Choisir la bonne vue selon le type
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
                                accentColor: accentColorForType
                            )
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 60)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var accentColorForType: Color {
        switch library.collectionType?.lowercased() {
        case "movies":
            return .appPrimary
        case "tvshows":
            return .appAccent
        case "music":
            return .appSecondary
        case "photos":
            return .appTertiary
        default:
            return .appPrimary
        }
    }
    
    // MARK: - Load Content
    
    @MainActor
    private func loadContent() async {
        isLoading = true

        #if DEBUG
        print("📡 Fetching items for: \(library.name) [ID: \(library.id)]")
        #endif
        do {
            let loadedItems = try await jellyfinService.getItems(parentId: library.id)
            #if DEBUG
            print("✅ Loaded \(loadedItems.count) items for: \(library.name)")
            #endif

            withAnimation(AppTheme.standardAnimation) {
                self.items = loadedItems
                self.isLoading = false
            }
        } catch {
            #if DEBUG
            print("❌ Error loading content for \(library.name): \(error)")
            print("   ℹ️ Details: \(error.localizedDescription)")
            #endif
            self.isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        LibraryContentView(
            library: LibraryItem(
                id: "1",
                name: "Films",
                collectionType: "movies",
                imageUrl: nil
            ),
            jellyfinService: JellyfinService()
        )
    }
}
