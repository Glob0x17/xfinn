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
    
    // MARK: - Image Preloading Cache
    @StateObject private var imagePreloader = ImagePreloader()
    
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
                    withAnimation(AppTheme.standardAnimation) {
                        jellyfinService.logout()
                    }
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 26))
                        .foregroundColor(.appError)
                }
            }
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
        .onChange(of: libraries) { _, newLibraries in
            // 5. Pré-charger les images des bibliothèques
            Task {
                await preloadImages(for: newLibraries)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 30) {
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
                    .tint(.appPrimary)
            }
            .glowing(color: .appPrimary, radius: 25)
            
            Text("library.loading".localized)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
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
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.appError)
            }
            
            VStack(spacing: 12) {
                Text("library.no_libraries".localized)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("library.no_libraries_message".localized)
                    .font(.system(size: 22))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Libraries Grid
    
    private var librariesGrid: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 40) {
                // En-tête
                VStack(alignment: .leading, spacing: 10) {
                    Text("library.all_libraries".localized)
                        .font(.system(size: 56, weight: .bold)) // 3. Taille adaptée tvOS
                        .foregroundColor(.appTextPrimary)
                    
                    Text("library.libraries_available".localized(with: libraries.count))
                        .font(.system(size: 28)) // 3. Taille adaptée tvOS
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
                
                // Grille de bibliothèques avec espacement vertical explicite
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 400, maximum: 600), spacing: 40),
                        GridItem(.flexible(minimum: 400, maximum: 600), spacing: 40)
                    ],
                    spacing: 50 // Espacement vertical entre les rangées
                ) {
                    ForEach(libraries) { library in
                        NavigationLink {
                            LibraryContentView(library: library, jellyfinService: jellyfinService)
                                .id(library.id) // Force le rafraîchissement
                        } label: {
                            LibraryCard(
                                library: library,
                                jellyfinService: jellyfinService,
                                imagePreloader: imagePreloader
                            )
                        }
                        .buttonStyle(
                            // 1. Focus feedback amélioré + 2. Zoom sur focus
                            TVOSLibraryCardButtonStyle(cornerRadius: 20)
                        )
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 80) // Plus d'espace en bas
            }
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
    
    /// Pré-charge les images des bibliothèques pour une fluidité optimale
    @MainActor
    private func preloadImages(for libraries: [LibraryItem]) async {
        for library in libraries {
            guard let imageUrl = library.imageUrl,
                  let url = URL(string: imageUrl) else {
                continue
            }
            
            await imagePreloader.preloadImage(from: url)
        }
    }
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
            return .appPrimary
        case "tvshows":
            return .appAccent
        case "music":
            return .appSecondary
        case "photos":
            return .appTertiary
        default:
            return .appPrimary
        }
    }
    
    /// Couleurs de gradient pour le fond
    var gradientColors: [Color] {
        switch collectionType?.lowercased() {
        case "movies":
            return [AppTheme.primary.opacity(0.6), AppTheme.accent.opacity(0.6)]
        case "tvshows":
            return [AppTheme.accent.opacity(0.6), AppTheme.secondary.opacity(0.6)]
        case "music":
            return [AppTheme.secondary.opacity(0.6), AppTheme.tertiary.opacity(0.6)]
        case "photos":
            return [AppTheme.tertiary.opacity(0.6), AppTheme.primary.opacity(0.6)]
        default:
            return [AppTheme.primary.opacity(0.6), AppTheme.accent.opacity(0.6)]
        }
    }
}

