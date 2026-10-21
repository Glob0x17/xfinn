//
//  AppTheme.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/12/2025.
//  Merged with Liquid Glass features on 23/12/2025.
//  Cleaned 18/08/2026: removed never-referenced members (typography and
//  spacing scales, dimensions, shadows, gradients, focus scales, redundant
//  *Color aliases). The canonical color names are primary/secondary/
//  accent/tertiary; the platform scale system is fs()/sp()/dm().
//

import SwiftUI

/// Thème centralisé de l'application xfinn
/// Contient les constantes de design, couleurs, animations et effets Liquid Glass
struct AppTheme {

    // MARK: - Platform Scale Factors

    /// Scale factor for font sizes (tvOS → iOS)
    #if os(tvOS)
    static let fontScale: CGFloat = 1.0
    static let spacingScale: CGFloat = 1.0
    static let dimScale: CGFloat = 1.0
    #else
    // iPad : écran plus grand et vu de plus loin qu'un iPhone, échelle
    // intermédiaire entre l'iPhone et la TV
    private static let isPad = UIDevice.current.userInterfaceIdiom == .pad
    static let fontScale: CGFloat = isPad ? 0.72 : 0.55
    static let spacingScale: CGFloat = isPad ? 0.55 : 0.38
    static let dimScale: CGFloat = isPad ? 0.7 : 0.5
    #endif

    #if !os(tvOS)
    /// Grille iOS : largeur minimale d'une carte selon l'appareil — l'écran
    /// en place autant qu'il peut (3 affiches sur iPhone, 5 à 7 sur iPad
    /// selon l'orientation) au lieu d'un nombre de colonnes fixe
    static func adaptiveColumns(phone: CGFloat, pad: CGFloat, spacing: CGFloat) -> [GridItem] {
        [GridItem(.adaptive(minimum: isPad ? pad : phone), spacing: spacing)]
    }
    #endif

    /// Scale a font size for the current platform
    static func fs(_ tvOSSize: CGFloat) -> CGFloat { tvOSSize * fontScale }
    /// Scale a spacing/padding value for the current platform
    static func sp(_ tvOSSize: CGFloat) -> CGFloat { tvOSSize * spacingScale }
    /// Scale a dimension (width/height) for the current platform
    static func dm(_ tvOSSize: CGFloat) -> CGFloat { tvOSSize * dimScale }

    // MARK: - Colors

    /// Couleur principale UI globale (style musique)
    static let primary = Color.jellyfinBlue

    /// Couleur secondaire de l'application (Jellyfin Blue)
    static let secondary = Color.jellyfinBlue

    /// Couleur tertiaire - Rose vif pour éléments spéciaux
    static let tertiary = Color(red: 1.0, green: 0.27, blue: 0.52) // #FF4585

    /// Couleur d'accent pour les éléments interactifs
    static let accent = tertiary

    // MARK: - Liquid Glass Colors

    /// Glass effect pour les cards (Liquid Glass)
    static let glassBackground = Color.white.opacity(0.08)
    static let elevatedGlassBackground = Color.white.opacity(0.12)
    static let glassStroke = Color.white.opacity(0.2)

    /// Couleur du contour de focus - Violet électrique vif
    static let focusBorder = Color(red: 0.40, green: 0.78, blue: 0.98)
    static let focusGlowColor = Color(red: 0.96, green: 0.32, blue: 0.67)

    // MARK: - Status Colors

    /// Couleur pour les erreurs - Rouge vif
    static let error = Color.red

    /// Couleur pour les succès - Vert vif
    static let success = Color.green

    // MARK: - Gradients

