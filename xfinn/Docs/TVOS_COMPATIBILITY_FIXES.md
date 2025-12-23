# 🍎 Corrections de compatibilité tvOS

## Problèmes résolus (22 décembre 2024)

### 1. **Generic parameter could not be inferred**

**Erreur**: `Generic parameter 'R', 'C', 'Content', 'Label' could not be inferred`

**Fichier**: `Theme.swift` - `GlassButtonModifier`

**Cause**: Le `ViewModifier` utilisait un `Group` avec des types incompatibles (Color vs Material). SwiftUI ne pouvait pas inférer le type de retour.

**Solution**: Restructuré avec if/else au niveau du body complet

```swift
// ❌ Avant (Ne compile pas)
func body(content: Content) -> some View {
    content
        .background(
            Group {
                if isProminent {
                    AppTheme.primary.opacity(0.9)  // Type: Color
                } else {
                    Material.ultraThinMaterial      // Type: Material
                }
            }
        )
}

// ✅ Après (Compile parfaitement)
func body(content: Content) -> some View {
    if isProminent {
        content
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(AppTheme.primary.opacity(0.9))
            .cornerRadius(25)
            .overlay(
                Capsule()
                    .stroke(AppTheme.accent, lineWidth: 2)
            )
    } else {
        content
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(Material.ultraThinMaterial)
            .cornerRadius(25)
            .overlay(
                Capsule()
                    .stroke(AppTheme.glassStroke, lineWidth: 1)
            )
    }
}
```

**Explication**: 
- `Group` nécessite que tous ses enfants aient le **même type de retour**
- `Color` et `Material` sont deux types différents
- La solution est de dupliquer le code avec if/else pour que chaque branche retourne exactement le même type de vue

---

### 2. **'onHover(perform:)' is unavailable in tvOS**

**Erreur**: `'onHover(perform:)' is unavailable in tvOS`

**Fichier**: `HomeView.swift` - `ModernMediaCard`

**Cause**: `.onHover()` est une API iOS/macOS pour détecter le survol de la souris. tvOS n'a pas de souris !

**Solution**: Remplacé par `.onFocus()` avec compilation conditionnelle

```swift
// ❌ Avant (Ne fonctionne pas sur tvOS)
@State private var isHovered = false

var body: some View {
    VStack {
        // ... contenu de la carte
    }
    .scaleEffect(isHovered ? 1.05 : 1.0)
    .onHover { hovering in
        isHovered = hovering
    }
}

// ✅ Après (Fonctionne parfaitement sur tvOS)
@State private var isFocused = false

var body: some View {
    VStack {
        // ... contenu de la carte
    }
    .scaleEffect(isFocused ? 1.08 : 1.0)
    #if os(tvOS)
    .onFocus { focused in
        isFocused = focused
    }
    #endif
}
```

**Améliorations apportées**:
- ✅ Remplacé `isHovered` par `isFocused` (meilleure sémantique pour tvOS)
- ✅ Augmenté le scale à 1.08 (au lieu de 1.05) pour meilleure visibilité sur TV
- ✅ Augmenté le shadow radius pour effet plus visible à distance
- ✅ Compilation conditionnelle `#if os(tvOS)` pour compatibilité future iOS/macOS

**Pourquoi `.onFocus()` sur tvOS?**
- Sur tvOS, l'utilisateur navigue avec la **télécommande Apple TV**
- Les éléments reçoivent le **focus** (sélection) au lieu du hover
- Le focus est visible avec un effet de scale et shadow
- L'utilisateur appuie sur le bouton central pour activer l'élément focusé

---

### 3. **Type 'ShapeStyle' has no member 'appTextXXX'**

**Erreur**: Multiple instances de cette erreur dans `HomeView.swift`

**Cause**: `.foregroundStyle()` est strict sur les types `ShapeStyle`, mais nos extensions Color ne sont pas reconnues automatiquement

**Solution**: Remplacé par `.foregroundColor()` pour les couleurs simples

```swift
// ❌ Avant
.foregroundStyle(.appTextPrimary)
.foregroundStyle(.appTextSecondary)
.foregroundStyle(.appTextTertiary)

// ✅ Après
.foregroundColor(.appTextPrimary)
.foregroundColor(.appTextSecondary)
.foregroundColor(.appTextTertiary)
```

