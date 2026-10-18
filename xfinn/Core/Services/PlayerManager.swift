//
//  PlayerManager.swift
//  xfinn
//
//  AVPlayer manager for media playback with progress reporting.
//

import Foundation
import AVKit
import Combine
import SwiftUI
import MediaPlayer
#if os(tvOS)
import UIKit
#endif

/// Mode de lecture
enum PlaybackMode {
    case video
    case audio
}

/// Mode de répétition pour la musique
enum RepeatMode {
    case off       // Pas de répétition
    case one       // Répéter la piste actuelle
    case all       // Répéter toute la playlist
}

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

/// Erreurs de chargement propres au PlayerManager
enum PlayerLoadError: LocalizedError {
    case timeout

    var errorDescription: String? {
        "error.loading_timeout".localized
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
    @Published private(set) var currentItem: MediaItem?

    /// Playlist audio pour la lecture en série
    @Published private(set) var playlist: [MediaItem] = []
    @Published private(set) var currentPlaylistIndex: Int = 0

    /// Mode de répétition
    @Published var repeatMode: RepeatMode = .off

    /// Indique si le contenu est transcodé ou en lecture directe
    @Published private(set) var isTranscoding: Bool = false

    /// Bitrate utilisé pour la lecture (en bps)
    @Published private(set) var currentBitrate: Int = 0

    /// Informations techniques de lecture
    @Published private(set) var playbackTechnicalInfo: PlaybackTechnicalInfo?

    /// Indique si le player est en train de buffering
    @Published private(set) var isBuffering: Bool = false

    /// Statistiques de buffering pour l'overlay de chargement
    @Published private(set) var bufferStats: BufferStats = .empty

    /// Segment (intro/générique/récap) actif à la position courante
    @Published private(set) var activeSegment: MediaSegment?

    /// Piste audio demandée pour la session en cours (nil = choix serveur)
    @Published private(set) var currentAudioStreamIndex: Int?

    // MARK: - Public Properties

    var callbacks = PlayerManagerCallbacks()

    var isPlaying: Bool {
        state == .playing
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    /// Description du mode de lecture (pour l'affichage)
    var playbackModeDescription: String {
        // Utiliser playbackTechnicalInfo comme source de vérité
        if let info = playbackTechnicalInfo {
            return info.playMethodDescription
        } else {
            return isTranscoding ? "Transcodage" : "Lecture directe"
        }
    }

    /// Description du bitrate formatée
    var bitrateDescription: String {
        if currentBitrate >= 1_000_000 {
            return "\(currentBitrate / 1_000_000) Mbps"
        } else if currentBitrate >= 1000 {
            return "\(currentBitrate / 1000) Kbps"
        } else if currentBitrate > 0 {
            return "\(currentBitrate) bps"
        } else {
            return "N/A"
        }
    }

    // MARK: - Private Properties

    private var playbackObserver: Any?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var didPlayToEndObserver: NSObjectProtocol?
    private var failedToPlayToEndObserver: NSObjectProtocol?
    private var accessLogObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    private var playSessionId: String = ""
    private var itemId: String = ""
    private var hasReportedPlaybackStopped = false
    private var jellyfinService: JellyfinService?
    private var subtitleStreams: [MediaStream] = []
    private var hasConfiguredSubtitleCallback = false
    private var isStoppingPlayback = false
    private var hasNotifiedPlaybackFinished = false
    private var currentQuality: StreamQuality = .auto
    @Published private(set) var playbackMode: PlaybackMode = .video

    // Repli audio. Un remux EAC3/AC3 → HLS fMP4 produit un segment d'init
    // invalide quand la piste audio démarre après la vidéo (ffmpeg : "Cannot
    // write moov atom before EAC3 packets parsed") ; AVPlayer refuse alors le
    // flux avant la première image. Après un tel échec sur un flux transcodé,
    // on relance UNE fois avec un profil qui force le réencodage audio en AAC.
    private var isAudioFallbackActive = false
    private var didReachReadyToPlay = false
    private var pendingResumePosition: TimeInterval?

    // Repli Direct Play → HLS. Certains fichiers servis bruts ne démarrent
    // pas (MP4 fragmenté non détecté par la sonde de PlaybackService, codec
    // refusé au décodage) : on relance UNE fois en demandant un flux HLS.
    private var isDirectPlayDisabled = false

    /// Incrémenté à chaque lancement et à chaque arrêt : un startPlayback
    /// encore en attente (réseau, chargement de l'asset) dont la génération
    /// n'est plus la courante abandonne sans toucher à l'état. Sans ça, un
    /// double appui ou un retour pendant le chargement laissaient des
    /// sessions et des AVPlayer orphelins qui finissaient par jouer en fond.
    private var playbackGeneration = 0

    /// Le serveur a reçu un PlaybackStart pour la session en cours
    private var hasReportedPlaybackStart = false

    // Media segments (intro/générique)
    private var mediaSegments: [MediaSegment] = []
    private var suppressedSegmentID: String?
    private var autoSkippedSegmentIDs: Set<String> = []
    private var segmentsTask: Task<Void, Never>?
    private var segmentObserver: Any?
    private var segmentDisplayTimer: Task<Void, Never>?
    private var subtitleResourceLoader: HLSSubtitleResourceLoader?

    // Buffer tracking
    private var bufferStartTime: Date?
    private var lastBytesReceived: Int64 = 0
    private var lastBufferSampleDate: Date?
    private var bufferUpdateTimer: Timer?

    // Configuration (utilise PlaybackConstants pour éviter les valeurs magiques)
    private let progressReportInterval = PlaybackConstants.progressReportInterval
    private let endApproachThreshold = PlaybackConstants.endApproachThreshold

    // MARK: - Initialization

    init() {
        configureAudioSession()
    }

    deinit {
        // Le cleanup sera appelé depuis MainActor
    }

    // MARK: - Now Playing Integration

    /// Configure AVAudioSession pour la lecture en arrière-plan
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("⚠️ AVAudioSession setup failed: \(error)")
            #endif
        }
    }

