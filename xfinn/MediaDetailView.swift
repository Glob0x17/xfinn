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
    @State private var showQualityPicker = false
    @State private var showSubtitlePicker = false
    @State private var showResumeAlert = false

    // MARK: - Initialization

    init(item: MediaItem, jellyfinService: JellyfinService) {
        self.jellyfinService = jellyfinService
        self._viewModel = StateObject(wrappedValue: MediaDetailViewModel(item: item, jellyfinService: jellyfinService))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            backgroundView

            // Detail content (when not playing)
            if !isPlaybackActive {
                detailContentView
            }
        }
        .navigationBarBackButtonHidden(isPlaybackActive)
        .fullScreenCover(isPresented: $isPlaybackActive, onDismiss: handlePlaybackDismiss) {
            playerOverlayView
        }
        .onChange(of: playerManager.state) { _, newState in
            handlePlayerStateChange(newState)
        }
        .task {
            await viewModel.loadInitialData()
            setupAutoPlayIfNeeded()
        }
        .onDisappear(perform: handleOnDisappear)
        .alert("Qualité de streaming", isPresented: $showQualityPicker) {
            qualityPickerButtons
        } message: {
            Text("Choisissez la qualité de streaming.")
        }
        .alert("Sous-titres", isPresented: $showSubtitlePicker) {
            subtitlePickerButtons
        } message: {
            Text("Choisissez les sous-titres à afficher.")
        }
        .alert("Reprendre la lecture ?", isPresented: $showResumeAlert) {
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
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: geometry.size.height * 0.03) {
                    headerSection(geometry: geometry)

                    if let seriesName = viewModel.item.seriesName {
                        seriesInfoSection(seriesName: seriesName, geometry: geometry)
                    }
                }
                .padding(.bottom, geometry.size.height * 0.05)
            }
        }
    }

    // MARK: - Header Section

    private func headerSection(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: geometry.size.width * 0.02) {
            posterView(geometry: geometry)
            infoView(geometry: geometry)
        }
        .padding(.horizontal, geometry.size.width * 0.03)
        .padding(.top, geometry.size.height * 0.03)
    }

    private func posterView(geometry: GeometryProxy) -> some View {
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
                        .font(.system(size: geometry.size.width * 0.04))
                        .foregroundColor(.appTextTertiary)
                }
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: geometry.size.width * 0.18, height: geometry.size.width * 0.27)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
        .shadow(color: AppTheme.primary.opacity(0.3), radius: 30, x: 0, y: 10)
    }

    private func infoView(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: geometry.size.height * 0.015) {
            typeBadge(geometry: geometry)
            titleView(geometry: geometry)
            metadataRow(geometry: geometry)
            synopsisView(geometry: geometry)
            actionButtons(geometry: geometry)
            progressView(geometry: geometry)
        }
    }

    private func typeBadge(geometry: GeometryProxy) -> some View {
        HStack(spacing: 10) {
            Image(systemName: typeIcon)
                .font(.system(size: geometry.size.width * 0.009))
            Text(viewModel.item.type == "Movie" ? "Film" : "Épisode")
                .font(.system(size: geometry.size.width * 0.01, weight: .semibold))
        }
        .foregroundColor(.appPrimary)
        .padding(.horizontal, geometry.size.width * 0.01)
        .padding(.vertical, geometry.size.height * 0.008)
        .background(
            Capsule()
                .fill(AppTheme.glassBackground)
                .overlay(Capsule().stroke(AppTheme.primary.opacity(0.5), lineWidth: 1.5))
        )
    }

    private func titleView(geometry: GeometryProxy) -> some View {
        Text(viewModel.item.displayTitle)
            .font(.system(size: geometry.size.width * 0.028, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, AppTheme.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private func metadataRow(geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.01) {
            if let year = viewModel.item.productionYear {
                metadataItem(icon: "calendar", text: String(year), geometry: geometry)
            }
            if let rating = viewModel.item.communityRating {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: geometry.size.width * 0.01))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: geometry.size.width * 0.012, weight: .medium))
                        .foregroundColor(.appTextPrimary)
                }
            }
            if let duration = viewModel.item.duration {
                metadataItem(icon: "clock", text: formatDuration(duration), geometry: geometry)
            }
        }
        .padding(.vertical, geometry.size.height * 0.008)
    }

    private func metadataItem(icon: String, text: String, geometry: GeometryProxy) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: geometry.size.width * 0.01))
            Text(text)
                .font(.system(size: geometry.size.width * 0.012, weight: .medium))
        }
        .foregroundColor(.appTextSecondary)
    }

    @ViewBuilder
    private func synopsisView(geometry: GeometryProxy) -> some View {
        if let overview = viewModel.item.overview, !overview.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Synopsis")
                    .font(.system(size: geometry.size.width * 0.014, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                Text(overview)
                    .font(.system(size: geometry.size.width * 0.011))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(6)
            }
            .padding(geometry.size.width * 0.012)
            .background(AppTheme.glassBackground)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassStroke, lineWidth: 1.5))
        }
    }

    private func actionButtons(geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.01) {
            playButton(geometry: geometry)
            qualityButton(geometry: geometry)
            if !viewModel.item.subtitleStreams.isEmpty {
                subtitleButton(geometry: geometry)
            }
        }
        .padding(.top, geometry.size.height * 0.008)
    }

    private func playButton(geometry: GeometryProxy) -> some View {
        Button(action: handlePlayButtonTap) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: geometry.size.width * 0.012))
                Text(viewModel.currentUserData?.played == true ? "Revoir" : "Lire")
                    .font(.system(size: geometry.size.width * 0.013, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, geometry.size.width * 0.02)
            .padding(.vertical, geometry.size.height * 0.015)
        }
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .white.opacity(0.5), radius: 15)
    }

    private func qualityButton(geometry: GeometryProxy) -> some View {
        Button(action: { showQualityPicker = true }) {
            HStack(spacing: 10) {
                Image(systemName: "video.badge.waveform")
                    .font(.system(size: geometry.size.width * 0.01))
                Text(jellyfinService.preferredQuality.rawValue)
                    .font(.system(size: geometry.size.width * 0.011, weight: .medium))
            }
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, geometry.size.width * 0.015)
            .padding(.vertical, geometry.size.height * 0.015)
        }
        .background(AppTheme.glassBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.glassStroke, lineWidth: 1.5))
    }

    private func subtitleButton(geometry: GeometryProxy) -> some View {
        Button(action: { showSubtitlePicker = true }) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.selectedSubtitleIndex != nil ? "captions.bubble.fill" : "captions.bubble")
                    .font(.system(size: geometry.size.width * 0.01))
                    .foregroundColor(viewModel.selectedSubtitleIndex != nil ? .appPrimary : .appTextPrimary)
                Text(viewModel.selectedSubtitleDisplayName)
                    .font(.system(size: geometry.size.width * 0.011, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, geometry.size.width * 0.015)
            .padding(.vertical, geometry.size.height * 0.015)
        }
        .background(viewModel.selectedSubtitleIndex != nil ? AppTheme.primary.opacity(0.2) : AppTheme.glassBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(viewModel.selectedSubtitleIndex != nil ? AppTheme.primary : AppTheme.glassStroke, lineWidth: 1.5))
    }

    @ViewBuilder
    private func progressView(geometry: GeometryProxy) -> some View {
        if let userData = viewModel.currentUserData,
           userData.playbackPositionTicks > 0,
           let duration = viewModel.item.duration {
            VStack(alignment: .leading, spacing: 10) {
                Text("Reprendre à \(formatDuration(userData.playbackPosition))")
                    .font(.system(size: geometry.size.width * 0.01, weight: .medium))
                    .foregroundColor(.appTextSecondary)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)
                    Capsule()
                        .fill(AppTheme.primary)
                        .frame(width: geometry.size.width * 0.22 * (userData.playbackPosition / duration), height: 6)
                }
                .frame(width: geometry.size.width * 0.22)
            }
            .padding(.top, geometry.size.height * 0.012)
        }
    }

    private func seriesInfoSection(seriesName: String, geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Série")
                .font(.system(size: geometry.size.width * 0.014, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text(seriesName)
                .font(.system(size: geometry.size.width * 0.012))
                .foregroundColor(.appTextSecondary)
            if let season = viewModel.item.parentIndexNumber, let episode = viewModel.item.indexNumber {
                Text("Saison \(season), Épisode \(episode)")
                    .font(.system(size: geometry.size.width * 0.011))
                    .foregroundColor(.appTextTertiary)
            }
        }
        .padding(.horizontal, geometry.size.width * 0.03)
    }

    // MARK: - Player Overlay View

    private var playerOverlayView: some View {
        ZStack {
            if let playerViewController = playerManager.playerViewController {
                PlayerViewControllerRepresentable(
                    playerViewController: playerViewController,
                    onDismiss: { isPlaybackActive = false }
                )
                .ignoresSafeArea()
                .scaleEffect(viewModel.showNextEpisodeOverlay ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showNextEpisodeOverlay)
            }

            if viewModel.showNextEpisodeOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

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
        .animation(.easeInOut(duration: 0.3), value: viewModel.showNextEpisodeOverlay)
    }

    // MARK: - Alert Buttons

    @ViewBuilder
    private var qualityPickerButtons: some View {
        ForEach(StreamQuality.allCases) { quality in
            Button(quality.rawValue) {
                jellyfinService.preferredQuality = quality
            }
        }
        Button("Annuler", role: .cancel) {}
    }

    @ViewBuilder
    private var subtitlePickerButtons: some View {
        Button("Aucun") {
            viewModel.disableSubtitles()
        }
        ForEach(viewModel.sortedSubtitleStreams) { subtitle in
            Button(subtitle.displayName) {
                viewModel.selectSubtitle(index: subtitle.index, language: subtitle.language)
            }
        }
        Button("Annuler", role: .cancel) {}
    }

    @ViewBuilder
    private var resumeAlertButtons: some View {
        Button("Continuer") { startPlayback(resumePosition: true) }
        Button("Reprendre du début") { startPlayback(resumePosition: false) }
        Button("Annuler", role: .cancel) {}
    }

    @ViewBuilder
    private var resumeAlertMessage: some View {
        if let userData = viewModel.currentUserData, userData.playbackPositionTicks > 0 {
            Text("Voulez-vous reprendre la lecture à \(formatDuration(userData.playbackPosition)) ?")
        } else {
            Text("Voulez-vous reprendre la lecture ?")
        }
    }

    // MARK: - Event Handlers

    private func handlePlayButtonTap() {
        if let userData = viewModel.currentUserData,
           userData.playbackPositionTicks > 0,
           !userData.played {
            showResumeAlert = true
        } else {
            startPlayback(resumePosition: false)
        }
    }

    private func setupAutoPlayIfNeeded() {
        if navigationCoordinator.shouldAutoPlay {
            navigationCoordinator.shouldAutoPlay = false
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                startPlayback(resumePosition: false)
            }
        }
        setupPlayerCallbacks()
    }

    private func setupPlayerCallbacks() {
        playerManager.callbacks.onApproachEnd = { [self] timeRemaining in
            guard viewModel.nextEpisode != nil,
                  !viewModel.showNextEpisodeOverlay,
                  viewModel.shouldAutoPlayNext else { return }
            viewModel.startNextEpisodeCountdown(initialTime: Int(timeRemaining))
        }

        playerManager.callbacks.onPlaybackFinished = { [self] in
            isPlaybackActive = false
        }
    }

    private func handleOnDisappear() {
        if !isPlaybackActive {
            Task { await viewModel.refreshUserData() }
        }
    }

    private func handlePlaybackDismiss() {
        Task {
            await playerManager.stop()
            await viewModel.refreshUserData()
        }
    }

    private func handlePlayerStateChange(_ state: PlaybackState) {
        switch state {
        case .ended:
            isPlaybackActive = false
        case .failed(let message):
            print("[MediaDetailView] Playback failed: \(message)")
            isPlaybackActive = false
        default:
            break
        }
    }

    // MARK: - Playback

    private func startPlayback(resumePosition: Bool) {
        let position: TimeInterval? = resumePosition ? viewModel.resumePosition : nil

        Task {
            await playerManager.startPlayback(
                item: viewModel.item,
                quality: jellyfinService.preferredQuality,
                resumePosition: position,
                subtitleIndex: viewModel.selectedSubtitleIndex,
                jellyfinService: jellyfinService
            )
            isPlaybackActive = true
        }
    }

    // MARK: - Next Episode

    private func playNextEpisode() async {
        guard let nextEpisode = viewModel.onAutoPlayTriggered() else { return }

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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)min" : "\(minutes)min"
    }
}

// MARK: - PlayerViewControllerRepresentable

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        playerViewController.delegate = context.coordinator
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
            super.init()
        }

        func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
            onDismiss()
            return true
        }

        #if !os(tvOS)
        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
            coordinator.animate(alongsideTransition: nil) { _ in
                self.onDismiss()
            }
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
