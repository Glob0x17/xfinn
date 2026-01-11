# xfinn - App Store Submission Guide

## Current Status: READY FOR SUBMISSION

### Completed Automatically
- [x] Privacy descriptions (NSLocalNetworkUsageDescription) - 4 languages
- [x] Debug code cleanup (all print statements wrapped in #if DEBUG)
- [x] Localizations (English, French, Spanish, Portuguese)
- [x] Base language set to English
- [x] App category: Entertainment
- [x] Bundle ID: `doriang.xfinn`
- [x] Marketing Version: 1.0
- [x] Build Number: 1
- [x] App Icons generated (see `/AppIcons/` folder)
- [x] Privacy Policy page created (see `/docs/privacy-policy.html`)
- [x] Support page created (see `/docs/support.html`)

---

## App Icons (GENERATED - Import to Xcode)

### tvOS App Icon Requirements

| Asset | Size | Purpose |
|-------|------|---------|
| **App Icon** | 400 x 240 px | Main app icon on tvOS home screen |
| **App Icon - App Store** | 1280 x 768 px | App Store listing |
| **Top Shelf Image** | 1920 x 720 px | Top Shelf when app is focused |
| **Top Shelf Image Wide** | 2320 x 720 px | Top Shelf wide format |

### Generated Icons Location
```
/Users/dorian/xfinn/AppIcons/
```

| File | Size | Use |
|------|------|-----|
| `AppIcon_400x240.png` | 400x240 | Main tvOS icon |
| `AppIcon_1280x768.png` | 1280x768 | App Store listing |
| `TopShelf_1920x720.png` | 1920x720 | Top Shelf |
| `TopShelf_2320x720.png` | 2320x720 | Top Shelf Wide |

### Parallax Layers (for 3D effect)
| File | Purpose |
|------|---------|
| `AppIcon_Back.png` | Background gradient |
| `AppIcon_Middle.png` | Glow effect |
| `AppIcon_Front.png` | "xfinn" text |

### How to Add Icons in Xcode
1. Open `xfinn.xcodeproj` in Xcode
2. Navigate to `Assets.xcassets` > `App Icon & Top Shelf Image`
3. Drag images from `/AppIcons/` folder to each slot
4. For parallax effect, use the _Back, _Middle, _Front layers

---

## REQUIRED: App Store Connect Metadata

### App Information

**App Name** (30 characters max):
```
xfinn - Jellyfin Client
```

**Subtitle** (30 characters max):
```
Stream Your Media Library
```

**Keywords** (100 characters max):
```
jellyfin,media,streaming,movies,tv,series,home,server,video,player
```

### Descriptions

**English:**
```
xfinn is a beautiful native tvOS client for Jellyfin media servers. Stream your personal movie and TV show collection directly on your Apple TV with a sleek, modern interface designed specifically for the big screen.

Features:
• Native tvOS experience with smooth animations
• Direct Play and transcoding support
• Subtitle support with multiple formats
• Resume playback across devices
• Auto-play next episode
• Quality selection (Auto, 4K, 1080p, 720p, etc.)
• Beautiful glass-morphism design

Requirements:
• Jellyfin server accessible on your network
• Apple TV 4K (2021 or later) recommended

Connect to your Jellyfin server and enjoy your media library like never before.
```

**French:**
```
xfinn est un magnifique client tvOS natif pour les serveurs multimédia Jellyfin. Diffusez votre collection de films et séries directement sur votre Apple TV avec une interface moderne et élégante conçue spécifiquement pour le grand écran.

Fonctionnalités:
• Expérience tvOS native avec animations fluides
• Lecture directe et support du transcodage
• Support des sous-titres multiples formats
• Reprise de lecture multi-appareils
• Lecture automatique de l'épisode suivant
• Sélection de qualité (Auto, 4K, 1080p, 720p, etc.)
• Design moderne glass-morphism

Prérequis:
• Serveur Jellyfin accessible sur votre réseau
• Apple TV 4K (2021 ou plus récent) recommandé

Connectez-vous à votre serveur Jellyfin et profitez de votre médiathèque comme jamais.
```

**Spanish:**
```
xfinn es un hermoso cliente tvOS nativo para servidores Jellyfin. Transmite tu colección personal de películas y series directamente en tu Apple TV con una interfaz moderna y elegante diseñada específicamente para la pantalla grande.

Características:
• Experiencia tvOS nativa con animaciones fluidas
• Reproducción directa y soporte de transcodificación
• Soporte de subtítulos en múltiples formatos
• Reanudar reproducción entre dispositivos
• Reproducción automática del siguiente episodio
• Selección de calidad (Auto, 4K, 1080p, 720p, etc.)
• Diseño moderno glass-morphism

Requisitos:
• Servidor Jellyfin accesible en tu red
• Apple TV 4K (2021 o posterior) recomendado
```

**Portuguese:**
```
xfinn é um lindo cliente tvOS nativo para servidores Jellyfin. Transmita sua coleção pessoal de filmes e séries diretamente no seu Apple TV com uma interface moderna e elegante projetada especificamente para a tela grande.

Recursos:
• Experiência tvOS nativa com animações suaves
• Reprodução direta e suporte a transcodificação
• Suporte a legendas em múltiplos formatos
• Retomar reprodução entre dispositivos
• Reprodução automática do próximo episódio
• Seleção de qualidade (Auto, 4K, 1080p, 720p, etc.)
• Design moderno glass-morphism

Requisitos:
• Servidor Jellyfin acessível em sua rede
• Apple TV 4K (2021 ou posterior) recomendado
```

### Privacy Policy URL
**File created:** `/docs/privacy-policy.html`

Host this file on any web server (GitHub Pages, Netlify, your own domain) and use the URL in App Store Connect.

Example URLs after hosting:
- `https://yourusername.github.io/xfinn/privacy-policy.html`
- `https://xfinn.example.com/privacy-policy.html`

### Support URL
**File created:** `/docs/support.html`

Host this file alongside the privacy policy and use the URL in App Store Connect.

Example URLs after hosting:
- `https://yourusername.github.io/xfinn/support.html`
- `https://xfinn.example.com/support.html`

---

## Screenshots Required

### tvOS Screenshot Sizes
- **1920 x 1080** (1080p) - Required
- **3840 x 2160** (4K) - Optional but recommended

### Recommended Screenshots (minimum 3, maximum 10):
1. Home screen with "Continue Watching" and "Recently Added"
2. Movie/Series detail view
3. Playback screen
4. Library view
5. Search results
6. Settings screen

---

## Pre-Submission Checklist

### In Xcode
- [ ] Set scheme to "Release"
- [ ] Archive the app (Product > Archive)
- [ ] Validate archive before upload
- [ ] Upload to App Store Connect

### In App Store Connect
- [ ] Create new app with bundle ID `doriang.xfinn`
- [ ] Fill in all metadata (name, descriptions, keywords)
- [ ] Upload app icons and screenshots
- [ ] Set pricing (Free)
- [ ] Add privacy policy URL
- [ ] Add support URL
- [ ] Select content rating
- [ ] Submit for review

---

## Technical Notes

### Deployment Target
- tvOS 18.6+

### Supported Devices
- Apple TV 4K (all generations)
- Apple TV HD (limited features)

### Code Signing
- Automatic signing enabled
- Development Team: 33P6KB3Y7P

### Privacy
- NSLocalNetworkUsageDescription: Configured in all 4 languages

---

## Version History

### 1.0 (Build 1)
- Initial release
- Native tvOS interface
- Direct Play and transcoding support
- Multi-language support (EN, FR, ES, PT)
- Subtitle support
- Quality selection
- Resume playback
- Auto-play next episode
