//
//  AlbumDetailView.swift
//  xfinn
//
//  Created by Dorian Galiana.
//

import SwiftUI

/// Vue détaillée d'un album avec ses pistes
struct AlbumDetailView: View {
    let album: MediaItem
    @ObservedObject var jellyfinService: JellyfinService

    @State private var tracks: [MediaItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showMusicPlayer = false
    @FocusState private var focusedTrackId: String?

    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            if isLoading {
                loadingView
            } else if tracks.isEmpty {
                emptyStateView
            } else {
                albumContent
            }
        }
        .navigationTitle(album.name)
        .fullScreenCover(isPresented: $showMusicPlayer) {
            MusicPlayerView(
                playerManager: jellyfinService.playerManager,
                jellyfinService: jellyfinService
            )
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("common.retry".localized) {
                Task {
                    await loadTracks()
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
                    await loadTracks()
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

            Text("music.loading_tracks".localized)
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

                Image(systemName: "music.note")
                    .font(.system(size: AppTheme.fs(80), weight: .light))
                    .foregroundColor(.appSecondary)
            }

            VStack(spacing: 12) {
                Text("music.no_tracks".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("music.no_tracks_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Album Content

    private var albumContent: some View {
        GeometryReader { geo in
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: AppTheme.sp(40)) {
                albumHeader

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: AppTheme.fs(32)))
                            .foregroundColor(.appSecondary)
                        Text("music.tracks".localized)
                            .font(.system(size: AppTheme.fs(42), weight: .bold))
                            .foregroundColor(.appTextPrimary)
                    }
                    .padding(.horizontal, AppTheme.screenPadding)

                    VStack(spacing: 8) {
                        ForEach(tracks) { track in
                            TrackRow(
                                track: track,
                                onPlay: {
                                    playTrack(track)
                                }
                            )
                            .focused($focusedTrackId, equals: track.id)
                        }
                    }
                    .padding(.horizontal, AppTheme.screenPadding)
                    #if os(tvOS)
                    .focusEffectDisabled()
                    #endif
                }
                .padding(.bottom, AppTheme.sp(60))
            }
            .frame(width: geo.size.width, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.top, 16)
        }
        .contentMargins(.top, 20, for: .scrollContent)
        }
    }

    // MARK: - Album Header

    /// iPhone (largeur compacte) : pochette au-dessus des informations, sinon titre et métadonnées
    /// sont écrasés à côté de la pochette
    private var isCompactWidth: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    private var albumHeader: some View {
        let layout = isCompactWidth
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppTheme.sp(40)))
            : AnyLayout(HStackLayout(spacing: AppTheme.sp(40)))
        return layout {
            // Pochette de l'album
            ZStack {
                AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: album.id))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: AppTheme.dm(350), height: AppTheme.dm(350))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    case .failure, .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.glassBackground)
                                .frame(width: AppTheme.dm(350), height: AppTheme.dm(350))
                            Image(systemName: "opticaldisc")
                                .font(.system(size: AppTheme.fs(100)))
                                .foregroundColor(.appTextTertiary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.glassStroke, lineWidth: 2)
                )
                .glowing(color: .appSecondary, radius: 20)
            }

            // Informations album
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "opticaldisc")
                        .font(.system(size: AppTheme.fs(28)))
                        .foregroundColor(.appSecondary)
                    Text("music.album".localized.uppercased())
                        .font(.system(size: AppTheme.fs(24), weight: .bold))
                        .foregroundColor(.appSecondary)
                }

                Text(album.name)
                    .font(.system(size: AppTheme.fs(56), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                // Artiste
                if let artist = album.primaryArtist {
                    HStack(spacing: 10) {
                        Image(systemName: "music.mic")
                            .font(.system(size: AppTheme.fs(20)))
                        Text(artist)
                            .font(.system(size: AppTheme.fs(28), weight: .medium))
                    }
                    .foregroundColor(.appTextSecondary)
                }

                HStack(spacing: AppTheme.sp(30)) {
                    // Année
                    if let year = album.productionYear {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: AppTheme.fs(20)))
                            Text(String(year))
                                .font(.system(size: AppTheme.fs(24), weight: .medium))
                        }
                        .foregroundColor(.appTextSecondary)
                    }

                    // Nombre de pistes
                    HStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .font(.system(size: AppTheme.fs(20)))
                        Text("music.tracks_count".localized(with: tracks.count))
                            .font(.system(size: AppTheme.fs(24), weight: .medium))
                            .fixedSize()
                    }
                    .foregroundColor(.appTextSecondary)

                    // Durée totale
                    if let totalDuration = calculateTotalDuration() {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: AppTheme.fs(20)))
                            Text(totalDuration)
                                .font(.system(size: AppTheme.fs(24), weight: .medium))
                        }
                        .foregroundColor(.appTextSecondary)
                    }
                }

                if !isCompactWidth {
                    Spacer()
                }

                // Bouton "Tout lire"
                Button {
                    playAllTracks()
                } label: {
                    HStack(spacing: 15) {
                        Image(systemName: "play.fill")
                            .font(.system(size: AppTheme.fs(26)))
                        Text("music.play_all".localized)
                            .font(.system(size: AppTheme.fs(28), weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.sp(40))
                    .padding(.vertical, 20)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppTheme.secondary,
                                        AppTheme.tertiary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(CustomCardButtonStyle(cornerRadius: 40))
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.sp(60))
    }

    // MARK: - Load Tracks

    @MainActor
    private func loadTracks() async {
        guard !hasLoaded else {
            return
        }

        hasLoaded = true
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let loadedTracks = try await jellyfinService.getAlbumTracks(albumId: album.id)

            withAnimation(AppTheme.standardAnimation) {
                self.tracks = loadedTracks.sorted { ($0.indexNumber ?? 0) < ($1.indexNumber ?? 0) }
                self.isLoading = false
            }
        } catch {
            withAnimation(AppTheme.standardAnimation) {
                self.hasLoaded = false
                self.isLoading = false
                self.errorMessage = "\("music.load_tracks_error".localized)\n\(error.localizedDescription)"
                self.showError = true
            }
        }
    }

    // MARK: - Helper Methods

    private func calculateTotalDuration() -> String? {
        let totalTicks = tracks.compactMap { $0.runTimeTicks }.reduce(0, +)
        guard totalTicks > 0 else { return nil }

        let totalMinutes = Int(Double(totalTicks) / 600000000.0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func playTrack(_ track: MediaItem) {
        guard let trackIndex = tracks.firstIndex(where: { $0.id == track.id }) else {
            return
        }

        Task {
            await jellyfinService.playerManager.startPlayback(
                item: track,
                quality: jellyfinService.preferredQuality,
                resumePosition: nil,
                subtitleIndex: nil,
                jellyfinService: jellyfinService,
                mode: .audio,
                playlist: tracks,
                playlistIndex: trackIndex
            )

            await MainActor.run {
                showMusicPlayer = true
            }
        }
    }

    private func playAllTracks() {
        // Jouer la première piste avec toute la playlist
        guard let firstTrack = tracks.first else { return }
        playTrack(firstTrack)
    }
}

// MARK: - Track Row

/// Ligne de piste dans la liste d'un album
struct TrackRow: View {
    let track: MediaItem
    let onPlay: () -> Void

    var body: some View {
        Button(action: onPlay) {
            // Le contenu vit dans une sous-vue : \.isFocused n'est renseigné
            // qu'à l'intérieur du label du Button focusable, pas au niveau
            // de TrackRow lui-même
            TrackRowContent(track: track)
        }
        .buttonStyle(CustomCardButtonStyle(cornerRadius: 15))
    }
}

private struct TrackRowContent: View {
    let track: MediaItem

    @Environment(\.isFocused) private var isFocused: Bool

    var body: some View {
        HStack(spacing: 20) {
                // Numéro de piste
                Text(track.formattedTrackNumber ?? "—")
                    .font(.system(size: AppTheme.fs(24), weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextSecondary)
                    .frame(width: 50, alignment: .trailing)

                // Titre
                Text(track.name)
                    .font(.system(size: AppTheme.fs(26), weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)

                Spacer()

                // Durée
                if let duration = track.formattedDuration {
                    Text(duration)
                        .font(.system(size: AppTheme.fs(24), weight: .medium, design: .monospaced))
                        .foregroundColor(.appTextSecondary)
                }

                // Icône lecture
                Image(systemName: "play.fill")
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appSecondary)
                    .opacity(isFocused ? 1.0 : 0.3)
        }
        .padding(.horizontal, AppTheme.sp(30))
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isFocused ? AppTheme.glassBackground : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    isFocused ? AppTheme.glassStroke : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

#Preview {
    NavigationStack {
        AlbumDetailView(
            album: MediaItem(
                id: "test",
                name: "Test Album",
                type: "MusicAlbum",
                productionYear: 2024
            ),
            jellyfinService: JellyfinService()
        )
    }
}
