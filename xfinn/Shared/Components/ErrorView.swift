//
//  ErrorView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//

import SwiftUI

/// Vue affichant une erreur avec option de réessai
struct ErrorView: View {
    let error: Error
    let retry: (() -> Void)?
    
    init(error: Error, retry: (() -> Void)? = nil) {
        self.error = error
        self.retry = retry
    }
    
    var body: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.appError)
            
            Text("Une erreur est survenue")
                .font(AppTheme.title)
                .fontWeight(.bold)
            
            Text(error.localizedDescription)
                .font(AppTheme.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.extraLargeSpacing)
            
            if let retry = retry {
                Button {
                    retry()
                } label: {
                    Label("Réessayer", systemImage: "arrow.clockwise")
                        .font(AppTheme.headline)
                        .padding(.horizontal, AppTheme.largeSpacing)
                        .padding(.vertical, AppTheme.mediumSpacing)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primaryColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
@available(iOS 17.0, *)
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorView(
                error: NSError(
                    domain: "TestError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Impossible de se connecter au serveur"]
                ),
                retry: {
                    print("Retry tapped")
                }
            )
            .background(AppTheme.backgroundGradient)
            .previewDisplayName("With Retry")
            
            ErrorView(
                error: NSError(
                    domain: "TestError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Une erreur s'est produite"]
                )
            )
            .background(AppTheme.backgroundGradient)
            .previewDisplayName("Without Retry")
        }
    }
}
#endif

