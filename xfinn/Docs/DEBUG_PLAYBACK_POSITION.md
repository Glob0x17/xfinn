# Debug : Sauvegarde de la position de lecture

## Problème observé

Les logs montrent que :
1. ✅ La position est bien capturée : `📊 Position actuelle du player: 257s`
2. ✅ L'arrêt est signalé : `✅ Arrêt signalé au serveur à la position 257s`
3. ✅ Le rafraîchissement se fait : `🔄 Rafraîchissement des userData depuis le serveur...`
4. ❌ **MAIS** les données récupérées sont à 0 : `Position: 0.0s, Ticks: 0`

## Causes possibles

1. **Le serveur Jellyfin ne reçoit pas correctement la requête d'arrêt**
2. **Le serveur prend du temps à traiter et sauvegarder**
3. **Il manque un paramètre dans la requête**
4. **Le serveur renvoie une erreur silencieuse**

## Modifications apportées pour déboguer

### 1. Logs détaillés dans `updatePlaybackProgress`

Ajout de logs pour voir exactement ce qui est envoyé au serveur :

```swift
print("📡 Envoi playback \(endpoint) - ItemId: \(itemId), Position: \(positionTicks) ticks (\(Double(positionTicks) / 10_000_000.0)s)")
print("   URL: \(components.url?.absoluteString ?? "N/A")")

let (data, response) = try await URLSession.shared.data(for: request)

if let httpResponse = response as? HTTPURLResponse {
    print("   📊 Réponse serveur: \(httpResponse.statusCode)")
    if httpResponse.statusCode != 204 && httpResponse.statusCode != 200 {
        print("   ⚠️ Code de statut inattendu!")
        if let responseString = String(data: data, encoding: .utf8) {
            print("   📄 Réponse: \(responseString)")
        }
    }
}
```

### 2. Logs détaillés dans `getItemDetails`

Pour voir exactement ce que le serveur renvoie :

```swift
print("🔍 Récupération des détails de l'item \(itemId)")
print("   URL: \(components.url?.absoluteString ?? "N/A")")

let (data, response) = try await URLSession.shared.data(for: request)

if let httpResponse = response as? HTTPURLResponse {
    print("   📊 Réponse serveur: \(httpResponse.statusCode)")
}

// Afficher les données brutes pour debug
if let jsonString = String(data: data, encoding: .utf8) {
    print("   📄 Données brutes (premiers 500 caractères):")
    print("   \(String(jsonString.prefix(500)))")
}

let item = try JSONDecoder().decode(MediaItem.self, from: data)

print("   ✅ Item décodé - userData présente: \(item.userData != nil)")
if let userData = item.userData {
    print("      Position: \(userData.playbackPosition)s")
    print("      Ticks: \(userData.playbackPositionTicks)")
    print("      Played: \(userData.played)")
}
```

### 3. Augmentation du délai d'attente

Changement de 0.5s à 2s pour laisser plus de temps au serveur :

```swift
// Attendre 2 secondes pour que le serveur ait le temps de traiter et sauvegarder
print("⏳ Attente de 2 secondes pour la synchronisation serveur...")
try? await Task.sleep(for: .seconds(2))

// Rafraîchir les userData depuis le serveur
print("🔄 Tentative de rafraîchissement des userData...")
await refreshUserData()
```

## Logs attendus au prochain test

### À l'arrêt de la lecture

```
⏹️ Arrêt de la lecture demandé
📊 Position actuelle du player: 257s (soit 4min)
🧹 Nettoyage de la lecture
📡 Envoi playback Stopped - ItemId: xxx, Position: 2570000000 ticks (257.0s)
   URL: http://192.168.100.48:8096/Sessions/Stopped?ItemId=xxx&PositionTicks=2570000000&IsPaused=false
   📊 Réponse serveur: 204
✅ Arrêt signalé au serveur à la position 257s (soit 4min)
⏳ Attente de 2 secondes pour la synchronisation serveur...
🔄 Tentative de rafraîchissement des userData...
```

### Lors du rafraîchissement

```
🔄 Rafraîchissement des userData depuis le serveur...
🔍 Récupération des détails de l'item xxx
   URL: http://192.168.100.48:8096/Users/yyy/Items/xxx?Fields=Overview,PrimaryImageAspectRatio
   📊 Réponse serveur: 200
   📄 Données brutes (premiers 500 caractères):
   {"Id":"xxx","Name":"...","UserData":{"PlaybackPositionTicks":2570000000,"Played":false,...},...}
   ✅ Item décodé - userData présente: true
      Position: 257.0s
      Ticks: 2570000000
      Played: false
✅ userData rafraîchies:
   - Position: 257.0s
   - Ticks: 2570000000
   - Played: false
```

## Scénarios possibles

### Scénario A : Le serveur accepte mais ne sauvegarde pas

**Logs** :
```
📊 Réponse serveur: 204
```
**Et pourtant** :
```
Position: 0.0s
```

**Cause** : Problème côté serveur Jellyfin (bug, base de données, permissions)

**Solution** : Vérifier les logs du serveur Jellyfin

### Scénario B : Le serveur renvoie une erreur

**Logs** :
```
📊 Réponse serveur: 400 (ou 500)
⚠️ Code de statut inattendu!
📄 Réponse: {"error": "..."}
```

**Solution** : Adapter la requête selon l'erreur

### Scénario C : L'URL est incorrecte

**Logs** :
```
URL: http://192.168.100.48:8096/Sessions/Stopped?ItemId=xxx&PositionTicks=2570000000&IsPaused=false
```

**Vérifier** : Est-ce que l'API Jellyfin attend ces paramètres exactement ?

### Scénario D : Le délai est trop court

**Si même avec 2s** les données sont à 0, il faudra :
1. Augmenter le délai (5s, 10s)
2. Ou ne rafraîchir qu'au prochain `.onAppear`

## Prochaines étapes

1. **Relancer le test** avec les nouveaux logs
2. **Observer attentivement** :
   - Le code de réponse du serveur (200/204 ou erreur ?)
   - L'URL exacte envoyée
   - Les données JSON brutes reçues
   - La position dans les `UserData`
3. **M'envoyer les logs complets** pour analyse

## Tests supplémentaires possibles

Si le problème persiste, on pourra :
1. Tester avec l'interface web de Jellyfin (est-ce que la position s'y sauvegarde ?)
2. Vérifier les logs du serveur Jellyfin directement
3. Utiliser un outil comme Postman pour tester l'API manuellement
4. Vérifier la version de Jellyfin et sa documentation API
