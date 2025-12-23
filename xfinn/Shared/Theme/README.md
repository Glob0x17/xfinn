# XFINN

> Modern Jellyfin client for tvOS with Liquid Glass design

[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-tvOS_17+-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/tvos/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-0081FB?style=flat-square&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

[English](#english) • [Français](#français)

---

## English

### About

XFINN is a modern Jellyfin client designed specifically for tvOS, offering a smooth and elegant user experience with Apple's Liquid Glass design inspiration. Enjoy your Jellyfin media library with an interface optimized for Apple TV.

### Features

**Media Playback**
- Video playback with AVPlayer
- Automatic resume functionality
- Full playback controls
- Progress tracking
- Multiple audio and subtitle support

**Library Management**
- Browse by libraries (Movies, TV Shows, etc.)
- Advanced search across all content
- Filter by media type
- High-quality poster display
- Complete metadata and ratings

**TV Series**
- Detailed series view with synopsis
- Season navigation
- Episode tracking
- Progress monitoring per episode

**Home Screen**
- "Continue Watching" carousel
- "Recently Added" section
- Horizontal scrolling layouts
- Image preloading for smooth performance

**Design**
- Liquid Glass Design effects
- Electric purple focus effects
- Smooth spring animations
- Modern gradients (Jellyfin purple/blue)
- Adaptive interface for tvOS

### Installation

**Requirements**
- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+
- tvOS 17.0+ Simulator or Apple TV device
- Jellyfin Server 10.8.0+

**Steps**

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/xfinn.git
   cd xfinn
   ```

2. Open in Xcode
   ```bash
   open xfinn.xcodeproj
   ```

3. Select the tvOS target and build

4. Connect to your Jellyfin server using the login screen

### Architecture

Built with modern Swift technologies:
- **SwiftUI** for UI
- **AVKit** for video playback
- **Combine** for reactive programming
- **URLSession** for networking
- **Swift Concurrency** (async/await)

Design patterns:
- MVVM architecture
- Service layer for API calls
- Observable objects for state management
- Reusable components
- Centralized theming

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Français

### À propos

XFINN est un client Jellyfin moderne conçu spécifiquement pour tvOS, offrant une expérience utilisateur fluide et élégante avec un design inspiré du Liquid Glass d'Apple. Profitez de votre bibliothèque multimédia Jellyfin avec une interface optimisée pour l'Apple TV.

### Fonctionnalités

**Lecture de médias**
- Lecture vidéo avec AVPlayer
- Reprise automatique de lecture
- Contrôles de lecture complets
- Suivi de progression
- Support audio et sous-titres multiples

**Gestion de bibliothèque**
- Navigation par bibliothèques (Films, Séries, etc.)
- Recherche avancée
- Filtres par type de média
- Affichage haute qualité des posters
- Métadonnées et notes complètes

**Séries TV**
- Vue détaillée des séries avec synopsis
- Navigation par saisons
- Suivi des épisodes
- Progression par épisode

**Page d'accueil**
- Carrousel "À reprendre"
- Section "Récemment ajoutés"
- Défilement horizontal
- Pré-chargement des images

**Design**
- Effets Liquid Glass Design
- Contours de focus violet électrique
- Animations spring fluides
- Gradients modernes (violet/bleu Jellyfin)
- Interface adaptative tvOS

### Installation

**Prérequis**
- macOS 14.0+ (Sonoma ou supérieur)
- Xcode 15.0+
- Simulateur tvOS 17.0+ ou Apple TV
- Serveur Jellyfin 10.8.0+

**Étapes**

1. Cloner le repository
   ```bash
   git clone https://github.com/votre-username/xfinn.git
   cd xfinn
   ```

2. Ouvrir dans Xcode
   ```bash
   open xfinn.xcodeproj
   ```

3. Sélectionner la cible tvOS et compiler

4. Se connecter au serveur Jellyfin via l'écran de connexion

### Architecture

**Technologies**
- SwiftUI pour l'interface utilisateur
- AVKit pour la lecture vidéo
- Combine pour la programmation réactive
- URLSession pour le réseau
- Swift Concurrency (async/await)

**Patterns**
- Architecture MVVM
- Couche service pour les appels API
- Observable objects pour la gestion d'état
- Composants réutilisables
- Thème centralisé

### Design System

**Couleurs**
```
Violet Jellyfin : #AA5CC3
Bleu Jellyfin   : #00A4DF
Focus violet    : #BF5AF2
```

**Typographie tvOS**
- Large Title: 70pt Bold
- Title: 58pt Bold
- Headline: 32pt Medium
- Body: 28pt Regular

### Contribuer

Les contributions sont les bienvenues ! N'hésitez pas à soumettre une Pull Request.

### License

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

**Made with ❤️ for the Jellyfin and Apple TV community**

