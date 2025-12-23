//
//  View+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//  Reorganized on 23/12/2025.
//

import SwiftUI

// MARK: - View Extensions

extension View {
    /// Applique un effet de carte pour tvOS
    func cardStyle() -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.3), radius: 10)
    }
    
    /// Rend la vue focusable avec animation
    func focusableCard() -> some View {
        modifier(FocusableCardModifier())
    }
}

// MARK: - Modifiers personnalisés

struct FocusableCardModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .focused($isFocused)
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension View {
    func debugPrint(_ value: Any) -> some View {
        print("🔍 Debug:", value)
        return self
    }
    
    func debugBorder(_ color: Color = .red) -> some View {
        self.border(color, width: 2)
    }
}
#endif
