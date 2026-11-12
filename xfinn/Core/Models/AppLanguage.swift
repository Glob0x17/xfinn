//
//  AppLanguage.swift
//  xfinn
//
//  Created by Dorian Galiana on 12/11/2026.
//

import Foundation

/// Langue de l'interface choisie dans les réglages de l'app.
/// tvOS n'a pas de réglage de langue par app (iOS l'a dans Réglages > xfinn),
/// d'où ce choix dans l'app, sur les deux plateformes.
enum AppLanguage {
    /// Langues traduites, dans l'ordre du sélecteur (noms des dossiers .lproj)
    static let supported = ["en", "fr", "es", "pt", "de", "it"]

    /// Langue choisie ; nil = suivre la langue du système
    static var selected: String? {
        get { UserDefaults.standard.appLanguage.flatMap { supported.contains($0) ? $0 : nil } }
        set {
            // Cache vidé avant l'écriture : l'écriture redessine l'interface (@AppStorage)
            cachedBundle = nil
            UserDefaults.standard.appLanguage = newValue
        }
    }

    /// Code de la langue réellement affichée (choix de l'utilisateur ou résolution du système)
    static var effective: String {
        selected ?? Bundle.main.preferredLocalizations.first ?? "en"
    }

    /// Locale à injecter dans l'environnement SwiftUI (dates, nombres)
    static var locale: Locale {
        selected.map(Locale.init(identifier:)) ?? .autoupdatingCurrent
    }

    /// Nom d'une langue dans cette langue même ("Deutsch", "Français"…)
    static func nativeName(of code: String) -> String {
        let name = Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    /// Bundle des chaînes : le .lproj choisi, ou le bundle principal (résolution système)
    static var bundle: Bundle {
        if let cachedBundle { return cachedBundle }
        let resolved = selected
            .flatMap { Bundle.main.path(forResource: $0, ofType: "lproj") }
            .flatMap(Bundle.init(path:)) ?? .main
        cachedBundle = resolved
        return resolved
    }

    private static var cachedBundle: Bundle?
}
