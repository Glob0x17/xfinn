//
//  BufferStatsOverlay.swift
//  xfinn
//
//  Custom loading overlay showing buffer statistics.
//

import SwiftUI

/// Overlay personnalisé affichant les statistiques de buffering
struct BufferStatsOverlay: View {
    let stats: BufferStats

    var body: some View {
        VStack(spacing: 20) {
            // Barre de progression circulaire
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)

                // Progress circle
                Circle()
                    .trim(from: 0, to: stats.percentage / 100)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: stats.percentage)

                // Pourcentage au centre
                Text(stats.formattedPercentage)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Statistiques détaillées
            VStack(spacing: 12) {
                // Vitesse de téléchargement
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                    Text(stats.formattedSpeed)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }

                // Temps restant
                if let remaining = stats.formattedRemainingTime {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text(remaining)
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }

                // Données téléchargées
                HStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.green)
                    Text(stats.formattedDownloaded)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Label "Chargement"
            Text("loading.default".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Initial Loading Overlay

/// Overlay pour le chargement initial (avant que les stats soient disponibles)
struct InitialLoadingOverlay: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            // Spinner personnalisé
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotation))
            }

            Text("loading.connecting".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        BufferStatsOverlay(stats: BufferStats(
            percentage: 45,
            downloadSpeed: 12_500_000,
            remainingTime: 8.5,
            downloadedBytes: 25_000_000,
            totalBytes: 50_000_000
        ))
    }
}
