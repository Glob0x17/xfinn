# Architecture de xfinn

## 📐 Vue d'ensemble

xfinn est une application tvOS native construite avec SwiftUI qui permet d'accéder à un serveur Jellyfin et de lire des médias sur Apple TV.

## 📁 Structure du Projet

```
xfinn/
├── App/
│   └── ContentView.swift                    # Point d'entrée de l'app
├── Core/
│   ├── Services/
│   │   └── JellyfinService.swift           # Service API Jellyfin
│   ├── Models/
│   │   └── JellyfinModels.swift            # Modèles de données
│   └── Coordinators/
│       └── NavigationCoordinator.swift      # Gestion de la navigation
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   └── LoginView.swift
│   │   └── Components/
│   │       ├── ServerConnectionView.swift
│   │       └── AuthenticationView.swift
│   ├── Home/
│   │   ├── Views/
│   │   │   └── HomeView.swift
│   │   └── Components/
│   │       └── MediaCarousel.swift
│   ├── Library/
│   │   ├── Views/
│   │   │   ├── LibraryView.swift
│   │   │   └── LibraryContentView.swift
│   │   └── Components/
│   │       └── LibraryCard.swift
│   ├── Series/
│   │   ├── Views/
│   │   │   ├── SeriesDetailView.swift
│   │   │   └── SeasonEpisodesView.swift
│   │   └── Components/
│   │       ├── SeasonCard.swift
│   │       └── EpisodeRow.swift
│   └── Media/
│       ├── Views/
│       │   └── MediaDetailView.swift
│       └── Components/
│           ├── MediaCard.swift
│           ├── CarouselMediaCard.swift
│           └── NextEpisodeOverlay.swift
├── Shared/
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── EmptyContentView.swift
│   ├── Theme/
│   │   └── AppTheme.swift                  # Thème centralisé
│   └── Extensions/
│       ├── View+Extensions.swift
│       ├── Color+Extensions.swift
│       ├── String+Extensions.swift
│       ├── TimeInterval+Extensions.swift
│       ├── UserDefaults+Extensions.swift
│       ├── Date+Extensions.swift
│       └── Array+Extensions.swift
└── Documentation/
    ├── ARCHITECTURE.md                      # Ce fichier
    ├── PROJECT_REORGANIZATION.md            # Guide de réorg
    ├── QUICK_REORGANIZATION_GUIDE.md        # Guide rapide
    └── ... (autres docs)
```

### 🎯 Principes d'Organisation

