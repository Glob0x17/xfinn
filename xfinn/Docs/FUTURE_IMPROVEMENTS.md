# Améliorations futures recommandées

## 🎯 Priorité 1 : Expérience utilisateur

### 1. Indicateur de chargement

**Problème actuel** : Aucun feedback visuel pendant le chargement de la vidéo

**Solution** :
```swift
struct MediaDetailView: View {
    @State private var isLoadingVideo = false
    
    var body: some View {
        ZStack {
            // ... contenu existant
            
            if isLoadingVideo {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                        
                        Text("Chargement...")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private func startPlayback() {
        isLoadingVideo = true
        
        // ... code existant
        
        // À la fin, après newPlayer.play()
        isLoadingVideo = false
    }
}
```

### 2. Gestion des erreurs utilisateur

**Problème actuel** : Les erreurs sont seulement dans les logs

**Solution** :
```swift
@State private var errorMessage: String?
@State private var showError = false

var body: some View {
    // ... contenu existant
    .alert("Erreur de lecture", isPresented: $showError) {
        Button("OK") {
            showError = false
        }
        Button("Réessayer") {
            startPlayback()
        }
    } message: {
        Text(errorMessage ?? "Une erreur est survenue")
    }
}

private func startPlayback() {
    // ... dans le catch
    catch {
        await MainActor.run {
            errorMessage = "Impossible de lire la vidéo: \(error.localizedDescription)"
            showError = true
            isLoadingVideo = false
        }
    }
}
```

### 3. Contrôles de qualité

**Ajout** : Permettre à l'utilisateur de choisir la qualité

```swift
enum VideoQuality: String, CaseIterable {
    case auto = "Auto"
    case high = "Haute (1080p)"
    case medium = "Moyenne (720p)"
    case low = "Basse (480p)"
    
    var maxBitrate: Int? {
        switch self {
        case .auto: return nil
        case .high: return 8_000_000
        case .medium: return 4_000_000
        case .low: return 1_500_000
        }
    }
}

@State private var selectedQuality: VideoQuality = .auto

// Dans les paramètres de streaming
func getStreamURL(itemId: String, quality: VideoQuality) -> URL? {
    var params = [
        "static": "true",
        "mediaSourceId": itemId,
        "api_key": accessToken
    ]
    
    if let maxBitrate = quality.maxBitrate {
        params["maxStreamingBitrate"] = String(maxBitrate)
    }
    
    // ... reste du code
}
```

## 🎯 Priorité 2 : Performance

### 4. Cache des métadonnées

**Problème** : Les métadonnées sont rechargées à chaque fois

**Solution** :
```swift
class MetadataCache {
    static let shared = MetadataCache()
    
    private var cache: [String: AVMetadataItem] = [:]
    
    func getArtwork(for itemId: String) -> AVMetadataItem? {
        return cache[itemId]
    }
    
    func setArtwork(_ item: AVMetadataItem, for itemId: String) {
        cache[itemId] = item
    }
}

// Utilisation
if let cachedArtwork = MetadataCache.shared.getArtwork(for: item.id) {
    playerItem.externalMetadata.append(cachedArtwork)
} else {
    // Charger et mettre en cache
}
```

### 5. Préchargement

**Ajout** : Précharger la vidéo suivante dans une série

```swift
class PlaybackManager: ObservableObject {
    @Published var currentItem: MediaItem?
    @Published var nextItem: MediaItem?
    
    private var preloadedPlayer: AVPlayer?
    
    func preloadNext(item: MediaItem, service: JellyfinService) {
        guard let streamURL = service.getStreamURL(itemId: item.id) else { return }
        
        let asset = AVURLAsset(url: streamURL)
        
        Task {
            let (isPlayable, _) = try await asset.load(.isPlayable, .duration)
            guard isPlayable else { return }
            
            await MainActor.run {
                let playerItem = AVPlayerItem(asset: asset)
                preloadedPlayer = AVPlayer(playerItem: playerItem)
                nextItem = item
            }
        }
    }
    
    func usePreloadedPlayer() -> AVPlayer? {
        let player = preloadedPlayer
        preloadedPlayer = nil
        nextItem = nil
        return player
    }
}
```

