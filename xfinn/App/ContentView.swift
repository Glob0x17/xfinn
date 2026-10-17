//
//  ContentView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

/// Point d'entrée principal de l'application
/// Gère l'affichage de LoginView ou HomeView selon l'état d'authentification
struct ContentView: View {
    @ObservedObject var jellyfinService: JellyfinService
    @ObservedObject private var playerManager: PlayerManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var showMusicPlayer = false

    /// Deep link reçu avant que la session soit prête (app lancée depuis le
    /// Top Shelf alors que l'utilisateur n'est pas encore authentifié)
    @State private var pendingDeepLink: DeepLink?

    init(jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._playerManager = ObservedObject(wrappedValue: jellyfinService.playerManager)
    }

    private var shouldShowFloatingPlayer: Bool {
        guard playerManager.playbackMode == .audio, playerManager.currentItem != nil else {
            return false
        }

        switch playerManager.state {
        case .loading, .playing, .paused:
            return true
        default:
            return false
        }
    }

    var body: some View {
        content
            .onOpenURL { url in
                guard let deepLink = DeepLink(url: url) else { return }
                if jellyfinService.isAuthenticated {
                    Task { await handle(deepLink) }
                } else {
                    pendingDeepLink = deepLink
                }
            }
            .onChange(of: jellyfinService.isAuthenticated) { _, authenticated in
                guard authenticated, let deepLink = pendingDeepLink else { return }
                pendingDeepLink = nil
                Task { await handle(deepLink) }
            }
    }

    /// Résout un deep link : fetch de l'item puis navigation vers sa fiche
    private func handle(_ deepLink: DeepLink) async {
        switch deepLink {
        case .item(let id):
            do {
                let item = try await jellyfinService.getItemDetails(itemId: id)
                navigationCoordinator.navigateTo(item: item)
            } catch {
                #if DEBUG
                print("[ContentView] Deep link resolution failed for \(id): \(error.localizedDescription)")
                #endif
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if jellyfinService.isAuthenticated {
            // Utilisateur connecté : afficher la page d'accueil
            ZStack(alignment: .bottom) {
                HomeView(jellyfinService: jellyfinService)

                if shouldShowFloatingPlayer && !showMusicPlayer {
                    FloatingMusicPlayerBar(
                        playerManager: playerManager,
                        onOpen: { showMusicPlayer = true },
                        onStop: {
                            Task {
                                await playerManager.stop()
                            }
                        }
                    )
                    #if os(tvOS)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 28)
                    #else
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    #endif
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(AppTheme.standardAnimation, value: shouldShowFloatingPlayer)
            .fullScreenCover(isPresented: $showMusicPlayer) {
                MusicPlayerView(
                    playerManager: playerManager,
                    jellyfinService: jellyfinService
                )
            }
        } else {
            // Utilisateur non connecté : afficher le login
            LoginView(jellyfinService: jellyfinService)
        }
    }
}

private struct FloatingMusicPlayerBar: View {
    @ObservedObject var playerManager: PlayerManager
    let onOpen: () -> Void
    let onStop: () -> Void

    private var title: String {
        playerManager.currentItem?.name ?? "music.unknown_track".localized
    }

    private var subtitle: String {
        playerManager.currentItem?.primaryArtist ?? "music.unknown_artist".localized
    }

    #if os(tvOS)
    private static let thumbSize: CGFloat = 56
    private static let titleSize: CGFloat = 22
    private static let subtitleSize: CGFloat = 18
    private static let playBtnSize: CGFloat = 66
    private static let playIconSize: CGFloat = 26
    private static let closeBtnSize: CGFloat = 52
    private static let closeIconSize: CGFloat = 22
    private static let maxBarWidth: CGFloat = 980
    #else
    private static let thumbSize: CGFloat = 40
    private static let titleSize: CGFloat = 15
    private static let subtitleSize: CGFloat = 12
    private static let playBtnSize: CGFloat = 44
    private static let playIconSize: CGFloat = 18
    private static let closeBtnSize: CGFloat = 36
    private static let closeIconSize: CGFloat = 15
    private static let maxBarWidth: CGFloat = 500
    #endif

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.accentGradient.opacity(0.85))
                            .frame(width: Self.thumbSize, height: Self.thumbSize)
                        Image(systemName: "music.note")
                            .font(.system(size: Self.thumbSize * 0.42, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: Self.titleSize, weight: .bold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.system(size: Self.subtitleSize, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(CustomCardButtonStyle(cornerRadius: 14))

            Button {
                playerManager.togglePlayPause()
            } label: {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: Self.playIconSize, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(width: Self.playBtnSize, height: Self.playBtnSize)
                    .background(
                        Circle()
                            .fill(AppTheme.glassBackground)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                            )
                    )
            }
            .buttonStyle(CustomCardButtonStyle(cornerRadius: Self.playBtnSize / 2))

            Button(action: onStop) {
                Image(systemName: "xmark")
                    .font(.system(size: Self.closeIconSize, weight: .bold))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: Self.closeBtnSize, height: Self.closeBtnSize)
                    .background(
                        Circle()
                            .fill(AppTheme.glassBackground.opacity(0.9))
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.glassStroke, lineWidth: 1.2)
                            )
                    )
            }
            .buttonStyle(CustomCardButtonStyle(cornerRadius: Self.closeBtnSize / 2))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: Self.maxBarWidth)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.elevatedGlassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                )
        )
        .shadow(color: AppTheme.secondary.opacity(0.25), radius: 18, x: 0, y: 10)
    }
}

#Preview {
    ContentView(jellyfinService: JellyfinService())
        .environmentObject(NavigationCoordinator())
}
