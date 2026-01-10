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

    var body: some View {
        NavigationStack {
            List {
                // Section Utilisateur
                Section("Utilisateur") {
                    if let user = jellyfinService.currentUser {
                        LabeledContent("Nom", value: user.name)
                        LabeledContent("ID", value: user.id)
                    }
                }

                // Section Serveur
                Section("Serveur") {
                    if let serverInfo = jellyfinService.serverInfo {
                        LabeledContent("Nom", value: serverInfo.serverName)
                        LabeledContent("Version", value: serverInfo.version)
                        LabeledContent("Système", value: serverInfo.operatingSystem)
                    }

                    LabeledContent("URL", value: jellyfinService.serverURL)
                }

                // Section Application
                Section("Application") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    LabeledContent("Plateforme", value: "tvOS")
                }

                // Section Streaming
                Section {
                    Picker("Qualité de streaming", selection: $jellyfinService.preferredQuality) {
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
                        Text("Qualité sélectionnée: \(jellyfinService.preferredQuality.displayName)")
                            .font(.subheadline)
                        Text(jellyfinService.preferredQuality.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Streaming")
                } footer: {
                    Text("Le mode Auto teste automatiquement votre connexion. Pour forcer le transcodage, choisissez un bitrate inférieur à celui de votre fichier source.")
                }

                // Section Actions
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Paramètres")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .alert("Se déconnecter ?", isPresented: $showLogoutConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Se déconnecter", role: .destructive) {
                    jellyfinService.logout()
                    dismiss()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter ?")
            }
        }
    }
}

#Preview {
    SettingsView(jellyfinService: JellyfinService())
}
