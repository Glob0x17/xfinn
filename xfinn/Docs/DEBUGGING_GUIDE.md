# Guide de débogage de la lecture vidéo

## 📋 Résumé des corrections appliquées

### ✅ Tous les problèmes de compilation résolus

1. **API dépréciée** : Utilisation de la nouvelle API `load()` avec valeurs de retour
2. **Weak self** : Refactorisation pour SwiftUI struct (pas de weak nécessaire)
3. **Result unused** : Capture des valeurs retournées par `load()`
4. **Nettoyage mémoire** : Séparation de `stopPlayback()` et `cleanupPlayback()`

### 📊 Système de débogage ajouté

Le code inclut maintenant un système complet de logs pour diagnostiquer les problèmes de lecture :

```
🎬 Démarrage de la lecture pour: [titre]
📺 URL: [url complète]
✅ Asset chargé - durée: XXXs
📊 Player créé - Status: 0/1/2
📊 Asset duration: XXXs
📊 Player rate: 0.0/1.0
📊 Player status: Unknown/Ready to play/Failed
📊 Access Log Events: X
   - URI: [url]
   - Playback Type: [type]
   - Indicated Bitrate: [bitrate]
⏩ Reprise à: XXXs (si applicable)
✅ Lecture signalée au serveur
✅ Artwork ajouté aux métadonnées
```

## 🔍 Diagnostic des problèmes

### Scénario 1 : L'asset ne se charge pas

**Logs attendus** :
```
🎬 Démarrage de la lecture pour: [titre]
📺 URL: [url]
❌ Le média n'est pas jouable
```

**Causes possibles** :
1. Format de fichier non supporté par tvOS
2. URL incorrecte ou inaccessible
3. Problème réseau

**Solutions** :
- Vérifier que le format est H.264/HEVC
- Tester l'URL dans un navigateur
- Vérifier les paramètres réseau

### Scénario 2 : Le player ne démarre pas

**Logs attendus** :
```
✅ Asset chargé - durée: XXXs
📊 Player créé - Status: 0
📊 Player status: Unknown
📊 Player status: Failed
❌ Player error: [description]
```

**Causes possibles** :
1. Codec non supporté
2. DRM/Protection de contenu
3. Erreur de streaming

**Solutions** :
- Vérifier les logs d'erreur détaillés
- Tester avec un fichier non protégé
- Vérifier les paramètres de transcodage Jellyfin

### Scénario 3 : Le player se bloque

**Logs attendus** :
```
✅ Player status: Ready to play
[Pas de logs d'erreur, mais pas de lecture]
```

**Causes possibles** :
1. Problème de buffering réseau
2. Bande passante insuffisante
3. Serveur Jellyfin surchargé

**Solutions** :
- Vérifier la connexion réseau
- Réduire la qualité de streaming
- Observer les logs du serveur Jellyfin

### Scénario 4 : La lecture démarre puis s'arrête

**Logs attendus** :
```
✅ Player status: Ready to play
📊 Access Log Events: 1
❌ Erreur de lecture: [erreur réseau]
```

**Causes possibles** :
1. Timeout réseau
2. Perte de connexion
3. Buffering insuffisant

**Solutions** :
- Augmenter le buffer
- Vérifier la stabilité du Wi-Fi
- Tester en Ethernet

## 🛠️ Commandes de débogage supplémentaires

### Ajouter plus de logs dans JellyfinService

```swift
func getStreamURL(itemId: String) -> URL? {
    let urlString = "\(baseURL)/Videos/\(itemId)/stream"
    let params = [
        "static": "true",
        "mediaSourceId": itemId,
        "api_key": accessToken
    ]
    
    var components = URLComponents(string: urlString)!
    components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
    
    let finalURL = components.url
    print("🔗 Stream URL construite: \(finalURL?.absoluteString ?? "nil")")
    
    return finalURL
}
```

### Tester la connectivité du serveur

Ajoutez ceci dans `startPlayback()` avant de créer l'asset :

```swift
// Tester la connectivité
Task {
    do {
        let (_, response) = try await URLSession.shared.data(from: streamURL)
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Réponse serveur: \(httpResponse.statusCode)")
            print("📡 Headers: \(httpResponse.allHeaderFields)")
        }
    } catch {
        print("❌ Erreur de connectivité: \(error)")
    }
}
```

### Observer le buffering

```swift
// Observer les changements de buffer
NotificationCenter.default.addObserver(
    forName: .AVPlayerItemPlaybackStalled,
    object: playerItem,
    queue: .main
) { _ in
    print("⏸️ Playback stalled - buffering...")
}

// Observer le buffer vide
NotificationCenter.default.addObserver(
    forName: .AVPlayerItemTimeJumped,
    object: playerItem,
    queue: .main
) { _ in
    print("⏭️ Time jumped")
}
```

## 📝 Checklist de dépannage

Avant de relancer l'application, vérifiez :

- [ ] Le serveur Jellyfin est accessible depuis le réseau
- [ ] L'URL de base est correcte (ex: `http://192.168.1.100:8096`)
- [ ] Le token d'authentification est valide
- [ ] Le média existe bien sur le serveur
- [ ] Le format est supporté par tvOS (H.264, AAC)
- [ ] La connexion réseau est stable (ping < 50ms)
- [ ] Le pare-feu autorise les connexions

## 🎯 Prochaines étapes

1. **Relancer l'application** et observer les nouveaux logs
2. **Copier tous les logs** depuis le début jusqu'à l'erreur
3. **Identifier le scénario** qui correspond à votre situation
4. **Appliquer la solution** recommandée

## 📧 Logs à fournir en cas de problème

Si le problème persiste, fournissez :

1. **Les logs complets** depuis `🎬 Démarrage...` jusqu'à l'erreur
2. **L'URL de streaming** (anonymisée si nécessaire)
3. **Le format du fichier** sur le serveur Jellyfin
4. **La version de tvOS** et du serveur Jellyfin
5. **Configuration réseau** (WiFi/Ethernet, bande passante)

## 🔧 Configuration Jellyfin recommandée

Pour une lecture optimale sur tvOS :

### Paramètres de transcodage
- **Codec vidéo** : H.264 (Level 4.1)
- **Codec audio** : AAC LC
- **Conteneur** : MP4 ou TS
- **Bitrate** : Auto ou 8 Mbps max

### Paramètres réseau
- **Protocole** : HTTP (pas HTTPS pour les tests)
- **Port** : 8096 (par défaut)
- **Buffer** : Augmenter si nécessaire

### Paramètres de sécurité
- **Désactiver HTTPS** pour les tests locaux
- **Autoriser les connexions locales** sans authentification supplémentaire
- **Vérifier les CORS** si applicable

## ✨ Fonctionnalités de débogage actives

Le code inclut maintenant :

1. ✅ **Logs détaillés** à chaque étape
2. ✅ **Observer d'erreurs** pour AVPlayerItem
3. ✅ **Access log** pour analyser le streaming
4. ✅ **Status observer** pour le player
5. ✅ **Logs de buffering** et de stalling
6. ✅ **Vérification de playabilité** avant lecture

Tous ces logs apparaîtront dans la console Xcode pour vous aider à diagnostiquer le problème !
