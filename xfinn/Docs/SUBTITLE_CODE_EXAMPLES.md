# Exemples de code - Sous-titres

## 📚 Guide de référence rapide

Ce document contient des exemples de code réutilisables et des patterns pour travailler avec les sous-titres dans xfinn.

---

## 1. Charger les sous-titres disponibles

### Depuis un MediaItem

```swift
let item: MediaItem = // ... votre item

// Obtenir toutes les pistes de sous-titres
let subtitles = item.subtitleStreams
print("Nombre de pistes : \(subtitles.count)")

// Afficher les informations
for subtitle in subtitles {
    print("Piste \(subtitle.index):")
    print("  Nom: \(subtitle.displayName)")
    print("  Langue: \(subtitle.language ?? "Inconnue")")
    print("  Défaut: \(subtitle.isDefault ?? false)")
    print("  Forcé: \(subtitle.isForced ?? false)")
}
```

### Filtrer par langue

```swift
let frenchSubtitles = item.subtitleStreams.filter { subtitle in
    subtitle.language?.lowercased() == "fra" || 
    subtitle.language?.lowercased() == "french"
}
```

### Trouver les sous-titres par défaut

```swift
let defaultSubtitle = item.subtitleStreams.first { $0.isDefault == true }
```

---

## 2. Gérer les préférences utilisateur

### Sauvegarder la langue préférée

```swift
func saveSubtitlePreference(language: String) {
    UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")
    print("✅ Langue sauvegardée: \(language)")
}
```

### Charger la langue préférée

```swift
func loadSubtitlePreference() -> String? {
    return UserDefaults.standard.string(forKey: "preferredSubtitleLanguage")
}
```

### Supprimer la préférence

```swift
func clearSubtitlePreference() {
    UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
    print("❌ Préférence de sous-titres supprimée")
}
```

---

## 3. Auto-sélection intelligente

### Version simple

```swift
func autoSelectSubtitles(from streams: [MediaStream], preferredLanguage: String?) -> MediaStream? {
    guard let language = preferredLanguage else { return nil }
    
    // Chercher par langue
    return streams.first { subtitle in
        subtitle.language?.lowercased() == language.lowercased()
    }
}
```

### Version avancée (avec fallback)

```swift
func autoSelectSubtitlesAdvanced(from streams: [MediaStream], preferredLanguage: String?) -> MediaStream? {
    guard !streams.isEmpty else { return nil }
    
    // 1. Essayer avec la langue préférée
    if let language = preferredLanguage {
        if let match = streams.first(where: { 
            $0.language?.lowercased() == language.lowercased() 
        }) {
            print("✅ Auto-sélection par langue: \(match.displayName)")
            return match
        }
    }
    
    // 2. Fallback : sous-titres par défaut
    if let defaultSubtitle = streams.first(where: { $0.isDefault == true }) {
        print("✅ Auto-sélection par défaut: \(defaultSubtitle.displayName)")
        return defaultSubtitle
    }
    
    // 3. Fallback : première piste non forcée
    if let firstNonForced = streams.first(where: { $0.isForced != true }) {
        print("ℹ️ Auto-sélection première piste: \(firstNonForced.displayName)")
        return firstNonForced
    }
    
    return nil
}
```

---

## 4. Intégration avec AVPlayer

### Charger une piste de sous-titres externe

```swift
func loadExternalSubtitles(
    jellyfinService: JellyfinService, 
    itemId: String, 
    subtitle: MediaStream
) -> URL? {
    return jellyfinService.getSubtitleURL(
        itemId: itemId,
        mediaSourceId: itemId,
        streamIndex: subtitle.index,
        format: "vtt"
    )
}
```

### Activer les sous-titres dans le player

```swift
func enableSubtitles(in playerItem: AVPlayerItem, language: String?) {
    guard let legibleGroup = playerItem.asset.mediaSelectionGroup(
        forMediaCharacteristic: .legible
    ) else {
        print("⚠️ Aucun groupe de sous-titres disponible")
        return
    }
    
    print("📝 \(legibleGroup.options.count) pistes disponibles")
    
    if let language = language?.lowercased() {
        // Chercher la piste correspondant à la langue
        let matchingOption = legibleGroup.options.first { option in
            option.extendedLanguageTag?.lowercased().contains(language) ?? false
        }
        
        if let option = matchingOption {
            playerItem.select(option, in: legibleGroup)
            print("✅ Sous-titres activés: \(option.displayName)")
        } else {
            print("⚠️ Aucune piste trouvée pour la langue: \(language)")
        }
    } else {
        // Désactiver les sous-titres
        playerItem.select(nil, in: legibleGroup)
        print("❌ Sous-titres désactivés")
    }
}
```

