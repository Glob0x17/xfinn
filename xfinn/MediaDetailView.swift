//
//  MediaDetailView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI
import AVKit
import Combine

struct MediaDetailView: View {
    let item: MediaItem
    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    @State private var player: AVPlayer?
    @State private var isPlaybackActive = false
    @State private var playbackObserver: Any?
    @State private var showVideoPlayer = false
    @State private var playerViewController: AVPlayerViewController?
    @State private var showQualityPicker = false
    @State private var selectedQuality: StreamQuality = .auto
    @State private var showResumeAlert = false
    @State private var isStoppingPlayback = false
    
    // Sous-titres
    @State private var showSubtitlePicker = false
    @State private var selectedSubtitleIndex: Int? = nil // nil = pas de sous-titres
    @State private var preferredSubtitleLanguage: String? = nil // Langue préférée pour auto-sélection
    @State private var hasConfiguredSubtitleCallback = false // Pour éviter de reconfigurer le callback
    
    // État pour suivre les userData à jour
    @State private var currentUserData: UserData?
    
    // PlaySessionId unique pour cette session de lecture
    @State private var playSessionId: String = ""
    
    // Lecture automatique du prochain épisode
    @State private var nextEpisode: MediaItem?
    @State private var showNextEpisodeOverlay = false
    @State private var nextEpisodeCountdown = 10
    @State private var countdownTimer: Timer?
    @State private var shouldAutoPlayNext = true
    
    // Coordinator pour gérer les interactions UIKit ↔ SwiftUI
    @StateObject private var playerCoordinator = PlayerCoordinator()
    
    // MARK: - Coordinator Class
    
    /// Classe coordinateur pour gérer les interactions entre UIKit (AVPlayerViewController) et SwiftUI
    class PlayerCoordinator: ObservableObject {
        var onSubtitleChange: ((Int?) -> Void)?
        var getCurrentTime: (() -> CMTime?)?
    }
    
    // MARK: - Player Menu Configuration
    
    /// Configure le menu des sous-titres dans le player tvOS
    private func configureSubtitleMenu(for controller: AVPlayerViewController) {
        #if os(tvOS)
        guard !item.subtitleStreams.isEmpty else { return }
        
        var subtitleActions: [UIAction] = []
        
        // Option "Aucun" pour désactiver les sous-titres
        let noneAction = UIAction(
            title: "Aucun",
            image: selectedSubtitleIndex == nil ? UIImage(systemName: "checkmark") : nil,
            state: selectedSubtitleIndex == nil ? .on : .off
        ) { _ in
            playerCoordinator.onSubtitleChange?(nil)
        }
        subtitleActions.append(noneAction)
        
        // Créer une action pour chaque piste de sous-titres
        let sortedStreams = item.subtitleStreams.sorted { s1, s2 in
            if s1.isDefault != s2.isDefault {
                return s1.isDefault == true
            }
            return s1.displayName < s2.displayName
        }
        
        for subtitle in sortedStreams {
            let isSelected = selectedSubtitleIndex == subtitle.index
            let subtitleIndex = subtitle.index // Capturer la valeur
            let action = UIAction(
                title: subtitle.displayName,
                image: isSelected ? UIImage(systemName: "checkmark") : nil,
                state: isSelected ? .on : .off
            ) { _ in
                playerCoordinator.onSubtitleChange?(subtitleIndex)
            }
            subtitleActions.append(action)
        }
        
        // 🎯 Titre différent pour distinguer notre menu du menu natif
        let subtitleMenu = UIMenu(
            title: "Changer de sous-titres",
            image: UIImage(systemName: "text.bubble"),
            children: subtitleActions
        )
        
        controller.transportBarCustomMenuItems = [subtitleMenu]
        #endif
    }
    
