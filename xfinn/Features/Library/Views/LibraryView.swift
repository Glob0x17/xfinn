//
//  LibraryView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI
import Combine

/// Vue des bibliothèques avec design Liquid Glass moderne
struct LibraryView: View {
    @ObservedObject var jellyfinService: JellyfinService
    @State private var libraries: [LibraryItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if libraries.isEmpty {
                emptyStateView
            } else {
                librariesGrid
            }
        }
        .navigationTitle("library.my_libraries".localized)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: AppTheme.fs(26)))
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(jellyfinService: jellyfinService)
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("common.retry".localized) {
                Task {
                    await loadLibraries()
                }
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            if !hasLoaded {
                Task {
                    await loadLibraries()
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            ZStack {
                Circle()
                    .fill(AppTheme.glassBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.glassStroke, lineWidth: 2)
                    )
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.8)
                    .tint(.appSecondary)
            }
            .glowing(color: .appSecondary, radius: 25)
            
            Text("library.loading".localized)
                .font(.system(size: AppTheme.fs(24), weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.error.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: AppTheme.dm(200), height: AppTheme.dm(200))
                    .blur(radius: 30)
                
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: AppTheme.fs(80), weight: .light))
                    .foregroundColor(.appError)
            }
            
            VStack(spacing: 12) {
                Text("library.no_libraries".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("library.no_libraries_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Libraries Grid
    
    #if os(tvOS)
    private static let gridColumns = [
        GridItem(.flexible(minimum: 400, maximum: 600), spacing: AppTheme.sp(40)),
        GridItem(.flexible(minimum: 400, maximum: 600), spacing: AppTheme.sp(40))
    ]
    #else
    private static let gridColumns = AppTheme.adaptiveColumns(phone: 140, pad: 300, spacing: 16)
    #endif

    private var librariesGrid: some View {
        GeometryReader { geo in
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: AppTheme.sp(40)) {
                // En-tête
                VStack(alignment: .leading, spacing: 8) {
                    Text("library.all_libraries".localized)
                        .font(.system(size: AppTheme.fs(56), weight: .bold))
                        .foregroundColor(.appTextPrimary)

                    Text("library.libraries_available".localized(with: libraries.count))
                        .font(.system(size: AppTheme.fs(28)))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.top, 16)

                LazyVGrid(
                    columns: Self.gridColumns,
                    spacing: AppTheme.sp(50)
                ) {
                    ForEach(libraries) { library in
                        NavigationLink(value: AppRoute.library(library)) {
                            LibraryCard(
                                library: library,
                                jellyfinService: jellyfinService
                            )
                        }
                        .buttonStyle(
                            TVOSLibraryCardButtonStyle(cornerRadius: 20)
                        )
                    }
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.bottom, AppTheme.sp(60))
            }
            .frame(width: geo.size.width, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.top, 16)
        }
        #if os(tvOS)
        .scrollClipDisabled()
        #endif
        .contentMargins(.top, 20, for: .scrollContent)
        }
    }

    // MARK: - Load Libraries
    
    @MainActor
    private func loadLibraries() async {
        guard !hasLoaded else {
            return
        }
        
        hasLoaded = true
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let loadedLibraries = try await jellyfinService.getLibraries()
            
            withAnimation(AppTheme.standardAnimation) {
                self.libraries = loadedLibraries
                self.isLoading = false
            }
        } catch {
            withAnimation(AppTheme.standardAnimation) {
                self.hasLoaded = false
                self.isLoading = false
                self.errorMessage = "\("library.load_error".localized)\n\(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    // MARK: - Image Preloading
    
}

// MARK: - Library Card

/// Configuration de présentation pour chaque type de bibliothèque
extension LibraryItem {
    /// Icône SF Symbol correspondante au type de collection
    var iconName: String {
        switch collectionType?.lowercased() {
        case "movies":
            return "film"
        case "tvshows":
            return "tv"
        case "music":
            return "music.note"
        case "photos":
            return "photo"
        default:
            return "folder.fill"
        }
    }
    
    /// Nom affiché pour le type de collection
    var typeDisplayName: String {
        switch collectionType?.lowercased() {
        case "movies":
            return "library.type.movies".localized
        case "tvshows":
            return "library.type.series".localized
        case "music":
            return "library.type.music".localized
        case "photos":
            return "library.type.photos".localized
        default:
            return "library.type.media".localized
        }
    }
    
    /// Couleur d'accent basée sur le type
    var accentColor: Color {
        switch collectionType?.lowercased() {
        case "movies":
            return .appSecondary
        case "tvshows":
            return .appTertiary
        case "music":
            return .appSecondary
        case "photos":
            return .appTertiary
        default:
            return .appSecondary
        }
    }
    
    /// Couleurs de gradient pour le fond
    var gradientColors: [Color] {
        switch collectionType?.lowercased() {
        case "movies":
            return [AppTheme.secondary.opacity(0.6), AppTheme.tertiary.opacity(0.45)]
        case "tvshows":
            return [AppTheme.tertiary.opacity(0.6), AppTheme.secondary.opacity(0.5)]
        case "music":
            return [AppTheme.secondary.opacity(0.6), AppTheme.tertiary.opacity(0.6)]
        case "photos":
            return [AppTheme.tertiary.opacity(0.6), AppTheme.secondary.opacity(0.45)]
        default:
            return [AppTheme.secondary.opacity(0.6), AppTheme.tertiary.opacity(0.45)]
        }
    }
}

struct LibraryCard: View {
    let library: LibraryItem
    let jellyfinService: JellyfinService
    
    // 4. Détection si la bibliothèque est "nouvelle" (ajoutée récemment)
    private var isNew: Bool {
        // On pourrait ajouter un timestamp dans LibraryItem
        // Pour l'instant, on simule avec une logique simple
        // Par exemple, toute bibliothèque ajoutée dans les dernières 24h
        false // À implémenter selon vos besoins
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image de la bibliothèque avec glass overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: library.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    // Image si disponible
                    if let imageUrl = library.imageUrl,
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure, .empty:
                                libraryIcon
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        libraryIcon
                    }
                }
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                }
                .overlay(alignment: .bottomLeading) {
                    HStack {
                        if isNew {
                            NewBadge()
                        }
                        LibraryTypeBadge(library: library)
                    }
                    .padding(12)
                }
                .frame(height: AppTheme.dm(300))
                .clipped()

            // Informations avec glass background
            VStack(alignment: .leading, spacing: 12) {
                Text(library.name)
                    .font(.system(size: AppTheme.fs(30), weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 18)) // 3. Taille adaptée tvOS
                        .foregroundColor(.appTextSecondary)
                    
                    Text("library.type".localized(with: library.typeDisplayName))
                        .font(.system(size: AppTheme.fs(22)))
                        .foregroundColor(.appTextSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fs(24)))
                        .foregroundColor(.appTextTertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(AppTheme.glassBackground)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }
    
    private var libraryIcon: some View {
        VStack(spacing: 20) {
            Image(systemName: library.iconName)
                .font(.system(size: AppTheme.fs(90), weight: .light))
                .foregroundStyle(.white.opacity(0.9))

            Text(library.name)
                .font(.system(size: AppTheme.fs(36), weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Library Type Badge

/// Badge indiquant le type de bibliothèque
private struct LibraryTypeBadge: View {
    let library: LibraryItem
    
    var body: some View {
        HStack {
            Image(systemName: library.iconName)
                .font(.system(size: AppTheme.fs(20)))
            Text(library.typeDisplayName)
                .font(.system(size: AppTheme.fs(20), weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 18) // 3. Padding adapté
        .padding(.vertical, 10) // 3. Padding adapté
        .background(
            Capsule()
                .fill(AppTheme.glassBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - New Badge (Feature 4)

/// Badge "Nouveau" pour les bibliothèques récemment ajoutées
private struct NewBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .bold))
            Text("common.new".localized)
                .font(.system(size: 18, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.0), // Orange vif
                            Color(red: 1.0, green: 0.2, blue: 0.4)  // Rose vif
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.orange.opacity(0.6), radius: 10, x: 0, y: 0)
        )
    }
}

// MARK: - tvOS Button Style (Features 1 & 2)

/// Style de bouton optimisé avec focus amélioré et zoom
struct TVOSLibraryCardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20
    #if os(tvOS)
    @Environment(\.isFocused) private var isFocused
    #endif

    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
        configuration.label
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.9) : .clear,
                radius: isFocused ? 30 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.6) : .clear,
                radius: isFocused ? 50 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.3) : .clear,
                radius: isFocused ? 70 : 0,
                x: 0,
                y: 0
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .focusEffectDisabled()
        #else
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        #endif
    }
}

// MARK: - Library Content Router

/// Router qui décide quelle vue afficher selon le type de bibliothèque
struct LibraryContentRouter: View {
    let library: LibraryItem
    @ObservedObject var jellyfinService: JellyfinService

    var body: some View {
        // Détection du type de bibliothèque
        if isMusicLibrary {
            MusicLibraryView(library: library, jellyfinService: jellyfinService)
                .id(library.id)
        } else {
            LibraryContentView(library: library, jellyfinService: jellyfinService)
                .id(library.id)
        }
    }

    private var isMusicLibrary: Bool {
        // collectionType est le vrai CollectionType Jellyfin depuis getLibraries()
        library.collectionType?.lowercased() == "music"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LibraryView(jellyfinService: JellyfinService())
    }
}