### Obtenir la piste actuellement active

```swift
func getCurrentSubtitle(from playerItem: AVPlayerItem) -> AVMediaSelectionOption? {
    guard let legibleGroup = playerItem.asset.mediaSelectionGroup(
        forMediaCharacteristic: .legible
    ) else {
        return nil
    }
    
    return playerItem.currentMediaSelection.selectedMediaOption(in: legibleGroup)
}
```

---

## 5. Interface utilisateur SwiftUI

### Bouton de sélection simple

```swift
struct SubtitleButton: View {
    let subtitles: [MediaStream]
    @Binding var selectedIndex: Int?
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack {
                Image(systemName: selectedIndex != nil ? 
                    "captions.bubble.fill" : "captions.bubble")
                Text(selectedSubtitleName)
            }
        }
        .alert("Sous-titres", isPresented: $showPicker) {
            Button("Aucun") { selectedIndex = nil }
            ForEach(subtitles) { subtitle in
                Button(subtitle.displayName) {
                    selectedIndex = subtitle.index
                }
            }
            Button("Annuler", role: .cancel) {}
        }
    }
    
    private var selectedSubtitleName: String {
        if let index = selectedIndex,
           let subtitle = subtitles.first(where: { $0.index == index }) {
            return subtitle.displayName
        }
        return "Aucun"
    }
}
```

### Liste de sélection complète

```swift
struct SubtitlePickerView: View {
    let subtitles: [MediaStream]
    @Binding var selectedIndex: Int?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // Option "Aucun"
            Button(action: {
                selectedIndex = nil
                dismiss()
            }) {
                HStack {
                    Text("Aucun")
                    Spacer()
                    if selectedIndex == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Pistes disponibles
            Section("Pistes disponibles") {
                ForEach(subtitles) { subtitle in
                    Button(action: {
                        selectedIndex = subtitle.index
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(subtitle.displayName)
                                    .font(.body)
                                if let language = subtitle.language {
                                    Text(language.uppercased())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if selectedIndex == subtitle.index {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                            if subtitle.isDefault == true {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Sous-titres")
    }
}
```

---

## 6. Gestion des erreurs

### Vérifier la disponibilité des sous-titres

```swift
func validateSubtitleAvailability(
    jellyfinService: JellyfinService,
    itemId: String,
    subtitle: MediaStream
) async -> Bool {
    guard let url = jellyfinService.getSubtitleURL(
        itemId: itemId,
        mediaSourceId: itemId,
        streamIndex: subtitle.index,
        format: "vtt"
    ) else {
        print("❌ URL invalide pour le sous-titre")
        return false
    }
    
    do {
        let (_, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ Erreur HTTP : \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            return false
        }
        
        print("✅ Sous-titre disponible : \(subtitle.displayName)")
        return true
    } catch {
        print("❌ Erreur réseau : \(error.localizedDescription)")
        return false
    }
}
```

### Gérer les timeouts

```swift
func loadSubtitlesWithTimeout(
    url: URL,
    timeout: TimeInterval = 10.0
) async throws -> Data {
    var request = URLRequest(url: url)
    request.timeoutInterval = timeout
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }
    
    return data
}
```

---

## 7. Tests et débogage

### Logger les informations des sous-titres

```swift
func logSubtitleInfo(_ subtitle: MediaStream) {
    print("""
    📝 Sous-titre Info:
       - Index: \(subtitle.index)
       - Nom: \(subtitle.displayName)
       - Langue: \(subtitle.language ?? "N/A")
       - Codec: \(subtitle.codec ?? "N/A")
       - Défaut: \(subtitle.isDefault ?? false)
       - Forcé: \(subtitle.isForced ?? false)
    """)
}
```

### Tester la sélection automatique

```swift
func testAutoSelection() {
    let mockStreams = [
        MediaStream(
            index: 0,
            type: "Subtitle",
            displayTitle: "English",
            language: "eng",
            codec: "webvtt",
            isDefault: false,
            isForced: false,
            deliveryUrl: nil
        ),
        MediaStream(
            index: 1,
            type: "Subtitle",
            displayTitle: "Français",
            language: "fra",
            codec: "webvtt",
            isDefault: true,
            isForced: false,
            deliveryUrl: nil
        )
    ]
    
    // Test 1: Sélection par langue préférée
    let result1 = autoSelectSubtitles(from: mockStreams, preferredLanguage: "fra")
    assert(result1?.index == 1, "Devrait sélectionner le français")
    
    // Test 2: Aucune préférence, sélection par défaut
    let result2 = autoSelectSubtitles(from: mockStreams, preferredLanguage: nil)
    assert(result2?.isDefault == true, "Devrait sélectionner les sous-titres par défaut")
    
    print("✅ Tous les tests passés")
}
```

