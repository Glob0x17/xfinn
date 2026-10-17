//
//  MediaCardBadges.swift
//  xfinn
//
//  Badges vu/favori affichés sur les cartes média, et menu contextuel
//  (appui long) pour basculer ces états. Les cartes lisent le UserData via
//  JellyfinService.effectiveUserData(for:) pour refléter les changements
//  locaux sans re-fetch des listes.
//

import SwiftUI

/// Coin supérieur droit des cartes : coche verte (vu) et cœur (favori)
struct MediaCardBadges: View {
    let userData: UserData?

    #if os(tvOS)
    private static let badgeSize: CGFloat = 26
    #else
    private static let badgeSize: CGFloat = 18
    #endif

    var body: some View {
        HStack(spacing: 6) {
            if userData?.isFavorite == true {
                badge(systemName: "heart.fill", color: AppTheme.tertiary)
            }
            if userData?.played == true {
                badge(systemName: "checkmark.circle.fill", color: AppTheme.success)
            }
        }
    }

    private func badge(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: Self.badgeSize * 0.55, weight: .bold))
            .foregroundColor(.white)
            .frame(width: Self.badgeSize, height: Self.badgeSize)
            .background(Circle().fill(color.opacity(0.9)))
            .shadow(color: .black.opacity(0.4), radius: 3)
    }
}

// MARK: - Context Menu (appui long)

extension View {
    /// Menu contextuel vu/favori sur une carte média
    /// (appui long sur la télécommande tvOS, long press iOS).
    /// `showDetailsAction` ajoute une entrée « Voir la fiche » — utile quand
    /// le tap direct lance la lecture (épisodes de série).
    func mediaContextMenu(
        item: MediaItem,
        jellyfinService: JellyfinService,
        showDetailsAction: (() -> Void)? = nil
    ) -> some View {
        modifier(MediaContextMenuModifier(
            item: item,
            jellyfinService: jellyfinService,
            showDetailsAction: showDetailsAction
        ))
    }
}

private struct MediaContextMenuModifier: ViewModifier {
    let item: MediaItem
    @ObservedObject var jellyfinService: JellyfinService
    var showDetailsAction: (() -> Void)? = nil

    private var userData: UserData? {
        jellyfinService.effectiveUserData(for: item)
    }

    func body(content: Content) -> some View {
        content.contextMenu {
            if let showDetailsAction {
                Button {
                    showDetailsAction()
                } label: {
                    Label("action.view_details".localized, systemImage: "info.circle")
                }
            }

            Button {
                Task {
                    try? await jellyfinService.setPlayed(
                        itemId: item.id,
                        played: !(userData?.played == true)
                    )
                }
            } label: {
                Label(
                    userData?.played == true
                        ? "action.mark_unwatched".localized
                        : "action.mark_watched".localized,
                    systemImage: userData?.played == true ? "checkmark.circle.badge.xmark" : "checkmark.circle"
                )
            }

            Button {
                Task {
                    try? await jellyfinService.setFavorite(
                        itemId: item.id,
                        favorite: !(userData?.isFavorite == true)
                    )
                }
            } label: {
                Label(
                    userData?.isFavorite == true
                        ? "action.unfavorite".localized
                        : "action.favorite".localized,
                    systemImage: userData?.isFavorite == true ? "heart.slash" : "heart"
                )
            }
        }
    }
}
