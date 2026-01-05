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
    let item: MediaItem
    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator

    // MARK: - Player Manager

    @StateObject private var playerManager = PlayerManager()

    // MARK: - UI State

    @State private var isPlaybackActive = false
    @State private var showQualityPicker = false
    @State private var showSubtitlePicker = false
    @State private var showResumeAlert = false

    // MARK: - Subtitle State

    @State private var selectedSubtitleIndex: Int?
    @State private var preferredSubtitleLanguage: String?

    // MARK: - User Data

    @State private var currentUserData: UserData?

    // MARK: - Next Episode (Autoplay)

    @State private var nextEpisode: MediaItem?
    @State private var showNextEpisodeOverlay = false
    @State private var nextEpisodeCountdown = 10
    @State private var shouldAutoPlayNext = true
    @State private var countdownTask: Task<Void, Never>?

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
        .onAppear(perform: handleOnAppear)
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

            if let imageUrl = URL(string: jellyfinService.getImageURL(itemId: item.id, imageType: "Backdrop", maxWidth: 1920)) {
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

                    if let seriesName = item.seriesName {
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
        AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: item.id, imageType: "Primary", maxWidth: 400))) { phase in
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
            Text(item.type == "Movie" ? "Film" : "Épisode")
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
        Text(item.displayTitle)
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
            if let year = item.productionYear {
                metadataItem(icon: "calendar", text: String(year), geometry: geometry)
            }
            if let rating = item.communityRating {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: geometry.size.width * 0.01))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: geometry.size.width * 0.012, weight: .medium))
                        .foregroundColor(.appTextPrimary)
                }
            }
            if let duration = item.duration {
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
        if let overview = item.overview, !overview.isEmpty {
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
            if !item.subtitleStreams.isEmpty {
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
                Text(currentUserData?.played == true ? "Revoir" : "Lire")
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
                Image(systemName: selectedSubtitleIndex != nil ? "captions.bubble.fill" : "captions.bubble")
                    .font(.system(size: geometry.size.width * 0.01))
                    .foregroundColor(selectedSubtitleIndex != nil ? .appPrimary : .appTextPrimary)
                Text(selectedSubtitleDisplayName)
                    .font(.system(size: geometry.size.width * 0.011, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, geometry.size.width * 0.015)
            .padding(.vertical, geometry.size.height * 0.015)
        }
        .background(selectedSubtitleIndex != nil ? AppTheme.primary.opacity(0.2) : AppTheme.glassBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(selectedSubtitleIndex != nil ? AppTheme.primary : AppTheme.glassStroke, lineWidth: 1.5))
    }

    @ViewBuilder
    private func progressView(geometry: GeometryProxy) -> some View {
        if let userData = currentUserData,
           userData.playbackPositionTicks > 0,
           let duration = item.duration {
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
            if let season = item.parentIndexNumber, let episode = item.indexNumber {
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
                .scaleEffect(showNextEpisodeOverlay ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: showNextEpisodeOverlay)
            }

            if showNextEpisodeOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if showNextEpisodeOverlay, let nextEpisode = nextEpisode {
                NextEpisodeOverlay(
                    nextEpisode: nextEpisode,
                    countdown: nextEpisodeCountdown,
                    jellyfinService: jellyfinService,
                    onPlayNext: { Task { await playNextEpisode() } },
                    onCancel: { cancelAutoPlay() }
                )
                .allowsHitTesting(true)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showNextEpisodeOverlay)
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
            selectedSubtitleIndex = nil
            preferredSubtitleLanguage = nil
            UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
        }
        ForEach(sortedSubtitleStreams) { subtitle in
            Button(subtitle.displayName) {
                selectedSubtitleIndex = subtitle.index
                if let language = subtitle.language {
                    preferredSubtitleLanguage = language
                    UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")
                }
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
        if let userData = currentUserData, userData.playbackPositionTicks > 0 {
            Text("Voulez-vous reprendre la lecture à \(formatDuration(userData.playbackPosition)) ?")
        } else {
            Text("Voulez-vous reprendre la lecture ?")
        }
    }

    // MARK: - Event Handlers

    private func handlePlayButtonTap() {
        if let userData = currentUserData,
           userData.playbackPositionTicks > 0,
           !userData.played {
            showResumeAlert = true
        } else {
            startPlayback(resumePosition: false)
        }
    }

    private func handleOnAppear() {
        // Load subtitle preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "preferredSubtitleLanguage") {
            preferredSubtitleLanguage = savedLanguage
        }
        autoSelectSubtitles()

        // Init user data
        currentUserData = item.userData
        Task { await refreshUserData() }

        // Load next episode for series
        if item.type == "Episode" {
            Task { await loadNextEpisode() }
        }

        // Autoplay if requested
        if navigationCoordinator.shouldAutoPlay {
            navigationCoordinator.shouldAutoPlay = false
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                startPlayback(resumePosition: false)
            }
        }

        // Setup callbacks
        setupPlayerCallbacks()
    }

    private func setupPlayerCallbacks() {
        playerManager.callbacks.onApproachEnd = { [self] timeRemaining in
            guard nextEpisode != nil, !showNextEpisodeOverlay, shouldAutoPlayNext else { return }
            showNextEpisodeOverlay = true
            nextEpisodeCountdown = Int(timeRemaining)
            startCountdown()
        }

        playerManager.callbacks.onPlaybackFinished = { [self] in
            isPlaybackActive = false
        }
    }

    private func handleOnDisappear() {
        if !isPlaybackActive {
            Task { await refreshUserData() }
        }
    }

    private func handlePlaybackDismiss() {
        Task {
            await playerManager.stop()
            await refreshUserData()
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
        let position: TimeInterval? = resumePosition ? currentUserData?.playbackPosition : nil

        Task {
            await playerManager.startPlayback(
                item: item,
                quality: jellyfinService.preferredQuality,
                resumePosition: position,
                subtitleIndex: selectedSubtitleIndex,
                jellyfinService: jellyfinService
            )
            isPlaybackActive = true
        }
    }

    // MARK: - Next Episode

    private func loadNextEpisode() async {
        do {
            nextEpisode = try await jellyfinService.getNextEpisode(currentItemId: item.id)
        } catch {
            print("[MediaDetailView] Erreur chargement prochain épisode: \(error.localizedDescription)")
        }
    }

    private func startCountdown() {
        countdownTask?.cancel()

        countdownTask = Task { @MainActor in
            while !Task.isCancelled && nextEpisodeCountdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    nextEpisodeCountdown -= 1
                }
            }

            if !Task.isCancelled && shouldAutoPlayNext {
                await playNextEpisode()
            }
        }
    }

    private func playNextEpisode() async {
        guard let nextEpisode = nextEpisode else { return }

        countdownTask?.cancel()
        countdownTask = nil
        showNextEpisodeOverlay = false

        await playerManager.stop()
        try? await Task.sleep(for: .seconds(0.3))

        isPlaybackActive = false
        navigationCoordinator.shouldAutoPlay = true
        navigationCoordinator.replaceLastWith(item: nextEpisode)
    }

    private func cancelAutoPlay() {
        shouldAutoPlayNext = false
        countdownTask?.cancel()
        countdownTask = nil
        withAnimation { showNextEpisodeOverlay = false }
    }

    // MARK: - Data

    private func refreshUserData() async {
        do {
            let updatedItem = try await jellyfinService.getItemDetails(itemId: item.id)
            await MainActor.run { currentUserData = updatedItem.userData }
        } catch {
            print("[MediaDetailView] Erreur rafraîchissement données utilisateur: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private var typeIcon: String {
        switch item.type {
        case "Movie": return "film"
        case "Episode": return "tv"
        default: return "play.rectangle"
        }
    }

    private var selectedSubtitleDisplayName: String {
        if let index = selectedSubtitleIndex,
           let subtitle = item.subtitleStreams.first(where: { $0.index == index }) {
            return subtitle.displayName
        }
        return "Aucun"
    }

    private var sortedSubtitleStreams: [MediaStream] {
        item.subtitleStreams.sorted { s1, s2 in
            let isForced1 = s1.isForced ?? false
            let isForced2 = s2.isForced ?? false
            if isForced1 != isForced2 { return !isForced1 }
            return s1.displayName < s2.displayName
        }
    }

    private func autoSelectSubtitles() {
        guard let preferredLanguage = preferredSubtitleLanguage,
              !item.subtitleStreams.isEmpty else { return }

        if let matching = item.subtitleStreams.first(where: {
            $0.language?.lowercased() == preferredLanguage.lowercased() && $0.isForced != true
        }) {
            selectedSubtitleIndex = matching.index
        } else if let defaultSub = item.subtitleStreams.first(where: {
            $0.isDefault == true && $0.isForced != true
        }) {
            selectedSubtitleIndex = defaultSub.index
        }
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