---

## 8. Optimisations

### Cache des URL de sous-titres

```swift
class SubtitleURLCache {
    private var cache: [String: URL] = [:]
    
    func getURL(for key: String, generator: () -> URL?) -> URL? {
        if let cachedURL = cache[key] {
            return cachedURL
        }
        
        if let newURL = generator() {
            cache[key] = newURL
            return newURL
        }
        
        return nil
    }
    
    func clear() {
        cache.removeAll()
    }
}

// Utilisation
let cache = SubtitleURLCache()
let url = cache.getURL(for: "\(itemId)_\(subtitleIndex)") {
    jellyfinService.getSubtitleURL(
        itemId: itemId,
        mediaSourceId: itemId,
        streamIndex: subtitleIndex,
        format: "vtt"
    )
}
```

### Préchargement des sous-titres

```swift
func preloadSubtitles(for item: MediaItem, jellyfinService: JellyfinService) async {
    for subtitle in item.subtitleStreams {
        guard let url = jellyfinService.getSubtitleURL(
            itemId: item.id,
            mediaSourceId: item.id,
            streamIndex: subtitle.index,
            format: "vtt"
        ) else { continue }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                print("✅ Préchargé: \(subtitle.displayName) (\(data.count) bytes)")
            } catch {
                print("⚠️ Échec préchargement: \(subtitle.displayName)")
            }
        }
    }
}
```

---

## 9. Extensions utiles

### Extension MediaStream

```swift
extension MediaStream {
    var languageCode: String? {
        language?.prefix(3).lowercased().map(String.init)
    }
    
    var isFrench: Bool {
        languageCode == "fra" || language?.lowercased() == "french"
    }
    
    var isEnglish: Bool {
        languageCode == "eng" || language?.lowercased() == "english"
    }
}
```

### Extension AVPlayerItem

```swift
extension AVPlayerItem {
    func availableSubtitleLanguages() -> [String] {
        guard let legibleGroup = asset.mediaSelectionGroup(
            forMediaCharacteristic: .legible
        ) else {
            return []
        }
        
        return legibleGroup.options.compactMap { $0.extendedLanguageTag }
    }
    
    func selectSubtitle(by languageCode: String) {
        guard let legibleGroup = asset.mediaSelectionGroup(
            forMediaCharacteristic: .legible
        ) else {
            return
        }
        
        let option = legibleGroup.options.first { option in
            option.extendedLanguageTag?.lowercased().contains(languageCode.lowercased()) ?? false
        }
        
        select(option, in: legibleGroup)
    }
}
```

---

## 10. Patterns avancés

### Observable Subtitle Manager

```swift
@MainActor
class SubtitleManager: ObservableObject {
    @Published var selectedIndex: Int?
    @Published var availableSubtitles: [MediaStream] = []
    @Published var preferredLanguage: String?
    
    private let userDefaults = UserDefaults.standard
    private let preferenceKey = "preferredSubtitleLanguage"
    
    init() {
        loadPreferences()
    }
    
    func loadPreferences() {
        preferredLanguage = userDefaults.string(forKey: preferenceKey)
    }
    
    func savePreference(language: String) {
        preferredLanguage = language
        userDefaults.set(language, forKey: preferenceKey)
    }
    
    func clearPreference() {
        preferredLanguage = nil
        selectedIndex = nil
        userDefaults.removeObject(forKey: preferenceKey)
    }
    
    func autoSelect(from streams: [MediaStream]) {
        availableSubtitles = streams
        
        guard let language = preferredLanguage else {
            selectedIndex = streams.first(where: { $0.isDefault == true })?.index
            return
        }
        
        selectedIndex = streams.first { subtitle in
            subtitle.language?.lowercased() == language.lowercased()
        }?.index
    }
}
```

---

## 📝 Notes importantes

1. **Toujours vérifier nil** : Les propriétés optionnelles de `MediaStream` peuvent être nil
2. **Gestion asynchrone** : Le chargement des sous-titres peut prendre du temps
3. **Erreurs réseau** : Toujours gérer les cas où le serveur est inaccessible
4. **Performance** : Ne pas charger tous les sous-titres à l'avance
5. **UX** : Fournir du feedback visuel pendant le chargement

---

**Dernière mise à jour :** 22 décembre 2024
