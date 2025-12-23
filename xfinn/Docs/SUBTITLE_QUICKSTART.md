# 🚀 Guide de démarrage rapide - Sous-titres

## Pour les développeurs qui rejoignent le projet

### 📚 Documents à lire en premier

1. **SUBTITLES_SUMMARY.md** - Vue d'ensemble de l'implémentation
2. **SUBTITLE_IMPLEMENTATION.md** - Détails techniques
3. **Ce document** - Pour commencer rapidement

### 🎯 En 5 minutes : Comment ça marche ?

Les sous-titres dans xfinn fonctionnent en 3 étapes :

1. **Chargement** : Les métadonnées des sous-titres viennent de Jellyfin
2. **Sélection** : L'utilisateur choisit une piste (ou c'est fait automatiquement)
3. **Affichage** : AVPlayer affiche les sous-titres nativement

```swift
// C'est aussi simple que ça !
let subtitles = mediaItem.subtitleStreams  // 1. Obtenir les pistes
selectedSubtitleIndex = subtitles.first?.index  // 2. Sélectionner
// 3. AVPlayer s'occupe du reste quand vous lancez la vidéo
```

---

## 📁 Où trouver le code ?

### Fichiers principaux

| Fichier | Contenu | Lignes clés |
|---------|---------|-------------|
| **MediaDetailView.swift** | UI et logique de sélection | 15-25, 230-280, 600-750 |
| **JellyfinService.swift** | API Jellyfin pour sous-titres | 380-395 |
| **JellyfinModels.swift** | Structure de données | 120-155 |

### Fonctions importantes

```swift
// Dans MediaDetailView.swift

autoSelectSubtitles()              // Auto-sélection intelligente
addExternalSubtitles(to:subtitle:) // Charger les sous-titres externes
enableSubtitlesInPlayer(playerItem:) // Activer dans AVPlayer
selectedSubtitleDisplayName        // Affichage dans l'UI
```

---

## 🔨 Modifications fréquentes

### Changer le format des sous-titres

Actuellement WebVTT, pour ajouter SRT :

```swift
// Dans JellyfinService.swift
func getSubtitleURL(..., format: String = "vtt") -> URL? {
    // Changer "vtt" en "srt" ou ajouter un paramètre
    let urlString = "\(baseURL)/Videos/\(itemId)/\(mediaSourceId)/Subtitles/\(streamIndex)/Stream.\(format)"
    // ...
}
```

### Modifier la logique d'auto-sélection

```swift
// Dans MediaDetailView.swift, fonction autoSelectSubtitles()

// Exemple: Toujours préférer le français
if let frenchSub = item.subtitleStreams.first(where: { $0.language == "fra" }) {
    selectedSubtitleIndex = frenchSub.index
}
```

### Changer l'apparence du bouton

```swift
// Dans MediaDetailView.swift, chercher "Bouton sélecteur de sous-titres"

// Modifier l'icône
Image(systemName: selectedSubtitleIndex != nil ? 
    "captions.bubble.fill" : "captions.bubble")

// Modifier les couleurs
.foregroundColor(selectedSubtitleIndex != nil ? .appPrimary : .appTextPrimary)
.background(selectedSubtitleIndex != nil ? AppTheme.primary.opacity(0.2) : AppTheme.glassBackground)
```

---

## 🐛 Debugging 101

### Problème : Les sous-titres ne s'affichent pas

**Checklist :**
1. Vérifier que `item.subtitleStreams` n'est pas vide
2. Vérifier que `selectedSubtitleIndex` est défini
3. Vérifier les logs dans la console

**Logs à chercher :**
```
📝 Chargement des sous-titres depuis: [URL]
✅ Piste de sous-titres externe chargée
✅ Sous-titres activés: [Nom]
```

**Si rien n'apparaît :**
```swift
// Ajouter ceci dans enableSubtitlesInPlayer()
print("🔍 DEBUG: legibleGroup.options.count = \(legibleGroup.options.count)")
for (index, option) in legibleGroup.options.enumerated() {
    print("  Option \(index): \(option.displayName)")
}
```

