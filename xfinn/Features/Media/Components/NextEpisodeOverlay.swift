//
//  NextEpisodeOverlay.swift
//  xfinn
//
//  Created by Dorian Galiana on 16/12/2025.
//

import SwiftUI

/// Overlay affichée 10 secondes avant la fin d'un épisode pour proposer la lecture du suivant
struct NextEpisodeOverlay: View {
    let nextEpisode: MediaItem
    let countdown: Int
    let jellyfinService: JellyfinService
    let onPlayNext: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var focusedButton: FocusableButton?
    
    enum FocusableButton {
        case cancel
        case playNext
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            
            // Card de l'épisode suivant
            VStack(alignment: .leading, spacing: 30) {
                // En-tête avec compte à rebours
                HStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Épisode suivant")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text("Lecture automatique dans")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Compte à rebours circulaire
                    ZStack {
                        // Cercle de fond
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                        
                        // Cercle de progression
                        Circle()
                            .trim(from: 0, to: CGFloat(countdown) / 10.0)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: countdown)
                        
                        // Nombre
                        Text("\(countdown)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                    .frame(width: 80, height: 80)
                }
                
                // Séparateur
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.2), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                
                // Informations de l'épisode
                HStack(spacing: 24) {
                    // Miniature de l'épisode avec effet glass
                    AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: nextEpisode.id, imageType: "Primary", maxWidth: 400))) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.glassBackground,
                                            AppTheme.glassBackground.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Image(systemName: "play.tv.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .frame(width: 260, height: 146)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Détails
                    VStack(alignment: .leading, spacing: 12) {
                        // Titre de l'épisode
                        Text(nextEpisode.displayTitle)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        
                        // Synopsis
                        if let overview = nextEpisode.overview, !overview.isEmpty {
                            Text(overview)
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(3)
                        }
                        
                        // Durée avec icône
                        if let duration = nextEpisode.duration {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16))
                                Text(formatDuration(duration))
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundStyle(AppTheme.primary)
                        }
                    }
                    .frame(maxWidth: 440, alignment: .leading)
                }
                
                // Boutons d'action avec focus tvOS
                HStack(spacing: 20) {
                    // Bouton annuler
                    Button(action: onCancel) {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Annuler")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(NextEpisodeButtonStyle(isDestructive: true))
                    .focused($focusedButton, equals: .cancel)
                    
                    // Bouton lecture (par défaut focusé)
                    Button(action: onPlayNext) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                            Text("Lire maintenant")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(NextEpisodeButtonStyle(isPrimary: true))
                    .focused($focusedButton, equals: .playNext)
                }
            }
            .padding(40)
            .frame(width: 840)
            .background {
                // Fond avec effet glass moderne
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.85),
                                Color.black.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppTheme.primary.opacity(0.5),
                                        AppTheme.primary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: .black.opacity(0.6), radius: 40, x: 0, y: 20)
            }
            .padding(.trailing, 80)
            .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .onAppear {
            // Focus automatique sur le bouton "Lire maintenant"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedButton = .playNext
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - Custom Button Style pour tvOS

struct NextEpisodeButtonStyle: ButtonStyle {
    var isPrimary: Bool = false
    var isDestructive: Bool = false
    
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if isPrimary {
                    // Bouton primaire (Lire maintenant) - Toujours avec fond primary
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primary,
                                    AppTheme.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            // Bordure violette quand focusé
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isFocused ? AppTheme.primary : Color.clear,
                                    lineWidth: isFocused ? 4 : 0
                                )
                        }
                        .shadow(
                            color: isFocused ? AppTheme.primary.opacity(0.8) : AppTheme.primary.opacity(0.3),
                            radius: isFocused ? 20 : 10,
                            x: 0,
                            y: isFocused ? 8 : 4
                        )
                } else if isDestructive {
                    // Bouton destructif (Annuler) - Fond transparent avec bordure
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isFocused ? Color.red : Color.white.opacity(0.3),
                                    lineWidth: isFocused ? 4 : 2
                                )
                        }
                        .shadow(
                            color: isFocused ? Color.red.opacity(0.5) : .clear,
                            radius: isFocused ? 15 : 0,
                            x: 0,
                            y: isFocused ? 6 : 0
                        )
                } else {
                    // Bouton secondaire
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isFocused ? AppTheme.primary : Color.white.opacity(0.3),
                                    lineWidth: isFocused ? 4 : 2
                                )
                        }
                }
            }
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.05 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        NextEpisodeOverlay(
            nextEpisode: MediaItem(
                id: "2",
                name: "Le Prisonnier de l'Espace",
                type: "Episode",
                overview: "L'équipage découvre un vaisseau abandonné dans l'espace profond. Une enquête révèle des secrets troublants sur le passé de l'un des membres.",
                productionYear: 2023,
                indexNumber: 2,
                parentIndexNumber: 1,
                communityRating: 8.7,
                officialRating: "PG-13",
                runTimeTicks: 28800000000,
                userData: nil,
                seriesName: "Odyssée Stellaire",
                seriesId: "series-1",
                seasonId: "season-1",
                mediaStreams: nil
            ),
            countdown: 7,
            jellyfinService: JellyfinService(),
            onPlayNext: {},
            onCancel: {}
        )
    }
}
