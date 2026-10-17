//
//  MusicPlayerView.swift
//  xfinn
//
//  Created by Dorian Galiana.
//  Vue fullscreen de lecture musicale
//

import SwiftUI
import Combine
import AVFoundation

/// Vue fullscreen du player audio avec grande pochette et contrôles
struct MusicPlayerView: View {
    @ObservedObject var playerManager: PlayerManager
    let jellyfinService: JellyfinService
    @Environment(\.dismiss) private var dismiss

    @FocusState private var focusedControl: PlayerControl?

    enum PlayerControl: Hashable {
        case previous
        case playPause
        case next
        case stop
        case close
        case repeatMode
    }

    var currentTrack: MediaItem? {
        playerManager.currentItem
    }

    var body: some View {
        ZStack {
            // Background avec gradient
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            #if os(tvOS)
            let progressWidth: CGFloat = 1000
            let hPad: CGFloat = 100
            #else
            let progressWidth: CGFloat = 0
            let hPad: CGFloat = 24
            #endif

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 20)

                // Pochette de l'album
                albumArtwork

                Spacer()
                    .frame(height: 20)

                // Infos piste
                trackInfo

                Spacer()
                    .frame(height: 20)

                // Barre de progression
                progressBar
                    .frame(maxWidth: progressWidth > 0 ? progressWidth : .infinity)

                Spacer()
                    .frame(height: 24)

                // Contrôles
                playerControls

                Spacer()
                    .frame(height: 30)
            }
            .padding(.horizontal, hPad)
        }
        .onAppear {
            // Focus par défaut sur play/pause
            focusedControl = .playPause
        }
    }

    // MARK: - Album Artwork

    private var albumArtwork: some View {
        ZStack {
            if let track = currentTrack,
               let albumId = track.albumId {
                AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: albumId))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: Self.artworkSize, height: Self.artworkSize)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    case .failure, .empty:
                        placeholderArtwork
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                placeholderArtwork
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(AppTheme.glassStroke, lineWidth: 3)
        )
        .shadow(color: AppTheme.secondary.opacity(0.5), radius: 50, x: 0, y: 20)
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
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
                .frame(width: Self.artworkSize, height: Self.artworkSize)

            Image(systemName: "music.note")
                .font(.system(size: Self.artworkSize * 0.32))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Track Info

    #if os(tvOS)
    private static let trackTitleSize: CGFloat = 40
    private static let trackArtistSize: CGFloat = 28
    private static let trackAlbumSize: CGFloat = 22
    private static let controlBtnSize: CGFloat = 100
    private static let controlIconSize: CGFloat = 40
    private static let secondaryBtnSize: CGFloat = 70
    private static let secondaryIconSize: CGFloat = 28
    private static let controlSpacing: CGFloat = 60
    private static let secondarySpacing: CGFloat = 50
    static let artworkSize: CGFloat = 500
    static let playBtnSize: CGFloat = 140
    static let playIconSize: CGFloat = 60
    #else
    private static let trackTitleSize: CGFloat = 22
    private static let trackArtistSize: CGFloat = 16
    private static let trackAlbumSize: CGFloat = 14
    private static let controlBtnSize: CGFloat = 56
    private static let controlIconSize: CGFloat = 24
    private static let controlSpacing: CGFloat = 36
    private static let secondaryBtnSize: CGFloat = 44
    private static let secondaryIconSize: CGFloat = 18
    private static let secondarySpacing: CGFloat = 24
    static let artworkSize: CGFloat = 260
    static let playBtnSize: CGFloat = 72
    static let playIconSize: CGFloat = 32
    #endif

    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(currentTrack?.name ?? "Titre inconnu")
                .font(.system(size: Self.trackTitleSize, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(currentTrack?.primaryArtist ?? "Artiste inconnu")
                .font(.system(size: Self.trackArtistSize, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .lineLimit(1)

            if let album = currentTrack?.album {
                Text(album)
                    .font(.system(size: Self.trackAlbumSize))
                    .foregroundColor(.appTextTertiary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        ProgressBarView(playerManager: playerManager)
    }

    // MARK: - Player Controls

    private var playerControls: some View {
        VStack(spacing: 20) {
            HStack(spacing: Self.controlSpacing) {
                Button {
                    Task { await playerManager.playPrevious() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.glassBackground)
                            .frame(width: Self.controlBtnSize, height: Self.controlBtnSize)
                        Image(systemName: "backward.fill")
                            .font(.system(size: Self.controlIconSize))
                            .foregroundColor(playerManager.hasPrevious ? .appTextPrimary : .appTextSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(PlayerControlButtonStyle())
                .focused($focusedControl, equals: .previous)
                .disabled(!playerManager.hasPrevious)

                PlayPauseButton(playerManager: playerManager)
                    .focused($focusedControl, equals: .playPause)

                Button {
                    Task { await playerManager.playNext() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.glassBackground)
                            .frame(width: Self.controlBtnSize, height: Self.controlBtnSize)
                        Image(systemName: "forward.fill")
                            .font(.system(size: Self.controlIconSize))
                            .foregroundColor(playerManager.hasNext || playerManager.repeatMode == .all ? .appTextPrimary : .appTextSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(PlayerControlButtonStyle())
                .focused($focusedControl, equals: .next)
                .disabled(!playerManager.hasNext && playerManager.repeatMode != .all)
            }

            HStack(spacing: Self.secondarySpacing) {
                Button { cycleRepeatMode() } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(playerManager.repeatMode != .off ? AppTheme.glassBackground.opacity(0.8) : AppTheme.glassBackground)
                                .frame(width: Self.secondaryBtnSize, height: Self.secondaryBtnSize)
                            Image(systemName: repeatModeIcon)
                                .font(.system(size: Self.secondaryIconSize))
                                .foregroundColor(playerManager.repeatMode != .off ? .appSecondary : .appTextSecondary)
                        }
                        Text(repeatModeText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .buttonStyle(PlayerControlButtonStyle())
                .focused($focusedControl, equals: .repeatMode)

                Spacer()

                Button {
                    Task { await playerManager.stop(); dismiss() }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.glassBackground)
                                .frame(width: Self.secondaryBtnSize, height: Self.secondaryBtnSize)
                            Image(systemName: "stop.fill")
                                .font(.system(size: Self.secondaryIconSize))
                                .foregroundColor(.appError)
                        }
                        Text("music.player.stop".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .buttonStyle(PlayerControlButtonStyle())
                .focused($focusedControl, equals: .stop)

                Spacer()

                Button { dismiss() } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.glassBackground)
                                .frame(width: Self.secondaryBtnSize, height: Self.secondaryBtnSize)
                            Image(systemName: "xmark")
                                .font(.system(size: Self.secondaryIconSize))
                                .foregroundColor(.appTextSecondary)
                        }
                        Text("common.close".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .buttonStyle(PlayerControlButtonStyle())
                .focused($focusedControl, equals: .close)
            }
        }
    }

    private var repeatModeIcon: String {
        switch playerManager.repeatMode {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }

    private var repeatModeText: String {
        switch playerManager.repeatMode {
        case .off: return "music.repeat.off".localized
        case .one: return "music.repeat.one".localized
        case .all: return "music.repeat.all".localized
        }
    }

    private func cycleRepeatMode() {
        switch playerManager.repeatMode {
        case .off:
            playerManager.repeatMode = .all
        case .all:
            playerManager.repeatMode = .one
        case .one:
            playerManager.repeatMode = .off
        }
    }

    // MARK: - Helpers

}

// MARK: - Play Pause Button

/// Vue séparée pour le bouton play/pause qui se met à jour indépendamment
private struct PlayPauseButton: View {
    @ObservedObject var playerManager: PlayerManager

    var body: some View {
        Button {
            if playerManager.isPlaying {
                playerManager.pause()
            } else {
                playerManager.play()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.secondary, AppTheme.tertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: MusicPlayerView.playBtnSize, height: MusicPlayerView.playBtnSize)

                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: MusicPlayerView.playIconSize))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlayerControlButtonStyle(isMainButton: true))
    }
}

// MARK: - Progress Bar View

/// Vue séparée pour la barre de progression qui se met à jour indépendamment
private struct ProgressBarView: View {
    let playerManager: PlayerManager // PAS @ObservedObject pour éviter les re-renders
    @State private var displayTime: TimeInterval = 0
    @State private var displayProgress: Double = 0
    @State private var displayDuration: TimeInterval = 0
    @State private var timeObserverToken: Any?

    var body: some View {
        VStack(spacing: 15) {
            // Barre
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.secondary, AppTheme.tertiary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(displayProgress),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            // Temps
            HStack {
                Text(displayTime.formattedPlaybackTime)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextSecondary)

                Spacer()

                Text(displayDuration.formattedPlaybackTime)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .onAppear {
            setupTimeObserver()
        }
        .onDisappear {
            removeTimeObserver()
        }
    }

    private func setupTimeObserver() {
        guard let player = playerManager.player else { return }

        // Récupère la durée
        if let duration = player.currentItem?.duration, duration.isValid, !duration.seconds.isNaN, !duration.seconds.isInfinite {
            displayDuration = duration.seconds
        }

        // Observer le temps toutes les 0.5 secondes pour une progression fluide
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak playerManager] time in
            // Protection contre les valeurs invalides
            guard let playerManager = playerManager,
                  let currentDuration = playerManager.player?.currentItem?.duration,
                  currentDuration.isValid,
                  !time.seconds.isNaN,
                  !time.seconds.isInfinite else {
                return
            }

            // Mise à jour du temps en temps réel depuis l'AVPlayer
            displayTime = time.seconds.isFinite ? time.seconds : 0

            // Mise à jour de la durée si elle a changé
            if !currentDuration.seconds.isNaN && !currentDuration.seconds.isInfinite {
                displayDuration = currentDuration.seconds
            }

            // Calcul de la progression avec protection contre division par zéro
            if displayDuration > 0 && displayTime.isFinite && displayDuration.isFinite {
                displayProgress = min(max(displayTime / displayDuration, 0), 1.0)
            } else {
                displayProgress = 0
            }
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken, let player = playerManager.player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

}

// MARK: - Player Control Button Style

/// Style de bouton pour les contrôles du player fullscreen
struct PlayerControlButtonStyle: ButtonStyle {
    var isMainButton: Bool = false
    #if os(tvOS)
    @Environment(\.isFocused) private var isFocused: Bool
    #endif

    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
        configuration.label
            .scaleEffect(isFocused ? 1.15 : 1.0)
            .shadow(
                color: isFocused ? (isMainButton ? AppTheme.secondary.opacity(0.9) : AppTheme.primary.opacity(0.6)) : .clear,
                radius: isFocused ? 40 : 0
            )
            .shadow(
                color: isFocused ? (isMainButton ? AppTheme.secondary.opacity(0.6) : AppTheme.primary.opacity(0.4)) : .clear,
                radius: isFocused ? 60 : 0
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        #else
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        #endif
    }
}

#Preview {
    MusicPlayerView(
        playerManager: PlayerManager(),
        jellyfinService: JellyfinService()
    )
}
