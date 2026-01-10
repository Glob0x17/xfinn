//
//  ImageWithOverlay.swift
//  xfinn
//
//  Created by Refactoring Phase 1
//

import SwiftUI

/// Image asynchrone avec overlay gradient, placeholder et gestion d'erreur
struct ImageWithOverlay: View {
    let url: URL?

    /// Type d'overlay gradient
    var overlayStyle: OverlayStyle = .bottom

    /// Hauteur de l'overlay gradient
    var overlayHeight: CGFloat = 150

    /// Afficher un indicateur de chargement
    var showLoadingIndicator: Bool = true

    /// Icône à afficher en cas d'erreur
    var errorIcon: String = "film"

    /// Message d'erreur
    var errorMessage: String? = "Image\nindisponible"

    /// Content mode de l'image
    var contentMode: ContentMode = .fill

    enum OverlayStyle {
        case none
        case bottom      // Gradient du bas (transparent → noir)
        case top         // Gradient du haut (noir → transparent)
        case full        // Gradient complet (noir → transparent → noir)
        case custom(LinearGradient)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Image chargée
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    if showLoadingIndicator {
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.appPrimary)
                        }
                    } else {
                        Color.gray.opacity(0.2)
                    }

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)

                case .failure:
                    ZStack {
                        Color.gray.opacity(0.2)
                        VStack(spacing: 10) {
                            Image(systemName: errorIcon)
                                .font(.system(size: 50))
                                .foregroundStyle(Color.appTextTertiary)

                            if let message = errorMessage {
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextTertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }

                @unknown default:
                    EmptyView()
                }
            }

            // Overlay gradient
            overlayGradient
        }
    }

    @ViewBuilder
    private var overlayGradient: some View {
        switch overlayStyle {
        case .none:
            EmptyView()

        case .bottom:
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: overlayHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)

        case .top:
            LinearGradient(
                colors: [.black.opacity(0.8), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: overlayHeight)
            .frame(maxHeight: .infinity, alignment: .top)

        case .full:
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: overlayHeight * 0.7)

                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: overlayHeight)
            }

        case .custom(let gradient):
            gradient
                .frame(height: overlayHeight)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

/// Image poster avec ratio 2:3 standard
struct PosterImage: View {
    let url: URL?
    var width: CGFloat = AppTheme.posterWidth
    var showOverlay: Bool = true

    private var height: CGFloat {
        width * 1.5 // Ratio 2:3
    }

    var body: some View {
        ImageWithOverlay(
            url: url,
            overlayStyle: showOverlay ? .bottom : .none,
            overlayHeight: height * 0.25
        )
        .frame(width: width, height: height)
        .clipped()
        .cornerRadius(AppTheme.largeRadius)
    }
}

/// Image backdrop avec ratio 16:9
struct BackdropImage: View {
    let url: URL?
    var height: CGFloat = 400
    var showOverlay: Bool = true
    var overlayStyle: ImageWithOverlay.OverlayStyle = .full

    private var width: CGFloat {
        height * (16.0 / 9.0)
    }

    var body: some View {
        ImageWithOverlay(
            url: url,
            overlayStyle: showOverlay ? overlayStyle : .none,
            overlayHeight: height * 0.4
        )
        .frame(height: height)
        .clipped()
    }
}

/// Image carrée pour les avatars/profils
struct SquareImage: View {
    let url: URL?
    var size: CGFloat = 100
    var cornerRadius: CGFloat = AppTheme.mediumRadius

    var body: some View {
        ImageWithOverlay(
            url: url,
            overlayStyle: .none,
            showLoadingIndicator: true,
            errorIcon: "person.fill"
        )
        .frame(width: size, height: size)
        .clipped()
        .cornerRadius(cornerRadius)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Image Components") {
    ZStack {
        AppTheme.backgroundGradient.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 40) {
                // ImageWithOverlay standard
                VStack(alignment: .leading, spacing: 10) {
                    Text("ImageWithOverlay - Bottom Overlay")
                        .font(AppTheme.caption)
                        .foregroundStyle(Color.appTextTertiary)

                    ImageWithOverlay(
                        url: nil, // Affichera l'erreur
                        overlayStyle: .bottom
                    )
                    .frame(width: 400, height: 225)
                    .clipped()
                    .cornerRadius(AppTheme.largeRadius)
                }

                // PosterImage
                VStack(alignment: .leading, spacing: 10) {
                    Text("PosterImage (2:3)")
                        .font(AppTheme.caption)
                        .foregroundStyle(Color.appTextTertiary)

                    PosterImage(url: nil, width: 200)
                }

                // BackdropImage
                VStack(alignment: .leading, spacing: 10) {
                    Text("BackdropImage (16:9)")
                        .font(AppTheme.caption)
                        .foregroundStyle(Color.appTextTertiary)

                    BackdropImage(url: nil, height: 200)
                }

                // SquareImage
                VStack(alignment: .leading, spacing: 10) {
                    Text("SquareImage (avatar)")
                        .font(AppTheme.caption)
                        .foregroundStyle(Color.appTextTertiary)

                    SquareImage(url: nil, size: 100)
                }
            }
            .padding()
        }
    }
}
#endif
