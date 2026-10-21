//
//  LibraryContentView.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

/// Vue du contenu d'une bibliothèque avec design Liquid Glass
struct LibraryContentView: View {
    let library: LibraryItem
    @ObservedObject var jellyfinService: JellyfinService
    
    @State private var items: [MediaItem] = []
    @State private var isLoading = true
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var showError = false

    // Tri, filtre, pagination
    @State private var sortOption: LibrarySortOption = .name
    @State private var unwatchedOnly = false
    @State private var totalCount = 0
    @State private var isLoadingMore = false

    private static let pageSize = 100

    var body: some View {
        ZStack {
            // Background
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if items.isEmpty {
                emptyStateView
            } else {
                contentGrid
            }
        }
        .navigationTitle(library.name)
        .alert("common.error".localized, isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("common.retry".localized) {
                Task { await reloadFromScratch() }
            }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            // Le routeur applique .id(library.id) : la vue (et donc son état
            // hasLoaded) est recréée quand on change de bibliothèque, mais un
            // simple réaffichage ne relance pas le chargement
            guard !hasLoaded else { return }
            hasLoaded = true
            await reloadFromScratch()
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
            
            Text("library.loading_content".localized)
                .font(.system(size: AppTheme.fs(24), weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.sp(30)) {
            Image(systemName: "film.stack")
                .font(.system(size: AppTheme.fs(80), weight: .light))
                .foregroundColor(.appTextTertiary)

            VStack(spacing: 12) {
                Text("library.no_content".localized)
                    .font(.system(size: AppTheme.fs(38), weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("library.empty_message".localized)
                    .font(.system(size: AppTheme.fs(22)))
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
    
    // MARK: - Content Grid
    
    private var contentGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sp(30)) {
                // En-tête
                VStack(alignment: .leading, spacing: 10) {
                    Text(library.name)
                        .font(.system(size: AppTheme.fs(48), weight: .bold))
                        .foregroundColor(.appTextPrimary)

                    Text("library.items_count".localized(with: totalCount))
                        .font(.system(size: AppTheme.fs(24)))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.horizontal, AppTheme.sp(60))
                .padding(.top, 20)

                sortFilterBar
                    .padding(.horizontal, AppTheme.sp(60))

                // Grille de médias
                #if os(tvOS)
                let gridColumns = [GridItem(.adaptive(minimum: 350, maximum: 450), spacing: AppTheme.sp(30))]
                let gridSpacing: CGFloat = AppTheme.sp(40)
                let gridHPad: CGFloat = AppTheme.sp(60)
                #else
                let gridColumns = AppTheme.adaptiveColumns(phone: 105, pad: 170, spacing: 10)
                let gridSpacing: CGFloat = 12
                let gridHPad: CGFloat = 16
                #endif
                LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            #if os(tvOS)
                            ModernMediaCard(
                                item: item,
                                jellyfinService: jellyfinService,
                                accentColor: accentColorForType
                            )
                            #else
                            LibraryGridCard(
                                item: item,
                                jellyfinService: jellyfinService,
                                accentColor: accentColorForType
                            )
                            #endif
                        }
                        .buttonStyle(CustomCardButtonStyle(cornerRadius: 12))
                        .onAppear {
                            loadMoreIfNeeded(currentItem: item)
                        }
                    }
                }
                .padding(.horizontal, gridHPad)
                .padding(.top, 10)

                if isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.appSecondary)
                        Spacer()
                    }
                    .padding(.vertical, AppTheme.sp(30))
                }

                Color.clear.frame(height: AppTheme.sp(60))
            }
        }
        #if os(tvOS)
        .scrollClipDisabled()
        #endif
        .defaultScrollAnchor(.top)
    }

    // MARK: - Helpers
    
    private var accentColorForType: Color {
        switch library.collectionType?.lowercased() {
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
    
    // MARK: - Sort & Filter Bar

    private var sortFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LibrarySortOption.allCases) { option in
                    filterChip(
                        title: option.displayName,
                        icon: option.icon,
                        isSelected: sortOption == option
                    ) {
                        guard sortOption != option else { return }
                        sortOption = option
                        Task { await reloadFromScratch() }
                    }
                }

                Divider()
                    .frame(height: AppTheme.fs(24))

                filterChip(
                    title: "library.filter.unwatched".localized,
                    icon: "eye.slash",
                    isSelected: unwatchedOnly
                ) {
                    unwatchedOnly.toggle()
                    Task { await reloadFromScratch() }
                }
            }
            .padding(.vertical, 6)
        }
        #if os(tvOS)
        .scrollClipDisabled()
        #endif
    }

    private func filterChip(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: AppTheme.fs(18)))
                Text(title)
                    .font(.system(size: AppTheme.fs(20), weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .appTextSecondary)
            .padding(.horizontal, AppTheme.sp(22))
            .padding(.vertical, AppTheme.sp(10))
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.glassBackground))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : AppTheme.glassStroke, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(CustomCardButtonStyle(cornerRadius: 25))
    }

    // MARK: - Load Content (paginated)

    /// Recharge la première page (changement de tri/filtre, retry)
    @MainActor
    private func reloadFromScratch() async {
        isLoading = true
        items = []
        totalCount = 0

        do {
            let page = try await jellyfinService.getItemsPage(
                parentId: library.id,
                sortBy: sortOption,
                unwatchedOnly: unwatchedOnly,
                startIndex: 0,
                limit: Self.pageSize
            )

            withAnimation(AppTheme.standardAnimation) {
                self.items = page.items
                self.totalCount = page.totalCount
                self.isLoading = false
            }
        } catch {
            #if DEBUG
            print("[LibraryContentView] Error loading \(library.name): \(error.localizedDescription)")
            #endif
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }

    /// Déclenche le chargement de la page suivante quand on approche de la fin
    private func loadMoreIfNeeded(currentItem: MediaItem) {
        guard !isLoadingMore,
              items.count < totalCount,
              let index = items.firstIndex(where: { $0.id == currentItem.id }),
              index >= items.count - 20 else { return }

        isLoadingMore = true
        Task { await loadNextPage() }
    }

    @MainActor
    private func loadNextPage() async {
        defer { isLoadingMore = false }

        do {
            let page = try await jellyfinService.getItemsPage(
                parentId: library.id,
                sortBy: sortOption,
                unwatchedOnly: unwatchedOnly,
                startIndex: items.count,
                limit: Self.pageSize
            )

            // Dédup défensive : le contenu peut bouger entre deux pages
            let existingIDs = Set(items.map(\.id))
            items.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
            totalCount = page.totalCount
        } catch {
            #if DEBUG
            print("[LibraryContentView] Error loading next page: \(error.localizedDescription)")
            #endif
            // Erreur de pagination silencieuse : l'utilisateur peut re-scroller
        }
    }
}

// MARK: - Library Grid Card (iOS compact poster)

#if !os(tvOS)
struct LibraryGridCard: View {
    let item: MediaItem
    let jellyfinService: JellyfinService
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster image
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(2/3, contentMode: .fit)
                .overlay {
                    AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: item.id))) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "film")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.appTextTertiary)
                        case .empty:
                            ProgressView().tint(accentColor)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .clipped()
                .overlay(alignment: .topTrailing) {
                    MediaCardBadges(userData: jellyfinService.effectiveUserData(for: item))
                        .padding(6)
                }

            // Title
            Text(item.displayTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
        }
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.glassStroke, lineWidth: 1)
        )
        .mediaContextMenu(item: item, jellyfinService: jellyfinService)
    }
}
#endif

#Preview {
    NavigationStack {
        LibraryContentView(
            library: LibraryItem(
                id: "1",
                name: "Films",
                collectionType: "movies",
                imageUrl: nil
            ),
            jellyfinService: JellyfinService()
        )
    }
}
