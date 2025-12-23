# Documentation API Jellyfin - Playback Reporting

## 📚 Documentation officielle

Selon https://api.jellyfin.org/#tag/Playstate/operation/ReportPlaybackProgress

## 🔍 Problème actuel

Les requêtes retournent toujours **404** :

```
📡 Envoi playback Progress
   Position: 3800001413 ticks (380.0s)
   📊 Réponse serveur: 404

📡 Envoi playback Stopped
   Position: 3830281834 ticks (383.0s)
   📊 Réponse serveur: 404
```

**404 = Session non trouvée** : La session de lecture n'est pas créée ou n'existe plus.

## 🎯 Champs requis selon la doc API

### POST `/Sessions/Playing` - Démarrer la lecture

**Body JSON requis** :
```json
{
  "ItemId": "fb6e22e982507d508f3dbe1d8d5054ac",
  "PositionTicks": 0,
  "CanSeek": true,
  "PlayMethod": "Transcode",  // ou "DirectPlay"
  "EventName": "playing"
}
```

### POST `/Sessions/Progress` - Mise à jour de la progression

**Body JSON requis** :
```json
{
  "ItemId": "fb6e22e982507d508f3dbe1d8d5054ac",
  "PositionTicks": 100000000,
  "IsPaused": false,
  "CanSeek": true,
  "PlayMethod": "Transcode",
  "EventName": "timeupdate"
}
```

### POST `/Sessions/Stopped` - Arrêt de la lecture

**Body JSON requis** :
```json
{
  "ItemId": "fb6e22e982507d508f3dbe1d8d5054ac",
  "PositionTicks": 500000000,
  "CanSeek": true,
  "PlayMethod": "Transcode",
  "EventName": "stopped"
}
```

## 🔧 Modifications appliquées

### Ajout des champs obligatoires

1. **`CanSeek: true`** - Indique que la vidéo peut être avancée/reculée
2. **`PlayMethod: "Transcode"`** - Indique la méthode de lecture (Transcode ou DirectPlay)
3. **`EventName`** - Nom de l'événement :
   - `"playing"` pour le démarrage
   - `"timeupdate"` pour les mises à jour
   - `"stopped"` pour l'arrêt

### Ajout de logs pour le body JSON

```swift
if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
    print("   📦 Body JSON: \(bodyString)")
}
```

Cela permettra de voir exactement ce qui est envoyé au serveur.

## 📊 Logs attendus au prochain test

### Au démarrage
```
📡 Envoi playback Playing
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 0 ticks (0.0s)
   URL: http://192.168.100.48:8096/Sessions/Playing
   📦 Body JSON: {"ItemId":"fb6e22e982507d508f3dbe1d8d5054ac","PositionTicks":0,"CanSeek":true,"PlayMethod":"Transcode","EventName":"playing"}
   📊 Réponse serveur: 204
   ✅ Succès!
```

### Pendant la lecture
```
📡 Envoi playback Progress
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 100000000 ticks (10.0s)
   IsPaused: false
   URL: http://192.168.100.48:8096/Sessions/Progress
   📦 Body JSON: {"ItemId":"fb6e22e982507d508f3dbe1d8d5054ac","PositionTicks":100000000,"IsPaused":false,"CanSeek":true,"PlayMethod":"Transcode","EventName":"timeupdate"}
   📊 Réponse serveur: 204
   ✅ Succès!
```

### À l'arrêt
```
📡 Envoi playback Stopped
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 250000000 ticks (25.0s)
   URL: http://192.168.100.48:8096/Sessions/Stopped
   📦 Body JSON: {"ItemId":"fb6e22e982507d508f3dbe1d8d5054ac","PositionTicks":250000000,"CanSeek":true,"PlayMethod":"Transcode","EventName":"stopped"}
   📊 Réponse serveur: 204
   ✅ Succès!
```

## 🤔 Questions à résoudre

### Si les 404 persistent...

1. **Vérifier que `/Sessions/Playing` est appelé AU DÉBUT** de la lecture
   - Chercher dans les logs complets
   - Si absent ou en erreur, la session n'est jamais créée

2. **Vérifier la version du serveur Jellyfin**
   - L'API peut différer selon les versions
   - Comparer avec la documentation de votre version spécifique

3. **Tester avec l'interface web Jellyfin**
   - Est-ce que la progression se sauvegarde dans l'interface web ?
   - Si oui, capturer les requêtes réseau pour voir le format exact

4. **Vérifier les logs du serveur Jellyfin**
   - Voir s'il y a des erreurs côté serveur
   - Vérifier les permissions utilisateur

## 🚀 Prochaine étape

**Relancer le test complet** en regardant attentivement :
1. Le log de `/Sessions/Playing` au DÉBUT (juste après "✅ Lecture signalée au serveur")
2. Les body JSON envoyés
3. Les codes de réponse

Si `/Sessions/Playing` retourne toujours 404 même avec les nouveaux champs, il y a peut-être :
- Un problème d'authentification
- Une API différente sur votre version de Jellyfin
- Un paramètre manquant que nous n'avons pas encore identifié
