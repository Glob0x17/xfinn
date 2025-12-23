# API Jellyfin - Référence pour xfinn

Ce document décrit toutes les endpoints de l'API Jellyfin utilisées dans l'application xfinn.

## 🔐 Authentification

### Headers requis
 
Pour toutes les requêtes authentifiées :

```http
Authorization: MediaBrowser Client="xfinn", Device="Apple TV", DeviceId="<device-id>", Version="1.0.0", Token="<access-token>"
```

## 📡 Endpoints utilisés

### 1. Informations du serveur

#### GET /System/Info/Public
Récupère les informations publiques du serveur (sans authentification).

**Requête** :
```http
GET http://server:8096/System/Info/Public
```

**Réponse** :
```json
{
  "Id": "server-id",
  "ServerName": "My Jellyfin Server",
  "Version": "10.8.0",
  "OperatingSystem": "Linux"
}
```

**Utilisé dans** : `JellyfinService.connect(to:)`

---

### 2. Authentification

#### POST /Users/AuthenticateByName
Authentifie un utilisateur avec son nom et mot de passe.

**Requête** :
```http
POST http://server:8096/Users/AuthenticateByName
Content-Type: application/json
Authorization: MediaBrowser Client="xfinn", Device="Apple TV", DeviceId="<device-id>", Version="1.0.0"

{
  "Username": "user",
  "Pw": "password"
}
```

**Réponse** :
```json
{
  "User": {
    "Id": "user-id",
    "Name": "Username",
    "ServerId": "server-id",
    "HasPassword": true
  },
  "AccessToken": "access-token-here",
  "ServerId": "server-id"
}
```

**Utilisé dans** : `JellyfinService.authenticate(username:password:)`

---

### 3. Bibliothèques

#### GET /Users/{userId}/Views
Récupère toutes les bibliothèques de l'utilisateur.

**Requête** :
```http
GET http://server:8096/Users/{userId}/Views
Authorization: MediaBrowser ... Token="<access-token>"
```

**Réponse** :
```json
{
  "Items": [
    {
      "Id": "library-id",
      "Name": "Movies",
      "Type": "CollectionFolder",
      "CollectionType": "movies"
    },
    {
      "Id": "library-id-2",
      "Name": "TV Shows",
      "Type": "CollectionFolder",
      "CollectionType": "tvshows"
    }
  ],
  "TotalRecordCount": 2
}
```

**Utilisé dans** : `JellyfinService.getLibraries()`

---

### 4. Contenu des bibliothèques

#### GET /Users/{userId}/Items
Récupère les éléments d'une bibliothèque ou d'un conteneur.

**Requête** :
```http
GET http://server:8096/Users/{userId}/Items?ParentId={parentId}&SortBy=SortName&SortOrder=Ascending&Fields=Overview,PrimaryImageAspectRatio&IncludeItemTypes=Movie,Series
Authorization: MediaBrowser ... Token="<access-token>"
```

**Paramètres de requête** :
- `ParentId` : ID de la bibliothèque ou du conteneur parent
- `SortBy` : Critère de tri (SortName, DateCreated, etc.)
- `SortOrder` : Ordre (Ascending, Descending)
- `Fields` : Champs additionnels à inclure
- `IncludeItemTypes` : Types d'éléments (Movie, Series, Season, Episode, etc.)
- `Limit` : Nombre maximum d'éléments
- `StartIndex` : Index de départ pour la pagination

**Réponse** :
```json
{
  "Items": [
    {
      "Id": "movie-id",
      "Name": "Movie Title",
      "Type": "Movie",
      "Overview": "Movie description...",
      "ProductionYear": 2023,
      "CommunityRating": 8.5,
      "OfficialRating": "PG-13",
      "RunTimeTicks": 72000000000,
      "UserData": {
        "Played": false,
        "PlaybackPositionTicks": 0,
        "PlayCount": 0
      }
    }
  ],
  "TotalRecordCount": 1
}
```

**Utilisé dans** : 
- `JellyfinService.getItems(parentId:includeItemTypes:)`
- `HomeView.loadResumeItems()`
- `HomeView.loadRecentItems()`

---

### 5. Éléments à reprendre

#### GET /Users/{userId}/Items/Resume
Récupère les médias en cours de visionnage.

