//
//  SettingsView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
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
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    
                    // Afficher une description de la qualité sélectionnée
                    Text(jellyfinService.preferredQuality.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Streaming")
                } footer: {
                    Text("La qualité Auto offre la meilleure qualité disponible (1080p à 15 Mbps). Choisissez une qualité inférieure si vous avez des problèmes de réseau.")
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
