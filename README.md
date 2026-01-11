# xfinn - Jellyfin Client for tvOS

A beautiful native tvOS client for Jellyfin media servers. Stream your personal movie and TV show collection directly on your Apple TV.

![tvOS](https://img.shields.io/badge/tvOS-18.6+-purple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

## Features

- **Native tvOS Experience**
  - Beautiful glass-morphism design
  - Smooth animations and transitions
  - Optimized for Apple TV remote navigation

- **Media Playback**
  - Direct Play for compatible formats
  - Transcoding support with quality selection (Auto, 4K, 1080p, 720p, etc.)
  - Resume playback across devices
  - Auto-play next episode
  - Subtitle support (multiple formats)

- **Library Management**
  - Browse all your libraries (Movies, TV Shows, Music, etc.)
  - Full series navigation (Series → Seasons → Episodes)
  - Search across your entire media collection
  - Recently added and continue watching sections

- **Multi-language Support**
  - English, French, Spanish, Portuguese
  - Automatic language detection based on device settings

## Screenshots

| Home | Library | Detail |
|------|---------|--------|
| ![Home](screenshots/home.png) | ![Library](screenshots/library.png) | ![Detail](screenshots/detail.png) |

## Requirements

- **tvOS 18.6+**
- **Jellyfin Server 10.8+**
- **Apple TV 4K** (recommended) or Apple TV HD

## Installation

### From Source

1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/xfinn.git
```

2. Open the project in Xcode
```bash
cd xfinn
open xfinn.xcodeproj
```

3. Select your Apple TV as the build target

4. Build and run (⌘+R)

### From App Store

Coming soon!

## Usage

### First Launch

1. Launch xfinn on your Apple TV
2. Enter your Jellyfin server URL (e.g., `http://192.168.1.100:8096`)
3. Enter your Jellyfin username and password
4. Enjoy your media!

### Navigation

- **Touch Surface** - Navigate through menus
- **Play/Pause** - Control video playback
- **Menu Button** - Go back / Access options
- **Swipe Down** - Access playback controls during video

## Architecture

The app follows the **MVVM** (Model-View-ViewModel) architecture pattern:

```
xfinn/
├── Core/
│   ├── Models/          # Data models (MediaItem, User, etc.)
│   ├── Services/        # JellyfinService, AuthService, PlaybackService
│   └── ViewModels/      # BaseViewModel, shared logic
├── Features/
│   ├── Home/            # Home screen with Continue Watching
│   ├── Library/         # Library browsing
│   ├── Search/          # Search functionality
│   ├── Series/          # TV series navigation
│   ├── Player/          # Video playback
│   └── Settings/        # App settings
├── Shared/
│   ├── Components/      # Reusable UI components
│   ├── Extensions/      # Swift extensions
│   └── Theme/           # App theming (AppTheme)
└── Resources/
    ├── Assets.xcassets  # Images and app icons
    └── Localizable/     # Localization strings (EN, FR, ES, PT)
```

## Jellyfin API

xfinn uses the following Jellyfin API endpoints:

| Endpoint | Purpose |
|----------|---------|
| `GET /System/Info/Public` | Server information |
| `POST /Users/AuthenticateByName` | Authentication |
| `GET /Users/{userId}/Views` | Library list |
| `GET /Users/{userId}/Items` | Media items |
| `GET /Items/{itemId}/PlaybackInfo` | Playback URLs |
| `POST /Sessions/Playing` | Report playback start |
| `POST /Sessions/Progress` | Report progress |
| `POST /Sessions/Stopped` | Report playback stop |

## Tech Stack

- **SwiftUI** - Declarative UI framework
- **AVKit / AVPlayer** - Native video playback
- **Combine** - Reactive state management
- **async/await** - Modern Swift concurrency
- **HLS Streaming** - HTTP Live Streaming for transcoded content

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Privacy

xfinn does not collect any personal data. All communication happens directly between your Apple TV and your Jellyfin server. See our [Privacy Policy](https://xfinn.flyc.fr/privacy-policy.html) for more details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Jellyfin](https://jellyfin.org/) - The amazing open-source media server
- [Swiftfin](https://github.com/jellyfin/Swiftfin) - Reference implementation

## Author

**Dorian Galiana** - 2025

---

Made with ❤️ for the Jellyfin community
