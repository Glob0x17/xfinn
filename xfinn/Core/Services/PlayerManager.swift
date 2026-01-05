//
//  PlayerManager.swift
//  xfinn
//
//  Created by Claude on 05/01/2026.
//  Extracted from MediaDetailView for better separation of concerns.
//

import Foundation
import AVKit
import Combine
import SwiftUI

/// État de lecture du player
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case ended
    case failed(String)

    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.playing, .playing),
             (.paused, .paused), (.ended, .ended):
            return true
        case (.failed(let lhsMsg), .failed(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

/// Callbacks pour les événements du PlayerManager
struct PlayerManagerCallbacks {
    var onStateChange: ((PlaybackState) -> Void)?
    var onProgressUpdate: ((TimeInterval, TimeInterval) -> Void)?
    var onApproachEnd: ((TimeInterval) -> Void)?
    var onPlaybackFinished: (() -> Void)?
    var onSubtitleChange: ((Int?) -> Void)?
}

/// Gestionnaire centralisé pour la lecture vidéo AVPlayer
@MainActor
final class PlayerManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var state: PlaybackState = .idle
    @Published private(set) var player: AVPlayer?
    @Published private(set) var playerViewController: AVPlayerViewController?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var selectedSubtitleIndex: Int?

    // MARK: - Public Properties

    var callbacks = PlayerManagerCallbacks()

    var isPlaying: Bool {
        state == .playing
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    // MARK: - Private Properties

    private var playbackObserver: Any?
    private var playSessionId: String = ""
    private var itemId: String = ""
    private var jellyfinService: JellyfinService?
    private var subtitleStreams: [MediaStream] = []
    private var hasConfiguredSubtitleCallback = false
    private var isStoppingPlayback = false

    // Configuration
    private let progressReportInterval: TimeInterval = 5.0
    private let endApproachThreshold: TimeInterval = 10.0

    // MARK: - Initialization

    init() {}

    deinit {
        // Le cleanup sera appelé depuis MainActor
    }

    // MARK: - Public API

    /// Prépare et démarre la lecture
    /// - Parameters:
    ///   - item: Le média à lire
    ///   - quality: La qualité de streaming
    ///   - resumePosition: Position de reprise en secondes (nil pour démarrer du début)
    ///   - subtitleIndex: Index de la piste de sous-titres (nil pour aucun)
    ///   - jellyfinService: Service Jellyfin pour les URLs et le reporting
    func startPlayback(
        item: MediaItem,
        quality: StreamQuality,
        resumePosition: TimeInterval?,
        subtitleIndex: Int?,
        jellyfinService: JellyfinService
    ) async {
        // Reset state
        await cleanup()

        self.jellyfinService = jellyfinService
        self.itemId = item.id
        self.selectedSubtitleIndex = subtitleIndex
        self.subtitleStreams = item.subtitleStreams
        self.duration = item.duration ?? 0
        self.playSessionId = UUID().uuidString

        state = .loading

        // Enregistrer les capabilities du device
        do {
            try await jellyfinService.registerDeviceCapabilities()
        } catch {
            print("[PlayerManager] Erreur enregistrement capabilities: \(error.localizedDescription)")
        }

        // Obtenir l'URL de streaming
        guard let streamURL = jellyfinService.getStreamURL(
            itemId: item.id,
            quality: quality,
            playSessionId: playSessionId,
            subtitleStreamIndex: subtitleIndex
        ) else {
            state = .failed("Impossible d'obtenir l'URL de streaming")
            return
        }

        // Créer et configurer le player
        await setupPlayer(
            url: streamURL,
            item: item,
            resumePosition: resumePosition,
            jellyfinService: jellyfinService
        )
    }

    /// Met en pause la lecture
    func pause() {
        player?.pause()
        state = .paused
        reportProgress(isPaused: true)
    }

    /// Reprend la lecture
    func play() {
        player?.play()
        state = .playing
        reportProgress(isPaused: false)
    }

    /// Bascule entre play et pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Seek à une position donnée
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        Task {
            await player?.seek(to: cmTime)
        }
        currentTime = time
    }

    /// Seek relatif (avancer/reculer)
    func seekRelative(by seconds: TimeInterval) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seek(to: newTime)
    }

    /// Arrête la lecture et nettoie les ressources
    func stop() async {
        guard !isStoppingPlayback else { return }
        isStoppingPlayback = true

        // Capturer la position finale
        let finalPosition = currentTime
        let positionTicks = Int64(finalPosition * 10_000_000)

        // Nettoyer
        await cleanup()

        // Reporter l'arrêt
        if let service = jellyfinService, !itemId.isEmpty {
            do {
                try await service.reportPlaybackStopped(
                    itemId: itemId,
                    positionTicks: positionTicks,
                    playSessionId: playSessionId
                )
            } catch {
                print("[PlayerManager] Erreur report stop: \(error.localizedDescription)")
            }
        }

        state = .idle
        isStoppingPlayback = false
        callbacks.onPlaybackFinished?()
    }

    /// Nettoie les ressources sans reporter l'arrêt
    func cleanup() async {
        // Retirer l'observer de progression
        if let observer = playbackObserver, let player = player {
            player.removeTimeObserver(observer)
            playbackObserver = nil
        }

        // Retirer les observers de notifications
        if let currentItem = player?.currentItem {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: currentItem
            )
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemFailedToPlayToEndTime,
                object: currentItem
            )
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.AVPlayerItemNewAccessLogEntry,
                object: currentItem
            )
        }

        // Arrêter et nettoyer le player
        player?.pause()
        player?.replaceCurrentItem(with: nil)

        // Nettoyer le view controller
        playerViewController?.player = nil
        playerViewController = nil

        player = nil
        currentTime = 0
    }

    // MARK: - Private Methods

    private func setupPlayer(
        url: URL,
        item: MediaItem,
        resumePosition: TimeInterval?,
        jellyfinService: JellyfinService
    ) async {
        let asset = AVURLAsset(url: url)

        do {
            // Vérifier que l'asset est jouable
            let isPlayable = try await asset.load(.isPlayable)
            guard isPlayable else {
                state = .failed("Le média n'est pas jouable")
                return
            }

            // Créer le player item
            let playerItem = AVPlayerItem(asset: asset)

            // Configurer les métadonnées
            configureExternalMetadata(for: playerItem, item: item, jellyfinService: jellyfinService)

            // Créer le player
            let newPlayer = AVPlayer(playerItem: playerItem)
            self.player = newPlayer

            // Observer le statut
            observePlayerItemStatus(playerItem)

            // Configurer la position de départ
            if let position = resumePosition, position > 0 {
                let startTime = CMTime(seconds: position, preferredTimescale: 600)
                await newPlayer.seek(to: startTime)
                currentTime = position
            }

            // Créer le view controller
            let controller = AVPlayerViewController()
            controller.player = newPlayer
            controller.allowsPictureInPicturePlayback = true

            #if os(tvOS)
            // Désactiver les sous-titres natifs (on utilise le burn-in)
            if let legibleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
                playerItem.select(nil, in: legibleGroup)
            }
            newPlayer.appliesMediaSelectionCriteriaAutomatically = false

            // Configurer le menu des sous-titres
            configureSubtitleMenu(for: controller, item: item)
            #endif

            self.playerViewController = controller

            // Observer la fin de lecture
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handlePlaybackEnded()
                }
            }

            // Démarrer la lecture
            newPlayer.play()
            state = .playing

            // Configurer l'observer de progression
            setupProgressObserver()

            // Reporter le début
            await reportPlaybackStart(resumePosition: resumePosition)

        } catch {
            state = .failed("Erreur de chargement: \(error.localizedDescription)")
        }
    }

    private func observePlayerItemStatus(_ playerItem: AVPlayerItem) {
        Task {
            for await status in playerItem.publisher(for: \.status).values {
                await MainActor.run {
                    switch status {
                    case .readyToPlay:
                        if self.selectedSubtitleIndex != nil {
                            self.enableSubtitlesInPlayer(playerItem: playerItem)
                        }
                    case .failed:
                        if let error = playerItem.error {
                            self.state = .failed(error.localizedDescription)
                        }
                    case .unknown:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        }
    }

    private func setupProgressObserver() {
        guard let player = player else { return }

        playbackObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: progressReportInterval, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }

            let seconds = time.seconds
            self.currentTime = seconds

            // Notifier via callback
            self.callbacks.onProgressUpdate?(seconds, self.duration)

            // Reporter la progression
            self.reportProgress(isPaused: false)

            // Vérifier si on approche de la fin
            if self.duration > 0 {
                let timeRemaining = self.duration - seconds
                if timeRemaining <= self.endApproachThreshold && timeRemaining > 0 {
                    self.callbacks.onApproachEnd?(timeRemaining)
                }
            }
        }
    }

    private func handlePlaybackEnded() {
        state = .ended

        // Reporter l'arrêt
        let positionTicks = Int64(currentTime * 10_000_000)
        Task {
            if let service = jellyfinService {
                try? await service.reportPlaybackStopped(
                    itemId: itemId,
                    positionTicks: positionTicks,
                    playSessionId: playSessionId
                )
            }
        }

        callbacks.onPlaybackFinished?()
    }

    // MARK: - Playback Reporting

    private func reportPlaybackStart(resumePosition: TimeInterval?) async {
        guard let service = jellyfinService else { return }

        let startTicks = Int64((resumePosition ?? 0) * 10_000_000)
        do {
            try await service.reportPlaybackStart(
                itemId: itemId,
                positionTicks: startTicks,
                playSessionId: playSessionId
            )
        } catch {
            print("[PlayerManager] Erreur report start: \(error.localizedDescription)")
        }
    }

    private func reportProgress(isPaused: Bool) {
        guard let service = jellyfinService else { return }

        let positionTicks = Int64(currentTime * 10_000_000)
        Task {
            try? await service.reportPlaybackProgress(
                itemId: itemId,
                positionTicks: positionTicks,
                isPaused: isPaused,
                playSessionId: playSessionId
            )
        }
    }

    // MARK: - Metadata

    private func configureExternalMetadata(
        for playerItem: AVPlayerItem,
        item: MediaItem,
        jellyfinService: JellyfinService
    ) {
        var metadataItems: [AVMetadataItem] = []

        // Titre
        let titleItem = AVMutableMetadataItem()
        titleItem.identifier = .commonIdentifierTitle
        titleItem.value = item.displayTitle as NSString
        titleItem.extendedLanguageTag = "und"
        metadataItems.append(titleItem)

        // Description
        if let overview = item.overview {
            let descriptionItem = AVMutableMetadataItem()
            descriptionItem.identifier = .commonIdentifierDescription
            descriptionItem.value = overview as NSString
            descriptionItem.extendedLanguageTag = "und"
            metadataItems.append(descriptionItem)
        }

        playerItem.externalMetadata = metadataItems

        // Charger l'artwork en arrière-plan
        if let imageURL = URL(string: jellyfinService.getImageURL(itemId: item.id, imageType: "Primary", maxWidth: 1920)) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    let artworkItem = AVMutableMetadataItem()
                    artworkItem.identifier = .commonIdentifierArtwork
                    artworkItem.value = data as NSData
                    artworkItem.dataType = kCMMetadataBaseDataType_JPEG as String
                    artworkItem.extendedLanguageTag = "und"

                    await MainActor.run {
                        var updatedMetadata = playerItem.externalMetadata
                        updatedMetadata.append(artworkItem)
                        playerItem.externalMetadata = updatedMetadata
                    }
                } catch {
                    print("[PlayerManager] Erreur chargement artwork: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Subtitles

    #if os(tvOS)
    private func configureSubtitleMenu(for controller: AVPlayerViewController, item: MediaItem) {
        guard !item.subtitleStreams.isEmpty else { return }

        var subtitleActions: [UIAction] = []

        // Option "Aucun"
        let noneAction = UIAction(
            title: "Aucun",
            image: selectedSubtitleIndex == nil ? UIImage(systemName: "checkmark") : nil,
            state: selectedSubtitleIndex == nil ? .on : .off
        ) { [weak self] _ in
            self?.handleSubtitleChange(nil)
        }
        subtitleActions.append(noneAction)

        // Trier : non-forcés d'abord
        let sortedStreams = item.subtitleStreams.sorted { s1, s2 in
            if s1.isDefault != s2.isDefault {
                return s1.isDefault == true
            }
            return s1.displayName < s2.displayName
        }

        for subtitle in sortedStreams {
            let isSelected = selectedSubtitleIndex == subtitle.index
            let subtitleIndex = subtitle.index

            let action = UIAction(
                title: subtitle.displayName,
                image: isSelected ? UIImage(systemName: "checkmark") : nil,
                state: isSelected ? .on : .off
            ) { [weak self] _ in
                self?.handleSubtitleChange(subtitleIndex)
            }
            subtitleActions.append(action)
        }

        let subtitleMenu = UIMenu(
            title: "Changer de sous-titres",
            image: UIImage(systemName: "text.bubble"),
            children: subtitleActions
        )

        controller.transportBarCustomMenuItems = [subtitleMenu]
    }
    #endif

    private func handleSubtitleChange(_ newIndex: Int?) {
        selectedSubtitleIndex = newIndex

        // Sauvegarder la préférence
        if let index = newIndex,
           let subtitle = subtitleStreams.first(where: { $0.index == index }),
           let language = subtitle.language {
            UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")
        } else if newIndex == nil {
            UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
        }

        callbacks.onSubtitleChange?(newIndex)
    }

    private func enableSubtitlesInPlayer(playerItem: AVPlayerItem) {
        guard let legibleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
            return
        }

        guard let selectedIndex = selectedSubtitleIndex,
              let selectedSubtitle = subtitleStreams.first(where: { $0.index == selectedIndex }) else {
            playerItem.select(nil, in: legibleGroup)
            return
        }

        // Chercher l'option correspondante
        var matchingOption: AVMediaSelectionOption?

        if let language = selectedSubtitle.language?.lowercased() {
            matchingOption = legibleGroup.options.first { option in
                if let tag = option.extendedLanguageTag?.lowercased() {
                    return tag.hasPrefix(language) || tag.contains(language)
                }
                if let locale = option.locale {
                    return locale.languageCode?.lowercased() == language
                }
                return false
            }
        }

        if matchingOption == nil {
            matchingOption = legibleGroup.options.first { option in
                option.displayName.lowercased().contains(selectedSubtitle.displayName.lowercased())
            }
        }

        if let option = matchingOption {
            playerItem.select(option, in: legibleGroup)
        }
    }
}
