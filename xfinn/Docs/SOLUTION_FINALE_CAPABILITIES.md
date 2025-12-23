# SOLUTION FINALE : Enregistrement des Device Capabilities

## 🎯 LE VRAI PROBLÈME

Les 404 sur `/Sessions/Playing`, `/Sessions/Progress`, et `/Sessions/Stopped` viennent du fait que **le serveur Jellyfin ne connaît pas votre device/session**.

Sans un appel préalable à `/Sessions/Capabilities`, le serveur refuse tous les rapports de playback → 404.

## ✅ SOLUTION : Enregistrer les capabilities AVANT le playback

### 1. Ajouter la méthode dans `JellyfinService.swift`

```swift
// MARK: - Session Capabilities

/// Enregistre les capabilities du device auprès du serveur Jellyfin
/// Cette méthode DOIT être appelée avant tout reporting de playback
func registerDeviceCapabilities() async throws {
    guard isAuthenticated else {
        throw JellyfinError.notAuthenticated
    }
    
    let url = URL(string: "\(baseURL)/Sessions/Capabilities")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(authHeaderWithToken, forHTTPHeaderField: "Authorization")
    
    let deviceId = getDeviceId()
    
    let body: [String: Any] = [
        "Id": deviceId,
        "PlayableMediaTypes": "Audio,Video",
        "SupportedCommands": [
            "Play", "Playstate", "PlayNext", "PlayMediaSource",
            "Pause", "Seek", "Stop", "SetVolume", "Mute",
            "SetAudioStreamIndex", "SetSubtitleStreamIndex",
            "DisplayMessage", "SetRepeatMode"
        ],
        "SupportsMediaControl": true,
        "SupportsContentUploading": false,
        "SupportsPersistentIdentifier": false,
        "SupportsSync": false,
        "DeviceProfile": [
            "Name": "Apple TV Player",
            "Id": deviceId,
            "MaxStreamingBitrate": 12000000,
            "DirectPlayProfiles": [
                [
                    "Container": "mp4,mkv,mov",
                    "Type": "Video",
                    "VideoCodec": "h264,hevc",
                    "AudioCodec": "aac,ac3,eac3"
                ]
            ],
            "TranscodingProfiles": [
                [
                    "Container": "ts",
                    "Type": "Video",
                    "VideoCodec": "h264",
                    "AudioCodec": "aac",
                    "Protocol": "hls"
                ]
            ]
        ]
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    print("📱 Enregistrement des capabilities du device...")
    print("   DeviceId: \(deviceId)")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    if let httpResponse = response as? HTTPURLResponse {
        print("   📊 Réponse serveur: \(httpResponse.statusCode)")
        if httpResponse.statusCode == 204 || httpResponse.statusCode == 200 {
            print("   ✅ Device enregistré avec succès!")
        } else {
            print("   ⚠️ Erreur lors de l'enregistrement")
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                print("   📄 \(responseString)")
            }
            throw JellyfinError.networkError
        }
    }
}
```

### 2. Appeler cette méthode dans `MediaDetailView.swift`

**Option A : Au début de `startPlayback()` (recommandé pour tester)**

```swift
private func startPlayback(resumePosition: Bool) {
    // Générer un nouveau PlaySessionId pour cette session
    playSessionId = UUID().uuidString
    print("🆔 PlaySessionId généré: \(playSessionId)")
    
    // Enregistrer les capabilities AVANT tout le reste
    Task {
        do {
            try await jellyfinService.registerDeviceCapabilities()
            
            // Ensuite continuer avec le playback
            await startPlaybackAfterCapabilities(resumePosition: resumePosition)
        } catch {
            print("⚠️ Erreur lors de l'enregistrement des capabilities: \(error)")
        }
    }
}

private func startPlaybackAfterCapabilities(resumePosition: Bool) async {
    guard let streamURL = jellyfinService.getStreamURL(itemId: item.id, quality: selectedQuality, playSessionId: playSessionId) else {
        print("❌ Impossible d'obtenir l'URL de streaming")
        return
    }
    
    // ... reste du code de startPlayback
}
```