    var body: some View {
        ZStack {
            // Background gradient (derrière tout)
            AppTheme.backgroundGradient
                .ignoresSafeArea()
                .allowsHitTesting(false) // ← Ne pas capturer les interactions
            
            // Image de fond avec effet blur (optionnelle, derrière le contenu)
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
                .allowsHitTesting(false) // ← Ne pas capturer les interactions
            }
            
            if !isPlaybackActive {
                // Vue des détails du média (scrollable)
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: geometry.size.height * 0.03) {
                            // En-tête avec poster et informations principales
                            HStack(alignment: .top, spacing: geometry.size.width * 0.02) {
                                // Poster
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
                                .shadow(
                                    color: AppTheme.primary.opacity(0.3),
                                    radius: 30,
                                    x: 0,
                                    y: 10
                                )
                                
                                // Informations
                                VStack(alignment: .leading, spacing: geometry.size.height * 0.015) {
                                    // Badge type
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
                                            .overlay(
                                                Capsule()
                                                    .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1.5)
                                            )
                                    )
                                    
                                    // Titre
                                    Text(item.displayTitle)
                                        .font(.system(size: geometry.size.width * 0.028, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, AppTheme.primary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    // Métadonnées
                                    HStack(spacing: geometry.size.width * 0.01) {
                                        if let year = item.productionYear {
                                            HStack(spacing: 8) {
                                                Image(systemName: "calendar")
                                                    .font(.system(size: geometry.size.width * 0.01))
                                                Text(String(year))
                                                    .font(.system(size: geometry.size.width * 0.012, weight: .medium))
                                            }
                                            .foregroundColor(.appTextSecondary)
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
                                            HStack(spacing: 8) {
                                                Image(systemName: "clock")
                                                    .font(.system(size: geometry.size.width * 0.01))
                                                Text(formatDuration(duration))
                                                    .font(.system(size: geometry.size.width * 0.012, weight: .medium))
                                            }
                                            .foregroundColor(.appTextSecondary)
                                        }
                                    }
                                    .padding(.vertical, geometry.size.height * 0.008)
                                    
                                    // Synopsis
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
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                                        )
                                    }
                                    
                                    // Boutons de lecture
                                    HStack(spacing: geometry.size.width * 0.01) {
                                        // Bouton de lecture
                                        Button(action: {
                                            // Vérifier s'il y a une position sauvegardée
                                            if let userData = currentUserData,
                                               userData.playbackPositionTicks > 0,
                                               !userData.played {
                                                showResumeAlert = true
                                            } else {
                                                startPlayback(resumePosition: false)
                                            }
                                        }) {
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
                                        
                                        // Bouton sélecteur de qualité
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
                                        .overlay(
                                            Capsule()
                                                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
                                        )
                                        
                                        // Bouton sélecteur de sous-titres
                                        if !item.subtitleStreams.isEmpty {
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
                                            .overlay(
                                                Capsule()
                                                    .stroke(selectedSubtitleIndex != nil ? AppTheme.primary : AppTheme.glassStroke, lineWidth: 1.5)
                                            )
                                        }
                                    }
                                    .padding(.top, geometry.size.height * 0.008)
                                    
                                    // Progression de lecture
                                    if let userData = currentUserData,
                                       userData.playbackPositionTicks > 0,
                                       let duration = item.duration {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("Reprendre à \(formatDuration(userData.playbackPosition))")
                                                .font(.system(size: geometry.size.width * 0.01, weight: .medium))
                                                .foregroundColor(.appTextSecondary)
                                            
                                            ZStack(alignment: .leading) {
                                                // Background
                                                Capsule()
                                                    .fill(Color.white.opacity(0.2))
                                                    .frame(height: 6)
                                                
                                                // Progress
                                                Capsule()
                                                    .fill(AppTheme.primary)
                                                    .frame(width: geometry.size.width * 0.22 * (userData.playbackPosition / duration), height: 6)
                                            }
                                            .frame(width: geometry.size.width * 0.22)
                                        }
                                        .padding(.top, geometry.size.height * 0.012)
                                    }
                                }
                            }
                            .padding(.horizontal, geometry.size.width * 0.03)
                            .padding(.top, geometry.size.height * 0.03)
                            
