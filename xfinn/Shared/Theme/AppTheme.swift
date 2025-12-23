//
//  AppTheme.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/12/2025.
//  Merged with Liquid Glass features on 23/12/2025.
//

import SwiftUI

/// Thème centralisé de l'application xfinn
/// Contient toutes les constantes de design, couleurs, typographie, animations et effets Liquid Glass
struct AppTheme {
    
    // MARK: - Colors
    
    /// Couleur principale de l'application (Jellyfin Purple)
    static let primaryColor = Color.jellyfinPurple
    
    /// Alias pour primaryColor (compatibilité)
    static let primary = primaryColor
    
    /// Couleur secondaire de l'application (Jellyfin Blue)
    static let secondaryColor = Color.jellyfinBlue
    
    /// Alias pour secondaryColor (compatibilité)
    static let secondary = secondaryColor
    
    /// Couleur d'accent pour les éléments interactifs
    static let accentColor = Color.jellyfinPurple
    
    /// Alias pour accentColor (compatibilité)
    static let accent = accentColor
    
    /// Couleur tertiaire - Rose vif pour éléments spéciaux
    static let tertiaryColor = Color(red: 1.0, green: 0.27, blue: 0.52) // #FF4585
    
    /// Alias pour tertiaryColor (compatibilité)
    static let tertiary = tertiaryColor
    
    // MARK: - Liquid Glass Colors
    
    /// Glass effect pour les cards (Liquid Glass)
    static let glassBackground = Color.white.opacity(0.08)
    static let glassStroke = Color.white.opacity(0.15)
    
    /// Couleur du contour de focus - Violet électrique vif
    static let focusBorder = Color(red: 0.75, green: 0.35, blue: 0.95) // #BF5AF2
    
    // MARK: - Status Colors
    
    /// Couleur pour les erreurs - Rouge vif
    static let error = Color.red
    
    /// Couleur pour les succès - Vert vif
    static let success = Color.green
    
    /// Couleur pour les avertissements - Orange
    static let warning = Color.orange
    
