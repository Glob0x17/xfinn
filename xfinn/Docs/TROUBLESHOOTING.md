# Guide de dépannage pour la lecture vidéo tvOS

## Diagnostic rapide

### Étape 1 : Vérifier les logs

Recherchez ces messages dans la console Xcode :

#### ✅ Succès attendus
```
🎬 Démarrage de la lecture pour: [Nom du média]
📺 URL: http://[serveur]/Videos/[id]/master.m3u8?...
✅ Asset chargé - durée: XXXXs
✅ Lecture signalée au serveur
✅ Artwork ajouté aux métadonnées
```

#### ❌ Erreurs possibles

| Code d'erreur | Signification | Solution |
|---------------|---------------|----------|
| `-11828` | Cannot Open - Format non supporté | ✅ **CORRIGÉ** : Utilisation de HLS maintenant |
| `-12847` | Erreur de connexion | Vérifier l'URL du serveur et la connectivité |
| `-1100` | URL invalide | Vérifier la configuration du serveur |
| `-1009` | Pas de connexion Internet | Vérifier le réseau |

### Étape 2 : Tester l'URL de streaming

Copiez l'URL complète depuis les logs et testez-la :

#### Option A : Dans Safari sur Mac/iPad
```
http://192.168.100.48:8096/Videos/{itemId}/master.m3u8?VideoCodec=h264&AudioCodec=aac&...
```

Si la vidéo se charge dans Safari, le problème vient de l'app. Sinon, c'est le serveur.

#### Option B : Avec VLC
1. Ouvrir VLC
2. Fichier → Ouvrir un flux réseau
3. Coller l'URL
4. Si ça marche dans VLC, le problème est dans le code de l'app

### Étape 3 : Vérifier la configuration Jellyfin

#### Accès réseau
```bash
# Depuis votre Mac, tester la connexion au serveur
curl http://192.168.100.48:8096/System/Info/Public

# Devrait retourner du JSON avec les infos du serveur
```

#### Dashboard Jellyfin
1. Connectez-vous à l'interface web Jellyfin
2. Dashboard → Playback
3. Vérifiez :
   - ✅ "Allow video playback that requires transcoding" activé
   - ✅ FFmpeg installé et détecté
   - ✅ Hardware acceleration configurée (si disponible)

## Problèmes courants et solutions

### 1. Erreur "-11828 Cannot Open"

**Symptôme** :
```
❌ Erreur lors du chargement de l'asset: Error Domain=AVFoundationErrorDomain Code=-11828 "Cannot Open"
UserInfo={NSLocalizedFailureReason=This media format is not supported.}
```

**Cause** : Format vidéo non supporté par tvOS/AVPlayer

**Solution appliquée** : ✅ Utilisation de HLS avec transcodage automatique

**Vérification** :
- L'URL doit maintenant contenir `/master.m3u8` au lieu de `/stream`
- Doit inclure `VideoCodec=h264` et `AudioCodec=aac`

### 2. Transcodage ne démarre pas

**Symptôme** :
```
🎬 Démarrage de la lecture pour: [média]
📺 URL: http://[serveur]/Videos/[id]/master.m3u8?...
❌ Erreur lors du chargement de l'asset: Error Domain=AVFoundationErrorDomain Code=-1100
```

**Causes possibles** :
1. FFmpeg non installé sur le serveur
2. Permissions insuffisantes pour le dossier de transcodage
3. Serveur Jellyfin surchargé

**Solutions** :

#### Vérifier FFmpeg
```bash
# Sur le serveur Jellyfin
ffmpeg -version

# Devrait retourner la version de FFmpeg
# Si erreur : installer FFmpeg
```

#### Vérifier les logs du serveur
Dans Jellyfin Dashboard → Logs, recherchez :
```
[ERR] Error starting transcoding
[ERR] FFmpeg process exited with code
```

#### Augmenter les ressources
Si le serveur est lent :
- Dashboard → Playback → Transcoding
- Réduire le nombre de threads de transcodage
- Activer l'accélération matérielle

### 3. Lecture saccadée (buffering)

**Symptôme** : La vidéo se met en pause fréquemment

**Causes possibles** :
1. Bande passante insuffisante
2. Serveur surchargé
3. Bitrate trop élevé

**Solutions** :

#### Réduire le bitrate
Dans `JellyfinService.swift`, modifier :
```swift
URLQueryItem(name: "VideoBitrate", value: "4000000"), // De 8 → 4 Mbps
URLQueryItem(name: "MaxHeight", value: "720"),        // De 1080p → 720p
```

#### Tester la bande passante
```bash
# Sur votre Mac, tester le débit vers le serveur
iperf3 -c 192.168.100.48

# Ou simplement télécharger un gros fichier
curl -o /dev/null http://192.168.100.48:8096/Videos/{itemId}/stream?api_key={token}
```

