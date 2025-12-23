# 🔧 Résolution de problèmes - Sous-titres

## Guide de dépannage pour les développeurs et utilisateurs

---

## 🔍 Table des matières

1. [Les sous-titres ne s'affichent pas](#les-sous-titres-ne-saffichent-pas)
2. [Le bouton de sous-titres est manquant](#le-bouton-de-sous-titres-est-manquant)
3. [L'auto-sélection ne fonctionne pas](#lauto-sélection-ne-fonctionne-pas)
4. [Crash lors de la sélection](#crash-lors-de-la-sélection)
5. [Sous-titres décalés](#sous-titres-décalés)
6. [Performance dégradée](#performance-dégradée)
7. [Problèmes de langues](#problèmes-de-langues)
8. [Erreurs réseau](#erreurs-réseau)

---

## 1. Les sous-titres ne s'affichent pas

### Symptôme
L'utilisateur sélectionne une piste de sous-titres, lance la lecture, mais aucun sous-titre n'apparaît à l'écran.

### Diagnostic

#### Étape 1 : Vérifier que la piste est sélectionnée
```swift
// Dans la console Xcode, chercher :
print("selectedSubtitleIndex: \(selectedSubtitleIndex ?? -1)")
```

**Si nil :**
→ Passer à "L'auto-sélection ne fonctionne pas"

**Si défini :**
→ Passer à l'étape 2

#### Étape 2 : Vérifier le chargement
```swift
// Chercher dans les logs :
"📝 Chargement des sous-titres depuis: [URL]"
```

**Si absent :**
```swift
// Dans MediaDetailView.swift, ajouter :
print("🔍 DEBUG: addExternalSubtitles() appelé ?")
```

**Solution :**
- Vérifier que `continueStartPlayback()` appelle bien `addExternalSubtitles()`
- S'assurer que la condition `if let subtitleIndex = selectedSubtitleIndex` est vraie

#### Étape 3 : Vérifier AVMediaSelectionGroup
```swift
// Dans enableSubtitlesInPlayer(), ajouter :
guard let legibleGroup = playerItem.asset.mediaSelectionGroup(
    forMediaCharacteristic: .legible
) else {
    print("❌ Aucun legibleGroup disponible")
    return
}

print("✅ legibleGroup trouvé avec \(legibleGroup.options.count) options:")
for (i, option) in legibleGroup.options.enumerated() {
    print("  \(i): \(option.displayName) - \(option.extendedLanguageTag ?? "no tag")")
}
```

**Si 0 options :**
- Les sous-titres ne sont pas correctement chargés par AVPlayer
- Vérifier que l'URL du sous-titre est valide
- Vérifier que le serveur retourne bien un fichier WebVTT

**Si > 0 options :**
→ Passer à l'étape 4

#### Étape 4 : Vérifier la sélection de l'option
```swift
// Après playerItem.select(option, in: legibleGroup), ajouter :
let currentSelection = playerItem.currentMediaSelection.selectedMediaOption(in: legibleGroup)
print("🔍 Option actuellement sélectionnée: \(currentSelection?.displayName ?? "Aucune")")
```

**Si "Aucune" :**
- Le select() n'a pas fonctionné
- Essayer de sélectionner la première option disponible :
```swift
if let firstOption = legibleGroup.options.first {
    playerItem.select(firstOption, in: legibleGroup)
}
```

#### Étape 5 : Vérifier le timing
Les sous-titres sont activés trop tôt si le player n'est pas prêt.

```swift
// S'assurer que enableSubtitlesInPlayer() est appelé
// SEULEMENT quand status == .readyToPlay
case .readyToPlay:
    if self.selectedSubtitleIndex != nil {
        self.enableSubtitlesInPlayer(playerItem: playerItem)
    }
```

### Solutions rapides

**Solution 1 : Force la première option**
```swift
// Dans enableSubtitlesInPlayer(), temporairement :
if let firstOption = legibleGroup.options.first {
    playerItem.select(firstOption, in: legibleGroup)
    print("🔧 Force première option: \(firstOption.displayName)")
}
```

**Solution 2 : Utiliser l'encodage**
Si rien ne fonctionne, retour à l'encodage :
```swift
// Dans JellyfinService.getStreamURL(), ajouter :
if let subtitleIndex = subtitleStreamIndex {
    queryItems.append(URLQueryItem(name: "SubtitleStreamIndex", value: "\(subtitleIndex)"))
    queryItems.append(URLQueryItem(name: "SubtitleMethod", value: "Encode"))
}
```
⚠️ Cela forcera le transcodage

---

## 2. Le bouton de sous-titres est manquant

### Symptôme
L'utilisateur ouvre une vidéo qui devrait avoir des sous-titres, mais le bouton n'apparaît pas.

### Diagnostic

#### Étape 1 : Vérifier les métadonnées
```swift
// Ajouter dans MediaDetailView.onAppear() :
print("🔍 Nombre de sous-titres pour \(item.name): \(item.subtitleStreams.count)")
item.subtitleStreams.forEach { sub in
    print("  - \(sub.displayName) (index: \(sub.index))")
}
```

**Si 0 :**
- La vidéo n'a vraiment pas de sous-titres, OU
- Les métadonnées ne sont pas chargées correctement

**Vérifier la requête API :**
```swift
// Dans JellyfinService.getItems() ou getItem()
// S'assurer que "MediaStreams" est dans les Fields :
URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio,MediaStreams")
```

#### Étape 2 : Vérifier la condition d'affichage
```swift
// Dans MediaDetailView, chercher :
if !item.subtitleStreams.isEmpty {
    // Bouton des sous-titres
}

// Remplacer temporairement par :
if true {  // Force l'affichage
    // ...
}
```

Si le bouton apparaît maintenant, le problème est dans `item.subtitleStreams`.

### Solutions

**Solution 1 : Rafraîchir les métadonnées**
```swift
// Au chargement de la vue, forcer un rafraîchissement :
Task {
    let freshItem = try await jellyfinService.getItemDetails(itemId: item.id)
    print("🔄 Métadonnées rafraîchies, sous-titres: \(freshItem.subtitleStreams.count)")
}
```

**Solution 2 : Vérifier le type de média**
```swift
// Certains types de médias peuvent ne pas exposer les sous-titres
print("🔍 Type de média: \(item.type)")
print("🔍 MediaStreams: \(item.mediaStreams?.count ?? 0)")
```

---

## 3. L'auto-sélection ne fonctionne pas

### Symptôme
L'utilisateur a sélectionné une langue de sous-titres, mais elle n'est pas automatiquement sélectionnée pour les vidéos suivantes.

### Diagnostic

#### Étape 1 : Vérifier UserDefaults
```swift
// Dans MediaDetailView.onAppear(), ajouter :
let saved = UserDefaults.standard.string(forKey: "preferredSubtitleLanguage")
print("🔍 Langue préférée sauvegardée: \(saved ?? "Aucune")")
```

**Si "Aucune" :**
- La sauvegarde ne fonctionne pas
- Vérifier dans l'alert :
```swift
Button(subtitle.displayName) {
    selectedSubtitleIndex = subtitle.index
    if let language = subtitle.language {
        UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")
        print("✅ Sauvegardé: \(language)")
    } else {
        print("⚠️ Pas de langue pour ce sous-titre")
    }
}
```

#### Étape 2 : Vérifier autoSelectSubtitles()
```swift
// Ajouter des logs dans autoSelectSubtitles() :
func autoSelectSubtitles() {
    print("🔍 autoSelectSubtitles() appelé")
    print("   - Langue préférée: \(preferredSubtitleLanguage ?? "nil")")
    print("   - Sous-titres disponibles: \(item.subtitleStreams.count)")
    
    guard let preferredLanguage = preferredSubtitleLanguage,
          !item.subtitleStreams.isEmpty else {
        print("   - Conditions non remplies, abandon")
        return
    }
    
    let match = item.subtitleStreams.first { subtitle in
        let result = subtitle.language?.lowercased() == preferredLanguage.lowercased()
        print("   - Test \(subtitle.displayName): \(result)")
        return result
    }
    
    if let match = match {
        selectedSubtitleIndex = match.index
        print("✅ Auto-sélectionné: \(match.displayName)")
    } else {
        print("⚠️ Aucune correspondance trouvée")
    }
}
```

### Solutions

**Solution 1 : Améliorer la correspondance**
```swift
// Correspondance plus flexible :
let match = item.subtitleStreams.first { subtitle in
    guard let subtitleLang = subtitle.language?.lowercased() else { return false }
    let preferredLang = preferredLanguage.lowercased()
    
    // Correspondance exacte
    if subtitleLang == preferredLang { return true }
    
    // Correspondance par code (fra = french)
    if subtitleLang.hasPrefix(preferredLang.prefix(3)) { return true }
    
    // Correspondance dans le displayTitle
    if subtitle.displayTitle?.lowercased().contains(preferredLang) == true { return true }
    
    return false
}
```

**Solution 2 : Fallback amélioré**
```swift
// Si aucune correspondance exacte, utiliser isDefault
if selectedSubtitleIndex == nil,
   let defaultSubtitle = item.subtitleStreams.first(where: { $0.isDefault == true }) {
    selectedSubtitleIndex = defaultSubtitle.index
    print("ℹ️ Utilisation du sous-titre par défaut")
}
```

---

## 4. Crash lors de la sélection

### Symptôme
L'application crash quand l'utilisateur sélectionne un sous-titre ou lance la lecture.

### Diagnostic

#### Type 1 : Index out of range
```
Fatal error: Index out of range
```

**Cause :** Accès direct à un tableau avec un index invalide.

**Vérifier :**
```swift
// ❌ Ne JAMAIS faire :
let subtitle = item.subtitleStreams[selectedSubtitleIndex!]

// ✅ TOUJOURS faire :
if let index = selectedSubtitleIndex,
   let subtitle = item.subtitleStreams.first(where: { $0.index == index }) {
    // Utiliser subtitle
}
```

#### Type 2 : Force unwrap of nil
```
Fatal error: Unexpectedly found nil while unwrapping an Optional value
```

**Causes possibles :**
- `jellyfinService.getSubtitleURL()` retourne nil
- `playerItem.asset.mediaSelectionGroup()` retourne nil

**Solution :**
```swift
// Toujours utiliser if let ou guard let
guard let subtitleURL = jellyfinService.getSubtitleURL(...) else {
    print("⚠️ URL invalide, abandon")
    return
}
```

#### Type 3 : Main actor isolation
```
Call to main actor-isolated function cannot be done from nonisolated context
```

**Solution :**
```swift
// Wrapper dans MainActor.run :
await MainActor.run {
    self.selectedSubtitleIndex = subtitle.index
}
```

### Solutions

**Solution préventive : Defensive programming**
```swift
func safelySelectSubtitle(index: Int) {
    guard !item.subtitleStreams.isEmpty else {
        print("⚠️ Aucun sous-titre disponible")
        return
    }
    
    guard item.subtitleStreams.contains(where: { $0.index == index }) else {
        print("⚠️ Index invalide: \(index)")
        return
    }
    
    selectedSubtitleIndex = index
    print("✅ Sélection sécurisée: index \(index)")
}
```

---

## 5. Sous-titres décalés

### Symptôme
Les sous-titres s'affichent avec un décalage par rapport à l'audio/vidéo.

### Diagnostic

**Causes possibles :**
1. Fichier de sous-titres mal synchronisé (problème serveur)
2. Seek dans la vidéo pendant le chargement des sous-titres
3. Buffering réseau

### Solutions

**Solution 1 : Vérifier le fichier source**
- Télécharger le fichier WebVTT manuellement
- Vérifier les timestamps dans le fichier
- Si incorrect → problème serveur Jellyfin

**Solution 2 : Attendre le chargement complet**
```swift
// Ne pas seek tant que le player n'est pas prêt
if resumePosition, let itemUserData = currentUserData, itemUserData.playbackPositionTicks > 0 {
    // Attendre que le status soit .readyToPlay
    Task {
        for await status in playerItem.publisher(for: \.status).values {
            if status == .readyToPlay {
                await MainActor.run {
                    let startTime = CMTime(seconds: itemUserData.playbackPosition, preferredTimescale: 600)
                    newPlayer.seek(to: startTime)
                }
                break
            }
        }
    }
}
```

**Solution 3 : Recharger les sous-titres**
```swift
// Fonction pour recharger
func reloadSubtitles() {
    guard let playerItem = player?.currentItem,
          let legibleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
        return
    }
    
    // Désactiver
    playerItem.select(nil, in: legibleGroup)
    
    // Réactiver après un délai
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if let option = legibleGroup.options.first {
            playerItem.select(option, in: legibleGroup)
        }
    }
}
```

---

## 6. Performance dégradée

### Symptôme
La lecture vidéo est saccadée ou le chargement est lent quand les sous-titres sont activés.

### Diagnostic

#### Vérifier si le transcodage est actif
```swift
// Dans les logs, chercher :
// Si vous voyez des logs de transcodage, c'est mauvais signe
```

**Vérifier dans getStreamURL() :**
```swift
// S'assurer que SubtitleMethod n'est PAS "Encode"
// La fonction actuelle ne devrait PAS avoir de paramètre subtitleStreamIndex
```

#### Mesurer le temps de chargement
```swift
let start = Date()
// ... chargement des sous-titres ...
let elapsed = Date().timeIntervalSince(start)
print("⏱ Temps de chargement: \(elapsed)s")
```

### Solutions

**Solution 1 : Préchargement**
```swift
// Charger les sous-titres en avance
Task {
    if let subtitleURL = jellyfinService.getSubtitleURL(...) {
        _ = try? await URLSession.shared.data(from: subtitleURL)
        print("✅ Sous-titres préchargés")
    }
}
```

**Solution 2 : Cache**
```swift
private var subtitleDataCache: [String: Data] = [:]

func getCachedSubtitleData(for key: String, loader: () async throws -> Data) async throws -> Data {
    if let cached = subtitleDataCache[key] {
        return cached
    }
    let data = try await loader()
    subtitleDataCache[key] = data
    return data
}
```

**Solution 3 : Timeout**
```swift
var request = URLRequest(url: subtitleURL)
request.timeoutInterval = 5.0  // 5 secondes max
```

---

## 7. Problèmes de langues

### Symptôme
Les noms de langues s'affichent mal, ou les langues ne sont pas reconnues.

### Diagnostic

#### Vérifier les codes de langue
```swift
// Pour chaque sous-titre :
print("🔍 Sous-titre:")
print("  displayTitle: \(subtitle.displayTitle ?? "nil")")
print("  language: \(subtitle.language ?? "nil")")
```

**Codes possibles :**
- "fra" (ISO 639-2)
- "fr" (ISO 639-1)
- "French" (nom complet)
- "fre" (variante)

### Solutions

**Solution 1 : Normalisation**
```swift
extension MediaStream {
    var normalizedLanguageCode: String? {
        guard let lang = language?.lowercased() else { return nil }
        
        // Convertir en code ISO 639-1 (2 lettres)
        switch lang {
        case "fra", "french", "français": return "fr"
        case "eng", "english": return "en"
        case "spa", "spanish", "español": return "es"
        // ... autres langues
        default: return lang.prefix(2).map(String.init)
        }
    }
}
```

**Solution 2 : Affichage localisé**
```swift
extension MediaStream {
    var localizedLanguageName: String {
        guard let code = normalizedLanguageCode else {
            return displayTitle ?? "Inconnu"
        }
        
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code)?.capitalized ?? code.uppercased()
    }
}

// Utilisation
Text(subtitle.localizedLanguageName)  // → "Français" au lieu de "fra"
```

---

## 8. Erreurs réseau

### Symptôme
Messages d'erreur de type "Failed to load", "Network error", etc.

### Diagnostic

#### Vérifier l'URL
```swift
if let url = jellyfinService.getSubtitleURL(itemId: item.id, mediaSourceId: item.id, streamIndex: subtitle.index) {
    print("🔍 URL des sous-titres: \(url.absoluteString)")
    
    // Tester manuellement
    Task {
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            print("✅ Serveur répond: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        } catch {
            print("❌ Erreur: \(error.localizedDescription)")
        }
    }
}
```

### Solutions

**Solution 1 : Retry avec backoff**
```swift
func loadSubtitlesWithRetry(url: URL, maxAttempts: Int = 3) async throws -> Data {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Chargé après \(attempt) tentative(s)")
            return data
        } catch {
            lastError = error
            print("⚠️ Tentative \(attempt) échouée")
            
            if attempt < maxAttempts {
                let delay = TimeInterval(attempt)  // 1s, 2s, 3s
                try await Task.sleep(for: .seconds(delay))
            }
        }
    }
    
    throw lastError ?? URLError(.unknown)
}
```

**Solution 2 : Fallback**
```swift
// Si le chargement échoue, continuer sans sous-titres
do {
    try await loadSubtitles()
} catch {
    print("⚠️ Impossible de charger les sous-titres: \(error.localizedDescription)")
    print("ℹ️ Lecture sans sous-titres")
    // Ne pas bloquer la lecture
}
```

---

## 🛠 Outils de diagnostic

### Script de test complet

```swift
func diagnoseSubtitles(item: MediaItem, jellyfinService: JellyfinService) {
    print("=" * 50)
    print("DIAGNOSTIC DES SOUS-TITRES")
    print("=" * 50)
    
    print("\n1. MÉTADONNÉES")
    print("   Nombre de pistes: \(item.subtitleStreams.count)")
    for (i, sub) in item.subtitleStreams.enumerated() {
        print("   [\(i)] \(sub.displayName)")
        print("       - Index: \(sub.index)")
        print("       - Langue: \(sub.language ?? "nil")")
        print("       - Codec: \(sub.codec ?? "nil")")
        print("       - Défaut: \(sub.isDefault ?? false)")
    }
    
    print("\n2. PRÉFÉRENCES")
    let savedLang = UserDefaults.standard.string(forKey: "preferredSubtitleLanguage")
    print("   Langue sauvegardée: \(savedLang ?? "Aucune")")
    
    print("\n3. URLs")
    for sub in item.subtitleStreams {
        if let url = jellyfinService.getSubtitleURL(
            itemId: item.id,
            mediaSourceId: item.id,
            streamIndex: sub.index
        ) {
            print("   [\(sub.index)] \(url.absoluteString)")
        } else {
            print("   [\(sub.index)] ❌ URL invalide")
        }
    }
    
    print("\n4. TESTS RÉSEAU")
    Task {
        for sub in item.subtitleStreams {
            guard let url = jellyfinService.getSubtitleURL(
                itemId: item.id,
                mediaSourceId: item.id,
                streamIndex: sub.index
            ) else { continue }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("   [\(sub.index)] ✅ \(statusCode) - \(data.count) bytes")
            } catch {
                print("   [\(sub.index)] ❌ \(error.localizedDescription)")
            }
        }
    }
    
    print("=" * 50)
}
```

**Utilisation :**
```swift
// Dans MediaDetailView.onAppear()
#if DEBUG
diagnoseSubtitles(item: item, jellyfinService: jellyfinService)
#endif
```

---

## 📞 Obtenir de l'aide

Si aucune de ces solutions ne fonctionne :

1. **Collecter les informations** :
   - Logs de la console
   - Version d'iOS/tvOS
   - Version du serveur Jellyfin
   - Format des sous-titres
   - Étapes pour reproduire

2. **Créer une issue** avec ces informations

3. **Documents de référence** :
   - `SUBTITLE_IMPLEMENTATION.md` pour les détails techniques
   - `SUBTITLE_CODE_EXAMPLES.md` pour des exemples
   - `SUBTITLE_TESTING_GUIDE.md` pour les tests

---

**Dernière mise à jour :** 22 décembre 2024
