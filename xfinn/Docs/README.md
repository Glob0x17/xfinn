# xfinn - Client Jellyfin pour tvOS

Une application tvOS native pour accéder à votre serveur Jellyfin et profiter de vos médias sur Apple TV.

## Fonctionnalités

### ✅ Implémenté

- **Connexion au serveur Jellyfin**
  - Connexion à un serveur via son URL
  - Authentification par nom d'utilisateur et mot de passe
  - Sauvegarde automatique des identifiants
  - Reconnexion automatique au lancement

- **Navigation dans les bibliothèques**
  - Affichage de toutes les bibliothèques disponibles
  - Interface optimisée pour tvOS avec grilles adaptatives
  - Cartes visuelles avec images et icônes

- **Gestion des médias**
  - Affichage des films et séries
  - Navigation complète pour les séries (Série → Saisons → Épisodes)
  - Détails complets des médias (synopsis, notes, durée, etc.)
  - Affichage des posters et images backdrop

- **Lecture de vidéos**
  - Lecture native avec AVPlayer
  - Reprise automatique à la dernière position
  - Interface de lecture plein écran
  - Rapport de progression au serveur Jellyfin
  - Sauvegarde de la position de lecture

## Architecture

### Structure du projet

```
xfinn/
├── ContentView.swift           # Vue principale avec gestion de l'authentification
├── JellyfinService.swift       # Service de communication avec l'API Jellyfin
├── JellyfinModels.swift        # Modèles de données Jellyfin
├── LoginView.swift             # Écran de connexion
├── LibraryView.swift           # Affichage des bibliothèques
├── LibraryContentView.swift    # Contenu d'une bibliothèque
├── MediaDetailView.swift       # Détails et lecture d'un média
└── SeriesDetailView.swift      # Navigation dans les séries TV
```

### Composants principaux

#### JellyfinService
Service centralisé pour toutes les interactions avec le serveur Jellyfin :
- Connexion et authentification
- Récupération des bibliothèques et médias
- Génération d'URLs de streaming
- Rapport de progression de lecture
- Gestion des sessions persistantes

#### Modèles de données
- `ServerInfo` : Informations sur le serveur
- `User` : Utilisateur authentifié
- `LibraryItem` : Bibliothèque (Films, Séries, Musique, etc.)
- `MediaItem` : Élément multimédia (Film, Série, Saison, Épisode)
- `UserData` : Données utilisateur (progression, statut vu/non vu)

## Configuration requise

- **tvOS 17.0+** (pour les fonctionnalités SwiftUI modernes)
- **Serveur Jellyfin 10.8+**
- **Connexion réseau** au serveur Jellyfin

## Installation

1. Clonez ou téléchargez le projet
2. Ouvrez `xfinn.xcodeproj` dans Xcode
3. Sélectionnez votre Apple TV comme destination
4. Compilez et exécutez le projet

## Utilisation

### Première connexion

1. Lancez l'application sur votre Apple TV
2. Entrez l'URL de votre serveur Jellyfin (ex: `http://192.168.1.100:8096`)
3. Entrez vos identifiants Jellyfin
4. Profitez de vos médias !

### Navigation

- **Télécommande Apple TV** : Utilisez le pavé tactile pour naviguer
- **Siri Remote** : Compatible avec tous les gestes standards
- **Menu** : Retour en arrière dans la navigation
- **Play/Pause** : Contrôle de la lecture vidéo

## API Jellyfin utilisées

- `GET /System/Info/Public` - Informations du serveur
- `POST /Users/AuthenticateByName` - Authentification
- `GET /Users/{userId}/Views` - Liste des bibliothèques
- `GET /Users/{userId}/Items` - Contenu des bibliothèques
- `GET /Videos/{itemId}/stream` - Streaming vidéo
- `POST /Sessions/Playing` - Début de lecture
- `POST /Sessions/Progress` - Progression de lecture
- `POST /Sessions/Stopped` - Fin de lecture

## Améliorations futures possibles

- [ ] Recherche de médias
- [ ] Filtres et tri avancés
- [ ] Support de la lecture audio
- [ ] Support des sous-titres
- [ ] Sélection de la piste audio
- [ ] Gestion des profils utilisateur
- [ ] Téléchargement pour visionnage hors ligne
- [ ] Support des listes de lecture
- [ ] Recommandations personnalisées
- [ ] Support du contenu en direct (TV)
- [ ] Interface de gestion des utilisateurs

## Technologies utilisées

- **SwiftUI** - Interface utilisateur déclarative
- **AVKit** - Lecture vidéo native
- **Combine** - Gestion de l'état réactif
- **async/await** - Programmation asynchrone moderne
- **URLSession** - Communication réseau
- **UserDefaults** - Persistance des sessions

## Notes de développement

### tvOS vs iOS

L'application est spécifiquement optimisée pour tvOS :
- Pas de support de `.roundedBorder` (remplacé par des styles personnalisés)
- Focus et navigation optimisés pour la télécommande
- Grilles et cartes dimensionnées pour l'affichage TV
- Polices et espacements adaptés à la distance de visionnage

### Sécurité

- Les tokens d'accès sont stockés localement dans UserDefaults
- Les mots de passe ne sont jamais stockés
- Communication HTTPS recommandée pour la production

## Licence

Ce projet est fourni à titre d'exemple pour l'apprentissage du développement tvOS avec Jellyfin.

## Auteur

Dorian Galiana - 2025

## Remerciements

- L'équipe Jellyfin pour leur excellent serveur média open-source
- La communauté Apple Developer pour les ressources SwiftUI