    /// Gradient de fond pour l'application
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.02, green: 0.05, blue: 0.10),
            Color(red: 0.05, green: 0.08, blue: 0.14),
            Color(red: 0.09, green: 0.06, blue: 0.12)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gradient d'accent global (style musique)
    static let accentGradient = LinearGradient(
        colors: [secondary, tertiary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Padding

    #if os(tvOS)
    static let screenPadding: CGFloat = 60
    #else
    static let screenPadding: CGFloat = 16
    #endif

    // MARK: - Animations

    /// Animation standard
    static let standardAnimation = Animation.easeInOut(duration: 0.3)

    /// Animation rapide
    static let quickAnimation = Animation.easeInOut(duration: 0.15)

    /// Animation avec spring
    static let springAnimation = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7
    )
}

// MARK: - Color Extensions

extension Color {
    /// Couleur bleue Jellyfin
    static let jellyfinBlue = Color(red: 0.0, green: 0.64, blue: 0.87)

    /// Couleur pour les erreurs
    static let appError = Color.red

    /// Couleur secondaire
    static let appSecondary = AppTheme.secondary

    /// Couleur tertiaire - Rose vif pour éléments spéciaux
    static let appTertiary = AppTheme.tertiary

    // MARK: - Text Colors

    /// Texte principal - Blanc pur pour contraste maximal
    static let appTextPrimary = Color.white

    /// Texte secondaire - Lecture confortable
    static let appTextSecondary = Color.white.opacity(0.85)

    /// Texte tertiaire - Informations moins importantes
    static let appTextTertiary = Color.white.opacity(0.60)
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

    #if os(tvOS)
    private let hPad: CGFloat = 40
    private let vPad: CGFloat = 20
    #else
    private let hPad: CGFloat = 20
    private let vPad: CGFloat = 12
    #endif

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(isProminent ? AppTheme.elevatedGlassBackground : AppTheme.glassBackground)
                    if isProminent {
                        RoundedRectangle(cornerRadius: 50)
                            .fill(AppTheme.accentGradient)
                            .opacity(0.85)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 50)
                    .stroke(isProminent ? AppTheme.tertiary.opacity(0.9) : AppTheme.glassStroke, lineWidth: isProminent ? 2 : 1)
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

// MARK: - Button Styles (tvOS)

struct CustomCardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
        let effectiveScale = (isFocused ? 1.05 : 1.0) * (configuration.isPressed ? 0.97 : 1.0)
        configuration.label
            .scaleEffect(effectiveScale)
            // Effet de lumière colorée qui se propage (sans contour)
            .shadow(
                color: isFocused ? AppTheme.focusGlowColor.opacity(0.75) : .clear,
                radius: isFocused ? 25 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.45) : .clear,
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
            .animation(AppTheme.quickAnimation, value: configuration.isPressed)
            .focusEffectDisabled()  // Désactiver l'effet système
        #else
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        #endif
    }
}

/// Style de bouton Glass pour tvOS (boutons arrondis type login)
struct GlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
        let effectiveScale = (isFocused ? 1.05 : 1.0) * (configuration.isPressed ? 0.97 : 1.0)
        configuration.label
            .scaleEffect(effectiveScale)
            .shadow(
                color: isFocused ? (isProminent ? AppTheme.focusGlowColor : AppTheme.focusBorder).opacity(0.8) : .clear,
                radius: isFocused ? 25 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: isFocused ? (isProminent ? AppTheme.focusGlowColor : AppTheme.focusBorder).opacity(0.5) : .clear,
                radius: isFocused ? 40 : 0,
                x: 0,
                y: 0
            )
            .animation(AppTheme.springAnimation, value: isFocused)
            .animation(AppTheme.quickAnimation, value: configuration.isPressed)
            .focusEffectDisabled()
        #else
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        #endif
    }
}

// MARK: - View Modifier Extensions

extension View {
    /// Applique un style de carte glass
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// Applique un style de bouton glass
    func glassButton(prominent: Bool = false) -> some View {
        modifier(GlassButtonModifier(isProminent: prominent))
    }

    /// Ajoute un effet de glow lumineux
    func glowing(color: Color, radius: CGFloat = 20) -> some View {
        modifier(GlowingModifier(color: color, radius: radius))
    }
}
