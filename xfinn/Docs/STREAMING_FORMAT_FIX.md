# Correction du problème de format vidéo sur tvOS

## Problème identifié

**Erreur** : `-11828 "Cannot Open" - This media format is not supported`

```
❌ Erreur lors du chargement de l'asset: Error Domain=AVFoundationErrorDomain Code=-11828 "Cannot Open" 
UserInfo={NSLocalizedFailureReason=This media format is not supported.}
```

### Cause

L'URL de streaming utilisait `Static=true`, ce qui signifie que Jellyfin servait le fichier vidéo dans son format original sans transcodage. Le format du fichier (probablement MKV avec des codecs non supportés par tvOS) n'était pas compatible avec AVPlayer sur tvOS.

**URL problématique** :
```
http://192.168.100.48:8096/Videos/{itemId}/stream?Static=true&MediaSourceId={itemId}&api_key={token}
```

### Formats supportés par tvOS/AVPlayer

tvOS supporte nativement ces formats via HTTP Live Streaming (HLS) :
- **Conteneur** : MPEG-TS (.ts) ou MP4 fMP4
- **Vidéo** : H.264 (AVC) ou HEVC (H.265)
- **Audio** : AAC, MP3, AC-3, E-AC-3

## Solution appliquée

### 1. Utilisation du transcodage HLS de Jellyfin

Changement de l'endpoint de streaming de `/stream` vers `/master.m3u8` :

```swift
func getStreamURL(itemId: String) -> URL? {
    guard isAuthenticated else { return nil }
    
    // Utiliser le endpoint de transcodage pour une meilleure compatibilité
    var components = URLComponents(string: "\(baseURL)/Videos/\(itemId)/master.m3u8")!
    components.queryItems = [
        // Codecs compatibles tvOS
        URLQueryItem(name: "VideoCodec", value: "h264"),
        URLQueryItem(name: "AudioCodec", value: "aac"),
        
        // Index des flux (généralement 1)
        URLQueryItem(name: "VideoStreamIndex", value: "1"),
        URLQueryItem(name: "AudioStreamIndex", value: "1"),
        
        // Bitrates
        URLQueryItem(name: "VideoBitrate", value: "8000000"), // 8 Mbps
        URLQueryItem(name: "AudioBitrate", value: "192000"),  // 192 kbps
        
        // Résolution max
        URLQueryItem(name: "MaxWidth", value: "1920"),
        URLQueryItem(name: "MaxHeight", value: "1080"),
        
        // Protocole de transcodage
        URLQueryItem(name: "TranscodingContainer", value: "ts"),
        URLQueryItem(name: "TranscodingProtocol", value: "hls"),
        
        // Identification
        URLQueryItem(name: "MediaSourceId", value: itemId),
        URLQueryItem(name: "DeviceId", value: getDeviceId()),
        URLQueryItem(name: "api_key", value: accessToken)
    ]
    
    return components.url
}
```

### 2. Paramètres expliqués

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `VideoCodec` | `h264` | Codec vidéo H.264, compatible avec tous les appareils Apple |
| `AudioCodec` | `aac` | Codec audio AAC, standard pour tvOS |
| `VideoBitrate` | `8000000` | 8 Mbps, bonne qualité pour 1080p |
| `AudioBitrate` | `192000` | 192 kbps, qualité CD |
| `MaxWidth` / `MaxHeight` | `1920` / `1080` | Résolution Full HD |
| `TranscodingContainer` | `ts` | Conteneur MPEG-TS pour HLS |
| `TranscodingProtocol` | `hls` | HTTP Live Streaming d'Apple |

### 3. Avantages de HLS

✅ **Compatibilité universelle** : Supporté nativement par AVPlayer  
✅ **Streaming adaptatif** : Ajuste la qualité selon la bande passante  
✅ **Démarrage rapide** : Charge les segments progressivement  
✅ **Reprise de lecture** : Peut reprendre facilement après une pause  
✅ **Économie de bande passante** : Transcoder seulement si nécessaire

