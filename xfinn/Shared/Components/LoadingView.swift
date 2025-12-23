//
//  LoadingView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//

import SwiftUI

/// Vue affichant un indicateur de chargement avec un message
struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Chargement...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: AppTheme.mediumSpacing) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(AppTheme.primaryColor)
            
            Text(message)
                .font(AppTheme.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
@available(iOS 17.0, *)
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView()
                .background(AppTheme.backgroundGradient)
                .previewDisplayName("Default")
            
            LoadingView("Chargement de vos séries...")
                .background(AppTheme.backgroundGradient)
                .previewDisplayName("Custom Message")
        }
    }
}
#endif