### 6. Gestion du cache réseau

**Ajout** : Configurer le cache URLSession

```swift
extension JellyfinService {
    static func configureNetworkCache() {
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let diskCacheURL = cachesURL.appendingPathComponent("VideoCache")
        
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50 MB
            diskCapacity: 200 * 1024 * 1024,    // 200 MB
            directory: diskCacheURL
        )
        
        URLCache.shared = cache
    }
}
```

## 🎯 Priorité 3 : Fonctionnalités avancées

### 7. Reprise intelligente

**Ajout** : Proposer de reprendre ou recommencer

```swift
@State private var showResumePrompt = false

var body: some View {
    // ... contenu existant
    .alert("Reprendre la lecture ?", isPresented: $showResumePrompt) {
        Button("Reprendre") {
            startPlayback(resume: true)
        }
        Button("Recommencer") {
            startPlayback(resume: false)
        }
        Button("Annuler", role: .cancel) {}
    } message: {
        if let userData = item.userData {
            Text("Vous étiez à \(formatDuration(userData.playbackPosition))")
        }
    }
}

private func checkResumeStatus() {
    if let userData = item.userData, 
       userData.playbackPositionTicks > 0,
       userData.playbackPositionTicks < (item.runTimeTicks ?? 0) - 30_000_000 { // Pas les 30 dernières secondes
        showResumePrompt = true
    } else {
        startPlayback(resume: false)
    }
}
```

### 8. Sélection audio et sous-titres

**Ajout** : Interface pour choisir la piste audio et les sous-titres

```swift
struct TrackSelectionView: View {
    let audioTracks: [AVMediaSelectionOption]
    let subtitleTracks: [AVMediaSelectionOption]
    @Binding var selectedAudio: AVMediaSelectionOption?
    @Binding var selectedSubtitle: AVMediaSelectionOption?
    
    var body: some View {
        List {
            Section("Audio") {
                ForEach(audioTracks, id: \.self) { track in
                    Button(action: { selectedAudio = track }) {
                        HStack {
                            Text(track.displayName)
                            Spacer()
                            if track == selectedAudio {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Section("Sous-titres") {
                Button("Aucun") {
                    selectedSubtitle = nil
                }
                ForEach(subtitleTracks, id: \.self) { track in
                    Button(action: { selectedSubtitle = track }) {
                        HStack {
                            Text(track.displayName)
                            Spacer()
                            if track == selectedSubtitle {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }
}
```

### 9. Chapitres

**Ajout** : Afficher et naviguer entre les chapitres

```swift
extension MediaDetailView {
    func loadChapters() async {
        do {
            let url = URL(string: "\(jellyfinService.baseURL)/Items/\(item.id)/Chapters")!
            var request = URLRequest(url: url)
            request.setValue(jellyfinService.authHeader, forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let chapters = try JSONDecoder().decode([Chapter].self, from: data)
            
            await MainActor.run {
                self.chapters = chapters
            }
        } catch {
            print("⚠️ Impossible de charger les chapitres: \(error)")
        }
    }
}

struct Chapter: Codable {
    let name: String
    let startPositionTicks: Int64
    let imageTag: String?
}
```

### 10. Picture-in-Picture avancé

**Amélioration** : Meilleure gestion du PiP sur tvOS

```swift
extension MediaDetailView {
    func configurePictureInPicture() {
        guard let player = player else { return }
        
        #if os(iOS)
        // Sur iOS, configuration PiP standard
        if AVPictureInPictureController.isPictureInPictureSupported() {
            let pipController = AVPictureInPictureController(playerLayer: playerLayer)
            pipController?.delegate = self
        }
        #endif
        
        // Sur tvOS, configuration spécifique
        #if os(tvOS)
        // tvOS gère automatiquement le PiP
        playerViewController?.allowsPictureInPicturePlayback = true
        #endif
    }
}
```

## 🎯 Priorité 4 : Accessibilité

### 11. VoiceOver

**Ajout** : Support complet de VoiceOver

