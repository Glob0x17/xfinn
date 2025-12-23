# Corrections pour la lecture vidéo sur tvOS

## Problèmes identifiés et résolus

### 1. ❌ Erreur de compilation : `userData` non défini (ligne 248)
**Problème** : Utilisation d'une variable `userData` hors de son scope  
**Solution** : Renommé en `itemUserData` pour éviter les conflits de noms

### 2. ❌ Erreur de delegate AVPlayerViewController sur tvOS (ligne 398)
**Problème** : La méthode `playerViewController(_:willEndFullScreenPresentationWithAnimationCoordinator:)` n'est pas disponible sur tvOS  
**Solution** : Utilisation de `NotificationCenter` pour observer la fin de lecture avec `.AVPlayerItemDidPlayToEndTime`

### 3. ⚠️ Warnings sur les constantes `resume` et `recent`
**Problème** : Les variables `async let` n'étaient pas utilisées correctement  
**Solution** : Renommé en `resumeTask` et `recentTask` avec `await` explicite

### 4. ⚠️ Warning : `deviceName` non utilisé
**Problème** : Variable déclarée mais jamais utilisée dans `authHeader`  
**Solution** : Supprimé la variable inutile

### 5. 🎬 Problèmes de lecture vidéo sur tvOS

#### 5.1 Métadonnées AVKit non chargées
**Problème** : Les logs montrent `+[AVInfoPanelPlaybackMetadata _metadataItemsForPlayerItem:withAsset:]: metadata has not yet been loaded`

**Solution** :
- Chargement asynchrone de l'asset avec `try await asset.load(.isPlayable, .duration)`
- Application immédiate des métadonnées de base (titre, description)
- Chargement asynchrone séparé de l'artwork
- Ajout de logs pour suivre le chargement

#### 5.2 Erreur MediaRemote Framework
**Problème** : `Operation requires a client callback to have been registered`

**Explication** : Cette erreur est généralement liée au Now Playing Info Center. Pour y remédier :

```swift
// Dans la fonction configureExternalMetadata
private func configureExternalMetadata(for playerItem: AVPlayerItem) {
    // Configuration immédiate des métadonnées de base
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
    
    // Appliquer immédiatement
    playerItem.externalMetadata = metadataItems
    
    // Artwork chargé de manière asynchrone
    // ...
}
```

#### 5.3 Gestion de la fermeture du lecteur
**Solution** : Ajout d'observateurs de fin de lecture et nettoyage approprié

```swift
// Observer la fin de la lecture
NotificationCenter.default.addObserver(
    forName: .AVPlayerItemDidPlayToEndTime,
    object: playerItem,
    queue: .main
) { [weak self] _ in
    print("🏁 Lecture terminée")
    self?.stopPlayback()
}
```

### 6. 🔧 Améliorations apportées

#### Meilleur suivi de la lecture
- Ajout de logs détaillés (`print("🎬 Démarrage..."`, `print("✅ Asset chargé...")`)
- Vérification que l'asset est jouable avant la lecture
- Confirmation de la position de reprise

#### Gestion des erreurs
- Gestion des erreurs de chargement d'asset
- Fallback si l'artwork ne peut pas être chargé
- Messages d'erreur explicites

#### Nettoyage des ressources
- Suppression des observateurs dans `stopPlayback()`
- Libération appropriée du player et du controller

## Tests recommandés

1. ✅ **Lecture depuis l'accueil** : Tester la lecture depuis une miniature
2. ✅ **Lecture depuis la série** : Tester la lecture d'un épisode
3. ✅ **Métadonnées** : Vérifier que le titre et l'image apparaissent dans l'interface tvOS
4. ✅ **Position de reprise** : Vérifier que la lecture reprend au bon endroit
5. ✅ **Progression** : Vérifier que la progression est bien enregistrée

## Problèmes subsistants possibles

### Contraintes Auto Layout
Les logs montrent des conflits de contraintes dans `UIStackView` :
```
Unable to simultaneously satisfy constraints.
UIStackView:0x144973d80.width >= 217
```

**Impact** : Visuel seulement, ne bloque pas la lecture  
**Recommandation** : Vérifier les vues personnalisées si vous en avez

### Clavier sur iPhone
**Problème rapporté** : "Le texte s'effaçait par moment"  
**Cause possible** : Problème de gestion du focus ou de la synchronisation de l'état  
**Solution recommandée** : Vérifier le code du champ de texte dans `LoginView`

### Timeouts "Result accumulator"
**Explication** : Ces timeouts sont liés au système de focus tvOS et sont généralement bénins  
**Recommandation** : Optimiser les vues pour réduire la complexité de la hiérarchie

## Logs à surveiller

Pour vérifier que les corrections fonctionnent, recherchez ces messages dans les logs :

✅ **Succès** :
- `🎬 Démarrage de la lecture pour: [titre]`
- `✅ Asset chargé - durée: [X]s`
- `✅ Lecture signalée au serveur`
- `✅ Artwork ajouté aux métadonnées`

❌ **Problèmes** :
- `❌ Impossible d'obtenir l'URL de streaming`
- `❌ Le média n'est pas jouable`
- `❌ Erreur lors du chargement de l'asset`

## Prochaines étapes

Si la lecture ne fonctionne toujours pas :

1. **Vérifier l'URL de streaming** : Ajouter un log pour voir l'URL complète
2. **Tester avec un autre média** : Vérifier si c'est un problème de format
3. **Vérifier les permissions réseau** : S'assurer que tvOS a accès au serveur Jellyfin
4. **Tester la connexion directe** : Essayer de lire l'URL dans Safari ou VLC

## Code de débogage supplémentaire

Si nécessaire, ajoutez ce code pour plus d'informations :

```swift
// Dans startPlayback(), après la création de l'asset
print("📊 Asset info:")
print("   - URL: \(asset.url)")
print("   - Duration: \(asset.duration.seconds)s")
print("   - Playable: \(asset.isPlayable)")
print("   - Tracks: \(asset.tracks.count)")

// Pour voir les erreurs du player
NotificationCenter.default.addObserver(
    forName: .AVPlayerItemFailedToPlayToEndTime,
    object: playerItem,
    queue: .main
) { notification in
    if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
        print("❌ Erreur de lecture: \(error)")
    }
}
```