**Requête** :
```http
GET http://server:8096/Users/{userId}/Items/Resume?Limit=10&Fields=Overview,PrimaryImageAspectRatio&MediaTypes=Video
Authorization: MediaBrowser ... Token="<access-token>"
```

**Paramètres** :
- `Limit` : Nombre maximum d'éléments
- `Fields` : Champs additionnels
- `MediaTypes` : Type de média (Video, Audio, Photo)

**Réponse** : Identique à `/Users/{userId}/Items` mais filtrée pour les éléments en cours.

**Utilisé dans** : `HomeView.loadResumeItems()`

---

### 6. Éléments récents

#### GET /Users/{userId}/Items/Latest
Récupère les médias récemment ajoutés.

**Requête** :
```http
GET http://server:8096/Users/{userId}/Items/Latest?Limit=10&Fields=Overview,PrimaryImageAspectRatio&IncludeItemTypes=Movie,Series
Authorization: MediaBrowser ... Token="<access-token>"
```

**Paramètres** :
- `Limit` : Nombre maximum d'éléments
- `Fields` : Champs additionnels
- `IncludeItemTypes` : Types d'éléments

**Réponse** : Tableau d'éléments directement (pas d'objet wrapper).

```json
[
  {
    "Id": "item-id",
    "Name": "Recent Item",
    "Type": "Movie",
    ...
  }
]
```

**Utilisé dans** : `HomeView.loadRecentItems()`

---

### 7. Images

#### GET /Items/{itemId}/Images/{imageType}
Récupère une image pour un élément.

**Requête** :
```http
GET http://server:8096/Items/{itemId}/Images/Primary?maxWidth=600&api_key={accessToken}
```

**Paramètres** :
- `imageType` : Type d'image (Primary, Backdrop, Logo, etc.)
- `maxWidth` : Largeur maximale
- `maxHeight` : Hauteur maximale
- `quality` : Qualité JPEG (0-100)
- `api_key` : Token d'accès

**Réponse** : Image binaire (JPEG ou PNG)

**Types d'images disponibles** :
- `Primary` : Poster principal
- `Backdrop` : Image de fond
- `Logo` : Logo du média
- `Thumb` : Vignette
- `Banner` : Bannière

**Utilisé dans** : 
- `JellyfinService.getImageURL(itemId:imageType:maxWidth:)`
- Toutes les vues avec `AsyncImage`

---

### 8. Streaming vidéo

#### GET /Videos/{itemId}/stream
Récupère le flux vidéo d'un élément.

**Requête** :
```http
GET http://server:8096/Videos/{itemId}/stream?Static=true&MediaSourceId={itemId}&api_key={accessToken}
```

**Paramètres** :
- `Static` : Streaming direct sans transcodage
- `MediaSourceId` : ID de la source média
- `api_key` : Token d'accès

**Paramètres de transcodage (optionnels)** :
- `VideoCodec` : Codec vidéo (h264, hevc, etc.)
- `AudioCodec` : Codec audio (aac, mp3, etc.)
- `MaxWidth` : Largeur maximale
- `MaxHeight` : Hauteur maximale
- `VideoBitRate` : Débit vidéo
- `AudioBitRate` : Débit audio

**Réponse** : Flux vidéo (généralement MP4 ou TS)

**Utilisé dans** : `JellyfinService.getStreamURL(itemId:)`

---

### 9. Rapport de lecture - Début

#### POST /Sessions/Playing
Signale le début de la lecture d'un média.

**Requête** :
```http
POST http://server:8096/Sessions/Playing?ItemId={itemId}&PositionTicks={ticks}&IsPaused=false
Authorization: MediaBrowser ... Token="<access-token>"
```

**Paramètres** :
- `ItemId` : ID de l'élément en cours de lecture
- `PositionTicks` : Position en ticks (10 000 000 ticks = 1 seconde)
- `IsPaused` : État de pause

**Réponse** : 204 No Content

**Utilisé dans** : `JellyfinService.reportPlaybackStart(itemId:positionTicks:)`

---

### 10. Rapport de lecture - Progression

#### POST /Sessions/Progress
Signale la progression de la lecture.

