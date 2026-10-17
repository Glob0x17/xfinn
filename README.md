# xfinn — Jellyfin client for Apple TV

A native tvOS client for [Jellyfin](https://jellyfin.org) media servers, built with SwiftUI and AVKit. Browse your movies, shows and music and play them with Apple's native player.

![tvOS](https://img.shields.io/badge/tvOS-18.6+-purple)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

## Features

### Sign-in
- Automatic discovery of Jellyfin servers on the local network
- Manual server address (with or without scheme and port)
- Username/password or **Quick Connect** (approve a code from another device, no typing on the remote)
- Recent servers, session stored in the Keychain

### Browsing
- Home screen with a hero banner, Continue Watching, recently added and favorites
- Libraries with sorting, an unwatched filter and server-side pagination
- Series pages with season chips and episode cards (progress, watched state)
- Global search across movies, shows, episodes and music
- Mark as watched/unwatched and add to favorites from any card (long press)
- **Top Shelf** extension with Continue Watching, and deep links into the app

### Playback
- Device profile built from the actual Apple TV hardware (HEVC, HDR10, HDR10+, Dolby Vision, AV1)
- Direct Play when the file is natively supported, HLS (fMP4) transcoding or remuxing otherwise — the server decides
- Fragmented MP4 files are detected and remuxed to HLS instead of Direct Play, which AVPlayer cannot load in reasonable time
- Automatic fallbacks: HLS retry when Direct Play fails, AAC audio retry when a transcoded stream is rejected
- In-player panels on tvOS: audio track, streaming quality (Auto, Maximum, 120 Mbps down to 4 Mbps) and technical details
- Text subtitles delivered as native HLS renditions (with a timing fix for Jellyfin's WebVTT segments); image subtitles are burned in
- Skip Intro / Credits / Recap using Jellyfin media segments, with an optional auto-skip for intros
- Resume where you left off, progress reported to the server, next-episode countdown

### Music
- Artists, albums and tracks
- Full-screen player with repeat modes, plus a floating mini player while browsing
- Now Playing and remote control integration

### Languages
English, French, Spanish and Portuguese, following the device language.

## Requirements

- Apple TV running **tvOS 18.6** or later
- A Jellyfin server (developed and tested against **Jellyfin 12**; skip segments need a server that provides media segments, 10.10 or later)
- Xcode with the tvOS 18.6 SDK or later (developed with Xcode 27)

## Building

1. Clone the repository and open `xfinn.xcodeproj`.
2. For the `xfinn` and `TopShelf` targets, select your own development team and change the bundle identifiers (`doriang.xfinn`, `doriang.xfinn.TopShelf`).
3. Change the App Group (`group.doriang.xfinn`) in both entitlements files (`Config/`) and in `TopShelf/TopShelfContentProvider.swift`. The app and the Top Shelf extension share the session through it.
4. Select an Apple TV device or simulator and run.

Unit tests live in `xfinnTests` and cover the pure logic (device profile, HLS playlist rewriting, MP4 layout detection, URL handling, sorting…).

## Project structure

```
xfinn/
├── App/            Entry point, root view, navigation destinations
├── Core/
│   ├── Coordinators/   Navigation (single NavigationStack path)
│   ├── Models/         Jellyfin models, device profile, capabilities
│   ├── Services/       Auth, media, playback, player, Keychain, discovery
│   └── ViewModels/
├── Features/       Authentication, Home, Library, Series, Media, Music, Search, Settings
├── Shared/         Theme, reusable components, extensions
└── Resources/      Localizations
TopShelf/           Top Shelf extension
xfinnTests/         Unit tests
```

The app follows MVVM. `JellyfinService` is the façade used by the views; it delegates to dedicated services (`AuthService`, `MediaService`, `PlaybackService`). Playback is handled by `PlayerManager` around `AVPlayer` and `AVPlayerViewController`.

## License

MIT — see [LICENSE](LICENSE).