```swift
// Bouton de lecture
Button(action: startPlayback) {
    HStack {
        Image(systemName: "play.fill")
        Text(item.userData?.played == true ? "Revoir" : "Lire")
    }
}
.accessibilityLabel(item.userData?.played == true ? "Revoir \(item.displayTitle)" : "Lire \(item.displayTitle)")
.accessibilityHint("Démarre la lecture de la vidéo")

// Progression
ProgressView(value: userData.playbackPosition / duration)
    .accessibilityLabel("Progression")
    .accessibilityValue("\(Int((userData.playbackPosition / duration) * 100)) pourcent regardé")
```

### 12. Taille de police dynamique

**Ajout** : Support de la taille de police système

```swift
Text(item.displayTitle)
    .font(.system(size: 50, weight: .bold))
    .minimumScaleFactor(0.5)
    .lineLimit(3)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

## 🎯 Priorité 5 : Expérience tvOS

### 13. Focus Engine

**Amélioration** : Meilleure gestion du focus sur tvOS

```swift
#if os(tvOS)
@FocusState private var focusedButton: FocusableButton?

enum FocusableButton {
    case play, resume, nextEpisode
}

var body: some View {
    // ...
    Button(action: startPlayback) {
        // ...
    }
    .focused($focusedButton, equals: .play)
    .onAppear {
        focusedButton = .play
    }
}
#endif
```

### 14. Menu contextuel

**Ajout** : Menu pour options avancées

```swift
Button(action: startPlayback) {
    // ... bouton play
}
.contextMenu {
    Button(action: {
        startPlayback(resume: false)
    }) {
        Label("Recommencer", systemImage: "arrow.clockwise")
    }
    
    Button(action: {
        markAsWatched()
    }) {
        Label("Marquer comme vu", systemImage: "checkmark.circle")
    }
    
    Button(action: {
        addToFavorites()
    }) {
        Label("Ajouter aux favoris", systemImage: "star")
    }
}
```

## 📊 Métriques et analytics

### 15. Collecte de métriques

**Ajout** : Suivre les performances de lecture

```swift
struct PlaybackMetrics {
    var startTime: Date
    var bufferingEvents: Int = 0
    var stallDuration: TimeInterval = 0
    var averageBitrate: Double = 0
    
    func report() {
        let duration = Date().timeIntervalSince(startTime)
        print("📊 Métriques de lecture:")
        print("   - Durée: \(duration)s")
        print("   - Buffering: \(bufferingEvents) événements")
        print("   - Stall total: \(stallDuration)s")
        print("   - Bitrate moyen: \(averageBitrate) bps")
    }
}
```

## 🎨 Interface utilisateur

### 16. Animations

**Ajout** : Animations fluides pour le chargement

```swift
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
            
            Text("Chargement...")
                .font(.title2)
        }
    }
}
```

### 17. Transitions

**Amélioration** : Transitions plus fluides

```swift
.fullScreenCover(isPresented: $isPlaybackActive) {
    if let playerViewController = playerViewController {
        PlayerViewControllerRepresentable(...)
            .transition(.opacity.combined(with: .scale))
            .ignoresSafeArea()
    }
}
```

## 🔐 Sécurité

### 18. Gestion des certificats SSL

**Ajout** : Support HTTPS avec certificats auto-signés

```swift
class SSLPinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        // Validation du certificat
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                return (.useCredential, URLCredential(trust: serverTrust))
            }
        }
        return (.cancelAuthenticationChallenge, nil)
    }
}
```

## 🧪 Tests

### 19. Tests unitaires

```swift
@Test("Calcul de la durée")
func testFormatDuration() {
    let view = MediaDetailView(item: mockItem, jellyfinService: mockService)
    
    #expect(view.formatDuration(3661) == "1h 1min")
    #expect(view.formatDuration(60) == "1min")
    #expect(view.formatDuration(3600) == "1h 0min")
}
```

### 20. Tests d'intégration

```swift
@Test("Chargement de la vidéo")
func testVideoLoading() async throws {
    let service = JellyfinService()
    try await service.connect(to: "http://demo.jellyfin.org")
    
    let url = service.getStreamURL(itemId: "test-id")
    #expect(url != nil)
}
```

---

Ces améliorations peuvent être implémentées progressivement pour enrichir l'expérience utilisateur !
