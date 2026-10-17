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
                        LabeledContent("settings.id".localized, value: user.id)
                    }
                }

                // Section Serveur
                Section("settings.server".localized) {
                    if let serverInfo = jellyfinService.serverInfo {
                        LabeledContent("settings.name".localized, value: serverInfo.serverName)
                        LabeledContent("settings.version".localized, value: serverInfo.version)
                        LabeledContent("settings.system".localized, value: serverInfo.operatingSystem)
                    }

                    LabeledContent("settings.url".localized, value: jellyfinService.serverURL)
                }

                // Section Application
                Section("settings.application".localized) {
                    LabeledContent("settings.version".localized, value: Self.appVersion)
                    LabeledContent("Build", value: Self.buildNumber)
                    LabeledContent("settings.platform".localized, value: Self.platformName)
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

#Preview {
    SettingsView(jellyfinService: JellyfinService())
}