**Bitrate recommandé** :
- 1080p : 6-8 Mbps
- 720p : 3-5 Mbps
- 480p : 1-2 Mbps

### 4. Métadonnées manquantes

**Symptôme** : Pas de titre ou d'image dans le lecteur tvOS

**Solution** : Vérifier que `configureExternalMetadata()` est appelée

Logs attendus :
```
✅ Artwork ajouté aux métadonnées
```

Si absent :
1. Vérifier que l'URL de l'image est correcte
2. Vérifier que le serveur est accessible
3. Vérifier les permissions CORS du serveur

### 5. Délai de démarrage long

**Symptôme** : 10-30 secondes avant le début de la lecture

**Causes** :
1. Le transcodage doit démarrer (normal)
2. Serveur lent
3. Pas d'accélération matérielle

**Solutions** :

#### Activer l'accélération matérielle
Dashboard → Playback → Transcoding :
- **Intel CPU** : Quick Sync Video
- **NVIDIA GPU** : NVENC
- **AMD GPU** : AMF/VCE

#### Pré-transcoder les médias populaires
Dans Jellyfin, planifier le transcodage des médias :
1. Bibliothèques → Tâches planifiées
2. Ajouter "Optimize Media"
3. Configurer pour H.264/AAC

### 6. Audio désynchronisé

**Symptôme** : L'audio ne correspond pas à la vidéo

**Causes** :
1. Problème dans le fichier source
2. Erreur de transcodage
3. Flux audio incorrect

**Solutions** :

#### Vérifier l'index du flux audio
```swift
// Changer l'index du flux audio si nécessaire
URLQueryItem(name: "AudioStreamIndex", value: "1"), // Essayer 0, 1, 2...
```

#### Logs du serveur
Chercher dans les logs Jellyfin :
```
[INF] Audio stream [index] selected for transcoding
```

#### Tester avec un autre épisode
Si le problème persiste sur tous les médias → problème de transcodage
Si seulement sur un média → problème du fichier source

### 7. Erreur "Cannot find 'userData' in scope"

**Symptôme** : Erreur de compilation

**Solution** : ✅ **DÉJÀ CORRIGÉ** dans MediaDetailView.swift

Vérifier que vous utilisez :
```swift
if let itemUserData = item.userData, itemUserData.playbackPositionTicks > 0 {
    // ...
}
```

Au lieu de :
```swift
if let userData = item.userData, userData.playbackPositionTicks > 0 {
    // ...
}
```

### 8. Crash au retour de la lecture

**Symptôme** : L'app crash quand on quitte le lecteur

**Cause** : Observateurs non nettoyés

**Solution** : Vérifier `stopPlayback()` :
```swift
private func stopPlayback() {
    guard let player = player else { return }
    
    // Nettoyer l'observateur périodique
    if let observer = playbackObserver {
        player.removeTimeObserver(observer)
        playbackObserver = nil
    }
    
    // Retirer l'observateur de fin de lecture
    NotificationCenter.default.removeObserver(
        self,
        name: .AVPlayerItemDidPlayToEndTime,
        object: player.currentItem
    )
    
    // Arrêter le lecteur
    player.pause()
    self.player = nil
    self.playerViewController = nil
    isPlaybackActive = false
}
```

## Tests de validation

### Test 1 : Lecture basique
```
✅ Lancer l'app
✅ Sélectionner un média
✅ Appuyer sur "Lire"
✅ Vérifier que la vidéo démarre sous 10 secondes
✅ Vérifier le titre et l'image dans l'interface
```

### Test 2 : Reprise de lecture
```
✅ Commencer à regarder un média
✅ Mettre en pause après 2 minutes
✅ Quitter le lecteur
✅ Revenir sur le média
✅ Vérifier que la barre de progression est visible
✅ Appuyer sur "Lire"
✅ Vérifier que la lecture reprend au bon endroit
```

### Test 3 : Navigation
```
✅ Avancer de 10 secondes (swipe sur la télécommande)
✅ Reculer de 10 secondes
✅ Passer au chapitre suivant (si disponible)
✅ Quitter la lecture (bouton Menu)
✅ Vérifier que l'app revient à l'écran précédent
```

### Test 4 : Qualité réseau
```
✅ Lire un média en 1080p
✅ Observer le buffering (doit être minimal)
✅ Vérifier la qualité de l'image
✅ Vérifier la synchronisation audio/vidéo
```

### Test 5 : Formats variés
```
✅ Tester un fichier MP4 (devrait lire directement)
✅ Tester un fichier MKV (devrait transcoder)
✅ Tester un fichier AVI (devrait transcoder)
✅ Tous doivent fonctionner sans erreur
```

