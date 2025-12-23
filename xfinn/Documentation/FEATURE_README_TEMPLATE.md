# 📝 Template README pour Features

Ce fichier est un template pour créer des README.md dans chaque dossier de feature.

## Comment l'Utiliser

1. Copiez ce fichier dans chaque dossier Feature
2. Renommez-le en `README.md`
3. Adaptez le contenu à la feature spécifique

---

# 📺 [Nom de la Feature]

> Brève description de ce que fait cette feature (1-2 lignes)

## 📁 Structure

```
[FeatureName]/
├── Views/
│   └── [ListeDesVues].swift
└── Components/
    └── [ListeDesComposants].swift
```

## 🎯 Responsabilités

Cette feature est responsable de :
- [ ] Responsabilité 1
- [ ] Responsabilité 2
- [ ] Responsabilité 3

## 🏗️ Architecture

### Views
| Fichier | Description | Route |
|---------|-------------|-------|
| `ExampleView.swift` | Description de la vue | `/example` |

### Components
| Fichier | Description | Utilisé par |
|---------|-------------|-------------|
| `ExampleComponent.swift` | Description du composant | ExampleView |

## 🔗 Dépendances

### Services Utilisés
- [ ] `JellyfinService` - Pour [quoi faire]
- [ ] `NavigationCoordinator` - Pour [quoi faire]

### Modèles Utilisés
- [ ] `MediaItem` - Représente [quoi]
- [ ] `User` - Représente [quoi]

## 🔄 Flux de Données

```
User Action
    ↓
View
    ↓
Service Call
    ↓
Update State
    ↓
Re-render
```

## 🎨 Design

### Couleurs Principales
- Couleur 1 : `AppTheme.primaryColor`
- Couleur 2 : `AppTheme.secondaryColor`

### Composants Partagés Utilisés
- [ ] `LoadingView`
- [ ] `ErrorView`
- [ ] `EmptyContentView`

## 🚀 Évolutions Futures

- [ ] Amélioration 1
- [ ] Amélioration 2
- [ ] Amélioration 3

## 🧪 Tests

### Tests Existants
- [ ] Test 1
- [ ] Test 2

### Tests à Ajouter
- [ ] Test 1
- [ ] Test 2

---

*Feature créée le [date]*

---

# Exemples Concrets

Voici des exemples de README pour chaque feature :

---

## Exemple 1 : Features/Authentication/README.md

```markdown
# 🔐 Authentication

> Gère la connexion au serveur Jellyfin et l'authentification des utilisateurs

## 📁 Structure

```
Authentication/
├── Views/
│   └── LoginView.swift
└── Components/
    ├── ServerConnectionView.swift (si existe)
    └── AuthenticationView.swift (si existe)
```

## 🎯 Responsabilités

Cette feature est responsable de :
- ✅ Connexion au serveur Jellyfin (validation d'URL)
- ✅ Authentification utilisateur (username/password)
- ✅ Sauvegarde des credentials
- ✅ Gestion des erreurs de connexion

## 🏗️ Architecture

### Views
| Fichier | Description | Route |
|---------|-------------|-------|
| `LoginView.swift` | Vue de connexion complète | Point d'entrée si non authentifié |

### Components
Composants intégrés dans LoginView pour le moment.

## 🔗 Dépendances

### Services Utilisés
- ✅ `JellyfinService.connect(to:)` - Connexion au serveur
- ✅ `JellyfinService.authenticate(username:password:)` - Authentification
- ✅ `JellyfinService.saveCredentials()` - Sauvegarde des credentials
- ✅ `UserDefaults` - Persistance des données

### Modèles Utilisés
- ✅ `ServerInfo` - Informations du serveur
- ✅ `User` - Utilisateur connecté
- ✅ `AuthenticationResult` - Résultat de l'authentification

## 🔄 Flux de Données

```
User entre URL
    ↓
LoginView.connectToServer()
    ↓
JellyfinService.connect(to:)
    ↓
Affiche formulaire username/password
    ↓
User entre credentials
    ↓
LoginView.authenticate()
    ↓
JellyfinService.authenticate()
    ↓
JellyfinService.saveCredentials()
    ↓
isAuthenticated = true
    ↓
