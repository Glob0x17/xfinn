//
//  MusicLibraryView.swift
//  xfinn
//
//  Created by Dorian Galiana.
//

import SwiftUI

/// Vue principale de bibliothèque musicale - affiche la grille des artistes
struct MusicLibraryView: View {
    let library: LibraryItem?
    @ObservedObject var jellyfinService: JellyfinService

    @State private var artists: [MediaItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var musicLibrary: LibraryItem?

    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            if isLoading {
                loadingView
            } else if artists.isEmpty {
                emptyStateView
            } else {
                artistsGrid
            }
        }
        .navigationTitle(library?.name ?? musicLibrary?.name ?? "music.library_title".localized)
        .alert("common.error".localized, isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("common.retry".localized) {
                Task {
                    await loadArtists()
                }
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            if !hasLoaded {
                Task {
                    // Si aucune bibliothèque n'est fournie, récupérer la bibliothèque musicale
                    if library == nil && musicLibrary == nil {
                        await loadMusicLibrary()
                    }
                    await loadArtists()
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppTheme.sp(30)) {
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

            Text("music.loading_artists".localized)
                .font(.system(size: AppTheme.fs(24), weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.secondary.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: AppTheme.dm(200), height: AppTheme.dm(200))
                    .blur(radius: 30)

                Image(systemName: "music.note.list")
                    .font(.system(size: AppTheme.fs(80), weight: .light))
                    .foregroundColor(.appSecondary)
            }

            VStack(spacing: 12) {
                Text("music.no_artists".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("music.no_artists_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Artists Grid

    #if os(tvOS)
    private static let artistColumns = [
        GridItem(.flexible(minimum: 300, maximum: 400), spacing: AppTheme.sp(40)),
        GridItem(.flexible(minimum: 300, maximum: 400), spacing: AppTheme.sp(40)),
        GridItem(.flexible(minimum: 300, maximum: 400), spacing: AppTheme.sp(40))
    ]
    #else
    private static let artistColumns = AppTheme.adaptiveColumns(phone: 140, pad: 200, spacing: 16)
    #endif

    private var artistsGrid: some View {
        GeometryReader { geo in
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: AppTheme.sp(40)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "music.mic")
                            .font(.system(size: AppTheme.fs(48)))
                            .foregroundColor(.appSecondary)
                        Text("music.all_artists".localized)
                            .font(.system(size: AppTheme.fs(56), weight: .bold))
                            .foregroundColor(.appTextPrimary)
                    }
                    Text("music.artists_available".localized(with: artists.count))
                        .font(.system(size: AppTheme.fs(28)))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.top, 16)

                LazyVGrid(columns: Self.artistColumns, spacing: AppTheme.sp(50)) {
                    ForEach(artists) { artist in
                        NavigationLink(value: artist) {
                            ArtistCard(artist: artist, jellyfinService: jellyfinService)
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.bottom, AppTheme.sp(60))
            }
            .frame(width: geo.size.width, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.top, 16)
        }
        #if os(tvOS)
        .scrollClipDisabled()
        #endif
        .contentMargins(.top, 20, for: .scrollContent)
        }
    }

    // MARK: - Load Artists

    @MainActor
    private func loadMusicLibrary() async {
        do {
            let libraries = try await jellyfinService.getLibraries()
            musicLibrary = libraries.first(where: { $0.collectionType == "music" })
        } catch {
            // Erreur silencieuse - sera gérée par loadArtists
        }
    }

    @MainActor
    private func loadArtists() async {
        guard !hasLoaded else {
            return
        }

        hasLoaded = true
        isLoading = true
        errorMessage = nil
        showError = false

        // Utiliser la bibliothèque fournie ou celle récupérée
        guard let libraryId = library?.id ?? musicLibrary?.id else {
            withAnimation(AppTheme.standardAnimation) {
                self.hasLoaded = false
                self.isLoading = false
                self.errorMessage = "music.no_library_found".localized
                self.showError = true
            }
            return
        }

        do {
            let loadedArtists = try await jellyfinService.getMusicArtists(parentId: libraryId)

            withAnimation(AppTheme.standardAnimation) {
                self.artists = loadedArtists
                self.isLoading = false
            }
        } catch {
            withAnimation(AppTheme.standardAnimation) {
                self.hasLoaded = false
                self.isLoading = false
                self.errorMessage = "\("music.load_artists_error".localized)\n\(error.localizedDescription)"
                self.showError = true
            }
        }
    }
}

// MARK: - Artist Card

/// Carte d'artiste avec design Liquid Glass
struct ArtistCard: View {
    let artist: MediaItem
    let jellyfinService: JellyfinService

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Image circulaire de l'artiste
            ZStack {
                // Background gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.secondary.opacity(0.6),
                                AppTheme.tertiary.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Image de l'artiste
                AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: artist.id))) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Circle()
                                .fill(AppTheme.glassBackground)
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.appSecondary)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                    case .failure:
                        ZStack {
                            Circle()
                                .fill(AppTheme.glassBackground)
                            Image(systemName: "music.mic")
                                .font(.system(size: AppTheme.fs(60)))
                                .foregroundStyle(Color.appTextTertiary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            #if os(tvOS)
            .frame(width: AppTheme.dm(280), height: AppTheme.dm(280))
            #else
            // Cercle à la largeur de la colonne (taille fixe : débordait et
            // collait les cartes entre elles sur iPad)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(Circle())
            .padding(.horizontal, 14)
            #endif
            .overlay(
                Circle()
                    .stroke(AppTheme.glassStroke, lineWidth: 2)
                    #if !os(tvOS)
                    .padding(.horizontal, 14)
                    #endif
            )
            .padding(.top, 20)

            // Nom de l'artiste
            VStack(spacing: 8) {
                Text(artist.name)
                    .font(.system(size: AppTheme.fs(28), weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)

                // Badge "Artiste"
                HStack(spacing: 8) {
                    Image(systemName: "music.mic")
                        .font(.system(size: 16))
                    Text("music.artist".localized)
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundColor(.appSecondary)
            }
            .padding(.top, 20)
            .padding(.horizontal, 15)
            .padding(.bottom, 20)
        }
        #if os(tvOS)
        .frame(width: AppTheme.dm(320), height: AppTheme.dm(380))
        #else
        .frame(maxWidth: .infinity)
        #endif
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }
}

#Preview {
    NavigationStack {
        MusicLibraryView(
            library: LibraryItem(
                id: "test",
                name: "Musique",
                collectionType: "music",
                imageUrl: nil
            ),
            jellyfinService: JellyfinService()
        )
    }
}
