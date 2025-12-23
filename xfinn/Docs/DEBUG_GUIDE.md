# 🔍 Guide de débogage rapide - Lecture vidéo sur tvOS

## 📋 Checklist de débogage

Utilisez ce guide pour diagnostiquer rapidement les problèmes de lecture vidéo.

---

## 🚨 Problème : La vidéo ne se lance pas

### Symptômes
- Le bouton "Lire" ne fait rien
- L'écran reste noir
- Message d'erreur "Cannot Open"

### Vérifications

1. **Vérifier l'URL de streaming**
   ```
   Chercher dans les logs : 📺 URL:
   ```
   
   ✅ **Bon** :
   ```
   http://SERVER:8096/Videos/ITEM_ID/master.m3u8?VideoCodec=h264&AudioCodec=aac&...
   ```
   
   ❌ **Mauvais** :
   ```
   http://SERVER:8096/Videos/ITEM_ID/stream?Static=true&...
   ```
   
   **Solution** : Vérifier que `JellyfinService.getStreamURL()` utilise bien `/master.m3u8`

2. **Vérifier le chargement de l'asset**
   ```
   Chercher dans les logs : ✅ Asset chargé
   ```
   
   ✅ **Bon** :
   ```
   ✅ Asset chargé - durée: 2562.685s
   ```
   
   ❌ **Mauvais** :
   ```
   ❌ Erreur lors du chargement de l'asset: Error Domain=AVFoundationErrorDomain Code=-11828
   ```
   
   **Solution** : Le format n'est pas supporté, vérifier que le transcodage HLS est activé

3. **Vérifier l'authentification**
   ```
   Chercher dans les logs : ❌ Impossible d'obtenir l'URL de streaming
   ```
   
   **Solution** : L'utilisateur n'est pas authentifié, vérifier `jellyfinService.isAuthenticated`

---

## 🔊 Problème : Le son continue après avoir quitté

### Symptômes
- Le player se ferme visuellement
- Le son continue de jouer en arrière-plan
- Impossible de revenir à la page précédente

### Vérifications

1. **Vérifier la détection de sortie**
   ```
   Chercher dans les logs : 🔙 L'utilisateur a quitté le player
   ```
   
   ✅ **Bon** :
   ```
   🔙 L'utilisateur a quitté le player
   📺 FullScreenCover fermé
   ⏹️ Arrêt de la lecture
   ```
   
   ❌ **Mauvais** : Aucun message après avoir appuyé sur "retour"
   
   **Solution** : Vérifier que `AVPlayerViewControllerDelegate` est bien implémenté

2. **Vérifier le nettoyage**
   ```
   Chercher dans les logs : 🧹 Nettoyage de la lecture
   ```
   
   ✅ **Bon** :
   ```
   🧹 Nettoyage de la lecture
      ✅ Observateur de progression supprimé
      ✅ Observateurs NotificationCenter supprimés
      ✅ Player mis en pause
      ✅ Player et PlayerViewController libérés
   ```
   
   ❌ **Mauvais** : Aucun message de nettoyage
   
   **Solution** : Vérifier que `cleanupPlayback()` est bien appelé

3. **Vérifier que le player est libéré**
   ```swift
   // Ajouter ce log temporaire dans stopPlayback()
   print("📊 Player avant nettoyage: \(player != nil)")
   cleanupPlayback()
   print("📊 Player après nettoyage: \(player != nil)")
   ```
   
   ✅ **Bon** :
   ```
   📊 Player avant nettoyage: true
   📊 Player après nettoyage: false
   ```

---

## 🖼️ Problème : Les métadonnées ne s'affichent pas

### Symptômes
- Pas de titre dans l'interface de lecture
- Pas d'image de couverture
- Interface générique

### Vérifications

1. **Vérifier le chargement des métadonnées**
   ```
   Chercher dans les logs : ✅ Artwork ajouté aux métadonnées
   ```
   
   ✅ **Bon** :
   ```
   ✅ Artwork ajouté aux métadonnées
   ```
   
   ❌ **Mauvais** :
   ```
   ⚠️ Impossible de charger l'artwork: ...
   ```
   
   **Solution** : Vérifier l'URL de l'image dans `configureExternalMetadata()`

