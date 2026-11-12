//
//  SettingsView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Updated on 10/01/2026: Enhanced quality settings with all bitrate options
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var jellyfinService: JellyfinService
    @Environment(\.dismiss) private var dismiss

    @State private var showLogoutConfirmation = false

    private static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private static let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    #if os(tvOS)
    private static let platformName = "tvOS"
    #else
    private static let platformName = UIDevice.current.systemName
    #endif

    var body: some View {
        NavigationStack {
            List {
                // Section Utilisateur
                Section("settings.user".localized) {
                    if let user = jellyfinService.currentUser {
                        LabeledContent("settings.name".localized, value: user.name)
                        .infoRow()
                        LabeledContent("settings.id".localized, value: user.id)
                        .infoRow()
                    }
                }

                // Section Serveur
                Section("settings.server".localized) {
                    if let serverInfo = jellyfinService.serverInfo {
                        LabeledContent("settings.name".localized, value: serverInfo.serverName)
                        .infoRow()
                        LabeledContent("settings.version".localized, value: serverInfo.version)
                        .infoRow()
                        LabeledContent("settings.system".localized, value: serverInfo.operatingSystem)
                        .infoRow()
                    }

                    LabeledContent("settings.url".localized, value: jellyfinService.serverURL)
                    .infoRow()
                }

                // Section Application
                Section("settings.application".localized) {
                    LabeledContent("settings.version".localized, value: Self.appVersion)
                    .infoRow()
                    LabeledContent("Build", value: Self.buildNumber)
                    .infoRow()
                    LabeledContent("settings.platform".localized, value: Self.platformName)
                    .infoRow()

                    // Page de choix explicite : sur tvOS, un Picker en style navigationLink
                    // ouvre une page vide (rien ne prend le focus)
                    NavigationLink {
                        LanguageSelectionView()
                    } label: {
                        LabeledContent(
                            "settings.language".localized,
                            value: AppLanguage.selected.map(AppLanguage.nativeName(of:)) ?? "settings.language_system".localized
                        )
                    }
                }

                // Section Streaming
                Section {
                    Picker("settings.streaming_quality".localized, selection: $jellyfinService.preferredQuality) {
                        ForEach(StreamQuality.allCases) { quality in
                            HStack {
                                Text(quality.displayName)
                                Spacer()
                                Text(quality.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(quality)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    // Afficher une description de la qualité sélectionnée
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.selected_quality".localized(with: jellyfinService.preferredQuality.displayName))
                            .font(.subheadline)
                        Text(jellyfinService.preferredQuality.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("settings.streaming".localized)
                } footer: {
                    Text("settings.quality_footer".localized)
                }

                // Section Lecture
                Section {
                    Toggle("settings.auto_skip_intro".localized, isOn: Binding(
                        get: { UserDefaults.standard.autoSkipIntro },
                        set: { UserDefaults.standard.autoSkipIntro = $0 }
                    ))
                } header: {
                    Text("settings.playback".localized)
                } footer: {
                    Text("settings.auto_skip_intro_footer".localized)
                }

                // Section Actions
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Label("settings.sign_out".localized, systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }
            }
            .alert("settings.sign_out_confirm".localized, isPresented: $showLogoutConfirmation) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("settings.sign_out".localized, role: .destructive) {
                    jellyfinService.logout()
                    dismiss()
                }
            } message: {
                Text("settings.sign_out_message".localized)
            }
        }
    }
}

// MARK: - Language

/// Choix de la langue : « Système » puis chaque langue écrite dans sa propre langue
private struct LanguageSelectionView: View {
    var body: some View {
        List {
            row(code: nil, title: "settings.language_system".localized)
            ForEach(AppLanguage.supported, id: \.self) { code in
                row(code: code, title: AppLanguage.nativeName(of: code))
            }
        }
        .navigationTitle("settings.language".localized)
    }

    private func row(code: String?, title: String) -> some View {
        Button {
            // Reconstruit l'interface dans la nouvelle langue (cf. xfinnApp)
            AppLanguage.selected = code
        } label: {
            HStack {
                Text(title)
                Spacer()
                if AppLanguage.selected == code {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

// MARK: - Presentation

extension View {
    /// Réglages : feuille sur iOS ; plein écran sur tvOS, où une feuille est une petite
    /// carte qui tronque le titre et cache le bas de la liste
    func settingsSheet(isPresented: Binding<Bool>, jellyfinService: JellyfinService) -> some View {
        #if os(tvOS)
        fullScreenCover(isPresented: isPresented) {
            SettingsView(jellyfinService: jellyfinService)
                // Le plein écran est transparent : sans fond, l'écran du dessous se voit à travers
                .background(AppTheme.backgroundGradient.ignoresSafeArea())
        }
        #else
        sheet(isPresented: isPresented) {
            SettingsView(jellyfinService: jellyfinService)
        }
        #endif
    }
}

private extension View {
    /// tvOS : une ligne d'information doit pouvoir prendre le focus, sinon la
    /// télécommande ne fait pas défiler la liste jusqu'aux réglages du bas
    func infoRow() -> some View {
        #if os(tvOS)
        focusable()
        #else
        self
        #endif
    }
}

#Preview {
    SettingsView(jellyfinService: JellyfinService())
}