### Problème : Le bouton ne s'affiche pas

**Vérifier :**
```swift
// Dans MediaDetailView, chercher cette condition
if !item.subtitleStreams.isEmpty {
    // Le bouton devrait être ici
}

// Ajouter un debug
print("🔍 Nombre de sous-titres: \(item.subtitleStreams.count)")
```

### Problème : La préférence n'est pas sauvegardée

**Vérifier :**
```swift
// Après sélection, vérifier :
let saved = UserDefaults.standard.string(forKey: "preferredSubtitleLanguage")
print("🔍 Langue sauvegardée: \(saved ?? "Aucune")")
```

---

## ✏️ Comment ajouter une nouvelle fonctionnalité ?

### Exemple 1 : Ajouter un indicateur de sous-titres forcés

```swift
// 1. Dans l'UI du bouton
if let index = selectedSubtitleIndex,
   let subtitle = item.subtitleStreams.first(where: { $0.index == index }),
   subtitle.isForced == true {
    Image(systemName: "exclamationmark.circle.fill")
        .foregroundColor(.yellow)
}

// 2. Dans l'alert de sélection
ForEach(item.subtitleStreams) { subtitle in
    Button(action: { /* ... */ }) {
        HStack {
            Text(subtitle.displayName)
            if subtitle.isForced == true {
                Text("(Forcé)")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
    }
}
```

### Exemple 2 : Ajouter un délai de synchronisation

```swift
// 1. Ajouter un @State
@State private var subtitleDelay: TimeInterval = 0.0

// 2. Appliquer le délai au playerItem
func applySubtitleDelay(_ delay: TimeInterval, to playerItem: AVPlayerItem) {
    guard let legibleGroup = playerItem.asset.mediaSelectionGroup(
        forMediaCharacteristic: .legible
    ) else { return }
    
    // Note: Cette fonctionnalité nécessite des APIs plus avancées
    // Voir AVSynchronizedLayer ou AVPlayerItemLegibleOutput
}
```

### Exemple 3 : Ajouter un cache des sous-titres

```swift
// 1. Créer un cache
private var subtitleCache: [String: Data] = [:]

// 2. Dans addExternalSubtitles()
let cacheKey = "\(item.id)_\(subtitle.index)"
if let cachedData = subtitleCache[cacheKey] {
    // Utiliser les données en cache
    return
}

// 3. Après chargement
subtitleCache[cacheKey] = data
```

---

## 🧪 Tests rapides

### Tester manuellement

```swift
// 1. Créer un MediaItem de test avec sous-titres
let testItem = MediaItem(
    id: "test",
    name: "Test Video",
    type: "Movie",
    // ...
    mediaStreams: [
        MediaStream(
            index: 0,
            type: "Subtitle",
            displayTitle: "Français",
            language: "fra",
            codec: "webvtt",
            isDefault: true,
            isForced: false,
            deliveryUrl: nil
        )
    ]
)

// 2. Vérifier
print("Sous-titres disponibles: \(testItem.subtitleStreams.count)")
```

### Tester l'auto-sélection

```swift
// 1. Sauvegarder une préférence
UserDefaults.standard.set("fra", forKey: "preferredSubtitleLanguage")

// 2. Ouvrir une vidéo
// 3. Vérifier que les sous-titres français sont pré-sélectionnés
```

---

## 📖 Ressources

