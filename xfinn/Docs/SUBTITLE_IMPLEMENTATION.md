# Implémentation des Sous-titres

## 📝 Vue d'ensemble

L'application xfinn prend désormais en charge les sous-titres pour la lecture vidéo. Les sous-titres sont intégrés nativement avec AVPlayer et peuvent être sélectionnés avant ou pendant la lecture.

## ✨ Fonctionnalités

### 1. **Sélection des sous-titres**
- Bouton dédié dans l'interface de détail du média
- Liste de toutes les pistes de sous-titres disponibles
- Option pour désactiver les sous-titres
- Affichage du nom de la piste sélectionnée

### 2. **Auto-sélection intelligente**
- Mémorisation de la langue préférée de l'utilisateur
- Sélection automatique des sous-titres dans la langue préférée pour les prochaines vidéos
- Si aucune langue préférée : sélection des sous-titres marqués comme "par défaut" par Jellyfin

### 3. **Intégration native**
- Utilisation de `AVMediaSelectionGroup` pour gérer les sous-titres
- Support des sous-titres externes (chargés depuis le serveur Jellyfin)
- Pas de transcodage nécessaire (meilleure performance)

### 4. **Interface utilisateur**
- Indicateur visuel quand les sous-titres sont activés (icône remplie + couleur primaire)
- Affichage du nom de la piste sélectionnée
- Design cohérent avec le reste de l'application (glass morphism)

## 🔧 Implémentation technique

### Modèles de données

**MediaStream** (`JellyfinModels.swift`)
```swift
struct MediaStream: Codable, Identifiable {
    let index: Int
    let type: String
    let displayTitle: String?
    let language: String?
    let codec: String?
    let isDefault: Bool?
    let isForced: Bool?
    
    var displayName: String {
        // Affichage intelligent du nom de la piste
    }
}
```

**MediaItem** a une propriété calculée pour récupérer les sous-titres :
```swift
var subtitleStreams: [MediaStream] {
    return mediaStreams?.filter { $0.type == "Subtitle" } ?? []
}
```

### Service Jellyfin

**Méthode `getSubtitleURL`** (`JellyfinService.swift`)
```swift
func getSubtitleURL(itemId: String, mediaSourceId: String, streamIndex: Int, format: String = "vtt") -> URL?
```
Génère l'URL pour télécharger une piste de sous-titres au format WebVTT depuis le serveur Jellyfin.

**Méthode `getStreamURL` modifiée**
Le paramètre `subtitleStreamIndex` a été retiré car les sous-titres sont désormais gérés séparément, pas encodés dans le flux vidéo.

### Vue de détail du média

**États** (`MediaDetailView.swift`)
```swift
@State private var selectedSubtitleIndex: Int? = nil
@State private var preferredSubtitleLanguage: String? = nil
```

**Fonctions principales**

1. **`autoSelectSubtitles()`**
   - Appelée au chargement de la vue
   - Sélectionne automatiquement les sous-titres basés sur la langue préférée
   - Fallback sur les sous-titres par défaut

2. **`addExternalSubtitles(to:subtitle:)`**
   - Charge les sous-titres externes depuis le serveur
   - Crée un `AVURLAsset` pour la piste de sous-titres
   - Les ajoute au `AVPlayerItem`

3. **`enableSubtitlesInPlayer(playerItem:)`**
   - Activée quand le player est prêt (`readyToPlay`)
   - Utilise `AVMediaSelectionGroup` pour trouver les options disponibles
   - Sélectionne la bonne option basée sur la langue ou l'index

### Persistance

Les préférences de l'utilisateur sont sauvegardées dans `UserDefaults` :

```swift
// Sauvegarde
UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")

// Chargement
let savedLanguage = UserDefaults.standard.string(forKey: "preferredSubtitleLanguage")

// Suppression (quand "Aucun" est sélectionné)
UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
```

## 🎨 Design

Le bouton de sous-titres change d'apparence selon l'état :

**Sans sous-titres :**
- Icône : `captions.bubble` (vide)
- Couleur : texte secondaire
- Fond : glass background standard

**Avec sous-titres :**
- Icône : `captions.bubble.fill` (remplie)
- Couleur : primaire (accent)
- Fond : primaire avec opacité
- Bordure : primaire

## 📱 Utilisation

### Pour l'utilisateur

1. Ouvrir les détails d'un média qui contient des sous-titres
2. Cliquer sur le bouton des sous-titres (à côté du sélecteur de qualité)
3. Choisir une piste ou "Aucun"
4. Lancer la lecture
5. Les sous-titres choisis seront automatiquement activés

La prochaine fois qu'une vidéo est visionnée, les sous-titres dans la même langue seront automatiquement sélectionnés.

### Pendant la lecture

Sur tvOS, l'utilisateur peut aussi changer les sous-titres via les contrôles natifs d'AVPlayerViewController :
- Appuyer sur le bouton du menu de la télécommande
- Naviguer vers "Audio et sous-titres"
- Sélectionner la piste désirée

## 🔍 Debugging

Des logs sont intégrés pour faciliter le débogage :

```swift
print("📝 Chargement des sous-titres depuis: \(subtitleURL)")
print("✅ Piste de sous-titres externe chargée")
print("✅ Sous-titres activés: \(option.displayName)")
print("✅ Langue de sous-titres préférée sauvegardée: \(language)")
```

## 🚀 Améliorations futures possibles

1. **Synchronisation avancée** : Ajuster le timing des sous-titres si nécessaire
2. **Style personnalisé** : Permettre à l'utilisateur de changer la taille/couleur des sous-titres
3. **Téléchargement offline** : Sauvegarder les sous-titres avec les vidéos téléchargées
4. **Multi-langues simultanées** : Afficher deux pistes de sous-titres en même temps
5. **Recherche dans les sous-titres** : Permettre de chercher une phrase dans les sous-titres

## ⚠️ Limitations connues

1. **Format** : Seul le format WebVTT est supporté actuellement
2. **Sous-titres embarqués** : Les sous-titres "Burned-in" (intégrés dans la vidéo) ne peuvent pas être désactivés
3. **Sous-titres forcés** : Les sous-titres marqués comme "forcés" ne sont pas traités différemment

## 📚 Références

- [AVFoundation Programming Guide](https://developer.apple.com/documentation/avfoundation)
- [AVMediaSelectionGroup](https://developer.apple.com/documentation/avfoundation/avmediaselectiongroup)
- [Jellyfin API Documentation](https://api.jellyfin.org/)
- [WebVTT Format](https://developer.mozilla.org/en-US/docs/Web/API/WebVTT_API)
