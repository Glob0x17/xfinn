# Fix : API Jellyfin - Erreurs 404 et 415

## 🎯 Problème identifié

Les logs révèlent que **toutes les requêtes vers l'API Jellyfin échouent** :

### Erreur 415 sur `/Sessions/Playing`
```
📡 Envoi playback Playing - ItemId: xxx, Position: 0 ticks (0.0s)
   URL: http://192.168.100.48:8096/Sessions/Playing?ItemId=xxx&PositionTicks=0
   📊 Réponse serveur: 415
   📄 Réponse: {"title":"Unsupported Media Type","status":415}
```

**415 = Unsupported Media Type** : Le serveur refuse la requête car le format n'est pas celui attendu.

### Erreurs 404 sur `/Sessions/Progress` et `/Sessions/Stopped`
```
📡 Envoi playback Progress - ItemId: xxx, Position: 41482107 ticks (4.1s)
   📊 Réponse serveur: 404

📡 Envoi playback Stopped - ItemId: xxx, Position: 4531643757 ticks (453.1s)
   📊 Réponse serveur: 404
```

**404 = Not Found** : Le serveur ne trouve pas la session car elle n'a jamais été créée (à cause de l'erreur 415 initiale).

## 🔍 Cause racine

### ❌ Ancien code (incorrect)
```swift
var components = URLComponents(string: "\(baseURL)/Sessions/\(endpoint)")!
components.queryItems = [
    URLQueryItem(name: "ItemId", value: itemId),
    URLQueryItem(name: "PositionTicks", value: String(positionTicks))
]

var request = URLRequest(url: components.url!)
request.httpMethod = "POST"
request.setValue(authHeaderWithToken, forHTTPHeaderField: "Authorization")
// PAS de Content-Type
// PAS de body JSON
```

**Problème** : Nous envoyons un POST avec des **query parameters dans l'URL**, mais sans **body JSON**.

L'API Jellyfin s'attend à recevoir :
- `Content-Type: application/json`
- Un body JSON avec `ItemId`, `PositionTicks`, etc.

## ✅ Solution appliquée

### Nouveau code (correct)
```swift
let url = URL(string: "\(baseURL)/Sessions/\(endpoint)")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue(authHeaderWithToken, forHTTPHeaderField: "Authorization")

// Créer le body JSON
var body: [String: Any] = [
    "ItemId": itemId,
    "PositionTicks": positionTicks
]

// IsPaused n'est pertinent que pour Progress
if endpoint == "Progress" {
    body["IsPaused"] = isPaused
}

request.httpBody = try JSONSerialization.data(withJSONObject: body)
```

### Changements clés

1. **Ajout du header `Content-Type: application/json`**
2. **Création d'un body JSON** avec les paramètres
3. **Suppression des query parameters** de l'URL
4. **Logs plus détaillés** pour suivre les requêtes

## 📊 Logs attendus au prochain test

### Création de session (Playing)
```
📡 Envoi playback Playing
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 0 ticks (0.0s)
   URL: http://192.168.100.48:8096/Sessions/Playing
   📊 Réponse serveur: 204
   ✅ Succès!
```

### Mise à jour de progression (Progress)
```
📡 Envoi playback Progress
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 100000000 ticks (10.0s)
   IsPaused: false
   URL: http://192.168.100.48:8096/Sessions/Progress
   📊 Réponse serveur: 204
   ✅ Succès!
```

### Arrêt de lecture (Stopped)
```
📡 Envoi playback Stopped
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 4531643757 ticks (453.1s)
   URL: http://192.168.100.48:8096/Sessions/Stopped
   📊 Réponse serveur: 204
   ✅ Succès!
```

### Rafraîchissement userData
```
🔄 Tentative de rafraîchissement des userData...
🔍 Récupération des détails de l'item xxx
   📊 Réponse serveur: 200
   ✅ Item décodé - userData présente: true
      Position: 453.1s
      Ticks: 4531643757
      Played: false
✅ userData rafraîchies:
   - Position: 453.1s
   - Ticks: 4531643757
   - Played: false
```

## 🎬 Flux complet attendu

1. **Démarrage** : `POST /Sessions/Playing` → 204 ✅
2. **Toutes les 10s** : `POST /Sessions/Progress` → 204 ✅
3. **Arrêt** : `POST /Sessions/Stopped` → 204 ✅
4. **Serveur sauvegarde** la position dans `UserData.PlaybackPositionTicks`
5. **Rafraîchissement** : `GET /Users/{userId}/Items/{itemId}` → Retourne les données à jour ✅
6. **Popup de reprise** s'affiche avec la bonne position ! 🎉

## 🚀 Test à effectuer

1. **Lancer l'application**
2. **Lire une vidéo** pendant quelques secondes (ex: 20-30s)
3. **Quitter le player**
4. **Observer les logs** - vous devriez voir "204" et "✅ Succès!" partout
5. **Revenir sur la page du média**
6. **Cliquer sur "Lire"**
7. **Vérifier que la popup de reprise apparaît** avec la bonne position ! 🎊

## 📚 Référence API Jellyfin

Les endpoints corrects selon la documentation Jellyfin :

- **POST** `/Sessions/Playing` - Body JSON: `{"ItemId": "xxx", "PositionTicks": 0}`
- **POST** `/Sessions/Progress` - Body JSON: `{"ItemId": "xxx", "PositionTicks": 1000000, "IsPaused": false}`
- **POST** `/Sessions/Stopped` - Body JSON: `{"ItemId": "xxx", "PositionTicks": 5000000}`

Tous nécessitent :
- `Content-Type: application/json`
- `Authorization: MediaBrowser Token="..."`
- Un body JSON (pas de query parameters)
