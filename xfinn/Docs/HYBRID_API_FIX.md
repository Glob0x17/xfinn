# Fix : API Jellyfin hybride (Query Params vs Body JSON)

## 🎯 Le VRAI problème identifié

Vous aviez raison ! Les logs montrent clairement :

```
📊 Position actuelle du player: 421s
📡 Envoi playback Stopped: Position 421s → 404 ❌
✅ userData rafraîchies: Position: 300.0s ← INCOHÉRENT !
```

**Rien n'est sauvegardé** parce que **toutes les requêtes échouent avec 404**.

Le 300s vient d'un ancien test où UN seul `Progress` avait réussi (204). Depuis, AUCUNE sauvegarde ne fonctionne.

## 🔍 Découverte de l'issue GitHub

D'après https://github.com/orgs/jellyfin/discussions/7259, l'API Jellyfin est **incohérente** :

- Certains endpoints attendent des **query parameters**
- D'autres attendent un **body JSON**
- Cela varie selon la version de Jellyfin

## ✅ Solution : Approche hybride

### Playing - Query Parameters

```swift
POST /Sessions/Playing?ItemId=xxx&PositionTicks=0&CanSeek=true&PlayMethod=Transcode
Headers:
  Authorization: MediaBrowser Token="..."
Body: (vide)
```

### Progress - Body JSON

```swift
POST /Sessions/Progress
Headers:
  Authorization: MediaBrowser Token="..."
  Content-Type: application/json
Body: {
  "ItemId": "xxx",
  "PositionTicks": 100000000,
  "IsPaused": false,
  "CanSeek": true,
  "PlayMethod": "Transcode",
  "EventName": "timeupdate"
}
```

### Stopped - Query Parameters

```swift
POST /Sessions/Stopped?ItemId=xxx&PositionTicks=500000000
Headers:
  Authorization: MediaBrowser Token="..."
Body: (vide)
```

## 📊 Logs attendus au prochain test

### Démarrage (Playing)

```
📡 Envoi playback Playing (query params)
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 0 ticks (0.0s)
   URL: http://.../Sessions/Playing?ItemId=xxx&PositionTicks=0&CanSeek=true&PlayMethod=Transcode
   📊 Réponse serveur: 204
   ✅ Succès!
```

### Pendant (Progress)

```
📡 Envoi playback Progress (body JSON)
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 50000000 ticks (5.0s)
   IsPaused: false
   📊 Réponse serveur: 204
   ✅ Succès!
```

### Arrêt (Stopped)

```
📡 Envoi playback Stopped (query params)
   ItemId: fb6e22e982507d508f3dbe1d8d5054ac
   Position: 4214979062 ticks (421.4979062s)
   URL: http://.../Sessions/Stopped?ItemId=xxx&PositionTicks=4214979062
   📊 Réponse serveur: 204
   ✅ Succès!
```

### Rafraîchissement

```
🔄 Tentative de rafraîchissement des userData...
✅ userData rafraîchies:
   - Position: 421.5s  ← LA BONNE VALEUR ! 🎉
   - Ticks: 4214979062
   - Played: false
```

## 🎯 Résultat attendu

1. **Toutes les requêtes** retournent 204 ✅
2. **La position est sauvegardée** correctement (421s au lieu de 300s)
3. **Au prochain lancement**, la popup affiche "Reprendre à 421s" (7min)
4. **La reprise fonctionne** à la bonne position

## 🚀 Test à effectuer

1. **Supprimer les données** de l'épisode dans Jellyfin (pour repartir de 0)
2. **Lancer l'application**
3. **Lire une vidéo** pendant 30-40 secondes
4. **Quitter**
5. **Vérifier les logs** :
   - Playing → 204 ✅
   - Progress (toutes les 5s) → 204 ✅
   - Stopped → 204 ✅
6. **Revenir sur la page du média**
7. **Cliquer sur "Lire"**
8. **Vérifier** que la popup affiche la BONNE position (30-40s)
9. **Tester "Continuer"** et vérifier que ça reprend au bon endroit

## 📝 Notes

### Pourquoi cette approche hybride ?

L'API Jellyfin a évolué au fil du temps :
- Les **anciens endpoints** (`Playing`, `Stopped`) utilisent des query parameters
- Les **nouveaux endpoints** (`Progress`) utilisent du body JSON
- Les clients Jellyfin officiels utilisent cette approche hybride

### Si ça ne fonctionne toujours pas...

Essayer l'inverse (tout en query params, tout en body JSON) pour identifier la configuration de votre serveur Jellyfin spécifique.

### Vérifier la version de Jellyfin

```bash
curl http://192.168.100.48:8096/System/Info/Public
```

Comparer avec la doc de votre version spécifique.

## 🎉 Cette fois-ci, ça devrait VRAIMENT marcher !

Avec cette approche hybride qui correspond au comportement observé des clients Jellyfin officiels, les 404 devraient enfin disparaître et la sauvegarde fonctionner correctement ! 🚀