**Requête** :
```http
POST http://server:8096/Sessions/Progress?ItemId={itemId}&PositionTicks={ticks}&IsPaused={paused}
Authorization: MediaBrowser ... Token="<access-token>"
```

**Paramètres** : Identiques à `/Sessions/Playing`

**Réponse** : 204 No Content

**Utilisé dans** : 
- `JellyfinService.reportPlaybackProgress(itemId:positionTicks:isPaused:)`
- Appelé toutes les 10 secondes pendant la lecture

---

### 11. Rapport de lecture - Fin

#### POST /Sessions/Stopped
Signale l'arrêt de la lecture.

**Requête** :
```http
POST http://server:8096/Sessions/Stopped?ItemId={itemId}&PositionTicks={ticks}&IsPaused=false
Authorization: MediaBrowser ... Token="<access-token>"
```

**Paramètres** : Identiques à `/Sessions/Playing`

**Réponse** : 204 No Content

**Utilisé dans** : `JellyfinService.reportPlaybackStopped(itemId:positionTicks:)`

---

## 📊 Structures de données

### Ticks Jellyfin

Jellyfin utilise des "ticks" pour représenter le temps :
- **1 tick** = 100 nanosecondes
- **10 000 000 ticks** = 1 seconde
- **600 000 000 ticks** = 1 minute
- **36 000 000 000 ticks** = 1 heure

**Conversion** :
```swift
// TimeInterval vers ticks
let ticks = Int64(timeInterval * 10_000_000)

// Ticks vers TimeInterval
let timeInterval = Double(ticks) / 10_000_000.0
```

### Types d'éléments

- `Movie` : Film
- `Series` : Série TV
- `Season` : Saison d'une série
- `Episode` : Épisode d'une série
- `MusicAlbum` : Album de musique
- `Audio` : Piste audio
- `Photo` : Photo
- `CollectionFolder` : Bibliothèque

### Types de collections

- `movies` : Films
- `tvshows` : Séries TV
- `music` : Musique
- `photos` : Photos
- `books` : Livres
- `homevideos` : Vidéos personnelles

## 🔒 Gestion des erreurs

### Codes HTTP courants

- **200 OK** : Succès
- **204 No Content** : Succès sans contenu
- **400 Bad Request** : Requête invalide
- **401 Unauthorized** : Non authentifié
- **403 Forbidden** : Accès refusé
- **404 Not Found** : Ressource introuvable
- **500 Internal Server Error** : Erreur serveur

### Erreurs courantes

1. **Connexion impossible** :
   - Serveur hors ligne
   - URL incorrecte
   - Problème réseau

2. **Authentification échouée** :
   - Nom d'utilisateur incorrect
   - Mot de passe incorrect
   - Utilisateur désactivé

3. **Ressource introuvable** :
   - ID d'élément invalide
   - Élément supprimé
   - Permissions insuffisantes

## 🚀 Optimisations

### Chargement d'images

**Bonnes pratiques** :
- Toujours spécifier `maxWidth` ou `maxHeight`
- Utiliser `quality` pour réduire la taille
- Préférer Primary pour les posters, Backdrop pour les fonds

**Exemple** :
```swift
let imageUrl = "\(baseURL)/Items/\(itemId)/Images/Primary?maxWidth=400&quality=90&api_key=\(token)"
```

### Pagination

Pour les grandes bibliothèques :
```http
GET /Users/{userId}/Items?ParentId={id}&StartIndex=0&Limit=50
```

### Champs sélectifs

Demander uniquement les champs nécessaires :
```http
GET /Users/{userId}/Items?Fields=Overview,PrimaryImageAspectRatio
```

Champs disponibles :
- `Overview` : Synopsis
- `PrimaryImageAspectRatio` : Ratio de l'image
- `MediaStreams` : Flux audio/vidéo
- `People` : Acteurs et équipe
- `Genres` : Genres
- `Studios` : Studios

## 📚 Ressources

### Documentation officielle
- [Jellyfin API Documentation](https://api.jellyfin.org/)
- [Jellyfin OpenAPI Spec](https://api.jellyfin.org/openapi/api-docs.html)

### Outils utiles
- [Jellyfin Swagger UI](http://your-server:8096/api-docs/swagger/index.html)
- Postman ou Insomnia pour tester les APIs

---

*Documentation API pour xfinn v1.0.0*
