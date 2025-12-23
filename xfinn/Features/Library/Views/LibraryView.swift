//
//  LibraryView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

/// Vue des bibliothèques avec design Liquid Glass moderne
struct LibraryView: View {
    @ObservedObject var jellyfinService: JellyfinService
    @State private var libraries: [LibraryItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    @State private var selectedLibrary: LibraryItem?
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if libraries.isEmpty {
                emptyStateView
            } else {
                librariesGrid
            }
        }
        .navigationTitle("Mes Bibliothèques")
        .toolbar {
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
            }
        }
        .onAppear {
            if !hasLoaded {
                Task {
                    await loadLibraries()
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
            
            Text("Chargement des bibliothèques...")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.error.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.appError)
            }
            
            VStack(spacing: 12) {
                Text("Aucune bibliothèque")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                
                Text("Aucune bibliothèque n'est disponible\nsur ce serveur")
                    .font(.system(size: 22))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Libraries Grid
    
    private var librariesGrid: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 40) {
                // En-tête
                VStack(alignment: .leading, spacing: 10) {
                    Text("Toutes vos bibliothèques")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    
                    Text("\(libraries.count) bibliothèque\(libraries.count > 1 ? "s" : "") disponible\(libraries.count > 1 ? "s" : "")")
                        .font(.system(size: 24))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
                
                // Grille de bibliothèques avec espacement vertical explicite
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 400, maximum: 600), spacing: 40),
                        GridItem(.flexible(minimum: 400, maximum: 600), spacing: 40)
                    ],
                    spacing: 50 // Espacement vertical entre les rangées
                ) {
                    ForEach(libraries) { library in
                        NavigationLink {
                            LibraryContentView(library: library, jellyfinService: jellyfinService)
                                .id(library.id) // Force le rafraîchissement
                        } label: {
                            LibraryCard(library: library, jellyfinService: jellyfinService)
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 80) // Plus d'espace en bas
            }
        }
    }
    
    // MARK: - Load Libraries
    
    @MainActor
    private func loadLibraries() async {
        guard !hasLoaded else {
            return
        }
        
        print("📚 [LibraryView] Début du chargement des bibliothèques")
        hasLoaded = true
        isLoading = true
        
        do {
            let loadedLibraries = try await jellyfinService.getLibraries()
            
            withAnimation(AppTheme.standardAnimation) {
                self.libraries = loadedLibraries
                self.isLoading = false
            }
        } catch {
            self.hasLoaded = false
            self.isLoading = false
        }
    }
}

// MARK: - Library Card

struct LibraryCard: View {
    let library: LibraryItem
    let jellyfinService: JellyfinService
    
    @Environment(\.isFocused) private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image de la bibliothèque avec glass overlay
            ZStack(alignment: .bottomLeading) {
                // Background avec gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Image si disponible
                if let imageUrl = library.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            libraryIcon
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    libraryIcon
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
                .frame(height: 120)
                .frame(maxHeight: .infinity, alignment: .bottom)
                
                // Badge type
                HStack {
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                    Text(typeDisplayName)
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppTheme.glassBackground)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(20)
            }
            .frame(height: 300)
            .clipped()
            
            // Informations avec glass background
            VStack(alignment: .leading, spacing: 12) {
                Text(library.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.appTextSecondary)
                    
                    Text("Bibliothèque \(typeDisplayName)")
                        .font(.system(size: 18))
                        .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20))
                        .foregroundColor(.appTextTertiary)
                }
            }
            .padding(20)
            .frame(height: 100) // Hauteur fixe pour les infos
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(AppTheme.glassBackground)
            )
        }
        .frame(height: 400) // Hauteur totale fixe (300 + 100)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }
    
    private var libraryIcon: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
            
            Text(library.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var iconName: String {
        switch library.collectionType?.lowercased() {
        case "movies":
            return "film"
        case "tvshows":
            return "tv"
        case "music":
            return "music.note"
        case "photos":
            return "photo"
        default:
            return "folder.fill"
        }
    }
    
    private var typeDisplayName: String {
        switch library.collectionType?.lowercased() {
        case "movies":
            return "Films"
        case "tvshows":
            return "Séries"
        case "music":
            return "Musique"
        case "photos":
            return "Photos"
        default:
            return "Médias"
        }
    }
    
    private var accentColor: Color {
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
    
    private var gradientColors: [Color] {
        switch library.collectionType?.lowercased() {
        case "movies":
            return [AppTheme.primary.opacity(0.6), AppTheme.accent.opacity(0.6)]
        case "tvshows":
            return [AppTheme.accent.opacity(0.6), AppTheme.secondary.opacity(0.6)]
        case "music":
            return [AppTheme.secondary.opacity(0.6), AppTheme.tertiary.opacity(0.6)]
        case "photos":
            return [AppTheme.tertiary.opacity(0.6), AppTheme.primary.opacity(0.6)]
        default:
            return [AppTheme.primary.opacity(0.6), AppTheme.accent.opacity(0.6)]
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView(jellyfinService: JellyfinService())
    }
}