2. **Vérifier l'ordre de chargement**
   
   Les métadonnées doivent être configurées **avant** de démarrer la lecture :
   ```swift
   // Bon ordre :
   let playerItem = AVPlayerItem(asset: asset)
   configureExternalMetadata(for: playerItem)  // ← Avant
   let newPlayer = AVPlayer(playerItem: playerItem)
   newPlayer.play()  // ← Après
   ```

---

## ⏸️ Problème : La progression n'est pas sauvegardée

### Symptômes
- La vidéo reprend toujours au début
- La barre de progression n'apparaît pas
- Le serveur n'enregistre pas la position

### Vérifications

1. **Vérifier les rapports au serveur**
   ```
   Chercher dans les logs : 
   - ✅ Lecture signalée au serveur (au démarrage)
   - ✅ Arrêt signalé au serveur (à la fin)
   ```
   
   Si ces messages n'apparaissent pas, vérifier les fonctions :
   - `reportPlaybackStart()`
   - `reportPlaybackProgress()`
   - `reportPlaybackStopped()`

2. **Vérifier l'observateur de progression**
   ```swift
   // Ajouter ce log temporaire dans setupPlaybackObserver()
   playbackObserver = player.addPeriodicTimeObserver(
       forInterval: CMTime(seconds: 10, preferredTimescale: 1),
       queue: .main
   ) { time in
       print("📊 Progression: \(time.seconds)s")  // ← Ajout temporaire
       // ...
   }
   ```
   
   Vous devriez voir ce message toutes les 10 secondes pendant la lecture.

---

## 🔄 Problème : La reprise ne fonctionne pas

### Symptômes
- La vidéo reprend toujours au début malgré une progression enregistrée
- Le message "Reprendre à X:XX" ne s'affiche pas

### Vérifications

1. **Vérifier que userData existe**
   ```swift
   // Dans MediaDetailView, ajouter ce log temporaire
   if let userData = item.userData {
       print("📊 UserData: playbackPositionTicks=\(userData.playbackPositionTicks)")
       print("📊 Position en secondes: \(userData.playbackPosition)")
   } else {
       print("⚠️ Pas de userData pour cet item")
   }
   ```

2. **Vérifier le seek**
   ```
   Chercher dans les logs : ⏩ Reprise à:
   ```
   
   ✅ **Bon** :
   ```
   ⏩ Reprise à: 1234.56s
   ```
   
   Si ce message n'apparaît pas, vérifier la condition dans `startPlayback()` :
   ```swift
   if let itemUserData = item.userData, itemUserData.playbackPositionTicks > 0 {
       let startTime = CMTime(seconds: itemUserData.playbackPosition, preferredTimescale: 600)
       newPlayer.seek(to: startTime)
       print("⏩ Reprise à: \(itemUserData.playbackPosition)s")
   }
   ```

---

## 🐌 Problème : La vidéo est lente ou saccadée

### Symptômes
- La vidéo se charge lentement
- Buffering fréquent
- Qualité dégradée

### Vérifications

1. **Vérifier les paramètres de transcodage**
   
   Dans `JellyfinService.getStreamURL()`, ajuster :
   ```swift
   URLQueryItem(name: "VideoBitrate", value: "8000000"), // Réduire si nécessaire
   URLQueryItem(name: "MaxWidth", value: "1920"),        // Réduire à 1280 pour 720p
   URLQueryItem(name: "MaxHeight", value: "1080"),       // Réduire à 720 pour 720p
   ```

2. **Vérifier les Access Logs**
   ```
   Chercher dans les logs : 📊 Access Log Events
   ```
   
   Exemple :
   ```
   📊 Access Log Events: 1
      - Indicated Bitrate: 5590467.0
      - Playback Type: VOD
   ```
   
   Si le bitrate est trop élevé pour votre connexion, réduire `VideoBitrate`.

3. **Tester avec Direct Play**
   
   Pour tester si le problème vient du transcodage, essayer temporairement :
   ```swift
   // TEST UNIQUEMENT - À ne pas laisser en production
   var components = URLComponents(string: "\(baseURL)/Videos/\(itemId)/stream")!
   components.queryItems = [
       URLQueryItem(name: "Static", value: "true"),
       URLQueryItem(name: "MediaSourceId", value: itemId),
       URLQueryItem(name: "api_key", value: accessToken)
   ]
   ```
   
   Si cela fonctionne mieux, le problème vient du serveur de transcodage.

---

## 🛠️ Outils de débogage

### 1. Ajouter des logs temporaires