    /// Gradient de fond pour l'application
    static let backgroundGradient = LinearGradient(
        colors: [.black, Color(white: 0.1)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Gradient alternatif plus subtil
    static let subtleBackgroundGradient = LinearGradient(
        colors: [Color(white: 0.05), Color(white: 0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Typography
    
    /// Très grand titre (pour les écrans principaux)
    static let largeTitle = Font.system(size: 60, weight: .bold)
    
    /// Titre principal
    static let title = Font.system(size: 50, weight: .bold)
    
    /// Titre secondaire
    static let title2 = Font.system(size: 40, weight: .semibold)
    
    /// Titre de section
    static let title3 = Font.system(size: 34, weight: .semibold)
    
    /// En-tête
    static let headline = Font.system(size: 28, weight: .medium)
    
    /// Corps de texte
    static let body = Font.system(size: 24)
    
    /// Corps de texte secondaire
    static let bodySecondary = Font.system(size: 22)
    
    /// Légende
    static let caption = Font.system(size: 20)
    
    /// Petite légende
    static let caption2 = Font.system(size: 18)
    
    // MARK: - Spacing
    
    /// Petit espacement (10pt)
    static let smallSpacing: CGFloat = 10
    
    /// Espacement moyen (20pt)
    static let mediumSpacing: CGFloat = 20
    
    /// Grand espacement (40pt)
    static let largeSpacing: CGFloat = 40
    
    /// Très grand espacement (60pt)
    static let extraLargeSpacing: CGFloat = 60
    
    /// Espacement énorme (80pt)
    static let hugeSpacing: CGFloat = 80
    
    // MARK: - Padding
    
    /// Padding des bords de l'écran
    static let screenPadding: CGFloat = 60
    
    /// Padding des cartes
    static let cardPadding: CGFloat = 30
    
    /// Padding des sections
    static let sectionPadding: CGFloat = 40
    
    // MARK: - Corner Radius
    
    /// Petit rayon de coin
    static let smallRadius: CGFloat = 8
    
    /// Rayon de coin moyen
    static let mediumRadius: CGFloat = 12
    
    /// Grand rayon de coin
    static let largeRadius: CGFloat = 15
    
    /// Très grand rayon de coin
    static let extraLargeRadius: CGFloat = 20
    
    // MARK: - Dimensions
    
    /// Largeur des posters de film
    static let posterWidth: CGFloat = 250
    
    /// Hauteur des posters de film
    static let posterHeight: CGFloat = 375
    
    /// Largeur des cartes de média dans les carrousels
    static let carouselCardWidth: CGFloat = 400
    
    /// Hauteur des cartes de média dans les carrousels
    static let carouselCardHeight: CGFloat = 225
    
    /// Hauteur des rangées d'épisodes
    static let episodeRowHeight: CGFloat = 180
    
    // MARK: - Shadows
    
    /// Ombre légère
    static func lightShadow() -> some View {
        EmptyView()
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    /// Ombre standard
    static func standardShadow() -> some View {
        EmptyView()
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
    }
    
    /// Ombre forte
    static func strongShadow() -> some View {
        EmptyView()
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
    }
    
    // MARK: - Animations
    
    /// Animation standard
    static let standardAnimation = Animation.easeInOut(duration: 0.3)
    
    /// Animation rapide
    static let quickAnimation = Animation.easeInOut(duration: 0.15)
    
    /// Animation lente
    static let slowAnimation = Animation.easeInOut(duration: 0.5)
    
    /// Animation avec spring
    static let springAnimation = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7
    )
    
    /// Animation spring douce
    static let softSpringAnimation = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8
    )
    
    /// Animation spring rebondissante
    static let bouncySpringAnimation = Animation.spring(
        response: 0.3,
        dampingFraction: 0.6
    )
    
    // MARK: - Focus Effects (tvOS)
    
    /// Scale lors du focus
    static let focusScale: CGFloat = 1.05
    
    /// Scale lors du focus (grand)
    static let largeFocusScale: CGFloat = 1.1
    
    // MARK: - Gradients
    
    /// Gradient pour les cartes
    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Gradient Jellyfin (violet vers bleu)
    static let jellyfinGradient = LinearGradient(
        colors: [Color.jellyfinPurple, Color.jellyfinBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Gradient pour les overlays (du bas, transparent vers noir)
    static let overlayGradient = LinearGradient(
        colors: [.clear, .black.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Materials
    
    /// Matériau pour les cartes
    static let cardMaterial = Material.ultraThinMaterial
    
    /// Matériau pour les overlays
    static let overlayMaterial = Material.ultraThin
    
    // MARK: - Progress Bar Colors
    
    /// Couleur de la barre de progression
    static let progressColor = Color.jellyfinPurple
    
    /// Couleur de fond de la barre de progression
    static let progressBackgroundColor = Color.white.opacity(0.3)
    
    // MARK: - Liquid Glass Effects
    
    /// Glass modifier pour cartes
    static func glassCard() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(glassStroke, lineWidth: 1)
            )
    }
    
    /// Glass modifier pour boutons
    static func glassButton() -> some View {
        Capsule()
            .fill(.thinMaterial)
            .overlay(
                Capsule()
                    .stroke(glassStroke, lineWidth: 1.5)
            )
    }
}

// MARK: - Color Extensions

extension Color {
    // MARK: - Couleurs Jellyfin
    
    /// Couleur violette Jellyfin
    static let jellyfinPurple = Color(red: 0.67, green: 0.27, blue: 0.82)
    
    /// Couleur bleue Jellyfin
    static let jellyfinBlue = Color(red: 0.0, green: 0.64, blue: 0.87)
    
    // MARK: - Couleurs de l'application
    
    /// Couleur pour les erreurs
    static let appError = Color.red
    
    /// Couleur pour les succès
    static let appSuccess = Color.green
    
    /// Couleur pour les avertissements
    static let appWarning = Color.orange
    
    /// Couleur d'accent principale
    static let appAccent = jellyfinPurple
    
    // MARK: - Liquid Glass Colors
    
    /// Couleur principale pour les éléments interactifs
    static let appPrimary = AppTheme.primaryColor
    
    /// Couleur secondaire
    static let appSecondary = AppTheme.secondaryColor
    
    /// Couleur tertiaire - Rose vif pour éléments spéciaux
    static let appTertiary = AppTheme.tertiaryColor
    
    /// Background glass
    static let appGlass = AppTheme.glassBackground
    
    /// Couleur du contour de focus
    static let appFocusBorder = AppTheme.focusBorder
    
    // MARK: - Text Colors
    
    /// Texte principal - Blanc pur pour contraste maximal
    static let appTextPrimary = Color.white
    
    /// Texte secondaire - Lecture confortable
    static let appTextSecondary = Color.white.opacity(0.85)
    
    /// Texte tertiaire - Informations moins importantes
    static let appTextTertiary = Color.white.opacity(0.60)
    
    /// Texte désactivé
    static let appTextDisabled = Color.white.opacity(0.30)
}

// MARK: - View Modifiers personnalisés

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.glassBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.glassStroke, lineWidth: 1)
            )
    }
}

struct GlassButtonModifier: ViewModifier {
    var isProminent: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(isProminent ? AppTheme.primaryColor.opacity(0.9) : AppTheme.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 50)
                    .stroke(isProminent ? AppTheme.accentColor : AppTheme.glassStroke, lineWidth: isProminent ? 2 : 1)
            )
    }
}