## Commandes de diagnostic

### Vérifier la connexion au serveur
```bash
# Test de connexion
curl http://192.168.100.48:8096/System/Info/Public

# Test d'authentification
curl -X POST http://192.168.100.48:8096/Users/AuthenticateByName \
  -H "Content-Type: application/json" \
  -H "Authorization: MediaBrowser Client=\"Test\", Device=\"Mac\", DeviceId=\"test123\", Version=\"1.0.0\"" \
  -d '{"Username":"votre_user","Pw":"votre_pass"}'
```

### Tester le streaming HLS
```bash
# Télécharger le manifest HLS
curl "http://192.168.100.48:8096/Videos/{itemId}/master.m3u8?api_key={token}"

# Devrait retourner quelque chose comme :
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=8000000
segment.m3u8
```

### Monitorer le transcodage
```bash
# Sur le serveur Jellyfin, voir les processus FFmpeg actifs
ps aux | grep ffmpeg

# Voir l'utilisation CPU
top -p $(pgrep ffmpeg)
```

## Optimisations avancées

### 1. Streaming direct si possible

Pour éviter le transcodage quand ce n'est pas nécessaire, ajoutez cette fonction :

```swift
func canDirectPlay(item: MediaItem) -> Bool {
    // Vérifier si le conteneur et les codecs sont compatibles
    guard let container = item.container?.lowercased() else { return false }
    guard let videoCodec = item.videoCodec?.lowercased() else { return false }
    guard let audioCodec = item.audioCodec?.lowercased() else { return false }
    
    let supportedContainers = ["mp4", "m4v", "mov"]
    let supportedVideoCodecs = ["h264", "hevc"]
    let supportedAudioCodecs = ["aac", "mp3"]
    
    return supportedContainers.contains(container) &&
           supportedVideoCodecs.contains(videoCodec) &&
           supportedAudioCodecs.contains(audioCodec)
}

func getStreamURL(itemId: String, item: MediaItem) -> URL? {
    guard isAuthenticated else { return nil }
    
    if canDirectPlay(item: item) {
        // Direct Play - pas de transcodage
        return getDirectPlayURL(itemId: itemId)
    } else {
        // Transcodage HLS
        return getHLSStreamURL(itemId: itemId)
    }
}
```

### 2. Profils de qualité

Ajoutez un paramètre de qualité :

```swift
enum StreamQuality {
    case auto, high, medium, low
    
    var settings: (bitrate: Int, height: Int) {
        switch self {
        case .auto: return (8_000_000, 1080)
        case .high: return (8_000_000, 1080)
        case .medium: return (4_000_000, 720)
        case .low: return (2_000_000, 480)
        }
    }
}

func getStreamURL(itemId: String, quality: StreamQuality = .auto) -> URL? {
    // Utiliser quality.settings.bitrate et quality.settings.height
}
```

### 3. Monitoring de la bande passante

Ajoutez un observateur pour monitorer la qualité de streaming :

```swift
private func observePlaybackQuality() {
    guard let player = player else { return }
    
    player.currentItem?.addObserver(
        self,
        forKeyPath: "accessLog",
        options: .new,
        context: nil
    )
}

override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?
) {
    if keyPath == "accessLog" {
        if let accessLog = player.currentItem?.accessLog() {
            for event in accessLog.events {
                print("📊 Bitrate: \(event.observedBitrate / 1_000_000) Mbps")
                print("📊 Stalls: \(event.numberOfStalls)")
            }
        }
    }
}
```

## Checklist finale

Avant de déclarer le problème résolu, vérifiez :

- [ ] ✅ L'app compile sans erreurs ni warnings
- [ ] ✅ La lecture démarre sous 10 secondes
- [ ] ✅ Le titre et l'image s'affichent dans le lecteur
- [ ] ✅ La progression est sauvegardée
- [ ] ✅ La reprise de lecture fonctionne
- [ ] ✅ Pas de crash au retour de la lecture
- [ ] ✅ Les logs montrent tous les ✅
- [ ] ✅ Le transcodage fonctionne sur le serveur
- [ ] ✅ La qualité vidéo est correcte
- [ ] ✅ L'audio est synchronisé

## Support et ressources

- **Documentation Jellyfin** : https://jellyfin.org/docs/
- **API Jellyfin** : https://api.jellyfin.org/
- **Apple AVFoundation** : https://developer.apple.com/documentation/avfoundation
- **Apple HLS** : https://developer.apple.com/streaming/

Si le problème persiste après toutes ces vérifications, fournissez :
1. Les logs complets de l'app
2. Les logs du serveur Jellyfin
3. Les informations sur le fichier source (codec, conteneur, résolution)
4. La configuration réseau (WiFi, Ethernet, débit)
