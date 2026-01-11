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

    /// Langue de sous-titre préférée
    @Published var preferredSubtitleLanguage: String?

    /// Afficher l'overlay du prochain épisode
    @Published var showNextEpisodeOverlay = false

    /// Compte à rebours pour auto-play
    @Published var nextEpisodeCountdown = 10

    /// Flag pour auto-play activé
    @Published var shouldAutoPlayNext = true

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

    /// Indique si on devrait proposer de reprendre
    var shouldShowResumeOption: Bool {
        hasPlaybackProgress && !hasBeenPlayed
    }

    /// Texte du bouton de lecture
    var playButtonText: String {
        hasBeenPlayed ? "Revoir" : "Lire"
    }

    /// Position de reprise formatée
    var resumePositionFormatted: String? {
        guard let userData = currentUserData, userData.playbackPositionTicks > 0 else { return nil }
        return formatDuration(userData.playbackPosition)
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

        // Rafraîchir les données utilisateur
        await refreshUserData()

        // Charger le prochain épisode si c'est un épisode
        if isEpisode {
            await loadNextEpisode()
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

    /// Réinitialise l'état d'auto-play pour le prochain épisode
    func resetAutoPlayState() {
        countdownTask?.cancel()
        countdownTask = nil
        showNextEpisodeOverlay = false
        shouldAutoPlayNext = true
    }

    /// Appelé quand le countdown atteint 0 ou que l'utilisateur clique "Lire"
    func onAutoPlayTriggered() -> MediaItem? {
        countdownTask?.cancel()
        countdownTask = nil
        showNextEpisodeOverlay = false
        return nextEpisode
    }

    // MARK: - Image URLs

    /// URL de l'image principale
    var primaryImageURL: String {
        jellyfinService.getImageURL(itemId: item.id, imageType: "Primary", maxWidth: 400)
    }

    /// URL du backdrop
    var backdropImageURL: String {
        jellyfinService.getImageURL(itemId: item.id, imageType: "Backdrop", maxWidth: 1920)
    }

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
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)min" : "\(minutes)min"
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