Navigation vers HomeView
```

## 🎨 Design

### Couleurs Principales
- Accent : `AppTheme.jellyfinGradient`
- Erreurs : `Color.appError`
- Succès : `Color.appSuccess`

### Composants Partagés Utilisés
- ✅ `LoadingView` - Pendant la connexion
- ✅ `ErrorView` - En cas d'erreur
- ✅ `AppTheme` - Styles et spacings

## 🚀 Évolutions Futures

- [ ] Support de la connexion Quick Connect
- [ ] Mémorisation du dernier serveur utilisé
- [ ] Support multi-serveurs
- [ ] Authentification biométrique (Face ID)
- [ ] Sélection du profil utilisateur

## 🧪 Tests

### Tests Existants
- ✅ Validation d'URL (dans String+Extensions tests)
- ✅ Nettoyage d'URL (dans String+Extensions tests)

### Tests à Ajouter
- [ ] Test de flux d'authentification complet
- [ ] Test de gestion d'erreurs réseau
- [ ] Test de sauvegarde de credentials

---

*Feature créée le 23/11/2025*
```

---

## Exemple 2 : Features/Media/README.md

```markdown
# 🎬 Media

> Gère l'affichage et la lecture des médias (films, épisodes)

## 📁 Structure

```
Media/
├── Views/
│   └── MediaDetailView.swift
└── Components/
    ├── MediaCard.swift
    ├── CarouselMediaCard.swift
    └── NextEpisodeOverlay.swift
```

## 🎯 Responsabilités

Cette feature est responsable de :
- ✅ Affichage des détails d'un média
- ✅ Lecture vidéo avec AVPlayer
- ✅ Gestion de la progression de lecture
- ✅ Rapport de playback au serveur
- ✅ Lecture automatique de l'épisode suivant

## 🏗️ Architecture

### Views
| Fichier | Description | Route |
|---------|-------------|-------|
| `MediaDetailView.swift` | Détails et lecture d'un média | Navigation depuis n'importe où |

### Components
| Fichier | Description | Utilisé par |
|---------|-------------|-------------|
| `MediaCard.swift` | Carte de média pour les grilles | LibraryContentView, etc. |
| `CarouselMediaCard.swift` | Carte paysage pour carrousels | MediaCarousel |
| `NextEpisodeOverlay.swift` | Overlay "Épisode suivant" | MediaDetailView |

## 🔗 Dépendances

### Services Utilisés
- ✅ `JellyfinService.getStreamURL()` - URL de streaming
- ✅ `JellyfinService.reportPlaybackStart()` - Début de lecture
- ✅ `JellyfinService.reportPlaybackProgress()` - Progression
- ✅ `JellyfinService.reportPlaybackStopped()` - Fin de lecture
- ✅ `JellyfinService.getNextEpisode()` - Épisode suivant
- ✅ `NavigationCoordinator` - Navigation vers épisode suivant

### Modèles Utilisés
- ✅ `MediaItem` - Média à lire
- ✅ `UserData` - Progression utilisateur

### Frameworks Apple
- ✅ `AVFoundation` - Lecture vidéo
- ✅ `AVKit` - VideoPlayer

## 🔄 Flux de Données

```
User sélectionne média
    ↓
MediaDetailView s'ouvre
    ↓
User clique "Lire"
    ↓
getStreamURL()
    ↓
AVPlayer créé
    ↓
Seek to saved position
    ↓
reportPlaybackStart()
    ↓
[Lecture en cours]
    ↓
Timer toutes les 10s
    ↓
reportPlaybackProgress()
    ↓
Si 10s avant la fin d'un épisode
    ↓
NextEpisodeOverlay apparaît
    ↓
Countdown 10s
    ↓
reportPlaybackStopped()
    ↓
Navigation vers épisode suivant
    ↓