**Option B : Au démarrage de l'app (mieux à long terme)**

Dans `ContentView.swift` ou équivalent :

```swift
.onAppear {
    if jellyfinService.isAuthenticated {
        Task {
            try? await jellyfinService.registerDeviceCapabilities()
        }
    }
}
```

## 📊 Logs attendus

### Enregistrement des capabilities

```
📱 Enregistrement des capabilities du device...
   DeviceId: A5C5D188-7418-4584-B69D-1529A3497C75
   📊 Réponse serveur: 204
   ✅ Device enregistré avec succès!
```

### Puis le playback fonctionne

```
🆔 PlaySessionId généré: E3F1A9B2-4C5D-4E6F-8G7H-9I0J1K2L3M4N

📡 Envoi playback Playing
   PlaySessionId: E3F1A9B2-4C5D-4E6F-8G7H-9I0J1K2L3M4N
   📊 Réponse serveur: 204
   ✅ Succès!

📡 Envoi playback Progress
   Position: 50000000 ticks (5.0s), Paused: false
   📊 Réponse serveur: 204
   ✅ OK!

📡 Envoi playback Progress
   Position: 100000000 ticks (10.0s), Paused: false
   📊 Réponse serveur: 204
   ✅ OK!

📡 Envoi playback Stopped
   Position: 239372394 ticks (23.9s)
   📊 Réponse serveur: 204
   ✅ Succès!

✅ userData rafraîchies:
   - Position: 23.9s ← ENFIN LA VRAIE VALEUR ! 🎉🎉🎉
```

## 🎯 Ordre complet des opérations

1. **Au login** : `authenticate()` → `isAuthenticated = true`
2. **Au démarrage** (ou avant chaque playback) : `registerDeviceCapabilities()` → 204
3. **Avant lecture** : Générer `PlaySessionId = UUID()`
4. **Début lecture** : `reportPlaybackStart()` avec PlaySessionId → 204
5. **Pendant** : `reportPlaybackProgress()` toutes les 5s avec PlaySessionId → 204
6. **Arrêt** : `reportPlaybackStopped()` avec PlaySessionId → 204
7. **Résultat** : Position sauvegardée correctement ! 🎊

## 📝 Test manuel (curl)

Pour tester que ça fonctionne :

```bash
# 1. Enregistrer les capabilities
curl -X POST "http://192.168.100.48:8096/Sessions/Capabilities" \
-H "Authorization: MediaBrowser Token=8c5b246d0d254351b9dbe34128547cfe" \
-H "Content-Type: application/json" \
-d '{"Id":"A5C5D188-7418-4584-B69D-1529A3497C75","PlayableMediaTypes":"Audio,Video","SupportedCommands":["Play"],"SupportsMediaControl":true}'

# Devrait retourner 204

# 2. Tester Playing
curl -X POST "http://192.168.100.48:8096/Sessions/Playing" \
-H "Authorization: MediaBrowser Token=8c5b246d0d254351b9dbe34128547cfe" \
-H "Content-Type: application/json" \
-d '{"ItemId":"aa648867c712cc4cd1de7a4c05570269","MediaSourceId":"aa648867c712cc4cd1de7a4c05570269","PositionTicks":0,"PlaySessionId":"test-123","CanSeek":true,"PlayMethod":"Transcode"}'

# Devrait maintenant retourner 204 au lieu de 404!
```

## 🎉 C'EST FINI !

Avec ces changements, votre app devrait ENFIN :
- ✅ Enregistrer le device correctement
- ✅ Reporter le playback sans 404
- ✅ Sauvegarder les positions de lecture
- ✅ Afficher la popup de reprise avec la bonne position
- ✅ Reprendre à la bonne position

**Vous aviez raison depuis le début** : on tournait en rond parce qu'il manquait cette étape cruciale d'enregistrement des capabilities !