                            // Informations sur la série (pour les épisodes)
                            if let seriesName = item.seriesName {
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
                        }
                        .padding(.bottom, geometry.size.height * 0.05)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(isPlaybackActive)
        .fullScreenCover(isPresented: $isPlaybackActive, onDismiss: {
            // Appelé automatiquement quand le fullScreenCover est fermé
            stopPlayback()
        }) {
            ZStack {
                // Le player vidéo (avec animation de scale)
                if let playerViewController = playerViewController {
                    PlayerViewControllerRepresentable(
                        playerViewController: playerViewController,
                        onDismiss: {
                            // Fermer le fullScreenCover
                            isPlaybackActive = false
                        }
                    )
                    .ignoresSafeArea()
                    .scaleEffect(showNextEpisodeOverlay ? 0.85 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: showNextEpisodeOverlay)
                }
                
                // Overlay sombre pour mettre en valeur la card
                if showNextEpisodeOverlay {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                
                // Overlay pour l'épisode suivant (10s avant la fin)
                if showNextEpisodeOverlay, let nextEpisode = nextEpisode {
                    NextEpisodeOverlay(
                        nextEpisode: nextEpisode,
                        countdown: nextEpisodeCountdown,
                        jellyfinService: jellyfinService,
                        onPlayNext: {
                            Task {
                                await playNextEpisode()
                            }
                        },
                        onCancel: {
                            cancelAutoPlay()
                        }
                    )
                    .allowsHitTesting(true)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showNextEpisodeOverlay)
        }
        .onChange(of: isPlaybackActive) { oldValue, newValue in
            // Si isPlaybackActive passe de true à false, arrêter la lecture
            // MAIS seulement si stopPlayback n'a pas déjà été appelé
            if oldValue && !newValue && !isStoppingPlayback {
                stopPlayback()
            }
        }
        .onAppear {
            // Charger la qualité préférée
            selectedQuality = jellyfinService.preferredQuality
            
            // Charger la langue de sous-titres préférée
            if let savedLanguage = UserDefaults.standard.string(forKey: "preferredSubtitleLanguage") {
                preferredSubtitleLanguage = savedLanguage
            }
            
            // Auto-sélectionner les sous-titres si une langue est préférée
            autoSelectSubtitles()
            
            // Initialiser currentUserData avec les données de l'item
            currentUserData = item.userData
            
            // Rafraîchir les userData depuis le serveur
            Task {
                await refreshUserData()
            }
            
            // Charger l'épisode suivant si c'est une série
            if item.type == "Episode" {
                Task {
                    await loadNextEpisode()
                }
            }
            
            // Lancer automatiquement la lecture si demandé (autoplay depuis épisode précédent)
            if navigationCoordinator.shouldAutoPlay {
                navigationCoordinator.shouldAutoPlay = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startPlayback(resumePosition: false)
                }
            }
        }
        .onDisappear {
            // Rafraîchir à nouveau si on quitte la vue (pour obtenir les dernières mises à jour)
            if !isPlaybackActive {
                Task {
                    await refreshUserData()
                }
            }
        }
        .alert("Qualité de streaming", isPresented: $showQualityPicker) {
            ForEach(StreamQuality.allCases) { quality in
                Button(quality.rawValue) {
                    jellyfinService.preferredQuality = quality
                    selectedQuality = quality
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Choisissez la qualité de streaming pour cette lecture.\nLa qualité sélectionnée sera utilisée par défaut pour tous les médias.")
        }
        .alert("Sous-titres", isPresented: $showSubtitlePicker) {
            // Option pour désactiver les sous-titres
            Button("Aucun") {
                selectedSubtitleIndex = nil
                preferredSubtitleLanguage = nil
                UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
                
                // Pas de changement pendant la lecture - l'utilisateur devra relancer
            }
            // Options pour chaque piste de sous-titres disponible (triées)
            ForEach(sortedSubtitleStreams) { subtitle in
                Button(subtitle.displayName) {
                    selectedSubtitleIndex = subtitle.index
                    // Sauvegarder la langue préférée pour la prochaine fois
                    if let language = subtitle.language {
                        preferredSubtitleLanguage = language
                        UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")
                    }
                    
                    // Pas de changement pendant la lecture - l'utilisateur devra relancer
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            if isPlaybackActive {
                Text("Les sous-titres seront appliqués au prochain lancement de la vidéo.\n\nPour les appliquer maintenant, fermez le lecteur et relancez la vidéo.")
            } else {
                Text("Choisissez les sous-titres à afficher.\nVotre choix sera mémorisé pour les prochaines vidéos.")
            }
        }
        .alert("Reprendre la lecture ?", isPresented: $showResumeAlert) {
            Button("Continuer") {
                startPlayback(resumePosition: true)
            }
            Button("Reprendre du début") {
                startPlayback(resumePosition: false)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            if let userData = currentUserData, userData.playbackPositionTicks > 0 {
                Text("Voulez-vous reprendre la lecture à \(formatDuration(userData.playbackPosition)) ?")
            } else {
                Text("Voulez-vous reprendre la lecture ?")
            }
        }
    }
    
    // MARK: - Rafraîchissement des données
    
    private func loadNextEpisode() async {
        do {
            nextEpisode = try await jellyfinService.getNextEpisode(currentItemId: item.id)
        } catch {
            print("[MediaDetailView] Erreur chargement prochain épisode: \(error.localizedDescription)")
        }
    }

    private func refreshUserData() async {
        do {
            let updatedItem = try await jellyfinService.getItemDetails(itemId: item.id)
            await MainActor.run {
                currentUserData = updatedItem.userData
            }
        } catch {
            print("[MediaDetailView] Erreur rafraîchissement données utilisateur: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Lecture
    
    private func startPlayback(resumePosition: Bool) {
        // Générer un nouveau PlaySessionId pour cette session
        playSessionId = UUID().uuidString
        
        // Enregistrer les capabilities du device AVANT le playback
        Task {
            do {
                try await jellyfinService.registerDeviceCapabilities()
                
                // Continuer avec le playback après l'enregistrement
                await MainActor.run {
                    continueStartPlayback(resumePosition: resumePosition)
                }
            } catch {
                // Continuer quand même
                await MainActor.run {
                    continueStartPlayback(resumePosition: resumePosition)
                }
            }
        }
    }
    
    private func continueStartPlayback(resumePosition: Bool) {
        guard let streamURL = jellyfinService.getStreamURL(
            itemId: item.id,
            quality: selectedQuality,
            playSessionId: playSessionId,
            subtitleStreamIndex: selectedSubtitleIndex // 🔥 Passer l'index pour burn-in
        ) else {
            return
        }
        
        // Créer l'asset et charger les métadonnées de manière asynchrone
        let asset = AVURLAsset(url: streamURL)
        
        // Charger les clés asynchrones nécessaires
        Task {
            do {
                // Charger les métadonnées avant de créer le player item
                let isPlayable = try await asset.load(.isPlayable)
                let duration = try await asset.load(.duration)
                
                // Vérifier que l'asset est jouable
                guard isPlayable else {
                    return
                }
                
                await MainActor.run {
                    // Créer le player item avec l'asset chargé
                    let playerItem = AVPlayerItem(asset: asset)
                    
                    // Les sous-titres sont gérés nativement par HLS - pas besoin d'ajout manuel
                    // Ils seront disponibles via AVMediaSelectionGroup
                    
                    // Observer les erreurs du player item
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemFailedToPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { notification in
                        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                        }
                    }
                    
                    // Observer le statut du player item
                    NotificationCenter.default.addObserver(
                        forName: NSNotification.Name.AVPlayerItemNewAccessLogEntry,
                        object: playerItem,
                        queue: .main
                    ) { _ in
                        if let accessLog = playerItem.accessLog() {
                        }
                    }
                    
                    // Configurer les métadonnées pour Now Playing (de manière synchrone)
                    configureExternalMetadata(for: playerItem)
                    
                    // Créer le player
                    let newPlayer = AVPlayer(playerItem: playerItem)
                    self.player = newPlayer
                    
                    // Observer les changements de statut
                    Task {
                        for await status in playerItem.publisher(for: \.status).values {
                            await MainActor.run {
                                switch status {
                                case .unknown:
                                    break
                                case .readyToPlay:
                                    // Activer automatiquement les sous-titres si sélectionnés
                                    if self.selectedSubtitleIndex != nil {
                                        self.enableSubtitlesInPlayer(playerItem: playerItem)
                                    }
                                case .failed:
                                    if let error = playerItem.error {
                                    }
                                @unknown default:
                                    break
                                }
                            }
                        }
                    }
                    
                    // Reprendre à la position sauvegardée (si demandé)
                    if resumePosition, let itemUserData = currentUserData, itemUserData.playbackPositionTicks > 0 {
                        let startTime = CMTime(seconds: itemUserData.playbackPosition, preferredTimescale: 600)
                        newPlayer.seek(to: startTime)
                    } else {
                    }
                    
                    // Créer le AVPlayerViewController
                    let controller = AVPlayerViewController()
                    controller.player = newPlayer
                    controller.allowsPictureInPicturePlayback = true
                    
                    #if os(tvOS)
                    // Désactiver toutes les pistes de sous-titres natives du player
                    if let legibleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
                        playerItem.select(nil, in: legibleGroup)
                    }
                    
                    // Désactiver la sélection automatique des sous-titres
                    newPlayer.appliesMediaSelectionCriteriaAutomatically = false
                    #endif
                    
                    #if os(tvOS)
                    // Configurer le coordinator pour gérer les callbacks
                    playerCoordinator.getCurrentTime = { [weak newPlayer] in
                        return newPlayer?.currentItem?.currentTime()
                    }
                    
                    // Configurer le callback de changement de sous-titre seulement la première fois
                    if !hasConfiguredSubtitleCallback {
                        // Capturer les valeurs nécessaires sans capturer self
                        let itemStreams = item.subtitleStreams
                        
                        playerCoordinator.onSubtitleChange = { newSubtitleIndex in
                            // Mettre à jour l'index de sous-titres
                            selectedSubtitleIndex = newSubtitleIndex
                            
                            // Sauvegarder la préférence si une langue est sélectionnée
                            if let index = newSubtitleIndex,
                               let subtitle = itemStreams.first(where: { $0.index == index }),
                               let language = subtitle.language {
                                preferredSubtitleLanguage = language
                                UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")
                            } else if newSubtitleIndex == nil {
                                preferredSubtitleLanguage = nil
                                UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
                            }
                            
                            // Avec le burn-in, on ne peut pas changer les sous-titres à la volée
                            // On ferme le player pour que l'utilisateur le relance manuellement
                            isPlaybackActive = false
                        }
                        hasConfiguredSubtitleCallback = true
                    }
                    
                    // Configurer le menu des sous-titres
                    configureSubtitleMenu(for: controller)
                    #endif
                    
                    self.playerViewController = controller
                    
                    // Observer la fin de la lecture avec un token d'observation
                    let itemId = item.id
                    let service = jellyfinService
                    let sessionId = playSessionId // Capturer le PlaySessionId
                    let stopPlaybackClosure = { [playerItem] in
                        Task { @MainActor in
                            
                            // Récupérer la position actuelle depuis le player item
                            let currentTime = playerItem.currentTime()
                            let positionTicks = Int64(currentTime.seconds * 10_000_000)
                            
                            // Signaler l'arrêt de la lecture
                            try? await service.reportPlaybackStopped(
                                itemId: itemId,
                                positionTicks: positionTicks,
                                playSessionId: sessionId
                            )
                            
                            // Nettoyer via la vue
                            self.cleanupPlayback()
                        }
                    }
                    
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { _ in
                        stopPlaybackClosure()
                    }
                    
                    // Démarrer la lecture
                    newPlayer.play()
                    
                    // Observer la progression de la lecture
                    setupPlaybackObserver()
                    
                    // Afficher le player
                    isPlaybackActive = true
                    
                    // Signaler le début de la lecture
                    Task {
                        let startTicks = currentUserData?.playbackPositionTicks ?? 0
                        do {
                            try await jellyfinService.reportPlaybackStart(
                                itemId: item.id,
                                positionTicks: startTicks,
                                playSessionId: playSessionId
                            )
                        } catch {
                        }
                    }
                }
            } catch {
            }
        }
    }
    
    // MARK: - Gestion des sous-titres
    
    /// Sélectionne automatiquement les sous-titres basés sur la langue préférée
    private func autoSelectSubtitles() {
        guard let preferredLanguage = preferredSubtitleLanguage,
              !item.subtitleStreams.isEmpty else {
            return
        }
        
        // Chercher une piste de sous-titres qui correspond à la langue préférée
        // Exclure les sous-titres "forcés" (forced) par défaut
        if let matchingSubtitle = item.subtitleStreams.first(where: { subtitle in
            let isMatchingLanguage = subtitle.language?.lowercased() == preferredLanguage.lowercased()
            let isNotForced = subtitle.isForced != true
            return isMatchingLanguage && isNotForced
        }) {
            selectedSubtitleIndex = matchingSubtitle.index
        } else if let firstDefault = item.subtitleStreams.first(where: { 
            $0.isDefault == true && $0.isForced != true
        }) {
            // Sinon, sélectionner les sous-titres par défaut s'ils existent
            selectedSubtitleIndex = firstDefault.index
        }
    }
    
    /// Retourne le nom d'affichage des sous-titres actuellement sélectionnés
    private var selectedSubtitleDisplayName: String {
        if let index = selectedSubtitleIndex,
           let subtitle = item.subtitleStreams.first(where: { $0.index == index }) {
            return subtitle.displayName
        }
        return "Aucun"
    }
    
    /// Retourne les sous-titres triés : non-forcés d'abord, forcés ensuite
    private var sortedSubtitleStreams: [MediaStream] {
        return item.subtitleStreams.sorted { subtitle1, subtitle2 in
            let isForced1 = subtitle1.isForced ?? false
            let isForced2 = subtitle2.isForced ?? false
            
            // Les non-forcés en premier
            if isForced1 != isForced2 {
                return !isForced1
            }
            
            // Sinon, trier par nom
            return subtitle1.displayName < subtitle2.displayName
        }
    }
    
    private func enableSubtitlesInPlayer(playerItem: AVPlayerItem) {
        guard let legibleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
            return
        }
        
        if let selectedSubtitleIndex = selectedSubtitleIndex,
           let selectedSubtitle = item.subtitleStreams.first(where: { $0.index == selectedSubtitleIndex }) {
            
            // Stratégie 1: Correspondance exacte par langue
            var matchingOption: AVMediaSelectionOption?
            
            if let language = selectedSubtitle.language?.lowercased() {
                matchingOption = legibleGroup.options.first { option in
                    // Comparer avec extendedLanguageTag (ex: "fr-FR", "en-US")
                    if let tag = option.extendedLanguageTag?.lowercased() {
                        return tag.hasPrefix(language) || tag.contains(language)
                    }
                    // Comparer avec locale (ex: Locale(identifier: "fr"))
                    if let locale = option.locale {
                        return locale.languageCode?.lowercased() == language
                    }
                    return false
                }
            }
            
            // Stratégie 2: Si pas de correspondance par langue, essayer par displayName
            if matchingOption == nil {
                matchingOption = legibleGroup.options.first { option in
                    option.displayName.lowercased().contains(selectedSubtitle.displayName.lowercased())
                }
            }
            
            // Stratégie 3: Si toujours rien, prendre la première option
            if matchingOption == nil {
                matchingOption = legibleGroup.options.first
            }
            
            // Activer l'option trouvée
            if let option = matchingOption {
                playerItem.select(option, in: legibleGroup)
                
                if let player = player {
                    player.currentItem?.select(option, in: legibleGroup)
                }
            }
            
        } else {
            // Désactiver les sous-titres
            playerItem.select(nil, in: legibleGroup)
        }
    }
    
    private func configureExternalMetadata(for playerItem: AVPlayerItem) {
        // Créer les métadonnées externes pour AVKit de manière synchrone
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
        
        // Appliquer immédiatement les métadonnées de base
        playerItem.externalMetadata = metadataItems
        
        // Charger l'artwork de manière asynchrone
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
                }
            }
        }
    }
    
    private func setupPlaybackObserver() {
        guard let player = player else { return }
        
        // Capturer les valeurs nécessaires pour la closure
        let itemId = item.id
        let service = jellyfinService
        let sessionId = playSessionId // Capturer le PlaySessionId
        
        // Mettre à jour la progression toutes les 5 secondes
        playbackObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 5, preferredTimescale: 1),
            queue: .main
        ) { [self] time in
            let positionTicks = Int64(time.seconds * 10_000_000)
            
            // Envoyer la progression au serveur
            Task {
                try? await service.reportPlaybackProgress(
                    itemId: itemId,
                    positionTicks: positionTicks,
                    isPaused: player.timeControlStatus != .playing,
                    playSessionId: sessionId
                )
            }
            
            // Vérifier si on approche de la fin (pour l'autoplay du prochain épisode)
            if let duration = self.item.duration,
               self.nextEpisode != nil,
               !self.showNextEpisodeOverlay,
               self.shouldAutoPlayNext {
                
                let timeRemaining = duration - time.seconds
                
                // Afficher l'overlay 10 secondes avant la fin
                if timeRemaining <= 10 && timeRemaining > 0 {
                    self.showNextEpisodeOverlay = true
                    self.nextEpisodeCountdown = Int(timeRemaining)
                    self.startCountdown()
                }
            }
        }
    }
    

