//
//  OrientationLock.swift
//  xfinn
//
//  Orientations sur iOS : sur iPhone l'interface reste en portrait et seul le
//  player vidéo peut passer en paysage ; sur iPad toutes les orientations sont
//  permises (exigé par l'App Store pour le multitâche).
//

#if os(iOS)
import UIKit

@MainActor
enum OrientationLock {
    private static var isPlayerVisible = false

    static var supportedOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad { return .all }
        return isPlayerVisible ? .allButUpsideDown : .portrait
    }

    /// Appelé à l'ouverture et à la fermeture du player plein écran
    static func setPlayerVisible(_ visible: Bool) {
        guard UIDevice.current.userInterfaceIdiom == .phone, visible != isPlayerVisible else { return }
        isPlayerVisible = visible

        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
            // En quittant le player en paysage, revenir tout de suite en portrait
            if !visible {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        MainActor.assumeIsolated { OrientationLock.supportedOrientations }
    }
}
#endif