Auto-play
```

## 🎨 Design

### Couleurs Principales
- Progress bar : `AppTheme.progressColor`
- Overlay : Gradient noir semi-transparent
- Accents : `AppTheme.primaryColor`

### Composants Partagés Utilisés
- ✅ `LoadingView` - Pendant le chargement
- ✅ `ErrorView` - En cas d'erreur
- ✅ `AppTheme` - Styles et animations

### Animations
- Apparition overlay : `AppTheme.standardAnimation`
- Countdown : Spring animation
- Scale on focus : `AppTheme.focusScale`

## 🚀 Évolutions Futures

- [ ] Support des sous-titres
- [ ] Sélection de piste audio
- [ ] Qualité de streaming ajustable
- [ ] Picture-in-picture (si supporté tvOS)
- [ ] Skip intro / skip credits
- [ ] Chapitres
- [ ] Lecture aléatoire
- [ ] Binge mode amélioré

## 🧪 Tests

### Tests Existants
- ✅ Formatage de durée (TimeInterval+Extensions)
- ✅ Conversion ticks (TimeInterval+Extensions)

### Tests à Ajouter
- [ ] Test du timer de progression
- [ ] Test de la détection de fin d'épisode
- [ ] Test du countdown overlay
- [ ] Test de navigation vers épisode suivant
- [ ] Test du rapport de playback
- [ ] Mock du AVPlayer pour tests

---

*Feature créée le 23/11/2025*
*Mise à jour majeure le 16/12/2025 (NextEpisodeOverlay)*
```

---

## Exemple 3 : Features/Home/README.md

```markdown
# 🏠 Home

> Page d'accueil avec médias à reprendre et récents

## 📁 Structure

```
Home/
├── Views/
│   └── HomeView.swift
└── Components/
    └── MediaCarousel.swift
```

## 🎯 Responsabilités

Cette feature est responsable de :
- ✅ Affichage des médias "À reprendre"
- ✅ Affichage des médias "Récemment ajoutés"
- ✅ Navigation vers les bibliothèques
- ✅ Point d'entrée principal après login

## 🏗️ Architecture

### Views
| Fichier | Description | Route |
|---------|-------------|-------|
| `HomeView.swift` | Page d'accueil principale | `/home` (après auth) |

### Components
| Fichier | Description | Utilisé par |
|---------|-------------|-------------|
| `MediaCarousel.swift` | Carrousel horizontal de médias | HomeView, potentiellement autres |

## 🔗 Dépendances

### Services Utilisés
- ✅ `JellyfinService.getResumeItems()` - Médias à reprendre
- ✅ `JellyfinService.getRecentItems()` - Médias récents
- ✅ `NavigationCoordinator` - Navigation vers détails

### Modèles Utilisés
- ✅ `MediaItem` - Médias affichés
- ✅ `UserData` - Progression de lecture

## 🔄 Flux de Données

```
HomeView.onAppear
    ↓
Task {
    loadResumeItems()
    loadRecentItems()
}
    ↓
JellyfinService API calls
    ↓
@State resumeItems / recentItems
    ↓
MediaCarousel affiche
    ↓
User clique sur média
    ↓
Navigation vers MediaDetailView
```

## 🎨 Design

### Layout
- ScrollView vertical
- Deux carrousels horizontaux
- Lien vers bibliothèques en bas

### Couleurs Principales
- Background : `AppTheme.backgroundGradient`
- Accents : `AppTheme.primaryColor`

### Composants Partagés Utilisés
- ✅ `LoadingView` - Pendant le chargement
- ✅ `ErrorView` - En cas d'erreur
- ✅ `EmptyContentView` - Si rien à reprendre
- ✅ `MediaCarousel` - Affichage des médias
- ✅ `CarouselMediaCard` - Cartes dans le carrousel

## 🚀 Évolutions Futures

- [ ] Section "Recommandé pour vous"
- [ ] Section "Continuer à regarder [Série]"
- [ ] Section "Nouveaux épisodes"
- [ ] Tri personnalisable des sections
- [ ] Actualisation pull-to-refresh

## 🧪 Tests

### Tests Existants
Aucun test spécifique pour le moment.

### Tests à Ajouter
- [ ] Test de chargement des données
- [ ] Test d'affichage vide
- [ ] Test de navigation vers détails
- [ ] Test du carrousel

---

*Feature créée le 23/11/2025*
```

---

## 📝 Instructions

1. **Copiez** le template ci-dessus
2. **Créez** un fichier `README.md` dans chaque dossier Feature
3. **Adaptez** le contenu selon la feature
4. **Mettez à jour** au fur et à mesure des évolutions

Ces README aident à :
- Onboarder rapidement les nouveaux développeurs
- Comprendre les responsabilités de chaque feature
- Planifier les évolutions
- Documenter les dépendances

---

*Template créé le 23 décembre 2025*
