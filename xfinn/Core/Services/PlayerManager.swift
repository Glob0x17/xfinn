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
    private var currentItem: MediaItem?
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
        self.currentItem = item
        self.selectedSubtitleIndex = subtitleIndex
        self.subtitleStreams = item.subtitleStreams
        self.duration = item.duration ?? 0

        state = .loading

        // Enregistrer les capabilities du device
        do {
            try await jellyfinService.registerDeviceCapabilities()
        } catch {
            print("[PlayerManager] Erreur enregistrement capabilities: \(error.localizedDescription)")
        }

        // Debug: Afficher les sous-titres disponibles selon Jellyfin
        print("[PlayerManager] 🎬 Sous-titres Jellyfin (\(item.subtitleStreams.count) piste(s)):")
        for sub in item.subtitleStreams {
            print("[PlayerManager]   - Index \(sub.index): \(sub.displayName) (langue: \(sub.language ?? "?"), codec: \(sub.codec ?? "?"))")
        }

        // Obtenir les informations de lecture via PlaybackInfo API
        // Cette méthode envoie un DeviceProfile au serveur qui inclut les sous-titres
        // dans le manifest HLS si transcoding est nécessaire
        do {
            let playbackResult = try await jellyfinService.getPlaybackInfo(
                itemId: item.id,
                quality: quality
            )

            self.playSessionId = playbackResult.playSessionId

            print("[PlayerManager] Démarrage lecture - Item: \(item.id), Qualité: \(quality)")
            print("[PlayerManager] Mode: \(playbackResult.isTranscoding ? "Transcoding (sous-titres dans manifest)" : "Direct")")
            print("[PlayerManager] URL: \(playbackResult.streamURL.absoluteString.prefix(200))...")

            // Créer et configurer le player
            // Les sous-titres sont gérés nativement via le manifest HLS du serveur
            await setupPlayer(
                url: playbackResult.streamURL,
                item: item,
                resumePosition: resumePosition,
                jellyfinService: jellyfinService
            )

        } catch {
            print("[PlayerManager] Erreur PlaybackInfo: \(error.localizedDescription)")
            state = .failed("Impossible d'obtenir les informations de lecture: \(error.localizedDescription)")
        }
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
        // Créer l'asset directement avec l'URL
        // Les sous-titres sont inclus dans le manifest HLS par le serveur Jellyfin
        // grâce au DeviceProfile avec enableSubtitlesInManifest: true
        let asset = AVURLAsset(url: url)

        print("[PlayerManager] 🎬 Création asset AVPlayer (sous-titres gérés par serveur via manifest HLS)")

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
            // Les sous-titres sont gérés nativement par le serveur Jellyfin
            // Le menu CC natif affichera toutes les pistes de sous-titres incluses dans le manifest HLS
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
                        // Les sous-titres sont gérés nativement par le serveur via le manifest HLS
                        // Ils apparaissent automatiquement dans le menu CC d'AVPlayerViewController
                        break
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

        // Observateur principal pour la progression (toutes les 5 secondes)
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

    // Les sous-titres sont gérés nativement par le serveur Jellyfin
    // via le DeviceProfile avec enableSubtitlesInManifest: true
    // Le menu CC natif d'AVPlayerViewController affiche toutes les pistes
}
