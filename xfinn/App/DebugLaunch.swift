//
//  DebugLaunch.swift
//  xfinn
//
//  DEBUG uniquement : connexion et navigation pilotées par les arguments de
//  lancement, pour la QA sur simulateur et les captures App Store sans
//  interaction (simctl launch … -xfinnDebugRoute <route>).
//
//  -xfinnDebugServer <url> -xfinnDebugUser <nom>   connexion ; mot de passe
//                   dans l'environnement XFINN_DEBUG_PASSWORD (simctl :
//                   SIMCTL_CHILD_XFINN_DEBUG_PASSWORD), vide par défaut
//                   (serveur de démo Jellyfin)
//  -xfinnDebugRoute home | libraries | library:<nom> | search | music | settings
//                   | item:<id> | play:<id>
//  -xfinnDebugSeeks "20:1500,40:300"   dans le lecteur, après 20 s de lecture
//                   sauter à 1500 s, puis après 40 s à 300 s (stress des sauts) ;
//                   aussi "15:audio=2", "15:sub=4" / "15:sub=none",
//                   "15:quality=8000000" (changements de piste et de qualité),
//                   "15:native=fr" / "15:native=off" (choix dans le menu natif),
//                   "5:show" (sous-titres affichés)
//

#if DEBUG
import SwiftUI

@MainActor
enum DebugLaunch {
    /// Réglages à présenter en feuille (lu par ContentView)
    static var showSettings = false

    static func run(jellyfinService: JellyfinService, coordinator: NavigationCoordinator) async {
        let defaults = UserDefaults.standard
        guard let route = defaults.string(forKey: "xfinnDebugRoute") else { return }

        if !jellyfinService.isAuthenticated,
           let server = defaults.string(forKey: "xfinnDebugServer"),
           let user = defaults.string(forKey: "xfinnDebugUser") {
            do {
                _ = try await jellyfinService.connect(to: server)
                let password = ProcessInfo.processInfo.environment["XFINN_DEBUG_PASSWORD"] ?? ""
                try await jellyfinService.authenticate(username: user, password: password)
            } catch {
                print("[DebugLaunch] Login failed: \(error)")
                return
            }
        }

        // Laisse l'accueil se construire avant de pousser un écran
        try? await Task.sleep(for: .seconds(2))

        let parts = route.split(separator: ":", maxSplits: 1).map(String.init)
        do {
            switch parts[0] {
            case "libraries":
                coordinator.navigationPath.append(AppRoute.libraries)
            case "library" where parts.count == 2:
                let libraries = try await jellyfinService.getLibraries()
                if let library = libraries.first(where: { $0.name == parts[1] }) {
                    coordinator.navigationPath.append(AppRoute.library(library))
                }
            case "search":
                coordinator.navigateToSearch()
            case "music":
                coordinator.navigateToMusicLibrary()
            case "settings":
                showSettings = true
            case "item" where parts.count == 2:
                coordinator.navigateTo(item: try await jellyfinService.getItemDetails(itemId: parts[1]))
            case "play" where parts.count == 2:
                coordinator.navigateTo(item: try await jellyfinService.getItemDetails(itemId: parts[1]), autoPlay: true)
            default:
                break
            }
        } catch {
            print("[DebugLaunch] Route \(route) failed: \(error)")
        }
    }

    private static var didScheduleSeeks = false

    /// Sauts programmés (-xfinnDebugSeeks), une seule fois par lancement
    static func scheduleSeeks(on player: PlayerManager) {
        guard !didScheduleSeeks,
              let spec = UserDefaults.standard.string(forKey: "xfinnDebugSeeks") else { return }
        didScheduleSeeks = true
        let steps = spec.split(separator: ",").compactMap { step -> (Double, String)? in
            let parts = step.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2, let delay = Double(parts[0]) else { return nil }
            return (delay, parts[1])
        }
        Task { @MainActor in
            for (delay, action) in steps {
                try? await Task.sleep(for: .seconds(delay))
                print("[DebugLaunch] \(action) (state \(player.state), t=\(Int(player.currentTime))s)")
                let pair = action.split(separator: "=", maxSplits: 1).map(String.init)
                switch pair.first {
                case "audio" where pair.count == 2:
                    player.switchAudioTrack(to: Int(pair[1]))
                case "sub" where pair.count == 2:
                    player.switchSubtitle(to: Int(pair[1]))
                case "native" where pair.count == 2:
                    await player.debugSelectNativeSubtitle(language: pair[1] == "off" ? nil : pair[1])
                case "show":
                    print("[DebugLaunch] subtitles: \(await player.debugNativeSubtitleDescription())")
                case "quality" where pair.count == 2:
                    if let raw = Int(pair[1]), let quality = StreamQuality(rawValue: raw) {
                        player.switchQuality(to: quality)
                    }
                default:
                    if let target = Double(action) { player.seek(to: target) }
                }
            }
            try? await Task.sleep(for: .seconds(10))
            print("[DebugLaunch] done (state \(player.state), t=\(Int(player.currentTime))s)")
        }
    }
}
#endif