### Documentation Apple
- [AVFoundation Programming Guide](https://developer.apple.com/documentation/avfoundation)
- [AVMediaSelectionGroup](https://developer.apple.com/documentation/avfoundation/avmediaselectiongroup)
- [Working with Media Selection](https://developer.apple.com/documentation/avfoundation/media_playback/selecting_subtitles_and_alternative_audio_tracks)

### Documentation interne
- `SUBTITLE_IMPLEMENTATION.md` - Détails techniques complets
- `SUBTITLE_CODE_EXAMPLES.md` - Exemples de code réutilisables
- `SUBTITLE_ARCHITECTURE_DIAGRAMS.md` - Diagrammes et flux

### API Jellyfin
- Endpoint: `GET /Videos/{itemId}/{mediaSourceId}/Subtitles/{index}/Stream.{format}`
- [Documentation officielle](https://api.jellyfin.org/)

---

## 💡 Tips & Astuces

### 1. Utiliser les breakpoints symboliques
Dans Xcode, ajouter un breakpoint sur toutes les méthodes liées aux sous-titres :
```
MediaDetailView.autoSelectSubtitles
MediaDetailView.addExternalSubtitles
MediaDetailView.enableSubtitlesInPlayer
```

### 2. Surveiller UserDefaults
```swift
// Dans le debugger LLDB
po UserDefaults.standard.dictionaryRepresentation()
```

### 3. Logger les options AVMediaSelection
```swift
// Utile pour voir ce qu'AVPlayer détecte
if let group = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
    print("Options disponibles:")
    group.options.forEach { print("  - \($0.displayName)") }
}
```

### 4. Tester sans réseau
```swift
// Simuler un échec de chargement
func getSubtitleURL(...) -> URL? {
    // return nil  // Décommenter pour tester
    return URL(string: "...")
}
```

---

## 🚨 Erreurs courantes

### Erreur 1 : Fatal error: Index out of range
**Cause :** Accès à un index de sous-titre qui n'existe pas
**Solution :**
```swift
// ❌ Mauvais
let subtitle = item.subtitleStreams[index]

// ✅ Bon
if let subtitle = item.subtitleStreams.first(where: { $0.index == index }) {
    // Utiliser subtitle
}
```

### Erreur 2 : Sous-titres pas synchronisés
**Cause :** Seek dans la vidéo avant que les sous-titres soient chargés
**Solution :** Observer `.readyToPlay` avant de seek

### Erreur 3 : Crash au changement de piste
**Cause :** Tentative de modification alors que le player n'est pas prêt
**Solution :** Vérifier `playerItem.status == .readyToPlay`

---

## ❓ FAQ

**Q : Peut-on avoir plusieurs pistes de sous-titres actives ?**  
R : Non, AVPlayer ne supporte qu'une seule piste à la fois.

**Q : Les sous-titres fonctionnent-ils en Picture-in-Picture ?**  
R : Oui, ils sont gérés nativement par AVPlayer.

**Q : Peut-on personnaliser l'apparence des sous-titres ?**  
R : Les options sont limitées. L'utilisateur peut modifier dans Réglages > Accessibilité.

**Q : Les sous-titres sont-ils téléchargés en entier ?**  
R : Non, ils sont streamés au fur et à mesure comme la vidéo.

**Q : Combien de langues sont supportées ?**  
R : Autant que Jellyfin en fournit pour le média.

---

## 📝 Checklist pour une PR

Avant de soumettre des modifications :

- [ ] Le code compile sans erreurs ni warnings
- [ ] Les logs de debug sont appropriés (pas trop, pas trop peu)
- [ ] Testé avec au moins 3 vidéos différentes
- [ ] Testé avec et sans sous-titres disponibles
- [ ] Testé l'auto-sélection
- [ ] Testé la persistance (fermer/rouvrir l'app)
- [ ] Documentation mise à jour si nécessaire
- [ ] Commentaires de code ajoutés pour les parties complexes

---

## 🎓 Pour aller plus loin

Une fois à l'aise avec les bases :

1. Lire `SUBTITLE_CODE_EXAMPLES.md` pour des patterns avancés
2. Étudier `SUBTITLE_ARCHITECTURE_DIAGRAMS.md` pour l'architecture complète
3. Consulter `SUBTITLE_TESTING_GUIDE.md` pour les scénarios de test
4. Explorer les APIs AVFoundation pour des fonctionnalités avancées

---

**Besoin d'aide ?**  
Consultez les documents de référence ou créez une issue avec :
- Description du problème
- Logs de la console
- Étapes pour reproduire

**Bonne chance ! 🚀**

---

**Dernière mise à jour :** 22 décembre 2024