struct GlowingModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - Focus Effect Modifier

struct FocusEffectModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var scale: CGFloat = 1.05
    var borderWidth: CGFloat = 4
    @Environment(\.isFocused) private var isFocused: Bool
    
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
            // Sur tvOS, utiliser buttonStyle(.card) est préférable
            // Mais si on veut un effet personnalisé, on doit:
            // 1. Désactiver l'effet système
            .focusEffectDisabled()
            // 2. Appliquer notre propre effet avec overlay
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isFocused ? AppTheme.focusBorder : .clear,
                        lineWidth: borderWidth
                    )
                    .allowsHitTesting(false)
            )
            // 3. Ajouter des effets de glow
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.6) : .clear,
                radius: isFocused ? 20 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.3) : .clear,
                radius: isFocused ? 30 : 0,
                x: 0,
                y: 0
            )
            // 4. Animation de scale
            .scaleEffect(isFocused ? scale : 1.0)
            .animation(AppTheme.springAnimation, value: isFocused)
        #else
        // Sur iOS/iPadOS, pas d'effet de focus nécessaire
        content
        #endif
    }
}

// MARK: - Button Style Card personnalisé (Alternative pour tvOS)

struct CustomCardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20
    @Environment(\.isFocused) private var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.05 : 1.0)
            // Effet de lumière colorée qui se propage (sans contour)
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.8) : .clear,
                radius: isFocused ? 25 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.5) : .clear,
                radius: isFocused ? 40 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.2) : .clear,
                radius: isFocused ? 60 : 0,
                x: 0,
                y: 0
            )
            .animation(AppTheme.springAnimation, value: isFocused)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - View Modifier Extensions

extension View {
    /// Applique le style de carte standard de l'app
    func appCardStyle() -> some View {
        self
            .background(AppTheme.cardMaterial)
            .cornerRadius(AppTheme.largeRadius)
            .shadow(color: .black.opacity(0.3), radius: 10)
    }
    
    /// Applique le padding standard de l'écran
    func screenPadding() -> some View {
        self.padding(AppTheme.screenPadding)
    }
    
    /// Applique un style de carte glass
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
    
    /// Applique un style de bouton glass
    func glassButton(prominent: Bool = false) -> some View {
        modifier(GlassButtonModifier(isProminent: prominent))
    }
    
    /// Ajoute un effet de glow lumineux
    func glowing(color: Color = .appPrimary, radius: CGFloat = 20) -> some View {
        modifier(GlowingModifier(color: color, radius: radius))
    }
    
    /// Applique un effet de focus moderne avec contour violet électrique
    /// - Parameters:
    ///   - cornerRadius: Rayon des coins (par défaut: 20)
    ///   - scale: Facteur d'agrandissement au focus (par défaut: 1.05)
    ///   - borderWidth: Épaisseur du contour (par défaut: 4)
    func focusEffect(cornerRadius: CGFloat = 20, scale: CGFloat = 1.05, borderWidth: CGFloat = 4) -> some View {
        modifier(FocusEffectModifier(cornerRadius: cornerRadius, scale: scale, borderWidth: borderWidth))
    }
    
    /// Applique un style de bouton personnalisé pour tvOS (alternative à focusEffect)
    /// - Parameter cornerRadius: Rayon des coins
    func customCardButtonStyle(cornerRadius: CGFloat = 20) -> some View {
        self.buttonStyle(CustomCardButtonStyle(cornerRadius: cornerRadius))
    }
}