## Tests à effectuer

### 1. Test de lecture basique
```
1. Ouvrir l'application sur tvOS
2. Sélectionner un épisode (par exemple "Under the Dome - S1E1")
3. Appuyer sur "Lire"
```

**Résultat attendu** :
```
🎬 Démarrage de la lecture pour: Under the Dome - S1E1
📺 URL: http://192.168.100.48:8096/Videos/dfa3c073f2ab40e3afa436cc34f2c9ed/master.m3u8?VideoCodec=h264&AudioCodec=aac...
✅ Asset chargé - durée: XXXXs
✅ Lecture signalée au serveur
```

### 2. Vérifier les logs Jellyfin

Sur votre serveur Jellyfin, vérifiez les logs de transcodage :
```
Dashboard → Activité → En direct → Transcodage
```

Vous devriez voir :
- Le processus de transcodage actif
- Le codec utilisé (H.264)
- Le bitrate
- La progression

### 3. Test de performance réseau

Surveillez l'utilisation réseau :
- **8 Mbps** pour la vidéo en 1080p
- **192 kbps** pour l'audio
- **Total** : ~8.2 Mbps (~1 MB/s)

## Optimisations possibles

### Option 1 : Streaming direct si possible

Pour économiser les ressources du serveur, vous pouvez ajouter une fonction qui essaie d'abord le streaming direct :

```swift
func getPlaybackInfo(itemId: String) async throws -> PlaybackInfo {
    var components = URLComponents(string: "\(baseURL)/Items/\(itemId)/PlaybackInfo")!
    components.queryItems = [
        URLQueryItem(name: "UserId", value: userId),
        URLQueryItem(name: "MaxStreamingBitrate", value: "8000000"),
        URLQueryItem(name: "api_key", value: accessToken)
    ]
    
    var request = URLRequest(url: components.url!)
    request.setValue(authHeaderWithToken, forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let info = try JSONDecoder().decode(PlaybackInfo.self, from: data)
    
    return info
}
```

### Option 2 : Qualité adaptative

Ajoutez des profils de qualité selon la connexion :

```swift
enum StreamQuality {
    case auto
    case high    // 8 Mbps - 1080p
    case medium  // 4 Mbps - 720p
    case low     // 2 Mbps - 480p
    
    var videoBitrate: Int {
        switch self {
        case .auto: return 8_000_000
        case .high: return 8_000_000
        case .medium: return 4_000_000
        case .low: return 2_000_000
        }
    }
    
    var maxHeight: Int {
        switch self {
        case .auto: return 1080
        case .high: return 1080
        case .medium: return 720
        case .low: return 480
        }
    }
}

func getStreamURL(itemId: String, quality: StreamQuality = .auto) -> URL? {
    // Utiliser quality.videoBitrate et quality.maxHeight
    // ...
}
```

### Option 3 : Support des sous-titres

Pour ajouter les sous-titres :

```swift
// Récupérer la liste des sous-titres disponibles
func getSubtitles(itemId: String) async throws -> [SubtitleTrack] {
    // Appel API pour obtenir les sous-titres
}

// Dans les paramètres de streaming
URLQueryItem(name: "SubtitleStreamIndex", value: "1") // Index du sous-titre
URLQueryItem(name: "SubtitleMethod", value: "Encode") // Ou "External"
```

## Configuration serveur Jellyfin recommandée

Pour optimiser le transcodage sur votre serveur :

### 1. Hardware Acceleration

**Dashboard → Playback → Transcoding**
- ✅ Activer l'accélération matérielle (Intel Quick Sync, NVIDIA NVENC, AMD VCE)
- ✅ Configurer le décodage H.264 et H.265

### 2. Streaming Bitrate

**Dashboard → Playback → Streaming**
- Internet streaming bitrate limit : `8 Mbps` (ou plus si votre réseau le permet)
- Allow video playback that requires transcoding : `Activé`

### 3. Codecs par défaut