struct LibraryCard: View {
    let library: LibraryItem
    let jellyfinService: JellyfinService
    let imagePreloader: ImagePreloader
    
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
            ZStack(alignment: .bottomLeading) {
                // Background avec gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: library.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
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
                
                // Overlay gradient en bas
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .frame(maxHeight: .infinity, alignment: .bottom)
                
                // 4. Badge "Nouveau" si applicable
                HStack {
                    if isNew {
                        NewBadge()
                            .padding(20)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Badge type
                LibraryTypeBadge(library: library)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(height: 300)
            .clipped()
            
            // Informations avec glass background
            VStack(alignment: .leading, spacing: 12) {
                Text(library.name)
                    .font(.system(size: 30, weight: .bold)) // 3. Taille adaptée tvOS
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 18)) // 3. Taille adaptée tvOS
                        .foregroundColor(.appTextSecondary)
                    
                    Text("library.type".localized(with: library.typeDisplayName))
                        .font(.system(size: 22)) // 3. Taille adaptée tvOS
                        .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24)) // 3. Taille adaptée tvOS
                        .foregroundColor(.appTextTertiary)
                }
            }
            .padding(20)
            .frame(height: 100) // Hauteur fixe pour les infos
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(AppTheme.glassBackground)
            )
        }
        .frame(height: 400) // Hauteur totale fixe (300 + 100)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
    }
    
    private var libraryIcon: some View {
        VStack(spacing: 20) {
            Image(systemName: library.iconName)
                .font(.system(size: 90, weight: .light)) // 3. Taille adaptée tvOS
                .foregroundStyle(.white.opacity(0.9))
            
            Text(library.name)
                .font(.system(size: 36, weight: .bold)) // 3. Taille adaptée tvOS
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
                .font(.system(size: 20)) // 3. Taille adaptée tvOS
            Text(library.typeDisplayName)
                .font(.system(size: 20, weight: .semibold)) // 3. Taille adaptée tvOS
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

/// Style de bouton optimisé pour tvOS avec focus amélioré et zoom
struct TVOSLibraryCardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20
    @Environment(\.isFocused) private var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // 2. Zoom sur focus (1.1 = 10% d'agrandissement)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            // 1. Focus feedback - Glow lumineux violet électrique
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
            // Animation fluide avec spring
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
            // Effet de pression
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Image Preloader (Feature 5)

/// Gestionnaire de pré-chargement des images pour optimiser la fluidité
/// Inclut une limite de mémoire et une politique d'éviction LRU
@MainActor
class ImagePreloader: ObservableObject {
    /// Limite maximale du cache (50 images par défaut)
    private let maxCacheSize: Int = 50

    /// Cache des images avec ordre d'accès pour LRU
    private var cache: [URL: UIImage] = [:]
    private var accessOrder: [URL] = []
    private var loadingTasks: [URL: Task<Void, Never>] = [:]

    /// Pré-charge une image depuis une URL
    func preloadImage(from url: URL) async {
        // Vérifier si déjà en cache
        if cache[url] != nil {
            // Mettre à jour l'ordre d'accès (LRU)
            updateAccessOrder(for: url)
            return
        }

        // Vérifier si déjà en cours de chargement
        if loadingTasks[url] != nil {
            return
        }

        // Créer une tâche de chargement
        let task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    self.addToCache(url: url, image: image)
                }
            } catch {
                print("[ImagePreloader] Erreur chargement image: \(error.localizedDescription)")
            }
            self.loadingTasks[url] = nil
        }

        loadingTasks[url] = task
        await task.value
    }

    /// Ajoute une image au cache avec éviction LRU si nécessaire
    private func addToCache(url: URL, image: UIImage) {
        // Éviction si le cache est plein
        while cache.count >= maxCacheSize, let oldestURL = accessOrder.first {
            cache.removeValue(forKey: oldestURL)
            accessOrder.removeFirst()
        }

        cache[url] = image
        accessOrder.append(url)
    }

    /// Met à jour l'ordre d'accès pour LRU
    private func updateAccessOrder(for url: URL) {
        if let index = accessOrder.firstIndex(of: url) {
            accessOrder.remove(at: index)
            accessOrder.append(url)
        }
    }

    /// Récupère une image du cache
    func getCachedImage(for url: URL) -> UIImage? {
        if let image = cache[url] {
            updateAccessOrder(for: url)
            return image
        }
        return nil
    }

    /// Vide le cache
    func clearCache() {
        cache.removeAll()
        accessOrder.removeAll()
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
    }

    /// Nombre d'images en cache
    var cacheCount: Int {
        cache.count
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LibraryView(jellyfinService: JellyfinService())
    }
}
