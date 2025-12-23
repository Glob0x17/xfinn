# Fix : Reprise de lecture

## Problème identifié

D'après les logs :
```
📊 Vérification userData:
   - Position: 0.0s
   - Ticks: 0
   - Played: false
▶️ Lecture directe (pas de position ou déjà vu)
```

**Le problème** : `item.userData` n'était jamais rafraîchi depuis le serveur après l'arrêt de la lecture. Même si le serveur recevait bien la position (44s), au prochain lancement de la vue, l'objet `item` contenait toujours les anciennes valeurs (0s).

## Solution implémentée

### 1. Ajout d'un état local pour les userData

```swift
@State private var currentUserData: MediaItem.UserData?
```

Cela permet de suivre les données utilisateur indépendamment de l'objet `item` initial.

### 2. Nouvelle méthode dans JellyfinService

Ajout de `getItemDetails(itemId:)` pour récupérer les détails actualisés d'un média :

```swift
func getItemDetails(itemId: String) async throws -> MediaItem {
    guard isAuthenticated else {
        throw JellyfinError.notAuthenticated
    }
    
    var components = URLComponents(string: "\(baseURL)/Users/\(userId)/Items/\(itemId)")!
    components.queryItems = [
        URLQueryItem(name: "Fields", value: "Overview,PrimaryImageAspectRatio")
    ]
    
    var request = URLRequest(url: components.url!)
    request.setValue(authHeaderWithToken, forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let item = try JSONDecoder().decode(MediaItem.self, from: data)
    
    return item
}
```

### 3. Nouvelle méthode de rafraîchissement

Ajout de `refreshUserData()` dans `MediaDetailView` :

```swift
private func refreshUserData() async {
    print("🔄 Rafraîchissement des userData depuis le serveur...")
    do {
        let updatedItem = try await jellyfinService.getItemDetails(itemId: item.id)
        await MainActor.run {
            currentUserData = updatedItem.userData
            
            if let userData = currentUserData {
                print("✅ userData rafraîchies:")
                print("   - Position: \(userData.playbackPosition)s")
                print("   - Ticks: \(userData.playbackPositionTicks)")
                print("   - Played: \(userData.played)")
            } else {
                print("   - Pas de userData disponibles")
            }
        }
    } catch {
        print("❌ Erreur lors du rafraîchissement des userData: \(error)")
    }
}
```

### 4. Rafraîchissements automatiques

Les `userData` sont maintenant rafraîchies :

1. **Au chargement de la vue** (`.onAppear`)
   ```swift
   .onAppear {
       selectedQuality = jellyfinService.preferredQuality
       currentUserData = item.userData
       
       Task {
           await refreshUserData()
       }
   }
   ```

2. **À la sortie de la vue** (`.onDisappear`) si pas en lecture
   ```swift
   .onDisappear {
       if !isPlaybackActive {
           Task {
               await refreshUserData()
           }
       }
   }
   ```

3. **Après l'arrêt de la lecture** (dans `stopPlayback()`)
   ```swift
   try await jellyfinService.reportPlaybackStopped(
       itemId: item.id,
       positionTicks: positionTicks
   )
   print("✅ Arrêt signalé au serveur...")
   
   // Attendre que le serveur traite
   try? await Task.sleep(for: .seconds(0.5))
   
   // Rafraîchir
   await refreshUserData()
   ```

### 5. Utilisation de currentUserData partout

Tous les endroits qui utilisaient `item.userData` utilisent maintenant `currentUserData` :

- Dans le bouton de lecture
- Dans l'affichage de la progression
- Dans la logique de reprise
- Dans l'alerte de reprise
- Dans le démarrage de la lecture

## Flux de données

```
1. Utilisateur lance la lecture
   └─> Lecture pendant 44 secondes
       └─> Utilisateur quitte le player
           └─> stopPlayback() capte 44s
               └─> reportPlaybackStopped() envoie au serveur
                   └─> Serveur sauvegarde 44s
                       └─> refreshUserData() récupère les nouvelles données
                           └─> currentUserData mise à jour avec 44s

2. Utilisateur re-ouvre la vue du média
   └─> onAppear se déclenche
       └─> refreshUserData() récupère depuis le serveur
           └─> currentUserData contient 44s
               └─> showResumeAlert = true
                   └─> Popup "Reprendre à 44s ?"
```

## Tests à effectuer

1. ✅ Lancer une vidéo, l'arrêter après quelques secondes
2. ✅ Vérifier dans les logs que `refreshUserData()` s'exécute
3. ✅ Vérifier que les nouvelles `userData` contiennent la position
4. ✅ Re-cliquer sur le bouton de lecture
5. ✅ Vérifier que la popup de reprise apparaît
6. ✅ Tester "Continuer" et vérifier que la lecture reprend à la bonne position
7. ✅ Tester "Reprendre du début" et vérifier que la lecture démarre à 0

## Logs attendus

Après l'arrêt :
```
⏹️ Arrêt de la lecture demandé
📊 Position actuelle du player: 44s (soit 0min)
✅ Arrêt signalé au serveur à la position 44s (soit 0min)
🔄 Rafraîchissement des userData depuis le serveur...
✅ userData rafraîchies:
   - Position: 44.0s
   - Ticks: 440000000
   - Played: false
```

Au prochain lancement :
```
🔄 Rafraîchissement des userData depuis le serveur...
✅ userData rafraîchies:
   - Position: 44.0s
   - Ticks: 440000000
   - Played: false
📊 Vérification userData:
   - Position: 44.0s
   - Ticks: 440000000
   - Played: false
✅ Affichage de la popup de reprise
```
