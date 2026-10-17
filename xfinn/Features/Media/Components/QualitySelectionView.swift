//
//  QualitySelectionView.swift
//  xfinn
//
//  Onglet « Qualité » du panneau d'infos du lecteur tvOS : grille de
//  bitrates cibles, bascule en cours de lecture (reprise à la position
//  courante). Le choix est persisté comme qualité préférée.
//

import SwiftUI
#if os(tvOS)
import UIKit
#endif

struct QualitySelectionView: View {
    let currentQuality: StreamQuality
    let onSelect: (StreamQuality) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 4
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(StreamQuality.allCases) { quality in
                qualityChip(quality)
            }
        }
        .padding(24)
    }

    private func qualityChip(_ quality: StreamQuality) -> some View {
        let isSelected = quality == currentQuality
        return Button {
            onSelect(quality)
        } label: {
            HStack(spacing: 8) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                }
                Text(quality.displayName)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : .appTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.glassBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppTheme.tertiary.opacity(0.8) : AppTheme.glassStroke, lineWidth: 1.5)
            )
        }
        .buttonStyle(GlassButtonStyle(isProminent: isSelected))
    }
}

// MARK: - UIKit Hosting Controller (tvOS only)

#if os(tvOS)
final class QualitySelectionViewController: UIHostingController<QualitySelectionView> {

    init(currentQuality: StreamQuality, onSelect: @escaping (StreamQuality) -> Void) {
        super.init(rootView: QualitySelectionView(
            currentQuality: currentQuality,
            onSelect: onSelect
        ))
        self.title = "media.streaming_quality".localized
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        preferredContentSize = CGSize(width: 1000, height: 320)
    }
}
#endif