1. **App/** : Point d'entrée unique de l'application
2. **Core/** : Logique métier fondamentale (services, modèles, coordinateurs)
3. **Features/** : Fonctionnalités organisées par domaine, chacune avec ses vues et composants
4. **Shared/** : Code réutilisable à travers toute l'application
5. **Documentation/** : Toute la documentation technique

## 🏗️ Structure de l'application

```
┌─────────────────────────────────────────────────────────┐
│                     ContentView                          │
│  Point d'entrée - Gère l'état d'authentification       │
└────────────┬────────────────────────────────────────────┘
             │
             ├─── Non authentifié
             │    └─────────────────────────────┐
             │                                   ▼
             │                          ┌──────────────┐
             │                          │  LoginView   │
             │                          └──────┬───────┘
             │                                 │
             │                                 ├─ ServerConnectionView
             │                                 └─ AuthenticationView
             │
             └─── Authentifié
                  └─────────────────────────────┐
                                                 ▼
                                        ┌─────────────────┐
                                        │    HomeView     │
                                        │  Page d'accueil │
                                        └────────┬────────┘
                                                 │
                  ┌──────────────────────────────┼────────────────────┐
                  │                              │                    │
                  ▼                              ▼                    ▼
         ┌──────────────┐              ┌─────────────────┐  ┌──────────────┐
         │ LibraryView  │              │ MediaCarousel   │  │SettingsView  │
         │              │              │ (Reprendre,     │  │              │
         │              │              │  Récemment)     │  │              │
         └──────┬───────┘              └─────────────────┘  └──────────────┘
                │
                ▼
    ┌──────────────────────┐
    │ LibraryContentView   │
    │ (Films, Séries, etc.)│
    └──────┬───────────────┘
           │
           ├─── Type: Movie
           │    └────────────────────┐
           │                         ▼
           │                 ┌──────────────────┐
           │                 │ MediaDetailView  │
           │                 │ (Lecture vidéo)  │
           │                 └──────────────────┘
           │
           └─── Type: Series
                └────────────────────┐
                                     ▼
                            ┌──────────────────┐
                            │ SeriesDetailView │
                            └────────┬─────────┘
                                     │
                                     ▼
                            ┌──────────────────┐
                            │SeasonEpisodesView│
                            └────────┬─────────┘
                                     │
                                     ▼
                            ┌──────────────────┐
                            │ MediaDetailView  │
                            │ (Épisode)        │
                            └──────────────────┘
```

## 🔧 Composants principaux

### 1. Services et Modèles

#### JellyfinService
**Responsabilité** : Service centralisé pour toutes les interactions avec l'API Jellyfin

**Propriétés** :
- `@Published isAuthenticated: Bool` - État d'authentification
- `@Published currentUser: User?` - Utilisateur actuel
- `@Published serverInfo: ServerInfo?` - Informations du serveur
- `baseURL: String` - URL du serveur
- `userId: String` - ID de l'utilisateur

**Méthodes principales** :
```swift
func connect(to serverURL: String) async throws -> ServerInfo
func authenticate(username: String, password: String) async throws
func getLibraries() async throws -> [LibraryItem]
func getItems(parentId: String, includeItemTypes: [String]) async throws -> [MediaItem]
func getStreamURL(itemId: String) -> URL?
func reportPlaybackStart/Progress/Stopped(...) async throws
func loadSavedCredentials()
func logout()
```

#### JellyfinModels
**Modèles de données** :
- `ServerInfo` - Informations du serveur
- `User` - Utilisateur
- `AuthenticationResult` - Résultat d'authentification
- `LibraryItem` - Bibliothèque (conforme à Hashable)
- `MediaItem` - Média (conforme à Hashable)
- `UserData` - Données utilisateur (progression, statut)
- `ItemsResponse` - Réponse de l'API

### 2. Vues principales

#### ContentView
- Point d'entrée de l'application
- Gère le `@StateObject JellyfinService`
- Affiche `LoginView` ou `HomeView` selon l'état d'authentification
- Charge les identifiants sauvegardés au démarrage

#### LoginView
- **Étape 1** : Connexion au serveur (URL)
- **Étape 2** : Authentification (username/password)
- Validation et nettoyage d'URL
- Gestion des erreurs
- Interface optimisée pour tvOS

#### HomeView
- Page d'accueil après authentification
- **Section "À reprendre"** : Médias en cours de visionnage
- **Section "Récemment ajoutés"** : Derniers médias
- Lien vers toutes les bibliothèques
- Utilise `MediaCarousel` pour l'affichage

#### LibraryView
- Affiche toutes les bibliothèques de l'utilisateur
- Grille adaptative avec `LazyVGrid`
- Cartes visuelles avec images et icônes
- Bouton de déconnexion

#### LibraryContentView
- Affiche le contenu d'une bibliothèque
- Grille de médias avec posters
- Navigation conditionnelle :
  - Films → `MediaDetailView`
  - Séries → `SeriesDetailView`
  - Saisons → `SeasonEpisodesView`

#### SeriesDetailView
- Affiche les détails d'une série
- Liste des saisons avec `SeasonCard`
- Navigation vers les épisodes

#### SeasonEpisodesView
- Affiche les épisodes d'une saison
- Liste verticale avec `EpisodeRow`
- Progression de lecture visible

#### MediaDetailView
- **Affichage des détails** :
  - Poster et image backdrop
  - Titre, année, note, durée
  - Synopsis complet
  - Progression de lecture
- **Lecture vidéo** :
  - Utilise `AVPlayer` et `VideoPlayer`
  - Reprise automatique à la dernière position
  - Rapport de progression au serveur
  - Gestion du cycle de vie de la lecture

### 3. Composants réutilisables

#### MediaCard
- Carte de média pour les grilles
- Affiche poster, titre, année, note
- Badge "Vu" si nécessaire

#### LibraryCard
- Carte de bibliothèque
- Image ou icône selon le type
- Dégradé de fond

#### CarouselMediaCard
- Carte pour les carrousels horizontaux
- Barre de progression pour les médias en cours
- Format paysage

#### EpisodeRow
- Ligne pour afficher un épisode
- Vignette, titre, synopsis
- Progression de lecture

#### MediaCarousel
- Carrousel horizontal de médias
- Scroll horizontal fluide
- Navigation intégrée

### 4. Extensions et utilitaires

#### Extensions.swift
**Extensions de types** :
- `View` : `.cardStyle()`, `.focusableCard()`
- `Color` : Couleurs Jellyfin personnalisées
- `String` : `.isValidURL`, `.cleanedJellyfinURL`
- `TimeInterval` : `.formattedDuration`, `.toTicks`
- `Int64` : `.fromTicks`
- `Array<MediaItem>` : `.unwatched`, `.inProgress`, `.groupedBySeason()`
- `UserDefaults` : Propriétés pour Jellyfin

**Vues utilitaires** :
- `LoadingView` - Indicateur de chargement
- `ErrorView` - Affichage d'erreur
- `EmptyContentView` - Contenu vide

## 🔄 Flux de données

### Authentification

```
User Input (URL + Credentials)
    ↓
LoginView.connectToServer()
    ↓
JellyfinService.connect(to:)
    ↓
API: GET /System/Info/Public
    ↓
LoginView.authenticate()
    ↓
JellyfinService.authenticate(username:password:)
    ↓
API: POST /Users/AuthenticateByName
    ↓
JellyfinService.saveCredentials()
    ↓
UserDefaults (token, userId, serverURL)
    ↓
@Published isAuthenticated = true
    ↓
ContentView affiche HomeView
```

### Chargement de contenu

```
HomeView.task
    ↓
loadResumeItems() + loadRecentItems()
    ↓
API: GET /Users/{userId}/Items/Resume
API: GET /Users/{userId}/Items/Latest
    ↓
@State resumeItems/recentItems
    ↓
MediaCarousel affiche les médias
```

### Lecture vidéo

```
User sélectionne MediaDetailView
    ↓
User clique "Lire"
    ↓
MediaDetailView.startPlayback()
    ↓
JellyfinService.getStreamURL(itemId:)
    ↓
AVPlayer(url: streamURL)
    ↓
Seek to saved position (userData.playbackPosition)
    ↓
player.play()
    ↓
JellyfinService.reportPlaybackStart()
    ↓
API: POST /Sessions/Playing
    ↓
[Lecture en cours]
    ↓
Periodic observer (toutes les 10s)
    ↓
JellyfinService.reportPlaybackProgress()
    ↓
API: POST /Sessions/Progress
    ↓
[Utilisateur quitte]
    ↓
MediaDetailView.stopPlayback()
    ↓
JellyfinService.reportPlaybackStopped()
    ↓
API: POST /Sessions/Stopped
```

## 💾 Persistance

### UserDefaults
```swift
// Clés stockées
- jellyfinServerURL: String?
- jellyfinAccessToken: String?
- jellyfinUserId: String?
- deviceId: String
```

### Sécurité
- ✅ Seul le token d'accès est stocké (pas le mot de passe)
- ✅ ID de device unique généré et persisté
- ✅ Possibilité de se déconnecter (efface les données)

## 🎨 Interface utilisateur

### Principes de design tvOS
- **Focus Management** : Navigation à la télécommande
- **Distance Viewing** : Polices grandes, espacements généreux
- **Materials** : `.ultraThinMaterial` pour les cartes
- **Animations** : Transitions fluides
- **Feedback visuel** : Scale effects, progress bars

### Hiérarchie visuelle
1. **Titres** : `.system(size: 50, weight: .bold)`
2. **Sous-titres** : `.title2` ou `.title3`
3. **Corps** : `.body` ou `.headline`
4. **Légendes** : `.caption` avec `.foregroundStyle(.secondary)`

### Grilles et layouts
- `LazyVGrid` avec colonnes adaptatives
- Spacing: 30-40pt entre éléments
- Padding: 60pt sur les côtés
- Corner radius: 12-15pt pour les cartes

## 🧪 Tests

### Tests unitaires (Swift Testing)
- Validation des formats d'URL
- Conversion ticks ↔ TimeInterval
- Formatage de durées
- Titres d'affichage des épisodes
- Conformité Hashable
- Filtrage de médias
- Extensions String et UserDefaults

### Couverture
- ✅ Modèles de données
- ✅ Extensions
- ✅ Logique de formatage
- ⚠️ À ajouter : Tests d'intégration réseau
- ⚠️ À ajouter : Tests UI

## 🚀 Performance

### Optimisations
- **LazyVGrid/LazyVStack** : Chargement paresseux des vues
- **AsyncImage** : Chargement asynchrone des images
- **Task** : Chargement concurrent des données
- **@MainActor** : Isolation pour JellyfinService
- **Hashable** : Optimisation des collections

### Gestion mémoire
- AVPlayer correctement libéré après lecture
- Observers nettoyés dans `stopPlayback()`
- Images chargées à la demande

## 🔮 Évolutions possibles

### Fonctionnalités
- [ ] Recherche de médias
- [ ] Filtres et tri avancés
- [ ] Support des sous-titres
- [ ] Sélection de piste audio
- [ ] Support de la musique
- [ ] Listes de lecture
- [ ] Téléchargement hors ligne
- [ ] Multi-profils

### Technique
- [ ] Cache d'images local
- [ ] Préchargement de métadonnées
- [ ] Support du transcodage
- [ ] Tests d'intégration
- [ ] CI/CD
- [ ] Internationalisation
- [ ] Accessibilité avancée

## 📚 Ressources

### Documentation Apple
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [AVFoundation](https://developer.apple.com/av-foundation/)
- [tvOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos)

### Documentation Jellyfin
- [API Documentation](https://api.jellyfin.org/)
- [Client Development Guide](https://jellyfin.org/docs/general/clients/index.html)

---

*Architecture documentée pour xfinn v1.0.0*
