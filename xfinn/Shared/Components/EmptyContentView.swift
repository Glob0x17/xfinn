//
//  EmptyContentView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//

import SwiftUI

/// Vue affichant un état vide avec icône et message
struct EmptyContentView: View {
    let icon: String
    let title: String
    let message: String
    
    init(
        icon: String = "tray.fill",
        title: String = "",
        message: String = ""
    ) {
        self.icon = icon
        self.title = title.isEmpty ? "empty.no_content".localized : title
        self.message = message.isEmpty ? "empty.no_content_message".localized : message
    }
    
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
                .font(AppTheme.title)
        } description: {
            Text(message)
                .font(AppTheme.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
@available(iOS 17.0, *)
struct EmptyContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyContentView()
                .background(AppTheme.backgroundGradient)
                .previewDisplayName("Default")
            
            EmptyContentView(
                icon: "film.stack",
                title: "Aucune série",
                message: "Vous n'avez pas encore de séries dans votre bibliothèque"
            )
            .background(AppTheme.backgroundGradient)
            .previewDisplayName("Custom")
            
            EmptyContentView(
                icon: "play.circle",
                title: "Rien à reprendre",
                message: "Commencez à regarder un média pour le voir apparaître ici"
            )
            .background(AppTheme.backgroundGradient)
            .previewDisplayName("No Resume Items")
        }
    }
}
#endif