```swift
// Dans startPlayback()
print("📊 Item: \(item.displayTitle)")
print("📊 Type: \(item.type)")
print("📊 Duration: \(item.duration ?? 0)")
print("📊 UserData: \(item.userData != nil)")

// Dans configureExternalMetadata()
print("📊 Métadonnées configurées:")
print("   - Titre: \(item.displayTitle)")
print("   - Description: \(item.overview != nil)")
print("   - Artwork URL: \(jellyfinService.getImageURL(itemId: item.id))")
```

### 2. Utiliser Instruments

Pour détecter les fuites mémoire :
1. Xcode → Product → Profile
2. Choisir "Leaks"
3. Lancer l'app et jouer plusieurs vidéos
4. Vérifier qu'il n'y a pas de fuites

### 3. Analyser les Access Logs

Ajouter ce code pour obtenir plus d'informations :
```swift
NotificationCenter.default.addObserver(
    forName: NSNotification.Name.AVPlayerItemNewAccessLogEntry,
    object: playerItem,
    queue: .main
) { _ in
    if let accessLog = playerItem.accessLog() {
        if let lastEvent = accessLog.events.last {
            print("📊 Access Log:")
            print("   - URI: \(lastEvent.uri ?? "N/A")")
            print("   - Playback Type: \(lastEvent.playbackType ?? "N/A")")
            print("   - Indicated Bitrate: \(lastEvent.indicatedBitrate)")
            print("   - Observed Bitrate: \(lastEvent.observedBitrate)")
            print("   - Number of Stalls: \(lastEvent.numberOfStalls)")
        }
    }
}
```

### 4. Analyser les Error Logs

```swift
NotificationCenter.default.addObserver(
    forName: NSNotification.Name.AVPlayerItemNewErrorLogEntry,
    object: playerItem,
    queue: .main
) { _ in
    if let errorLog = playerItem.errorLog() {
        for event in errorLog.events {
            print("❌ Error Log:")
            print("   - Error Status Code: \(event.errorStatusCode)")
            print("   - Error Domain: \(event.errorDomain)")
            print("   - Error Comment: \(event.errorComment ?? "N/A")")
        }
    }
}
```

---

## 📞 Checklist complète de débogage

Avant de demander de l'aide, vérifier :

- [ ] Les logs contiennent `📺 URL: ... master.m3u8`
- [ ] Les logs contiennent `✅ Asset chargé - durée: XXs`
- [ ] Les logs contiennent `✅ Lecture signalée au serveur`
- [ ] Les logs contiennent `✅ Artwork ajouté aux métadonnées`
- [ ] Le bouton "retour" affiche `🔙 L'utilisateur a quitté le player`
- [ ] Le nettoyage affiche `🧹 Nettoyage de la lecture`
- [ ] Les logs contiennent `✅ Arrêt signalé au serveur`
- [ ] Aucune erreur `❌` dans les logs

Si tous ces points sont vérifiés et que le problème persiste, copier les logs complets et décrire précisément le problème.

---

## 🎯 Messages de logs importants

### ✅ Succès

```
🎬 Démarrage de la lecture pour: [titre]
📺 URL: [URL avec master.m3u8]
✅ Asset chargé - durée: [X]s
📊 Player créé - Status: 0
✅ Artwork ajouté aux métadonnées
✅ Lecture signalée au serveur
```

### ❌ Erreurs

```
❌ Impossible d'obtenir l'URL de streaming
❌ Erreur lors du chargement de l'asset: Error Domain=AVFoundationErrorDomain Code=-11828
❌ Le média n'est pas jouable
⚠️ Impossible de charger l'artwork: [erreur]
```

### 🔙 Sortie du player

```
🔙 L'utilisateur a quitté le player
📺 FullScreenCover fermé
⏹️ Arrêt de la lecture
🧹 Nettoyage de la lecture
   ✅ Observateur de progression supprimé
   ✅ Observateurs NotificationCenter supprimés
   ✅ Player mis en pause
   ✅ Player et PlayerViewController libérés
✅ Arrêt signalé au serveur
```

---

## 📚 Ressources

- [Documentation AVFoundation](https://developer.apple.com/documentation/avfoundation)
- [Guide HLS](https://developer.apple.com/streaming/)
- [API Jellyfin](https://api.jellyfin.org/)
- [Forums Apple Developer](https://developer.apple.com/forums/)

---

**Dernière mise à jour** : 15 décembre 2024
