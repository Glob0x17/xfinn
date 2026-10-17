//
//  ErrorStateView.swift
//  xfinn
//
//  État d'erreur plein écran avec bouton Réessayer — partagé par les vues
//  dont le chargement peut échouer (Home, Search, SeriesDetail, Library).
//

import SwiftUI

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.sp(30)) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.error.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: AppTheme.dm(200), height: AppTheme.dm(200))
                    .blur(radius: 30)

                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: AppTheme.fs(80), weight: .light))
                    .foregroundColor(.appError)
            }

            VStack(spacing: 12) {
                Text("common.error".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text(message)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(maxWidth: AppTheme.dm(900))

            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: AppTheme.fs(24)))
                    Text("common.retry".localized)
                        .font(.system(size: AppTheme.fs(26), weight: .semibold))
                }
                .foregroundColor(.white)
            }
            .buttonStyle(GlassButtonStyle(isProminent: true))
            .glassButton(prominent: true)
        }
        .padding(AppTheme.screenPadding)
    }
}

#Preview {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()
        ErrorStateView(message: "Impossible de se connecter au serveur.") {}
    }
}
