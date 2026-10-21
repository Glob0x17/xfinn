//
//  ArtistDetailView.swift
//  xfinn
//
//  Created by Dorian Galiana.
//

import SwiftUI

/// Vue détaillée d'un artiste avec ses albums
struct ArtistDetailView: View {
    let artist: MediaItem
    @ObservedObject var jellyfinService: JellyfinService

    @State private var albums: [MediaItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            if isLoading {
                loadingView
            } else if albums.isEmpty {
                emptyStateView
            } else {
                albumsContent
            }
        }
        .navigationTitle(artist.name)
        .alert("common.error".localized, isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("common.retry".localized) {
                Task {
                    await loadAlbums()
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
                    await loadAlbums()
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

            Text("music.loading_albums".localized)
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

                Image(systemName: "opticaldisc")
                    .font(.system(size: AppTheme.fs(80), weight: .light))
                    .foregroundColor(.appSecondary)
            }

            VStack(spacing: 12) {
                Text("music.no_albums".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("music.no_albums_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Albums Content

    #if os(tvOS)
    private static let albumColumns = [
        GridItem(.flexible(minimum: 350, maximum: 450), spacing: AppTheme.sp(40)),
        GridItem(.flexible(minimum: 350, maximum: 450), spacing: AppTheme.sp(40)),
        GridItem(.flexible(minimum: 350, maximum: 450), spacing: AppTheme.sp(40))
    ]
    #else
    private static let albumColumns = AppTheme.adaptiveColumns(phone: 140, pad: 200, spacing: 16)
    #endif

    private var albumsContent: some View {
        GeometryReader { geo in
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: AppTheme.sp(40)) {
                artistHeader

                LazyVGrid(columns: Self.albumColumns, spacing: AppTheme.sp(50)) {
                    ForEach(albums) { album in
                        NavigationLink(value: album) {
                            AlbumCard(album: album, jellyfinService: jellyfinService)
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

    // MARK: - Artist Header

    private var artistHeader: some View {
        HStack(spacing: AppTheme.sp(30)) {
            // Avatar de l'artiste
            AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: artist.id))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: AppTheme.dm(180), height: AppTheme.dm(180))
                        .clipShape(Circle())
                case .failure, .empty:
                    ZStack {
                        Circle()
                            .fill(AppTheme.glassBackground)
                            .frame(width: AppTheme.dm(180), height: AppTheme.dm(180))
                        Image(systemName: "music.mic")
                            .font(.system(size: AppTheme.fs(70)))
                            .foregroundColor(.appTextTertiary)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .overlay(
                Circle()
                    .stroke(AppTheme.glassStroke, lineWidth: 2)
            )
            .glowing(color: .appSecondary, radius: 20)

            // Informations artiste
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 12) {
                    Image(systemName: "music.mic")
                        .font(.system(size: AppTheme.fs(28)))
                        .foregroundColor(.appSecondary)
                    Text("music.artist".localized.uppercased())
                        .font(.system(size: AppTheme.fs(24), weight: .bold))
                        .foregroundColor(.appSecondary)
                }

                Text(artist.name)
                    .font(.system(size: AppTheme.fs(56), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                HStack(spacing: 20) {
                    // Nombre d'albums
                    HStack(spacing: 8) {
                        Image(systemName: "opticaldisc")
                            .font(.system(size: AppTheme.fs(20)))
                        Text("music.albums_count".localized(with: albums.count))
                            .font(.system(size: AppTheme.fs(24), weight: .medium))
                    }
                    .foregroundColor(.appTextSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.sp(60))
    }

    // MARK: - Load Albums

    @MainActor
    private func loadAlbums() async {
        guard !hasLoaded else {
            return
        }

        hasLoaded = true
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let loadedAlbums = try await jellyfinService.getArtistAlbums(artistId: artist.id)

            withAnimation(AppTheme.standardAnimation) {
                self.albums = loadedAlbums
                self.isLoading = false
            }
        } catch {
            withAnimation(AppTheme.standardAnimation) {
                self.hasLoaded = false
                self.isLoading = false
                self.errorMessage = "\("music.load_albums_error".localized)\n\(error.localizedDescription)"
                self.showError = true
            }
        }
    }
}

// MARK: - Album Card

/// Carte d'album avec design Liquid Glass
struct AlbumCard: View {
    let album: MediaItem
    let jellyfinService: JellyfinService

    /// tvOS : hauteur fixe ; iOS : carré à la largeur de la colonne
    @ViewBuilder
    private var albumArtFrame: some View {
        #if os(tvOS)
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.dm(380))
        #else
        Color.clear
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pochette d'album. Le cadre est fixé par la colonne et l'image posée
            // en overlay : en .fill dans la pile, elle imposait sa largeur
            // naturelle et débordait (coupée à gauche sur iPad)
            albumArtFrame
            .overlay {
            ZStack(alignment: .bottomLeading) {
                // Background gradient
                Rectangle()
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

                // Image de l'album
                AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: album.id))) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.appSecondary)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.2)
                            VStack(spacing: 10) {
                                Image(systemName: "opticaldisc")
                                    .font(.system(size: AppTheme.fs(60)))
                                    .foregroundStyle(Color.appTextTertiary)
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
                .frame(height: 100)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            }
            .clipped()

            // Informations album
            VStack(alignment: .leading, spacing: 10) {
                Text(album.name)
                    .font(.system(size: AppTheme.fs(24), weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 15) {
                    // Année
                    if let year = album.productionYear {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                            Text(String(year))
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundStyle(Color.appTextSecondary)
                    }

                    Spacer()

                    // Icône lecture
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: AppTheme.fs(26)))
                        .foregroundColor(.appSecondary)
                }
            }
            .padding(20)
            .frame(height: 100)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(AppTheme.glassBackground)
            )
        }
        .frame(height: AppTheme.dm(480))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }
}

#Preview {
    NavigationStack {
        ArtistDetailView(
            artist: MediaItem(
                id: "test",
                name: "Test Artist",
                type: "MusicArtist"
            ),
            jellyfinService: JellyfinService()
        )
    }
}
