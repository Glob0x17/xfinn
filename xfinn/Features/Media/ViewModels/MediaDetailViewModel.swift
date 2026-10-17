//
//  MediaDetailViewModel.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import Foundation
import SwiftUI
import Combine

// MARK: - Media Detail ViewModel

/// ViewModel pour la vue de détail média (film ou épisode)
@MainActor
final class MediaDetailViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// L'item média affiché
    let item: MediaItem

    /// Données utilisateur actuelles (progression, vu, etc.)
    @Published private(set) var currentUserData: UserData?

    /// Prochain épisode (pour séries)
    @Published private(set) var nextEpisode: MediaItem?

    /// Index du sous-titre sélectionné
    @Published var selectedSubtitleIndex: Int?

    /// Index de la piste audio sélectionnée (nil = choix du serveur,
    /// qui applique la préférence de langue du compte Jellyfin)
    @Published var selectedAudioStreamIndex: Int?

    /// Langue de sous-titre préférée
    @Published var preferredSubtitleLanguage: String?

    /// Afficher l'overlay du prochain épisode
    @Published var showNextEpisodeOverlay = false

    /// Compte à rebours pour auto-play
    @Published var nextEpisodeCountdown = 10

    /// Flag pour auto-play activé
    @Published var shouldAutoPlayNext = true

    /// Trigger pour signaler que le countdown est terminé (remplace callback pour éviter fuite mémoire)
    @Published var countdownFinishedTrigger = false

    // MARK: - Dependencies

    private let jellyfinService: JellyfinService

    // MARK: - Private Properties

    /// Tâche du compte à rebours
    private var countdownTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Indique si l'item a une progression de lecture
    var hasPlaybackProgress: Bool {
        guard let userData = currentUserData else { return false }
        return userData.playbackPositionTicks > 0
    }

    /// Indique si l'item a été vu
    var hasBeenPlayed: Bool {
        currentUserData?.played == true
    }

    /// Position de reprise en secondes
    var resumePosition: TimeInterval? {
        currentUserData?.playbackPosition
    }

    /// Indique si c'est un épisode
    var isEpisode: Bool {
        item.type == "Episode"
    }

    /// Icône du type de média
    var typeIcon: String {
        switch item.type {
        case "Movie": return "film"
        case "Episode": return "tv"
        default: return "play.rectangle"
        }
    }

    /// Nom d'affichage du sous-titre sélectionné
    var selectedSubtitleDisplayName: String {
        if let index = selectedSubtitleIndex,
           let subtitle = item.subtitleStreams.first(where: { $0.index == index }) {
            return subtitle.displayName
        }
        return "subtitles.none".localized
    }

    /// Flux de sous-titres triés (non-forcés en premier)
    var sortedSubtitleStreams: [MediaStream] {
        item.subtitleStreams.sorted { s1, s2 in
            let isForced1 = s1.isForced ?? false
            let isForced2 = s2.isForced ?? false
            if isForced1 != isForced2 { return !isForced1 }
            return s1.displayName < s2.displayName
        }
    }

    /// Indique si des sous-titres sont disponibles
    var hasSubtitles: Bool {
        !item.subtitleStreams.isEmpty
    }

    /// Nom d'affichage de la piste audio sélectionnée
    var selectedAudioDisplayName: String {
        if let index = selectedAudioStreamIndex,
           let stream = item.audioStreams.first(where: { $0.index == index }) {
            return stream.displayName
        }
        return "media.audio_auto".localized
    }

    // MARK: - Initialization

    init(item: MediaItem, jellyfinService: JellyfinService) {
        self.item = item
        self.jellyfinService = jellyfinService
        super.init()

        // Initialiser avec les données de l'item
        self.currentUserData = item.userData
    }

    deinit {
        countdownTask?.cancel()
    }

    // MARK: - Public Methods

    /// Charge les données initiales
    func loadInitialData() async {
        // Charger les préférences de sous-titres
        loadSubtitlePreferences()
        autoSelectSubtitles()
        autoSelectAudio()

        // Rafraîchir les données utilisateur
        await refreshUserData()

        // Charger le prochain épisode si c'est un épisode
        if isEpisode {
            await loadNextEpisode()
        }
    }

    /// Indique si l'item est en favori
    var isFavorite: Bool {
        currentUserData?.isFavorite == true
    }

    /// Bascule l'état vu/non vu
    func toggleWatched() async {
        do {
            try await jellyfinService.setPlayed(itemId: item.id, played: !hasBeenPlayed)
            currentUserData = jellyfinService.effectiveUserData(for: item)
        } catch {
            #if DEBUG
            print("[MediaDetailViewModel] toggleWatched failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Bascule l'état favori
    func toggleFavorite() async {
        do {
            try await jellyfinService.setFavorite(itemId: item.id, favorite: !isFavorite)
            currentUserData = jellyfinService.effectiveUserData(for: item)
        } catch {
            #if DEBUG
            print("[MediaDetailViewModel] toggleFavorite failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Rafraîchit les données utilisateur
    func refreshUserData() async {
        do {
            let updatedItem = try await jellyfinService.getItemDetails(itemId: item.id)
            currentUserData = updatedItem.userData
        } catch {
            // Erreur silencieuse - données utilisateur optionnelles
        }
    }

    /// Charge le prochain épisode
    func loadNextEpisode() async {
        guard isEpisode else { return }

        do {
            nextEpisode = try await jellyfinService.getNextEpisode(currentItemId: item.id)
        } catch {
            // Prochain épisode optionnel
        }
    }

    // MARK: - Subtitle Management

    /// Charge les préférences de sous-titres depuis UserDefaults
    func loadSubtitlePreferences() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "preferredSubtitleLanguage") {
            preferredSubtitleLanguage = savedLanguage
        }
    }

    /// Sélectionne automatiquement les sous-titres selon les préférences utilisateur
    /// Par défaut, les sous-titres sont désactivés sauf si l'utilisateur a défini une préférence
    func autoSelectSubtitles() {
        guard let preferredLanguage = preferredSubtitleLanguage,
              hasSubtitles else {
            // Pas de préférence utilisateur = sous-titres désactivés par défaut
            selectedSubtitleIndex = nil
            return
        }

        // Chercher un sous-titre correspondant à la langue préférée de l'utilisateur
        if let matching = item.subtitleStreams.first(where: {
            $0.language?.lowercased() == preferredLanguage.lowercased() && $0.isForced != true
        }) {
            selectedSubtitleIndex = matching.index
        } else {
            // Langue préférée non trouvée = sous-titres désactivés
            selectedSubtitleIndex = nil
        }
    }

    /// Met à jour la sélection de sous-titre
    func selectSubtitle(index: Int?, language: String?) {
        selectedSubtitleIndex = index
        preferredSubtitleLanguage = language

        if let lang = language {
            UserDefaults.standard.set(lang, forKey: "preferredSubtitleLanguage")
        } else {
            UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
        }
    }

    /// Désactive les sous-titres
    func disableSubtitles() {
        selectSubtitle(index: nil, language: nil)
    }

    // MARK: - Audio Track Management

    /// Pré-sélectionne la piste correspondant à la dernière langue audio
    /// choisie par l'utilisateur (nil sinon : le serveur décide)
    func autoSelectAudio() {
        guard item.hasMultipleAudioTracks else { return }
        let preferred = UserDefaults.standard.string(forKey: "preferredAudioLanguage")
        selectedAudioStreamIndex = item.audioStreams.firstAudioIndex(matchingLanguage: preferred)
    }

    /// Met à jour la piste audio choisie et mémorise la langue
    func selectAudio(index: Int?, language: String?) {
        selectedAudioStreamIndex = index

        if let language {
            UserDefaults.standard.set(language, forKey: "preferredAudioLanguage")
        } else {
            UserDefaults.standard.removeObject(forKey: "preferredAudioLanguage")
        }
    }

    // MARK: - Autoplay Management

    /// Démarre le compte à rebours pour l'épisode suivant
    func startNextEpisodeCountdown(initialTime: Int = 10) {
        guard nextEpisode != nil, !showNextEpisodeOverlay, shouldAutoPlayNext else { return }

        showNextEpisodeOverlay = true
        nextEpisodeCountdown = initialTime
        startCountdownTimer()
    }

    /// Annule l'auto-play
    func cancelAutoPlay() {
        shouldAutoPlayNext = false
        countdownTask?.cancel()
        countdownTask = nil
        withAnimation {
            showNextEpisodeOverlay = false
        }
    }

    /// Appelé quand le countdown atteint 0 ou que l'utilisateur clique "Lire"
    func onAutoPlayTriggered() -> MediaItem? {
        countdownTask?.cancel()
        countdownTask = nil
        showNextEpisodeOverlay = false
        shouldAutoPlayNext = false  // Empêche le double-déclenchement
        return nextEpisode
    }

    // MARK: - Image URLs

    /// URL d'image pour un item donné
    func getImageURL(for mediaItem: MediaItem, imageType: String = "Primary", maxWidth: Int = 400) -> String {
        jellyfinService.getImageURL(itemId: mediaItem.id, imageType: imageType, maxWidth: maxWidth)
    }

    // MARK: - Private Methods

    private func startCountdownTimer() {
        countdownTask?.cancel()

        countdownTask = Task { @MainActor in
            while !Task.isCancelled && nextEpisodeCountdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    nextEpisodeCountdown -= 1
                }
            }

            // Si le countdown est arrivé à 0 (pas annulé), déclencher l'autoplay via Publisher
            if !Task.isCancelled && nextEpisodeCountdown == 0 {
                countdownFinishedTrigger = true
            }
        }
    }

}

// MARK: - Preview Helper

#if DEBUG
extension MediaDetailViewModel {
    static var preview: MediaDetailViewModel {
        MediaDetailViewModel(
            item: MediaItem(
                id: "1",
                name: "Film Test",
                type: "Movie",
                overview: "Ceci est un synopsis de test pour le preview.",
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
    }
}
#endif