**Dashboard → Playback → Transcoding**
- Transcoding thread count : `Auto` (ou nombre de cœurs CPU)
- Hardware acceleration : Selon votre matériel
- H264 crf : `23` (qualité par défaut)

## Dépannage

### Le transcodage ne démarre pas

**Symptômes** : Erreur de lecture, pas de transcodage dans les logs

**Solutions** :
1. Vérifier que FFmpeg est installé sur le serveur
2. Vérifier les permissions du dossier de transcodage
3. Vérifier la configuration de l'accélération matérielle

### Qualité vidéo dégradée

**Symptômes** : Vidéo pixelisée, artefacts

**Solutions** :
1. Augmenter `VideoBitrate` (par exemple 10-15 Mbps pour 1080p)
2. Vérifier la qualité du fichier source
3. Vérifier la charge CPU du serveur

### Lecture saccadée (buffering)

**Symptômes** : Pauses fréquentes pendant la lecture

**Solutions** :
1. Réduire `VideoBitrate` (par exemple 4-6 Mbps)
2. Vérifier la bande passante réseau
3. Vérifier la charge du serveur Jellyfin

### Délai de démarrage

**Symptômes** : Temps d'attente long avant le début de la lecture

**Solutions** :
1. Normal pour le transcodage (5-10 secondes)
2. Activer l'accélération matérielle sur le serveur
3. Pré-transcoder les médias populaires

## Références

- [Jellyfin Streaming Documentation](https://jellyfin.org/docs/general/server/media/streaming.html)
- [Apple HTTP Live Streaming](https://developer.apple.com/streaming/)
- [AVFoundation Programming Guide](https://developer.apple.com/documentation/avfoundation)
- [Jellyfin API Reference](https://api.jellyfin.org/)

## Logs attendus après correction

```
🎬 Démarrage de la lecture pour: Under the Dome - S1E1
📺 URL: http://192.168.100.48:8096/Videos/dfa3c073f2ab40e3afa436cc34f2c9ed/master.m3u8?VideoCodec=h264&AudioCodec=aac&VideoStreamIndex=1&AudioStreamIndex=1&VideoBitrate=8000000&AudioBitrate=192000&MaxWidth=1920&MaxHeight=1080&TranscodingContainer=ts&TranscodingProtocol=hls&MediaSourceId=dfa3c073f2ab40e3afa436cc34f2c9ed&DeviceId=xxx&api_key=xxx
✅ Asset chargé - durée: 2580.0s (43 minutes)
⏩ Reprise à: 120.5s (si applicable)
✅ Lecture signalée au serveur
✅ Artwork ajouté aux métadonnées
```

## Prochaines améliorations possibles

1. **Profils de qualité utilisateur** : Permettre à l'utilisateur de choisir la qualité
2. **Direct Play intelligent** : Détecter automatiquement si le transcodage est nécessaire
3. **Pré-buffering** : Charger plus de segments pour réduire le buffering
4. **Statistiques de streaming** : Afficher le bitrate actuel et la mise en mémoire tampon
5. **Support HDR/Dolby Vision** : Pour les appareils compatibles
6. **Audio multicanal** : Support 5.1/7.1 si disponible
7. **Sélection de pistes** : Permettre le changement de pistes audio/sous-titres pendant la lecture

## Conclusion

Cette modification permet maintenant à votre application de lire n'importe quel format vidéo sur tvOS en utilisant le transcodage HLS de Jellyfin. Le serveur convertira automatiquement la vidéo dans un format compatible, garantissant une lecture fluide sur Apple TV.

**Avantages** :
- ✅ Compatibilité universelle avec tous les formats
- ✅ Qualité optimale (1080p @ 8 Mbps)
- ✅ Pas de limite de codec
- ✅ Streaming adaptatif

**Inconvénients** :
- ⚠️ Charge CPU sur le serveur (utilisez l'accélération matérielle)
- ⚠️ Léger délai de démarrage (5-10 secondes)
- ⚠️ Utilisation de bande passante accrue

Pour la plupart des cas d'usage, les avantages l'emportent largement sur les inconvénients !