    private func stopPlayback() {
        guard !isStoppingPlayback else {
            return
        }
        
        isStoppingPlayback = true
        
        // Capturer la position AVANT le nettoyage
        var finalPosition: TimeInterval = 0
        
        if let currentPlayer = player {
            let currentTime = currentPlayer.currentTime()
            finalPosition = currentTime.seconds
        }
        
        let positionTicks = Int64(finalPosition * 10_000_000)
        
        // Nettoyer AVANT de signaler l'arrêt
        cleanupPlayback()
        
        // Signaler l'arrêt de la lecture avec la position capturée
        Task {
            do {
                try await jellyfinService.reportPlaybackStopped(
                    itemId: item.id,
                    positionTicks: positionTicks,
                    playSessionId: playSessionId
                )
                
                // Attendre que le serveur traite
                try? await Task.sleep(for: .seconds(2))
                
                await refreshUserData()
                
            } catch {
            }
            
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                self.isStoppingPlayback = false
            }
        }
    }
    
    private func cleanupPlayback() {
        
        // Nettoyer le timer de compte à rebours
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // Réinitialiser l'état de l'autoplay
        showNextEpisodeOverlay = false
        shouldAutoPlayNext = true
        nextEpisodeCountdown = 10
        
        // Nettoyer l'observateur de progression
        if let observer = playbackObserver, let player = player {
            player.removeTimeObserver(observer)
            playbackObserver = nil
        }
        
        // Retirer TOUS les observateurs de notifications pour l'item actuel
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
        
        // Arrêter le lecteur
        if let player = player {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        
        // Nettoyer le player view controller
        if let playerVC = playerViewController {
            playerVC.player = nil
        }
        
        self.player = nil
        self.playerViewController = nil
    }
    
    // MARK: - Lecture automatique du prochain épisode

    /// Task pour le countdown afin d'éviter les race conditions avec Timer
    @State private var countdownTask: Task<Void, Never>?

    private func startCountdown() {
        // Annuler le countdown précédent s'il existe
        countdownTask?.cancel()
        countdownTimer?.invalidate()
        countdownTimer = nil

        // Utiliser une Task async au lieu d'un Timer pour éviter les race conditions
        countdownTask = Task { @MainActor in
            while !Task.isCancelled && nextEpisodeCountdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    nextEpisodeCountdown -= 1
                }
            }

            // Vérifier qu'on n'a pas été annulé avant de lancer l'épisode suivant
            if !Task.isCancelled && shouldAutoPlayNext {
                await playNextEpisode()
            }
        }
    }

    private func playNextEpisode() async {
        guard let nextEpisode = nextEpisode else {
            return
        }

        // Nettoyer le countdown
        countdownTask?.cancel()
        countdownTask = nil
        countdownTimer?.invalidate()
        countdownTimer = nil

        // Masquer l'overlay immédiatement
        showNextEpisodeOverlay = false

        // Arrêter la lecture actuelle
        stopPlayback()

        // Attendre que le cleanup soit terminé
        try? await Task.sleep(for: .seconds(0.3))

        // Fermer le player actuel
        isPlaybackActive = false

        // Utiliser replaceLastWith pour une navigation atomique
        navigationCoordinator.shouldAutoPlay = true
        navigationCoordinator.replaceLastWith(item: nextEpisode)
    }
    
    private func cancelAutoPlay() {
        shouldAutoPlayNext = false
        countdownTask?.cancel()
        countdownTask = nil
        countdownTimer?.invalidate()
        countdownTimer = nil

        withAnimation {
            showNextEpisodeOverlay = false
        }
    }
    
    // MARK: - Utilitaires
    
    private var typeIcon: String {
        switch item.type {
        case "Movie": return "film"
        case "Episode": return "tv"
        default: return "play.rectangle"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - PlayerViewController Representable

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        playerViewController.delegate = context.coordinator
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Pas de mise à jour nécessaire
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        let onDismiss: () -> Void
        
        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
            super.init()
        }
        
        // Cette méthode est appelée quand l'utilisateur quitte le player sur tvOS
        func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
            onDismiss()
            return true
        }
        
        // Pour iOS (n'existe pas sur tvOS)
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

#Preview {
    NavigationStack {
        MediaDetailView(
            item: MediaItem(
                id: "1",
                name: "Film Test",
                type: "Movie",
                overview: "Ceci est un synopsis de test pour démontrer l'affichage des informations du média.",
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