    /// Tokens des handlers posés sur MPRemoteCommandCenter (singleton global) :
    /// à retirer dans cleanup(), sinon chaque instance de PlayerManager
    /// (une par fiche média ouverte) empile ses handlers
    private var remoteCommandTargets: [(MPRemoteCommand, Any)] = []

    /// Enregistre les commandes du Control Center / Lock Screen
    private func setupRemoteCommands() {
        guard remoteCommandTargets.isEmpty else { return }
        let commandCenter = MPRemoteCommandCenter.shared()

        remoteCommandTargets.append((commandCenter.playCommand, commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.play()
            return .success
        }))
        remoteCommandTargets.append((commandCenter.pauseCommand, commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.pause()
            return .success
        }))
        remoteCommandTargets.append((commandCenter.togglePlayPauseCommand, commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }))
        remoteCommandTargets.append((commandCenter.nextTrackCommand, commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { await self.playNext() }
            return .success
        }))
        remoteCommandTargets.append((commandCenter.previousTrackCommand, commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { await self.playPrevious() }
            return .success
        }))
        remoteCommandTargets.append((commandCenter.changePlaybackPositionCommand, commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }))

        // Skip forward/backward (15 secondes)
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        remoteCommandTargets.append((commandCenter.skipForwardCommand, commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.seekRelative(by: 15)
            return .success
        }))
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        remoteCommandTargets.append((commandCenter.skipBackwardCommand, commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.seekRelative(by: -15)
            return .success
        }))
    }

    /// Met à jour les infos Now Playing (lock screen, Control Center)
    private func updateNowPlayingInfo() {
        guard let item = currentItem else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.name,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyMediaType: playbackMode == .audio ? MPNowPlayingInfoMediaType.audio.rawValue : MPNowPlayingInfoMediaType.video.rawValue
        ]

        // Artiste (pour la musique)
        if let artist = item.primaryArtist {
            info[MPMediaItemPropertyArtist] = artist
        }

        // Album
        if let album = item.album {
            info[MPMediaItemPropertyAlbumTitle] = album
        }

        // Numéro de piste
        if let trackNumber = item.indexNumber {
            info[MPMediaItemPropertyAlbumTrackNumber] = trackNumber
        }

        // Artwork — charger en arrière-plan
        if let service = jellyfinService {
            let imageId = item.albumId ?? item.id
            let urlString = service.getImageURL(itemId: imageId, maxWidth: 600)
            if let url = URL(string: urlString) {
                Task.detached {
                    if let (data, _) = try? await URLSession.shared.data(from: url),
                       let image = UIImage(data: data) {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                        await MainActor.run {
                            var currentInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                            currentInfo[MPMediaItemPropertyArtwork] = artwork
                            MPNowPlayingInfoCenter.default().nowPlayingInfo = currentInfo
                        }
                    }
                }
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Efface les infos Now Playing
    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Public API

    /// Prépare et démarre la lecture
    /// - Parameters:
    ///   - item: Le média à lire
    ///   - quality: La qualité de streaming
    ///   - resumePosition: Position de reprise en secondes (nil pour démarrer du début)
    ///   - subtitleIndex: Index de la piste de sous-titres (nil pour aucun)
    ///   - jellyfinService: Service Jellyfin pour les URLs et le reporting
    ///   - mode: Mode de lecture (video ou audio)
    ///   - playlist: Liste de lecture pour la musique (optionnel)
    ///   - playlistIndex: Index de départ dans la playlist (par défaut 0)
    func startPlayback(
        item: MediaItem,
        quality: StreamQuality,
        resumePosition: TimeInterval?,
        subtitleIndex: Int?,
        audioIndex: Int? = nil,
        jellyfinService: JellyfinService,
        mode: PlaybackMode = .video,
        playlist: [MediaItem]? = nil,
        playlistIndex: Int = 0
    ) async {
        await startPlayback(
            item: item,
            quality: quality,
            resumePosition: resumePosition,
            subtitleIndex: subtitleIndex,
            audioIndex: audioIndex,
            jellyfinService: jellyfinService,
            mode: mode,
            playlist: playlist,
            playlistIndex: playlistIndex,
            audioFallback: false,
            directPlayDisabled: false
        )
    }

    /// Implémentation de `startPlayback` — `audioFallback` et
    /// `directPlayDisabled` ne sont vrais que lors des relances automatiques
    /// après échec (voir `handlePlaybackFailure`)
    private func startPlayback(
        item: MediaItem,
        quality: StreamQuality,
        resumePosition: TimeInterval?,
        subtitleIndex: Int?,
        audioIndex: Int?,
        jellyfinService: JellyfinService,
        mode: PlaybackMode,
        playlist: [MediaItem]?,
        playlistIndex: Int,
        audioFallback: Bool,
        directPlayDisabled: Bool
    ) async {
        playbackGeneration += 1
        let generation = playbackGeneration

        // Reset state
        await cleanup()
        guard generation == playbackGeneration else { return }

        self.jellyfinService = jellyfinService
        self.itemId = item.id
        self.currentItem = item
        self.playbackMode = mode
        self.selectedSubtitleIndex = subtitleIndex
        self.currentAudioStreamIndex = audioIndex
        self.currentQuality = quality
        self.subtitleStreams = item.subtitleStreams
        self.duration = item.duration ?? 0
        self.hasReportedPlaybackStopped = false
        self.hasNotifiedPlaybackFinished = false
        self.isAudioFallbackActive = audioFallback
        self.isDirectPlayDisabled = directPlayDisabled
        self.hasReportedPlaybackStart = false
        self.didReachReadyToPlay = false
        self.pendingResumePosition = resumePosition
        setupRemoteCommands()

        // Configuration playlist pour le mode audio
        if let playlist = playlist, mode == .audio {
            self.playlist = playlist
            self.currentPlaylistIndex = playlistIndex
        } else {
            self.playlist = []
            self.currentPlaylistIndex = 0
        }

        state = .loading

        // Charger les segments (intro/générique) en parallèle, sans bloquer
        // le démarrage — indisponibles (serveur ancien, média non analysé) = []
        if mode == .video {
            let capturedItemId = item.id
            segmentsTask = Task { [weak self] in
                let segments = (try? await jellyfinService.getMediaSegments(itemId: capturedItemId)) ?? []
                guard let self, !Task.isCancelled, self.itemId == capturedItemId else { return }
                self.mediaSegments = segments
            }
        }

        // Enregistrer les capabilities du device (no-op après le 1er succès)
        do {
            try await jellyfinService.registerDeviceCapabilities()
        } catch {
            #if DEBUG
            print("[PlayerManager] registerDeviceCapabilities failed: \(error.localizedDescription)")
            #endif
        }
        guard generation == playbackGeneration else { return }

        // Obtenir les informations de lecture via PlaybackInfo API
        do {
            // subtitleIndex nil = mode natif : les pistes texte partent en
            // renditions HLS (grâce aux SubtitleProfiles), le menu CC
            // d'AVPlayer gère l'activation/désactivation. Un index explicite
            // (choisi sur la fiche) marque cette piste DEFAULT dans le manifest.
            let playbackResult = try await jellyfinService.getPlaybackInfo(
                itemId: item.id,
                quality: quality,
                audioStreamIndex: audioIndex,
                subtitleStreamIndex: subtitleIndex,
                forceAudioTranscode: audioFallback,
                allowDirectPlay: !directPlayDisabled && !Self.isAirPlayOutput
            )
            guard generation == playbackGeneration else { return }

            self.playSessionId = playbackResult.playSessionId
            self.isTranscoding = playbackResult.isTranscoding
            self.isDirectPlayDisabled = playbackResult.directPlayDisabled
            self.currentBitrate = playbackResult.mediaSource.bitrate ?? quality.maxBitrate ?? 0

            // Créer les informations techniques de lecture
            self.playbackTechnicalInfo = PlaybackTechnicalInfo.from(
                playbackResult: playbackResult,
                requestedBitrate: quality.maxBitrate
            )

            // Créer et configurer le player
            await setupPlayer(
                url: playbackResult.streamURL,
                item: item,
                resumePosition: resumePosition,
                jellyfinService: jellyfinService,
                generation: generation
            )

        } catch {
            guard generation == playbackGeneration else { return }
            state = .failed("error.playback_info".localized(with: error.localizedDescription))
        }
    }

    /// Met en pause la lecture
    func pause() {
        player?.pause()
        state = .paused
        reportProgress(isPaused: true)
        updateNowPlayingInfo()
    }

    /// Reprend la lecture
    func play() {
        player?.play()
        state = .playing
        reportProgress(isPaused: false)
        updateNowPlayingInfo()
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
        let cmTime = CMTime(seconds: time, preferredTimescale: PlaybackConstants.cmTimePreferredTimescale)
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

    // MARK: - Media Segments (skip intro/générique)

    /// Saute le segment actif (bouton "Passer l'intro/le générique")
    func skipActiveSegment() {
        guard let segment = activeSegment else { return }
        // Supprimé jusqu'à ce que la position sorte de sa plage : pas de
        // flicker après le seek, mais un rewind dans l'intro ré-affiche le bouton
        suppressedSegmentID = segment.id
        setActiveSegment(nil)
        seek(to: segment.endSeconds)
    }

    /// Relance la lecture à la position courante avec une autre piste audio
    /// (le flux HLS transcodé ne contient qu'une piste : changer = redemander
    /// un PlaybackInfo avec le nouvel AudioStreamIndex)
    func switchAudioTrack(to index: Int?) {
        guard playbackMode == .video,
              index != currentAudioStreamIndex,
              let item = currentItem,
              let service = jellyfinService else { return }

        // Mémoriser la langue pour les prochains médias
        if let index, let stream = item.audioStreams.first(where: { $0.index == index }),
           let language = stream.language {
            UserDefaults.standard.set(language, forKey: "preferredAudioLanguage")
        }

        let position = currentTime
        let subtitle = selectedSubtitleIndex
        let quality = currentQuality

        Task {
            await startPlayback(
                item: item,
                quality: quality,
                resumePosition: position > 5 ? position : nil,
                subtitleIndex: subtitle,
                audioIndex: index,
                jellyfinService: service,
                mode: .video
            )
        }
    }

    /// Relance la lecture à la position courante avec une autre qualité
    /// (même mécanique que le changement de piste audio : nouveau
    /// PlaybackInfo avec le bitrate cible, reprise à la position courante).
    /// Le choix est persisté comme qualité préférée pour les lectures suivantes.
    func switchQuality(to quality: StreamQuality) {
        guard playbackMode == .video,
              quality != currentQuality,
              let item = currentItem,
              let service = jellyfinService else { return }

        service.preferredQuality = quality

        let position = currentTime
        let subtitle = selectedSubtitleIndex
        let audio = currentAudioStreamIndex

        Task {
            await startPlayback(
                item: item,
                quality: quality,
                resumePosition: position > 5 ? position : nil,
                subtitleIndex: subtitle,
                audioIndex: audio,
                jellyfinService: service,
                mode: .video
            )
        }
    }

    /// Applique la sélection de sous-titres de l'app au groupe legible
    /// d'AVPlayer : sélection explicite de la piste correspondant à la langue
    /// choisie, ou désactivation explicite (nil) — sans quoi AVPlayer applique
    /// les réglages système, pas le choix de l'utilisateur dans l'app
    private func applySubtitleSelection(to playerItem: AVPlayerItem) async {
        guard playbackMode == .video else { return }

        guard let group = try? await playerItem.asset.loadMediaSelectionGroup(for: .legible) else {
            return
        }

        guard let selectedIndex = selectedSubtitleIndex,
              let stream = subtitleStreams.first(where: { $0.index == selectedIndex }) else {
            // Pas de choix explicite dans l'app : laisser AVPlayer et les
            // réglages système décider (comportement natif)
            return
        }

        // Piste correspondant à la langue choisie (fre/fra normalisés) ;
        // à défaut, la première piste du groupe
        let option: AVMediaSelectionOption?
        if let language = stream.language {
            let normalized = [MediaStream].normalizeLanguage(language)
            option = group.options.first { candidate in
                guard let tag = candidate.extendedLanguageTag ?? candidate.locale?.identifier else { return false }
                return [MediaStream].normalizeLanguage(tag) == normalized
            } ?? group.options.first
        } else {
            option = group.options.first
        }

        if let option {
            playerItem.select(option, in: group)
        }
    }

    /// Direct Play : choisit la piste audio dans le fichier (l'AudioStreamIndex envoyé à Jellyfin ne
    /// sert qu'au transcodage). Sans ça, un MP4 dont toutes les pistes audio sont actives les joue
    /// simultanément. En HLS, le serveur ne fournit déjà que la piste demandée.
    private func applyAudioSelection(to playerItem: AVPlayerItem) async {
        guard playbackMode == .video, !isTranscoding, let item = currentItem, item.audioStreams.count > 1 else { return }
        let streams = item.audioStreams
        let selectedIndex = currentAudioStreamIndex

        // Pistes regroupées en alternatives : sélection native, une seule est jouée
        if let group = try? await playerItem.asset.loadMediaSelectionGroup(for: .audible), group.options.count > 1 {
            let languages = group.options.map { $0.extendedLanguageTag ?? $0.locale?.identifier }
            if let position = AudioTrackMatching.trackPosition(streams: streams, selectedIndex: selectedIndex, trackLanguages: languages) {
                playerItem.select(group.options[position], in: group)
            }
            return
        }

        // Pistes indépendantes, toutes actives : n'en laisser qu'une
        var audioTracks: [(track: AVPlayerItemTrack, language: String?)] = []
        for track in playerItem.tracks {
            guard let assetTrack = track.assetTrack, assetTrack.mediaType == .audio else { continue }
            var language = try? await assetTrack.load(.extendedLanguageTag)
            if language == nil {
                language = try? await assetTrack.load(.languageCode)
            }
            audioTracks.append((track, language))
        }
        guard audioTracks.count > 1,
              let position = AudioTrackMatching.trackPosition(streams: streams, selectedIndex: selectedIndex,
                                                               trackLanguages: audioTracks.map(\.language)) else { return }
        for (offset, entry) in audioTracks.enumerated() {
            entry.track.isEnabled = offset == position
        }
    }

    /// Observer périodique dédié à la détection du segment actif
    private func setupSegmentObserver(on player: AVPlayer) {
        let interval = CMTime(
            seconds: PlaybackConstants.segmentCheckInterval,
            preferredTimescale: PlaybackConstants.cmTimePreferredTimescale
        )
        segmentObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateActiveSegment(at: time.seconds)
        }
    }

    /// Met à jour le segment actif pour la position donnée et gère l'auto-skip
    private func updateActiveSegment(at time: TimeInterval) {
        guard playbackMode == .video, !mediaSegments.isEmpty, time.isFinite else { return }

        // Ré-éligibilité : une fois sorti de la plage du segment skippé,
        // il redevient proposable (cas du retour en arrière volontaire)
        if let suppressedID = suppressedSegmentID,
           let suppressed = mediaSegments.first(where: { $0.id == suppressedID }),
           !(time >= suppressed.startSeconds && time < suppressed.endSeconds) {
            suppressedSegmentID = nil
        }

        let segment = mediaSegments.activeSegment(at: time, excluding: suppressedSegmentID)

        // Auto-skip des intros (opt-in, une seule fois par segment)
        if let segment,
           segment.type == .intro,
           UserDefaults.standard.autoSkipIntro,
           !autoSkippedSegmentIDs.contains(segment.id) {
            autoSkippedSegmentIDs.insert(segment.id)
            suppressedSegmentID = segment.id
            setActiveSegment(nil)
            seek(to: segment.endSeconds)
            return
        }

        if segment != activeSegment {
            setActiveSegment(segment)
        }
    }

    /// Point unique de mutation d'activeSegment — synchronise l'UI native tvOS
    /// et arme le masquage automatique du bouton
    private func setActiveSegment(_ segment: MediaSegment?) {
        activeSegment = segment
        #if os(tvOS)
        updateContextualActions(for: segment)
        #endif

        // Affichage limité dans le temps (pattern Netflix) : sans interaction,
        // le bouton se masque seul. Indispensable pour les génériques de fin,
        // dont le segment court jusqu'à la fin du fichier et n'est jamais quitté.
        segmentDisplayTimer?.cancel()
        segmentDisplayTimer = nil
        subtitleResourceLoader = nil

        guard let segment else { return }
        segmentDisplayTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(PlaybackConstants.skipButtonDisplayDuration))
            guard let self, !Task.isCancelled, self.activeSegment == segment else { return }
            // Suppression jusqu'à sortie de plage : un rewind dans le segment
            // ré-affichera le bouton
            self.suppressedSegmentID = segment.id
            self.setActiveSegment(nil)
        }
    }

    #if os(tvOS)
    /// Bouton natif tvOS (bas droite, focusable à la télécommande) via
    /// AVPlayerViewController.contextualActions — le mécanisme système
    /// utilisé par les apps de streaming pour "Passer l'intro"
    private func updateContextualActions(for segment: MediaSegment?) {
        guard let controller = playerViewController else { return }

        guard let segment else {
            controller.contextualActions = []
            return
        }

        let action = UIAction(title: Self.skipTitle(for: segment.type)) { [weak self] _ in
            Task { @MainActor in
                self?.skipActiveSegment()
            }
        }
        controller.contextualActions = [action]
    }
    #endif

    /// Libellé du bouton selon le type de segment
    static func skipTitle(for type: MediaSegment.SegmentType) -> String {
        switch type {
        case .outro: return "player.skip_outro".localized
        case .recap: return "player.skip_recap".localized
        default: return "player.skip_intro".localized
        }
    }

    /// Arrête la lecture et nettoie les ressources
    func stop() async {
        guard !isStoppingPlayback else { return }
        isStoppingPlayback = true
        playbackGeneration += 1

        // Capturer la position finale
        let finalPosition = currentTime
        let positionTicks = Int64(finalPosition * Double(PlaybackConstants.jellyfinTicksPerSecond))

        // Rapport figé AVANT le nettoyage (qui remet isTranscoding à false)
        let stoppedReport = makePlaybackStoppedReport(positionTicks: positionTicks)

        // Nettoyer
        await cleanup()

        // État local finalisé avant l'aller-retour réseau : une nouvelle
        // lecture lancée pendant le rapport ne doit pas être écrasée par la
        // fin de cet arrêt (state = .idle, callback de fin de lecture)
        state = .idle
        isStoppingPlayback = false
        notifyPlaybackFinishedOnce()

        await stoppedReport?()
    }

    /// Passer à la piste suivante dans la playlist
    func playNext() async {
        guard !playlist.isEmpty else { return }

        let nextIndex: Int
        if currentPlaylistIndex < playlist.count - 1 {
            nextIndex = currentPlaylistIndex + 1
        } else if repeatMode == .all {
            // Revenir au début si mode repeat all
            nextIndex = 0
        } else {
            // Pas de piste suivante
            return
        }

        let nextItem = playlist[nextIndex]
        guard let service = jellyfinService else { return }

        await startPlayback(
            item: nextItem,
            quality: service.preferredQuality,
            resumePosition: nil,
            subtitleIndex: nil,
            jellyfinService: service,
            mode: .audio,
            playlist: playlist,
            playlistIndex: nextIndex
        )
    }

    /// Revenir à la piste précédente dans la playlist
    func playPrevious() async {
        guard !playlist.isEmpty, currentPlaylistIndex > 0 else { return }

        let previousIndex = currentPlaylistIndex - 1
        let previousItem = playlist[previousIndex]

        guard let service = jellyfinService else { return }

        await startPlayback(
            item: previousItem,
            quality: service.preferredQuality,
            resumePosition: nil,
            subtitleIndex: nil,
            jellyfinService: service,
            mode: .audio,
            playlist: playlist,
            playlistIndex: previousIndex
        )
    }

    /// Indique si une piste suivante est disponible
    var hasNext: Bool {
        !playlist.isEmpty && currentPlaylistIndex < playlist.count - 1
    }

    /// Indique si une piste précédente est disponible
    var hasPrevious: Bool {
        !playlist.isEmpty && currentPlaylistIndex > 0
    }

    /// Nettoie les ressources sans reporter l'arrêt
    func cleanup() async {
        // Retirer l'observer de progression
        if let observer = playbackObserver, let player = player {
            player.removeTimeObserver(observer)
            playbackObserver = nil
        }

        // Retirer l'observer de segments et annuler le fetch en cours
        if let observer = segmentObserver, let player = player {
            player.removeTimeObserver(observer)
        }
        segmentObserver = nil
        segmentsTask?.cancel()
        segmentsTask = nil
        segmentDisplayTimer?.cancel()
        segmentDisplayTimer = nil
        subtitleResourceLoader = nil

        // Retirer les observers de notifications (API block-based)
        if let observer = didPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
            didPlayToEndObserver = nil
        }
        if let observer = failedToPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
            failedToPlayToEndObserver = nil
        }
        if let observer = accessLogObserver {
            NotificationCenter.default.removeObserver(observer)
            accessLogObserver = nil
        }

        // Arrêter et nettoyer le player
        player?.pause()
        player?.replaceCurrentItem(with: nil)

        // Nettoyer le view controller
        playerViewController?.player = nil
        playerViewController = nil

        // Arrêter le timer de buffer et l'observer KVO
        bufferUpdateTimer?.invalidate()
        bufferUpdateTimer = nil
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil

        // Retirer les handlers du Control Center (singleton global partagé
        // entre toutes les instances de PlayerManager)
        for (command, token) in remoteCommandTargets {
            command.removeTarget(token)
        }
        remoteCommandTargets.removeAll()

        // Annuler tous les subscribers Combine
        cancellables.removeAll()

        player = nil
        currentTime = 0
        isTranscoding = false
        currentBitrate = 0
        playbackTechnicalInfo = nil
        isBuffering = false
        bufferStats = .empty
        bufferStartTime = nil
        lastBytesReceived = 0
        lastBufferSampleDate = nil
        mediaSegments = []
        activeSegment = nil
        suppressedSegmentID = nil
        autoSkippedSegmentIDs = []

        clearNowPlayingInfo()
    }

    // MARK: - Private Methods

    private func setupPlayer(
        url: URL,
        item: MediaItem,
        resumePosition: TimeInterval?,
        jellyfinService: JellyfinService,
        generation: Int
    ) async {
        // Créer l'asset — pour un master de transcodage, passer par le proxy
        // qui corrige la carte de temps des sous-titres VTT (bug Jellyfin :
        // X-TIMESTAMP-MAP à 10 s alors que les segments fMP4 démarrent à 0)
        let asset: AVURLAsset
        if playbackMode == .video, let proxied = HLSSubtitleResourceLoader.proxyURL(for: url) {
            let loader = HLSSubtitleResourceLoader(mediaDuration: item.duration ?? 0)
            asset = AVURLAsset(url: proxied)
            asset.resourceLoader.setDelegate(loader, queue: loader.queue)
            self.subtitleResourceLoader = loader
        } else {
            asset = AVURLAsset(url: url)
        }

        do {
            // Vérifier que l'asset est jouable
            // Direct Play : chargement borné dans le temps (un fichier que
            // AVPlayer doit parcourir en entier ne rend pas la main)
            let isPlayable = isTranscoding
                ? try await asset.load(.isPlayable)
                : try await loadIsPlayable(asset, timeout: PlaybackConstants.directPlayLoadTimeout)
            guard generation == playbackGeneration else {
                asset.cancelLoading()
                return
            }
            guard isPlayable else {
                await handlePlaybackFailure("error.not_playable".localized)
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

            // Observer le buffering
            observeBufferState(playerItem)

            // Configurer la position de départ
            if let position = resumePosition, position > 0 {
                let startTime = CMTime(seconds: position, preferredTimescale: PlaybackConstants.cmTimePreferredTimescale)
                await newPlayer.seek(to: startTime)
                guard generation == playbackGeneration else { return }
                currentTime = position
            }

            // Créer le view controller uniquement pour la vidéo
            if playbackMode == .video {
                let controller = AVPlayerViewController()
                controller.player = newPlayer
                controller.allowsPictureInPicturePlayback = true

                #if os(tvOS)
                // Panneaux personnalisés : choix audio, qualité, infos techniques.
                // Le menu audio système est inutilisable sur un flux transcodé
                // (une seule piste muxée, sans langue → "Inconnue") ; cet onglet
                // liste les vraies pistes et permet de basculer en cours de lecture
                var infoPanels: [UIViewController] = []
                if item.hasMultipleAudioTracks {
                    infoPanels.append(AudioTrackViewController(
                        title: "media.audio".localized,
                        streams: item.audioStreams,
                        currentIndex: self.currentAudioStreamIndex,
                        noneLabel: "media.audio_auto".localized
                    ) { [weak self] newIndex in
                        self?.switchAudioTrack(to: newIndex)
                    })
                }
                infoPanels.append(QualitySelectionViewController(
                    currentQuality: self.currentQuality
                ) { [weak self] newQuality in
                    self?.switchQuality(to: newQuality)
                })
                if let technicalInfo = self.playbackTechnicalInfo {
                    infoPanels.append(TechnicalInfoViewController(info: technicalInfo))
                }
                controller.customInfoViewControllers = infoPanels
                #endif

                self.playerViewController = controller
            } else {
                // Mode audio : pas de view controller
                self.playerViewController = nil
            }

            // Observer la fin de lecture
            didPlayToEndObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handlePlaybackEnded()
                }
            }

            failedToPlayToEndObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    guard let self, self.isCurrent(playerItem) else { return }
                    let message = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?
                        .localizedDescription ?? "error.generic".localized
                    await self.handlePlaybackFailure(message)
                }
            }

            // Démarrer la lecture
            newPlayer.play()
            state = .playing

            // Configurer Now Playing (lock screen, Control Center)
            updateNowPlayingInfo()

            // Configurer l'observer de progression
            setupProgressObserver()

            // Observer dédié aux segments (plus fin que le reporting 5 s)
            setupSegmentObserver(on: newPlayer)

            // Reporter le début
            await reportPlaybackStart(resumePosition: resumePosition)

        } catch {
            guard generation == playbackGeneration else { return }
            await handlePlaybackFailure("error.loading".localized(with: error.localizedDescription))
        }
    }

    /// `asset.load(.isPlayable)` avec délai max : au-delà, le chargement est
    /// annulé et `PlayerLoadError.timeout` est levée
    private func loadIsPlayable(_ asset: AVURLAsset, timeout: TimeInterval) async throws -> Bool {
        let loadTask = Task { try await asset.load(.isPlayable) }
        let timeoutTask = Task {
            try await Task.sleep(for: .seconds(timeout))
            loadTask.cancel()
            asset.cancelLoading()
        }
        defer { timeoutTask.cancel() }

        do {
            return try await loadTask.value
        } catch where loadTask.isCancelled {
            throw PlayerLoadError.timeout
        }
    }

    // MARK: - Failure handling

    /// Un observer d'un AVPlayerItem remplacé (relance) ne doit pas
    /// contaminer la nouvelle session
    private func isCurrent(_ playerItem: AVPlayerItem) -> Bool {
        player?.currentItem === playerItem
    }

    /// Sortie audio AirPlay (HomePod, enceintes AirPlay). Sur cette route, AVPlayer passe en AirPlay
    /// tamponné (latence 2 s) et perd l'audio d'un fichier lu en Direct Play au bout de 20 s à 2 min, sans
    /// aucun événement : lecture « en cours », même route, mais plus de son (constaté sous tvOS 27, aussi
    /// avec le lecteur natif de Swiftfin). Le même fichier remuxé en HLS par le serveur n'est pas touché.
    static var isAirPlayOutput: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .airPlay }
    }

    /// Relance possible : vidéo transcodée, échec avant la première image,
    /// et pas déjà en repli
    private var canRetryWithAudioFallback: Bool {
        playbackMode == .video && isTranscoding && !isAudioFallbackActive && !didReachReadyToPlay
    }

    /// Relance en HLS possible : vidéo servie en Direct Play, pas déjà en
    /// repli. Pas de condition sur readyToPlay : un codec refusé au décodage
    /// échoue après readyToPlay, et la relance reprend à la position courante
    private var canRetryWithoutDirectPlay: Bool {
        playbackMode == .video && !isTranscoding && !isDirectPlayDisabled
    }

    /// Point unique de traitement d'un échec de lecture : relance en repli
    /// audio si les conditions sont réunies, sinon expose l'erreur à l'UI
    private func handlePlaybackFailure(_ message: String) async {
        guard let item = currentItem, let service = jellyfinService else {
            state = .failed(message)
            return
        }

        if canRetryWithoutDirectPlay {
            #if DEBUG
            print("[PlayerManager] Direct Play failed (\(message)) — retrying with HLS")
            #endif

            await reportPlaybackStoppedIfNeeded(positionTicks: 0)

            let position = max(pendingResumePosition ?? 0, currentTime)
            await startPlayback(
                item: item,
                quality: currentQuality,
                resumePosition: position > 0 ? position : nil,
                subtitleIndex: selectedSubtitleIndex,
                audioIndex: currentAudioStreamIndex,
                jellyfinService: service,
                mode: playbackMode,
                playlist: nil,
                playlistIndex: 0,
                audioFallback: isAudioFallbackActive,
                directPlayDisabled: true
            )
            return
        }

        guard canRetryWithAudioFallback else {
            state = .failed(message)
            return
        }

        #if DEBUG
        print("[PlayerManager] Transcoded stream failed before first frame (\(message)) — retrying with forced AAC audio")
        #endif

        // Le serveur a reçu un PlaybackStart pour cette session : la clore
        await reportPlaybackStoppedIfNeeded(positionTicks: 0)

        await startPlayback(
            item: item,
            quality: currentQuality,
            resumePosition: pendingResumePosition,
            subtitleIndex: selectedSubtitleIndex,
            audioIndex: currentAudioStreamIndex,
            jellyfinService: service,
            mode: playbackMode,
            playlist: nil,
            playlistIndex: 0,
            audioFallback: true,
            directPlayDisabled: isDirectPlayDisabled
        )
    }

    private func observePlayerItemStatus(_ playerItem: AVPlayerItem) {
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .readyToPlay:
                    self.didReachReadyToPlay = true
                    // Les renditions du manifest sont là, mais AVPlayer suit les
                    // réglages système de sous-titres — DEFAULT=YES n'est qu'un
                    // indice. La sélection de l'utilisateur doit être appliquée
                    // explicitement sur le groupe legible.
                    Task {
                        await self.applyAudioSelection(to: playerItem)
                        await self.applySubtitleSelection(to: playerItem)
                    }
                case .failed:
                    guard self.isCurrent(playerItem) else { return }
                    let message = playerItem.error?.localizedDescription ?? "error.generic".localized
                    Task { await self.handlePlaybackFailure(message) }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func observeBufferState(_ playerItem: AVPlayerItem) {
        guard let player = player else { return }

        // Observer timeControlStatus avec KVO direct - plus fiable que Combine dans un Task
        timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                switch player.timeControlStatus {
                case .waitingToPlayAtSpecifiedRate:
                    // Le player attend - buffering en cours (seulement si on est en lecture)
                    if self.state == .playing {
                        self.isBuffering = true
                        self.bufferStartTime = Date()
                        self.startBufferStatsTimer()
                    }
                case .playing:
                    // Le player joue - pas de buffering
                    self.isBuffering = false
                    self.stopBufferStatsTimer()
                case .paused:
                    // En pause - pas de buffering à afficher
                    self.isBuffering = false
                    self.stopBufferStatsTimer()
                @unknown default:
                    break
                }
            }
        }

        // Observer l'access log pour les statistiques réseau
        accessLogObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateBufferStatsFromAccessLog()
            }
        }
    }

    private func startBufferStatsTimer() {
        stopBufferStatsTimer()

        // Mise à jour des stats toutes les 0.5 secondes
        bufferUpdateTimer = Timer.scheduledTimer(withTimeInterval: PlaybackConstants.bufferUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateBufferStats()
            }
        }
    }

    private func stopBufferStatsTimer() {
        bufferUpdateTimer?.invalidate()
        bufferUpdateTimer = nil
    }

    private func updateBufferStats() {
        guard let playerItem = player?.currentItem else { return }

        // Calculer le pourcentage de buffer
        let loadedRanges = playerItem.loadedTimeRanges
        var bufferedDuration: TimeInterval = 0

        for range in loadedRanges {
            let timeRange = range.timeRangeValue
            bufferedDuration += timeRange.duration.seconds
        }

        // Calculer le pourcentage basé sur le buffer minimum nécessaire (10 secondes)
        let requiredBuffer = PlaybackConstants.minimumBufferRequired
        let percentage = min((bufferedDuration / requiredBuffer) * 100, 100)

        // Obtenir les stats réseau depuis l'access log
        // Vitesse = delta d'octets / temps réellement écoulé : correct quel que
        // soit le chemin d'appel (timer 0.5 s ou notification d'access log)
        var downloadSpeed: Double = 0
        var totalBytesReceived: Int64 = 0

        if let accessLog = playerItem.accessLog(),
           let lastEvent = accessLog.events.last {
            totalBytesReceived = lastEvent.numberOfBytesTransferred

            let now = Date()
            if lastBytesReceived > 0, let lastSample = lastBufferSampleDate {
                let elapsed = now.timeIntervalSince(lastSample)
                if elapsed >= 0.1 {
                    let bytesDelta = totalBytesReceived - lastBytesReceived
                    downloadSpeed = max(0, Double(bytesDelta) / elapsed)
                    lastBytesReceived = totalBytesReceived
                    lastBufferSampleDate = now
                }
            } else {
                lastBytesReceived = totalBytesReceived
                lastBufferSampleDate = now
            }
        }

        // Estimer le temps restant (percentage > 0 : évite division par zéro
        // au tout début du buffering, qui produisait un temps restant infini)
        var remainingTime: TimeInterval? = nil
        if downloadSpeed > 0 && percentage > 0 && percentage < 100 {
            let remainingPercentage = 100 - percentage
            let estimatedRemainingBytes = (Double(totalBytesReceived) / percentage) * remainingPercentage
            remainingTime = estimatedRemainingBytes / downloadSpeed
        }

        bufferStats = BufferStats(
            percentage: percentage,
            downloadSpeed: downloadSpeed,
            remainingTime: remainingTime,
            downloadedBytes: totalBytesReceived,
            totalBytes: nil
        )
    }

    private func updateBufferStatsFromAccessLog() {
        updateBufferStats()
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

            // Mettre à jour Now Playing (position)
            self.updateNowPlayingInfo()

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
        let positionTicks = Int64(currentTime * Double(PlaybackConstants.jellyfinTicksPerSecond))
        Task {
            await self.reportPlaybackStoppedIfNeeded(positionTicks: positionTicks)

            // Gérer la répétition ou passer à la piste suivante
            if playbackMode == .audio {
                switch repeatMode {
                case .one:
                    // Répéter la piste actuelle
                    if let currentItem = currentItem, let service = jellyfinService {
                        await startPlayback(
                            item: currentItem,
                            quality: service.preferredQuality,
                            resumePosition: nil,
                            subtitleIndex: nil,
                            jellyfinService: service,
                            mode: .audio,
                            playlist: playlist,
                            playlistIndex: currentPlaylistIndex
                        )
                    }
                case .all, .off:
                    // Passer à la piste suivante (playNext gère déjà le mode .all)
                    await playNext()
                }
            }
        }

        notifyPlaybackFinishedOnce()
    }

    /// Le callback UI de fin de lecture ne doit partir qu'une fois par session :
    /// handlePlaybackEnded() (fin naturelle) puis stop() (fermeture du player)
    /// passent tous deux ici — le second tir coupait l'auto-play épisode suivant
    private func notifyPlaybackFinishedOnce() {
        guard !hasNotifiedPlaybackFinished else { return }
        hasNotifiedPlaybackFinished = true
        callbacks.onPlaybackFinished?()
    }

    // MARK: - Playback Reporting

    /// PlayMethod Jellyfin réel de la session en cours (les stats serveur et la
    /// libération des sessions de transcodage en dépendent)
    private var currentPlayMethod: String {
        isTranscoding ? "Transcode" : "DirectStream"
    }

    private func reportPlaybackStart(resumePosition: TimeInterval?) async {
        guard let service = jellyfinService else { return }

        let startTicks = Int64((resumePosition ?? 0) * Double(PlaybackConstants.jellyfinTicksPerSecond))
        hasReportedPlaybackStart = true
        do {
            try await service.reportPlaybackStart(
                itemId: itemId,
                positionTicks: startTicks,
                playSessionId: playSessionId,
                playMethod: currentPlayMethod
            )
        } catch {
            #if DEBUG
            print("[PlayerManager] Playback start report failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func reportProgress(isPaused: Bool) {
        guard let service = jellyfinService else { return }

        let positionTicks = Int64(currentTime * Double(PlaybackConstants.jellyfinTicksPerSecond))
        Task {
            do {
                try await service.reportPlaybackProgress(
                    itemId: itemId,
                    positionTicks: positionTicks,
                    isPaused: isPaused,
                    playSessionId: playSessionId,
                    playMethod: currentPlayMethod
                )
            } catch {
                #if DEBUG
                print("[PlayerManager] Progress report failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func reportPlaybackStoppedIfNeeded(positionTicks: Int64) async {
        await makePlaybackStoppedReport(positionTicks: positionTicks)?()
    }

    /// Prépare le rapport d'arrêt de la session courante en figeant ses
    /// valeurs (item, session, PlayMethod) : il reste correct même exécuté
    /// après un nettoyage ou le lancement d'une autre session.
    /// nil si rien à rapporter — notamment une session jamais démarrée côté
    /// serveur (arrêt pendant le chargement)
    private func makePlaybackStoppedReport(positionTicks: Int64) -> (() async -> Void)? {
        guard hasReportedPlaybackStart,
              !hasReportedPlaybackStopped,
              let service = jellyfinService,
              !itemId.isEmpty else { return nil }

        hasReportedPlaybackStopped = true
        let itemId = itemId
        let playSessionId = playSessionId
        let playMethod = currentPlayMethod

        return {
            do {
                try await service.reportPlaybackStopped(
                    itemId: itemId,
                    positionTicks: positionTicks,
                    playSessionId: playSessionId,
                    playMethod: playMethod
                )
            } catch {
                #if DEBUG
                print("[PlayerManager] Playback stopped report failed: \(error.localizedDescription)")
                #endif
            }
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
                    // Artwork optionnel - erreur ignorée
                }
            }
        }
    }

    // MARK: - Subtitles

    // Les sous-titres sont gérés nativement par le serveur Jellyfin
    // via le DeviceProfile avec enableSubtitlesInManifest: true
    // Le menu CC natif d'AVPlayerViewController affiche toutes les pistes
}
