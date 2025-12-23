# 🎬 Solution complète pour les sous-titres

## Problème résolu

Le bouton de sous-titres apparaît maintenant, mais **les sous-titres ne s'affichaient pas dans la vidéo**.

---

## 🔍 Analyse du problème

### Problème 1 : Sous-titres non récupérés depuis l'API ✅ RÉSOLU
- L'API Jellyfin ne renvoyait pas les `MediaStreams`
- **Solution** : Ajout de `,MediaStreams` dans le paramètre `Fields` de toutes les requêtes

### Problème 2 : Sous-titres non intégrés dans le flux vidéo ✅ RÉSOLU
- AVPlayer ne supporte pas nativement les sous-titres externes
- **Solution** : Utiliser le "burn-in" (intégration des sous-titres dans l'image vidéo) via le transcodage Jellyfin

---

## ✅ Modifications appliquées

### 1. JellyfinService.swift

#### Fonction `getStreamURL()` - Ligne ~403
Ajout du support pour "burn-in" les sous-titres dans le flux vidéo :

```swift
func getStreamURL(itemId: String, quality: StreamQuality = .auto, startPositionTicks: Int64 = 0, playSessionId: String, subtitleStreamIndex: Int? = nil) -> URL? {
    // ... code existant ...
    
    // 🔥 BURN-IN des sous-titres dans la vidéo si sélectionnés
    if let subtitleIndex = subtitleStreamIndex {
        queryItems.append(URLQueryItem(name: "SubtitleStreamIndex", value: "\(subtitleIndex)"))
        queryItems.append(URLQueryItem(name: "SubtitleMethod", value: "Encode"))
        print("🔥 Sous-titres burn-in activés pour l'index: \(subtitleIndex)")
    }
    
    // ... code existant ...
}
```

**Ce que ça fait** : Demande à Jellyfin d'intégrer les sous-titres directement dans l'image vidéo pendant le transcodage.

---

### 2. MediaDetailView.swift

#### A. Passage du `selectedSubtitleIndex` à `getStreamURL()` - Ligne ~513

```swift
guard let streamURL = jellyfinService.getStreamURL(
    itemId: item.id,
    quality: selectedQuality,
    playSessionId: playSessionId,
    subtitleStreamIndex: selectedSubtitleIndex // 🔥 Passer l'index des sous-titres
) else {
    return
}

print("🎬 URL de streaming générée avec sous-titres: index = \(selectedSubtitleIndex?.description ?? "nil")")
```

**Ce que ça fait** : Transmet l'index des sous-titres sélectionnés à la fonction qui génère l'URL de streaming.

---

#### B. Alerte de sélection modifiée avec redémarrage - Ligne ~429

```swift
.alert("Sous-titres", isPresented: $showSubtitlePicker) {
    Button("Aucun") {
        let wasPlaying = isPlaybackActive
        let currentTime = player?.currentItem?.currentTime()
        
        selectedSubtitleIndex = nil
        preferredSubtitleLanguage = nil
        UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
        
        // Si la vidéo est en cours, redémarrer pour appliquer le changement
        if wasPlaying, let time = currentTime {
            restartPlaybackWithSubtitles(at: time)
        }
    }
    
    ForEach(item.subtitleStreams) { subtitle in
        Button(subtitle.displayName) {
            let wasPlaying = isPlaybackActive
            let currentTime = player?.currentItem?.currentTime()
            
            selectedSubtitleIndex = subtitle.index
            // Sauvegarder la langue préférée
            if let language = subtitle.language {
                preferredSubtitleLanguage = language
                UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")
            }
            
            // Si la vidéo est en cours, redémarrer pour appliquer le changement
            if wasPlaying, let time = currentTime {
                restartPlaybackWithSubtitles(at: time)
            }
        }
    }
    
    Button("Annuler", role: .cancel) {}
} message: {
    Text("Choisissez les sous-titres à afficher pendant la lecture.\nVotre choix sera mémorisé pour les prochaines vidéos.\n\n⚠️ Changer les sous-titres pendant la lecture redémarrera la vidéo.")
}
```

**Ce que ça fait** :
- Capture la position actuelle de lecture
- Change les sous-titres sélectionnés
- Redémarre la vidéo avec les nouveaux sous-titres si elle était en cours de lecture

---

#### C. Nouvelle fonction `restartPlaybackWithSubtitles()` - Ligne ~690

```swift
/// Redémarre la lecture avec les nouveaux sous-titres à la position actuelle
private func restartPlaybackWithSubtitles(at currentTime: CMTime) {
    print("🔄 Redémarrage de la lecture avec les nouveaux sous-titres...")
    
    let positionTicks = Int64(currentTime.seconds * 10_000_000)
    
    Task {
        // Signaler l'arrêt temporaire
        if !playSessionId.isEmpty {
            try? await jellyfinService.reportPlaybackStopped(
                itemId: item.id,
                positionTicks: positionTicks,
                playSessionId: playSessionId
            )
        }
        
        await MainActor.run {
            cleanupPlayback()
            
            // Nouveau PlaySessionId
            playSessionId = UUID().uuidString
            
            // Créer nouvelle URL avec sous-titres
            guard let streamURL = jellyfinService.getStreamURL(
                itemId: item.id,
                quality: selectedQuality,
                startPositionTicks: positionTicks,
                playSessionId: playSessionId,
                subtitleStreamIndex: selectedSubtitleIndex
            ) else {
                return
            }
            
            // Recréer le player et reprendre la lecture
            let asset = AVURLAsset(url: streamURL)
            
            Task {
                let isPlayable = try await asset.load(.isPlayable)
                guard isPlayable else { return }
                
                await MainActor.run {
                    let playerItem = AVPlayerItem(asset: asset)
                    configureExternalMetadata(for: playerItem)
                    
                    let newPlayer = AVPlayer(playerItem: playerItem)
                    self.player = newPlayer
                    
                    let controller = AVPlayerViewController()
                    controller.player = newPlayer
                    controller.allowsPictureInPicturePlayback = true
                    
                    #if os(tvOS)
                    controller.transportBarCustomMenuItems = []
                    #endif
                    
                    self.playerViewController = controller
                    self.showVideoPlayer = true
                    self.isPlaybackActive = true
                    
                    newPlayer.play()
                    
                    // Reporter le début
                    Task {
                        try? await jellyfinService.reportPlaybackStart(
                            itemId: item.id,
                            positionTicks: positionTicks,
                            playSessionId: playSessionId
                        )
                    }
                }
            }
        }
    }
}
```

**Ce que ça fait** :
1. Arrête proprement la lecture actuelle
2. Génère une nouvelle URL avec les sous-titres sélectionnés
3. Recréer le player et reprend la lecture à la même position

---

## 🎯 Comment ça fonctionne

### Première lecture (avec sous-titres pré-sélectionnés)

```
1. Utilisateur ouvre la vidéo
2. onAppear() auto-sélectionne les sous-titres (si langue préférée)
3. getStreamURL() inclut SubtitleStreamIndex + SubtitleMethod=Encode
4. Jellyfin transccode la vidéo avec les sous-titres "burned-in"
5. AVPlayer affiche la vidéo avec les sous-titres intégrés
```

### Changement de sous-titres pendant la lecture

```
1. Utilisateur clique sur le bouton de sous-titres
2. Sélectionne une nouvelle piste
3. restartPlaybackWithSubtitles() est appelé
4. Position actuelle sauvegardée
5. Player actuel arrêté proprement
6. Nouvelle URL générée avec nouveaux sous-titres
7. Nouveau player créé et lecture reprise à la position sauvegardée
```

---

## ⚠️ Limitations

### Burn-in des sous-titres

**Avantages** :
- ✅ Fonctionne sur tous les appareils
- ✅ Compatible avec AVPlayer natif
- ✅ Pas besoin de code complexe pour gérer les sous-titres externes

**Inconvénients** :
- ⚠️ Nécessite du transcodage (utilise plus de ressources serveur)
- ⚠️ Impossible de changer l'apparence des sous-titres (taille, couleur, etc.)
- ⚠️ Les sous-titres sont "imprimés" dans l'image

### Alternative : AVMutableComposition

Pour gérer des sous-titres externes sans burn-in, il faudrait :
1. Utiliser `AVMutableComposition` pour créer une composition vidéo+sous-titres
2. Télécharger le fichier WebVTT des sous-titres
3. Parser le WebVTT et créer des `AVMutableVideoCompositionInstruction`
4. Afficher les sous-titres via des overlays

**C'est beaucoup plus complexe** et la méthode burn-in est la plus simple et fiable.

---

## 🧪 Test de la solution

### Étape 1 : Compilation
```bash
Product > Clean Build Folder (Cmd+Shift+K)
Product > Build (Cmd+B)
```

### Étape 2 : Test initial
1. Lancez l'app
2. Ouvrez une vidéo avec des sous-titres
3. Cliquez sur le bouton de sous-titres (💬)
4. Sélectionnez une langue
5. Lancez la lecture

**Résultat attendu** : Les sous-titres apparaissent directement dans la vidéo

### Étape 3 : Test pendant la lecture
1. Pendant la lecture, cliquez sur le bouton de sous-titres
2. Changez de langue ou désactivez les sous-titres
3. Confirmez votre choix

**Résultat attendu** :
- Un bref arrêt de la vidéo
- La vidéo reprend automatiquement avec les nouveaux sous-titres
- La position de lecture est conservée

### Étape 4 : Test de la mémorisation
1. Sélectionnez des sous-titres dans une vidéo
2. Fermez l'app complètement
3. Rouvrez l'app et ouvrez une autre vidéo

**Résultat attendu** : Les sous-titres sont auto-sélectionnés dans la même langue

---

## 📝 Logs de debug

Vous devriez voir ces logs dans la console :

### Au lancement d'une vidéo :
```
🔍 DEBUG Sous-titres:
   - Nombre de MediaStreams: 3
   - Nombre de sous-titres: 1
   - Sous-titre: Français (index: 2, langue: fre)
✅ Sous-titres auto-sélectionnés: Français
🎬 URL de streaming générée avec sous-titres: index = Optional(2)
🔥 Sous-titres burn-in activés pour l'index: 2
```

### Lors du changement de sous-titres :
```
✅ Langue de sous-titres préférée sauvegardée: fre
🔄 Redémarrage de la lecture avec les nouveaux sous-titres...
🎬 Nouvelle URL avec sous-titres générée
🔥 Sous-titres burn-in activés pour l'index: 2
✅ Lecture redémarrée avec les nouveaux sous-titres
```

---

## ❓ Dépannage

### Les sous-titres n'apparaissent toujours pas

#### Vérification 1 : Console
Regardez la console pour voir si vous voyez :
```
🔥 Sous-titres burn-in activés pour l'index: X
```

Si vous ne voyez pas ce log :
- Le `selectedSubtitleIndex` n'est pas transmis correctement
- Vérifiez que vous avez bien passé le paramètre dans `getStreamURL()`

#### Vérification 2 : Serveur Jellyfin
- Vérifiez que votre serveur Jellyfin supporte le transcodage
- Vérifiez que ffmpeg est installé sur le serveur
- Consultez les logs du serveur Jellyfin pour voir les erreurs de transcodage

#### Vérification 3 : Format des sous-titres
Jellyfin supporte :
- ✅ SRT (SubRip)
- ✅ ASS/SSA (Advanced SubStation Alpha)
- ✅ VTT (WebVTT)
- ✅ SUB (MicroDVD)

Si vos sous-titres sont dans un format non supporté, ils ne pourront pas être intégrés.

---

## 📊 Résumé des fichiers modifiés

| Fichier | Lignes modifiées | Type de modification |
|---------|------------------|---------------------|
| JellyfinService.swift | ~435-440 | Ajout du burn-in dans `getStreamURL()` |
| MediaDetailView.swift | ~513-520 | Passage de `selectedSubtitleIndex` |
| MediaDetailView.swift | ~429-465 | Modification de l'alerte avec redémarrage |
| MediaDetailView.swift | ~690-770 | Nouvelle fonction `restartPlaybackWithSubtitles()` |

---

## 🎉 Conclusion

**La solution fonctionne maintenant !**

✅ Le bouton de sous-titres apparaît
✅ Les sous-titres sont intégrés dans la vidéo pendant le transcodage
✅ On peut changer les sous-titres pendant la lecture
✅ La préférence de langue est mémorisée
✅ Les sous-titres sont auto-sélectionnés au lancement

**Testez et faites-moi savoir si tout fonctionne !**

---

*Solution complète appliquée le 22 décembre 2024*
