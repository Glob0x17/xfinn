//
//  MediaDetailView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Refactored on 05/01/2026: Utilisation de PlayerManager
//

import SwiftUI
import AVKit

struct MediaDetailView: View {
    @StateObject private var viewModel: MediaDetailViewModel
    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator

    // MARK: - Player Manager

    @StateObject private var playerManager = PlayerManager()

    // MARK: - UI State

    @State private var isPlaybackActive = false
    #if os(iOS)
    @State private var showPlayerOptions = false
    @State private var playerOptionsHideTask: Task<Void, Never>?
    @State private var stallWatchdog: Task<Void, Never>?
    @State private var showStallAlert = false
    #endif
    @State private var showQualityPicker = false
    @State private var showSubtitlePicker = false
    @State private var showAudioPicker = false
    @State private var showResumeAlert = false
    /// Erreur remontée par le player ; affichée une fois le plein écran refermé
    @State private var playbackErrorMessage: String?
    @State private var showPlaybackError = false

    /// Lancement en cours (PlaybackInfo, chargement de l'asset) : le plein
    /// écran ne s'ouvre qu'à la fin, le bouton Lire affiche l'attente et
    /// refuse les appuis — sans ça, chaque appui relançait une session
    @State private var isStartingPlayback = false
    @State private var playbackStartTask: Task<Void, Never>?

    // MARK: - Initialization