**Exception**: Les gradients utilisent `.foregroundStyle()` (correct):
```swift
// ✅ Correct pour les gradients
.foregroundStyle(
    LinearGradient(
        colors: [.white, AppTheme.accent],
        startPoint: .leading,
        endPoint: .trailing
    )
)
```

---

## Comparaison : iOS/macOS vs tvOS

| Fonctionnalité | iOS/macOS | tvOS |
|----------------|-----------|------|
| **Input** | Souris/Trackpad/Touch | Télécommande Apple TV |
| **Hover** | `.onHover()` | ❌ Non disponible |
| **Focus** | `.onFocus()` (optionnel) | `.onFocus()` (essentiel) |
| **Scale effect** | 1.05x (subtil) | 1.08x (plus visible) |
| **Shadow** | Radius 10-20pt | Radius 10-25pt |
| **Distance d'affichage** | ~50cm | ~3m |

---

## Best practices pour tvOS

### 1. **Focus, pas Hover**
```swift
// ✅ Toujours utiliser .onFocus() sur tvOS
#if os(tvOS)
.onFocus { focused in
    isFocused = focused
}
#endif
```

### 2. **Effets visuels amplifiés**
```swift
// ✅ Scale et shadow plus prononcés pour TV
.scaleEffect(isFocused ? 1.08 : 1.0)  // Au lieu de 1.05
.shadow(
    color: accentColor.opacity(isFocused ? 0.5 : 0.2),
    radius: isFocused ? 25 : 10  // Shadow plus grande
)
```

### 3. **Tailles de texte généreuses**
```swift
// ✅ Texte minimum 18pt, idéalement 20-26pt
.font(.system(size: 26, weight: .medium))  // Lisible à 3m
```

### 4. **Zones de tap larges**
```swift
// ✅ Minimum 70pt de hauteur pour les boutons
.frame(height: 70)
```

### 5. **Navigation claire**
```swift
// ✅ Ordre de focus explicite si nécessaire
.focusable(true)
.focusSection()  // Grouper les sections de focus
```

---

## Testing sur tvOS

### Simulateur
1. Ouvrir Xcode
2. Sélectionner un simulateur **Apple TV** (pas iPad!)
3. Build & Run (`Cmd + R`)
4. Utiliser le trackpad pour simuler la télécommande

### Contrôles simulateur
- **Swipe** : Navigation directionnelle
- **Click** : Sélection (équivalent du bouton central)
- **Option + Swipe** : Rotation de la télécommande virtuelle

### Tests à effectuer
- [ ] Navigation fluide entre les cartes
- [ ] Effet de focus visible (scale + shadow)
- [ ] Animations smooth sans lag
- [ ] Textes lisibles depuis l'autre bout de la pièce
- [ ] Pas de "hover" accidentel (vérifié ✅)

---

## État de la compilation

### ✅ Theme.swift
- [x] GlassButtonModifier : if/else restructuré
- [x] GlassCardModifier : Material.ultraThinMaterial correct
- [x] Toutes les erreurs résolues

### ✅ HomeView.swift
- [x] Tous les .foregroundStyle() → .foregroundColor()
- [x] .onHover() → .onFocus() avec #if os(tvOS)
- [x] isFocused au lieu de isHovered
- [x] Toutes les erreurs résolues

### ✅ LoginView.swift
- [x] Aucune erreur de compilation
- [x] Compatible tvOS

---

## Fichiers modifiés

| Fichier | Modifications | Lignes |
|---------|--------------|--------|
| `Theme.swift` | GlassButtonModifier restructuré | 145-175 |
| `HomeView.swift` | onFocus + foregroundColor | 100-565 |

---

## Prochaines étapes

1. ✅ **Build l'application** : `Cmd + B`
2. ✅ **Run sur Apple TV Simulator** : `Cmd + R`
3. 🎯 **Tester la navigation** avec trackpad/télécommande
4. 🎯 **Vérifier les effets de focus** sur les cartes
5. 🎯 **Continuer le redesign** : MediaDetailView ou Player?

---

*Dernière mise à jour : 22 décembre 2024*
*Plateforme cible : tvOS 17.0+*