    init(item: MediaItem, jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._viewModel = StateObject(wrappedValue: MediaDetailViewModel(item: item, jellyfinService: jellyfinService))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Detail content (when not playing)
            if !isPlaybackActive {
                detailContentView
            }
        }
        .background { backgroundView }
        .navigationBarBackButtonHidden(isPlaybackActive)
        .fullScreenCover(isPresented: $isPlaybackActive, onDismiss: handlePlaybackDismiss) {
            playerOverlayView
        }
        .onChange(of: playerManager.state) { _, newState in
            handlePlayerStateChange(newState)
        }
        .task {
            // Le drapeau est consommé AVANT le chargement de la fiche : le
            // bouton Lire passe en attente immédiatement, l'utilisateur ne
            // peut pas lancer une seconde lecture pendant ce temps
            let autoPlay = consumeAutoPlayFlag()
            await viewModel.loadInitialData()
            setupPlayerCallbacks()
            if autoPlay {
                startAutoPlay()
            }
        }
        .onChange(of: viewModel.countdownFinishedTrigger) { _, triggered in
            if triggered {
                viewModel.countdownFinishedTrigger = false
                Task { await playNextEpisode() }
            }
        }
        .onDisappear(perform: handleOnDisappear)
        .alert("media.streaming_quality".localized, isPresented: $showQualityPicker) {
            qualityPickerButtons
        } message: {
            Text("media.choose_quality".localized)
        }
        .alert("media.playback_error".localized, isPresented: $showPlaybackError) {
            Button("OK", role: .cancel) { playbackErrorMessage = nil }
        } message: {
            if let playbackErrorMessage {
                Text(playbackErrorMessage)
            }
        }
        .alert("media.audio".localized, isPresented: $showAudioPicker) {
            audioPickerButtons
        } message: {
            Text("media.choose_audio".localized)
        }
        .alert("media.subtitles".localized, isPresented: $showSubtitlePicker) {
            subtitlePickerButtons
        } message: {
            Text("media.choose_subtitles".localized)
        }
        .alert("media.resume_playback".localized, isPresented: $showResumeAlert) {
            resumeAlertButtons
        } message: {
            resumeAlertMessage
        }
    }

    // MARK: - Background View

    private var backgroundView: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if let imageUrl = URL(string: jellyfinService.getImageURL(itemId: viewModel.item.id, imageType: "Backdrop", maxWidth: 1920)) {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 60)
                        .opacity(0.2)
                } placeholder: {
                    Color.clear
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Detail Content View

    private var detailContentView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: AppTheme.sp(32)) {
                headerSection()

                if let seriesName = viewModel.item.seriesName {
                    seriesInfoSection(seriesName: seriesName)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.bottom, 20)
        }
    }

    // MARK: - Header Section

    private func headerSection() -> some View {
        #if os(tvOS)
        HStack(alignment: .top, spacing: AppTheme.sp(38)) {
            posterView()
            infoView()
        }
        .padding(.horizontal, AppTheme.sp(58))
        .padding(.top, AppTheme.sp(32))
        #else
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                posterView()
                VStack(alignment: .leading, spacing: 8) {
                    typeBadge()
                    titleView()
                    metadataRow()
                }
            }
            synopsisView()
            playbackInfoView()
            actionButtons()
            progressView()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        #endif
    }

    private func posterView() -> some View {
        AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: viewModel.item.id, imageType: "Primary", maxWidth: 400))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure, .empty:
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Image(systemName: "film")
                        .font(.system(size: 24))
                        .foregroundColor(.appTextTertiary)
                }
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: AppTheme.dm(346), height: AppTheme.dm(518))
        .clipShape(RoundedRectangle(cornerRadius: posterCornerRadius))
        .overlay(
            // Même rayon que le clip, sinon la bordure décolle du poster
            RoundedRectangle(cornerRadius: posterCornerRadius)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
        .shadow(color: AppTheme.secondary.opacity(0.35), radius: 15, x: 0, y: 5)
    }

    private var posterCornerRadius: CGFloat { AppTheme.dm(20) }

    private func infoView() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.sp(16)) {
            typeBadge()
            titleView()
            metadataRow()
            synopsisView()
            playbackInfoView()
            actionButtons()
            progressView()
        }
    }

    private func typeBadge() -> some View {
        HStack(spacing: 6) {
            Image(systemName: typeIcon)
                .font(.system(size: AppTheme.fs(17)))
            Text(viewModel.item.type == "Movie" ? "media.movie".localized : "media.episode".localized)
                .font(.system(size: AppTheme.fs(19), weight: .semibold))
        }
        .foregroundColor(.appSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(AppTheme.glassBackground)
                .overlay(Capsule().stroke(AppTheme.secondary.opacity(0.5), lineWidth: 1.5))
        )
    }

    private func titleView() -> some View {
        Text(viewModel.item.displayTitle)
            .font(.system(size: AppTheme.fs(54), weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, AppTheme.tertiary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private func metadataRow() -> some View {
        HStack(spacing: 10) {
            if let year = viewModel.item.productionYear {
                metadataItem(icon: "calendar", text: String(year))
            }
            if let rating = viewModel.item.communityRating {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: AppTheme.fs(19)))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: AppTheme.fs(23), weight: .medium))
                        .foregroundColor(.appTextPrimary)
                }
            }
            if let duration = viewModel.item.duration {
                metadataItem(icon: "clock", text: duration.formattedDuration)
            }
        }
        .padding(.vertical, AppTheme.sp(9))
    }

    private func metadataItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.fs(19)))
            Text(text)
                .font(.system(size: AppTheme.fs(23), weight: .medium))
        }
        .foregroundColor(.appTextSecondary)
    }

    @ViewBuilder
    private func synopsisView() -> some View {
        if let overview = viewModel.item.overview, !overview.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("media.synopsis".localized)
                    .font(.system(size: AppTheme.fs(27), weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(overview)
                    .font(.system(size: AppTheme.fs(21)))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(6)
            }
            .padding(AppTheme.sp(23))
            .background(AppTheme.glassBackground)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.glassStroke, lineWidth: 1.5))
        }
    }

    @ViewBuilder
    private func playbackInfoView() -> some View {
        // Afficher seulement quand la lecture est active ET que les infos techniques sont disponibles
        if (playerManager.state == .playing || playerManager.state == .paused),
           let technicalInfo = playerManager.playbackTechnicalInfo {
            VStack(alignment: .leading, spacing: 12) {
                Text("media.now_playing".localized)
                    .font(.system(size: AppTheme.fs(27), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                HStack(spacing: AppTheme.sp(38)) {
                    // Mode de lecture (utilise technicalInfo comme source de vérité)
                    HStack(spacing: 8) {
                        Image(systemName: technicalInfo.playMethodIcon)
                            .font(.system(size: AppTheme.fs(23)))
                            .foregroundColor(technicalInfo.playMethod == .transcode ? .orange : .green)
                        Text(technicalInfo.playMethodDescription)
                            .font(.system(size: AppTheme.fs(21), weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }

                    // Bitrate
                    if playerManager.currentBitrate > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "speedometer")
                                .font(.system(size: AppTheme.fs(23)))
                                .foregroundColor(.appSecondary)
                            Text(playerManager.bitrateDescription)
                                .font(.system(size: AppTheme.fs(21), weight: .medium))
                                .foregroundColor(.appTextSecondary)
                        }
                    }

                    // Qualité sélectionnée
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: AppTheme.fs(23)))
                            .foregroundColor(.appSecondary)
                        Text(jellyfinService.preferredQuality.displayName)
                            .font(.system(size: AppTheme.fs(21), weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .padding(AppTheme.sp(23))
            .background(
                technicalInfo.playMethod == .transcode
                    ? AppTheme.glassBackground.opacity(0.8)
                    : AppTheme.glassBackground
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        technicalInfo.playMethod == .transcode ? Color.orange.opacity(0.5) : AppTheme.glassStroke,
                        lineWidth: 1.5
                    )
            )
        }
    }

    private func actionButtons() -> some View {
        #if os(tvOS)
        HStack(spacing: 10) {
            playButton()
            secondaryActionButtons()
        }
        .padding(.top, 4)
        #else
        // iPhone/iPad : Lire sur toute la largeur, les réglages en dessous
        // (sur une seule ligne, ils écrasaient le bouton Lire)
        VStack(alignment: .leading, spacing: 10) {
            playButton()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    secondaryActionButtons()
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 4)
        #endif
    }

    @ViewBuilder
    private func secondaryActionButtons() -> some View {
        qualityButton()
        if !viewModel.item.subtitleStreams.isEmpty {
            subtitleButton()
        }
        if viewModel.item.hasMultipleAudioTracks {
            audioButton()
        }
        watchedButton()
        favoriteButton()
    }

    private func watchedButton() -> some View {
        Button {
            Task { await viewModel.toggleWatched() }
        } label: {
            Image(systemName: viewModel.hasBeenPlayed ? "checkmark.circle.fill" : "checkmark.circle")
                .font(.system(size: AppTheme.fs(21)))
                .foregroundColor(viewModel.hasBeenPlayed ? AppTheme.success : .appTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .background(AppTheme.glassBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.glassStroke, lineWidth: 1.5))

    }

    private func favoriteButton() -> some View {
        Button {
            Task { await viewModel.toggleFavorite() }
        } label: {
            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                .font(.system(size: AppTheme.fs(21)))
                .foregroundColor(viewModel.isFavorite ? AppTheme.tertiary : .appTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .background(AppTheme.glassBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.glassStroke, lineWidth: 1.5))
    }

    /// Une position enregistrée prime sur « vu » : le bouton propose alors la
    /// reprise (cf. handlePlayButtonTap), son libellé doit le dire
    private var playButtonTitle: String {
        if viewModel.hasPlaybackProgress { return "media.resume".localized }
        if viewModel.currentUserData?.played == true { return "media.rewatch".localized }
        return "media.play".localized
    }

    private func playButton() -> some View {
        Button(action: handlePlayButtonTap) {
            HStack(spacing: 8) {
                if isStartingPlayback {
                    ProgressView()
                        .tint(.black)
                    Text("common.loading".localized)
                        .font(.system(size: AppTheme.fs(25), weight: .semibold))
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: AppTheme.fs(23)))
                    Text(playButtonTitle)
                        .font(.system(size: AppTheme.fs(25), weight: .semibold))
                }
            }
            .lineLimit(1)
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            #if !os(tvOS)
            .frame(maxWidth: .infinity)
            .contentShape(Capsule())
            #endif
        }
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .white.opacity(0.5), radius: 10)
    }

    private func qualityButton() -> some View {
        Button(action: { showQualityPicker = true }) {
            HStack(spacing: 6) {
                Image(systemName: "video.badge.waveform")
                    .font(.system(size: AppTheme.fs(19)))
                Text(jellyfinService.preferredQuality.displayName)
                    .font(.system(size: AppTheme.fs(21), weight: .medium))
            }
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(AppTheme.glassBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.glassStroke, lineWidth: 1.5))
    }

    private func subtitleButton() -> some View {
        Button(action: { showSubtitlePicker = true }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.selectedSubtitleIndex != nil ? "captions.bubble.fill" : "captions.bubble")
                    .font(.system(size: AppTheme.fs(19)))
                    .foregroundColor(viewModel.selectedSubtitleIndex != nil ? .appSecondary : .appTextPrimary)
                Text(viewModel.selectedSubtitleDisplayName)
                    .font(.system(size: AppTheme.fs(21), weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(viewModel.selectedSubtitleIndex != nil ? AppTheme.secondary.opacity(0.2) : AppTheme.glassBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(viewModel.selectedSubtitleIndex != nil ? AppTheme.secondary : AppTheme.glassStroke, lineWidth: 1.5))
    }

    @ViewBuilder
    private func progressView() -> some View {
        if let userData = viewModel.currentUserData,
           userData.playbackPositionTicks > 0,
           let duration = viewModel.item.duration {
            VStack(alignment: .leading, spacing: 6) {
                Text("media.resume_at_time".localized(with: userData.playbackPosition.formattedDuration))
                    .font(.system(size: AppTheme.fs(19), weight: .medium))
                    .foregroundColor(.appTextSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 5)
                        Capsule()
                            .fill(AppTheme.secondary)
                            .frame(width: geo.size.width * (userData.playbackPosition / duration), height: 5)
                    }
                }
                .frame(height: 5)
            }
            .padding(.top, 8)
        }
    }

    private func seriesInfoSection(seriesName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("media.series".localized)
                .font(.system(size: AppTheme.fs(27), weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text(seriesName)
                .font(.system(size: AppTheme.fs(23)))
                .foregroundColor(.appTextSecondary)
            if let season = viewModel.item.parentIndexNumber, let episode = viewModel.item.indexNumber {
                Text("media.season_episode".localized(with: season, episode))
                    .font(.system(size: AppTheme.fs(21)))
                    .foregroundColor(.appTextTertiary)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Player Overlay View

    private var playerOverlayView: some View {
        ZStack {
            if let playerViewController = playerManager.playerViewController {
                PlayerViewControllerRepresentable(
                    playerViewController: playerViewController,
                    onDismiss: { isPlaybackActive = false },
                    onTap: {
                        #if os(iOS)
                        togglePlayerOptions()
                        #endif
                    }
                )
                .id(ObjectIdentifier(playerViewController))
                .ignoresSafeArea()
                .scaleEffect(viewModel.showNextEpisodeOverlay ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showNextEpisodeOverlay)
            } else {
                // Relance en cours (repli HLS / audio) : le player est
                // reconstruit, afficher l'attente plutôt qu'un écran noir
                Color.black.ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }

            // Overlay de buffering personnalisé (stall pendant la lecture).
            // Purement informatif : il laisse passer les touchers, sinon un flux
            // bloqué empêche de quitter le lecteur
            if playerManager.isBuffering {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                BufferStatsOverlay(stats: playerManager.bufferStats)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale))
            }

            #if os(iOS)
            // Bouton fermer toujours accessible pendant un chargement (le lecteur
            // natif et ses commandes peuvent être absents ou masqués)
            if playerManager.isBuffering || playerManager.playerViewController == nil {
                VStack {
                    HStack {
                        Button {
                            isPlaybackActive = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .accessibilityLabel("common.close".localized)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 16)
                .zIndex(997)
            }
            #endif

            if viewModel.showNextEpisodeOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            #if !os(tvOS)
            // Bouton "Passer l'intro/le générique" (iOS — sur tvOS c'est le
            // bouton natif contextualActions géré par PlayerManager)
            if let segment = playerManager.activeSegment {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            playerManager.skipActiveSegment()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(PlayerManager.skipTitle(for: segment.type))
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.appTextPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(Capsule().stroke(AppTheme.glassStroke, lineWidth: 1.5))
                            )
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 90)
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(999)
            }
            #endif

            #if os(iOS)
            if showPlayerOptions, playerManager.playerViewController != nil {
                VStack {
                    HStack {
                        Spacer()
                        PlayerOptionsMenu(playerManager: playerManager)
                    }
                    Spacer()
                }
                .padding(.top, 64)
                .padding(.trailing, 16)
                .transition(.opacity)
                .zIndex(998)
            }
            #endif

            if viewModel.showNextEpisodeOverlay, let nextEpisode = viewModel.nextEpisode {
                NextEpisodeOverlay(
                    nextEpisode: nextEpisode,
                    countdown: viewModel.nextEpisodeCountdown,
                    jellyfinService: jellyfinService,
                    onPlayNext: { Task { await self.playNextEpisode() } },
                    onCancel: { self.viewModel.cancelAutoPlay() }
                )
                .allowsHitTesting(true)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        #if os(iOS)
        .onAppear {
            OrientationLock.setPlayerVisible(true)
            togglePlayerOptions()
        }
        .onDisappear {
            OrientationLock.setPlayerVisible(false)
            stallWatchdog?.cancel()
        }
        .onChange(of: playerManager.isBuffering) { _, buffering in
            armStallWatchdog(buffering)
        }
        .alert("player.stalled_title".localized, isPresented: $showStallAlert) {
            Button("common.retry".localized) { playerManager.retryCurrentPlayback() }
            Button("player.keep_waiting".localized, role: .cancel) { armStallWatchdog(playerManager.isBuffering) }
            Button("common.close".localized, role: .destructive) { isPlaybackActive = false }
        } message: {
            Text("player.stalled_message".localized)
        }
        .animation(.easeInOut(duration: 0.2), value: showPlayerOptions)
        #endif
        .animation(.easeInOut(duration: 0.3), value: viewModel.showNextEpisodeOverlay)
        .animation(.easeInOut(duration: 0.2), value: playerManager.isBuffering)
        #if !os(tvOS)
        .animation(.easeInOut(duration: 0.25), value: playerManager.activeSegment)
        #endif
    }

    #if os(iOS)
    /// Chargement qui ne repart pas après 20 s : proposer de relancer ou de
    /// fermer plutôt que de laisser le lecteur figé
    private func armStallWatchdog(_ buffering: Bool) {
        stallWatchdog?.cancel()
        guard buffering else { return }
        stallWatchdog = Task {
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, playerManager.isBuffering else { return }
            showStallAlert = true
        }
    }

    /// Le bouton d'options suit les commandes natives : il apparaît au tap
    /// sur la vidéo et disparaît après quelques secondes
    private func togglePlayerOptions() {
        playerOptionsHideTask?.cancel()
        showPlayerOptions.toggle()
        guard showPlayerOptions else { return }
        playerOptionsHideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            showPlayerOptions = false
        }
    }
    #endif

    // MARK: - Alert Buttons

    @ViewBuilder
    private var qualityPickerButtons: some View {
        ForEach(StreamQuality.allCases) { quality in
            Button(quality.displayName) {
                jellyfinService.preferredQuality = quality
            }
        }
        Button("common.cancel".localized, role: .cancel) {}
    }

    private func audioButton() -> some View {
        Button(action: { showAudioPicker = true }) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: AppTheme.fs(19)))
                    .foregroundColor(viewModel.selectedAudioStreamIndex != nil ? .appSecondary : .appTextPrimary)
                Text(viewModel.selectedAudioDisplayName)
                    .font(.system(size: AppTheme.fs(21), weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(viewModel.selectedAudioStreamIndex != nil ? AppTheme.secondary.opacity(0.2) : AppTheme.glassBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(viewModel.selectedAudioStreamIndex != nil ? AppTheme.secondary : AppTheme.glassStroke, lineWidth: 1.5))
    }

    @ViewBuilder
    private var audioPickerButtons: some View {
        Button("media.audio_auto".localized) {
            viewModel.selectAudio(index: nil, language: nil)
        }
        ForEach(viewModel.item.audioStreams) { stream in
            Button(stream.displayName) {
                viewModel.selectAudio(index: stream.index, language: stream.language)
            }
        }
        Button("common.cancel".localized, role: .cancel) {}
    }

    @ViewBuilder
    private var subtitlePickerButtons: some View {
        Button("common.none".localized) {
            viewModel.disableSubtitles()
        }
        ForEach(viewModel.sortedSubtitleStreams) { subtitle in
            Button(subtitle.displayName) {
                viewModel.selectSubtitle(index: subtitle.index, language: subtitle.language)
            }
        }
        Button("common.cancel".localized, role: .cancel) {}
    }

    @ViewBuilder
    private var resumeAlertButtons: some View {
        Button("common.continue".localized) { startPlayback(resumePosition: true) }
        Button("media.start_beginning".localized) { startPlayback(resumePosition: false) }
        Button("common.cancel".localized, role: .cancel) {}
    }

    @ViewBuilder
    private var resumeAlertMessage: some View {
        if let userData = viewModel.currentUserData, userData.playbackPositionTicks > 0 {
            Text("media.resume_at".localized(with: userData.playbackPosition.formattedDuration))
        } else {
            Text("media.resume_prompt".localized)
        }
    }

    // MARK: - Event Handlers

    private func handlePlayButtonTap() {
        guard !isStartingPlayback else { return }
        // Même condition que la barre « Reprendre à » : une position enregistrée suffit, même si
        // l'épisode est marqué vu (commencé ailleurs, ou marqué vu à la main) — sinon la fiche
        // annonçait une reprise que le bouton ne proposait pas
        if viewModel.hasPlaybackProgress {
            showResumeAlert = true
        } else {
            startPlayback(resumePosition: false)
        }
    }

    /// Lecture directe demandée par la navigation (clic épisode, Top Shelf,
    /// épisode suivant) : consomme le drapeau et met le bouton en attente
    private func consumeAutoPlayFlag() -> Bool {
        guard navigationCoordinator.shouldAutoPlay else { return false }
        navigationCoordinator.shouldAutoPlay = false
        isStartingPlayback = true
        return true
    }

    private func startAutoPlay() {
        // Lecture directe : reprendre automatiquement là où on s'était
        // arrêté, comme l'app Apple TV
        let canResume = viewModel.hasPlaybackProgress
        // Laisse l'animation de navigation se terminer avant le plein écran
        startPlayback(resumePosition: canResume, delay: .milliseconds(500))
    }

    private func setupPlayerCallbacks() {
        // Note: [self] est correct ici car MediaDetailView est une struct (value type)
        // Les structs SwiftUI ne créent pas de cycles de rétention
        playerManager.callbacks.onApproachEnd = { [self] timeRemaining in
            guard viewModel.nextEpisode != nil,
                  !viewModel.showNextEpisodeOverlay,
                  viewModel.shouldAutoPlayNext else { return }
            viewModel.startNextEpisodeCountdown(initialTime: Int(timeRemaining))
        }

        playerManager.callbacks.onPlaybackFinished = { [self] in
            // Ne pas dismiss si l'auto-play est en cours — le countdown gère la transition
            if !(viewModel.showNextEpisodeOverlay || (viewModel.nextEpisode != nil && viewModel.shouldAutoPlayNext)) {
                isPlaybackActive = false
            }
        }
    }

    private func handleOnDisappear() {
        guard !isPlaybackActive else { return }

        // Fiche quittée pendant un lancement : sans arrêt explicite, le
        // chargement continuait et la lecture finissait par démarrer en fond
        playbackStartTask?.cancel()
        playbackStartTask = nil
        isStartingPlayback = false
        Task {
            await playerManager.stop()
            await viewModel.refreshUserData()
        }
    }

    private func handlePlaybackDismiss() {
        Task {
            await playerManager.stop()
            await viewModel.refreshUserData()
            // Le plein écran est refermé : l'alerte peut maintenant s'afficher
            if playbackErrorMessage != nil {
                showPlaybackError = true
            }
        }
    }

    private func handlePlayerStateChange(_ state: PlaybackState) {
        switch state {
        case .ended:
            if viewModel.showNextEpisodeOverlay {
                // L'épisode est fini pendant le countdown — déclencher l'auto-play immédiatement
                Task { await playNextEpisode() }
            } else if viewModel.nextEpisode != nil && viewModel.shouldAutoPlayNext {
                // Le next episode est chargé mais le countdown n'a pas encore démarré
                // (race condition avec le progress observer) — déclencher directement
                Task { await playNextEpisode() }
            } else {
                isPlaybackActive = false
            }
        case .failed(let message):
            playbackErrorMessage = message
            if isPlaybackActive {
                // Fermer le player ; l'alerte part de handlePlaybackDismiss
                isPlaybackActive = false
            } else {
                // Échec avant l'ouverture du plein écran (PlaybackInfo, asset)
                showPlaybackError = true
            }
        default:
            break
        }
    }

    // MARK: - Playback

    private func startPlayback(resumePosition: Bool, delay: Duration? = nil) {
        let position: TimeInterval? = resumePosition ? viewModel.resumePosition : nil

        // Un seul lancement à la fois : le précédent est abandonné (le
        // PlayerManager invalide de son côté toute session plus ancienne)
        playbackStartTask?.cancel()
        isStartingPlayback = true

        playbackStartTask = Task {
            if let delay {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
            }
            await playerManager.startPlayback(
                item: viewModel.item,
                quality: jellyfinService.preferredQuality,
                resumePosition: position,
                subtitleIndex: viewModel.selectedSubtitleIndex,
                audioIndex: viewModel.selectedAudioStreamIndex,
                jellyfinService: jellyfinService
            )
            // Lancement remplacé par un plus récent, ou fiche quittée
            guard !Task.isCancelled else { return }
            isStartingPlayback = false
            playbackStartTask = nil
            // Échec au chargement : ne pas ouvrir un plein écran vide
            if case .failed = playerManager.state { return }
            // Arrêtée entre-temps (stop depuis un autre chemin)
            guard playerManager.playerViewController != nil else { return }
            isPlaybackActive = true
        }
    }

    // MARK: - Next Episode

    private func playNextEpisode() async {
        // Guard contre le double-déclenchement (handlePlayerStateChange + countdownFinishedTrigger)
        guard viewModel.shouldAutoPlayNext,
              let nextEpisode = viewModel.onAutoPlayTriggered() else { return }

        await playerManager.stop()
        try? await Task.sleep(for: .seconds(0.3))

        isPlaybackActive = false
        navigationCoordinator.shouldAutoPlay = true
        navigationCoordinator.replaceLastWith(item: nextEpisode)
    }

    // MARK: - Helpers

    private var typeIcon: String {
        viewModel.typeIcon
    }

}

// MARK: - PlayerViewControllerRepresentable

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController
    let onDismiss: () -> Void
    var onTap: () -> Void = {}

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        playerViewController.delegate = context.coordinator
        #if os(iOS)
        // Tap observé sans le consommer : les commandes natives restent actives
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        playerViewController.view.addGestureRecognizer(tap)
        #endif
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss, onTap: onTap)
    }

    class Coordinator: NSObject, AVPlayerViewControllerDelegate, UIGestureRecognizerDelegate {
        let onDismiss: () -> Void
        let onTap: () -> Void

        init(onDismiss: @escaping () -> Void, onTap: @escaping () -> Void) {
            self.onDismiss = onDismiss
            self.onTap = onTap
            super.init()
        }

        @objc func handleTap() {
            onTap()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        #if os(tvOS)
        func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
            onDismiss()
            return true
        }
        #else
        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
            // Au verrouillage de l'écran (lecture en AirPlay ou en image dans
            // l'image), le lecteur signale aussi une fin de plein écran : ce n'est
            // pas l'utilisateur qui ferme, la lecture doit continuer
            guard UIApplication.shared.applicationState == .active,
                  !isPictureInPictureActive else { return }
            coordinator.animate(alongsideTransition: nil) { context in
                guard !context.isCancelled else { return }
                self.onDismiss()
            }
        }

        private var isPictureInPictureActive = false

        func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            isPictureInPictureActive = true
        }

        func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            isPictureInPictureActive = false
        }

        // Lecteur intégré à la vue (pas présenté) : rien à fermer au démarrage
        // de l'image dans l'image, et l'interface est toujours là au retour
        func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
            return false
        }

        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
        ) {
            completionHandler(true)
        }
        #endif
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MediaDetailView(
            item: MediaItem(
                id: "1",
                name: "Film Test",
                type: "Movie",
                overview: "Ceci est un synopsis de test.",
                productionYear: 2023,
                indexNumber: nil,
                parentIndexNumber: nil,
                communityRating: 8.5,
                officialRating: "PG-13",
                runTimeTicks: 72000000000,
                userData: nil,
                seriesName: nil,
                seriesId: nil,
                seasonId: nil,
                mediaStreams: nil
            ),
            jellyfinService: JellyfinService()
        )
        .environmentObject(NavigationCoordinator())
    }
}
