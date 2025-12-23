# Correction de l'effet de surbrillance automatique (Material)

## Problème identifié

L'utilisateur voyait une surbrillance blanche/bleue persistante sur les éléments, même avec notre effet de focus personnalisé. Ce n'était pas notre code, mais le comportement par défaut d'Apple.

## Cause racine

### `Material.ultraThinMaterial` sur tvOS/iOS

Sur tvOS et iOS, les `Material` (`.ultraThinMaterial`, `.thinMaterial`, etc.) ont un comportement automatique :
- **Au repos** : Apparence normale semi-transparente
- **Au focus** : Le Material devient automatiquement **plus lumineux et plus opaque**

C'est un comportement natif d'Apple qu'on ne peut pas désactiver directement sur le Material lui-même.

### Où ça posait problème

Le Material était utilisé dans tous nos backgrounds :
```swift
.background(Material.ultraThinMaterial)  // ← Devient lumineux au focus
```

## Solution appliquée

### Remplacement du Material par un background personnalisé

Au lieu d'utiliser `Material.ultraThinMaterial`, nous utilisons maintenant :

```swift
.background(
    RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.glassBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
)
```

Où :
- `AppTheme.glassBackground` = `Color.white.opacity(0.08)` - Contrôle total
- `AppTheme.glassStroke` = `Color.white.opacity(0.15)` - Contour glass

### Avantages

✅ **Pas de surbrillance automatique** : Notre background ne change pas au focus  
✅ **Contrôle total** : Seul notre effet violet apparaît  
✅ **Cohérence** : Même apparence sur toutes les plateformes  
✅ **Performance** : Légèrement plus rapide (pas de Material blur)  

## Fichiers modifiés

### 1. Theme.swift
**Changements** :
- Couleur de focus : Cyan (#00E5FF) → **Violet électrique (#BF5AF2)**
- Suppression du glow et de la surbrillance
- Contour uniquement (4px)

**Nouveau `FocusEffectModifier`** :
```swift
struct FocusEffectModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var scale: CGFloat = 1.05
    var borderWidth: CGFloat = 4
    @Environment(\.isFocused) private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            // Contour violet électrique uniquement
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isFocused ? AppTheme.focusBorder : .clear,
                        lineWidth: borderWidth
                    )
            )
            // Animation de scale
            .scaleEffect(isFocused ? scale : 1.0)
            .animation(AppTheme.springAnimation, value: isFocused)
    }
}
```

### 2. HomeView.swift

**libraryButton** :
```swift
// Avant
.glassCard(cornerRadius: 20, padding: 0)

// Après
.padding(30)
.background(
    RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.glassBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        )
)
.buttonStyle(.plain) // ← Important pour désactiver le style par défaut
```

**ModernMediaCard** :
```swift
// Avant
.background(Material.ultraThinMaterial)

// Après
.background(
    RoundedRectangle(cornerRadius: 0)
        .fill(AppTheme.glassBackground)
)
```

### 3. LibraryView.swift

**LibraryCard** :
```swift
// Avant
.background(Material.ultraThinMaterial)

// Après
.background(
    RoundedRectangle(cornerRadius: 0)
        .fill(AppTheme.glassBackground)
)
```

### 4. SeriesDetailView.swift

**SeasonCard** :
```swift
// Avant
.background(Material.ultraThinMaterial)

// Après
.background(
    RoundedRectangle(cornerRadius: 0)
        .fill(AppTheme.glassBackground)
)
```

**ModernEpisodeRow** :
```swift
// Avant
.background(Material.ultraThinMaterial)

// Après
.background(
    RoundedRectangle(cornerRadius: 20)
        .fill(AppTheme.glassBackground)
)
```

## Comparaison visuelle

### Avant (avec Material)

```
État normal                État focusé
───────────────           ────────────────────
┌─────────────┐           ┌─────────────────┐
│ Background  │     →     │ ████████████    │ ← Material devient lumineux
│ semi-trans  │           │ ███ Bright ███  │    (surbrillance automatique)
└─────────────┘           └─────────────────┘
                          ┏━━━━━━━━━━━━━━━━━┓ ← + Notre contour violet
                          ┗━━━━━━━━━━━━━━━━━┛
```

### Après (sans Material)

```
État normal                État focusé
───────────────           ────────────────────
┌─────────────┐           ┌─────────────┐
│ Background  │     →     │ Background  │ ← Reste identique
│ semi-trans  │           │ semi-trans  │
└─────────────┘           └─────────────┘
                          ┏━━━━━━━━━━━━━┓ ← Seulement notre contour violet
                          ┗━━━━━━━━━━━━━┛
```

## Effet final

### Ce qui est visible au focus :
1. ✅ **Contour violet électrique** (4px) - Très visible et propre
2. ✅ **Léger agrandissement** (scale 1.03-1.08)
3. ✅ **Animation fluide** (spring)

### Ce qui a été retiré :
- ❌ Surbrillance automatique du Material
- ❌ Glow bleu
- ❌ Ombres multiples
- ❌ Background lumineux au focus

## Notes techniques

### Pourquoi `cornerRadius: 0` pour certains backgrounds ?

```swift
.background(
    RoundedRectangle(cornerRadius: 0)  // ← Pourquoi 0 ?
        .fill(AppTheme.glassBackground)
)
```

Parce que la carte parente a déjà `.clipShape(RoundedRectangle(cornerRadius: 20))`. 
Le background est automatiquement clippé, donc pas besoin de coins arrondis doubles.

Pour les backgrounds complets (comme libraryButton), on met le `cornerRadius` :
```swift
.background(
    RoundedRectangle(cornerRadius: 20)  // ← 20 car c'est le seul
        .fill(AppTheme.glassBackground)
)
```

### Pourquoi `.buttonStyle(.plain)` ?

Sur `NavigationLink` et `Button`, SwiftUI applique un style par défaut qui peut aussi créer des effets de focus. `.buttonStyle(.plain)` désactive tout ça et nous laisse le contrôle total.

## Alternatives considérées

### Option 1 : Garder le Material + masquer le focus
❌ Impossible - Pas d'API pour désactiver le comportement du Material

### Option 2 : Utiliser `.regularMaterial` ou `.thickMaterial`
❌ Même problème - Tous les Materials réagissent au focus

### Option 3 : Wrapper le Material dans un conteneur
❌ Complexe et peut causer des problèmes de layout

### Option 4 : Background personnalisé ✅
✅ **Solution retenue** - Simple, performant, contrôle total

## Performance

### Material vs Background personnalisé

| Aspect | Material | Background personnalisé |
|--------|----------|------------------------|
| Blur | Oui (GPU) | Non |
| Transparence | Oui | Oui (moins coûteux) |
| Réactivité | Auto (incontrôlable) | Contrôlée |
| Performance | Bonne | Meilleure |
| Rendu | Adaptatif | Fixe |

Notre background personnalisé est **légèrement plus performant** car il n'utilise pas de blur dynamique.

## Tests

Pour vérifier que tout fonctionne :

1. **Lancez l'application**
2. **Naviguez sur les éléments** (télécommande tvOS, trackpad, souris)
3. **Vérifiez** :
   - ✅ Pas de surbrillance blanche/bleue
   - ✅ Contour violet électrique au focus
   - ✅ Léger agrandissement
   - ✅ Background reste stable

## Effet glass conservé

Même sans Material, l'effet glass est toujours présent grâce à :
- Background semi-transparent (`Color.white.opacity(0.08)`)
- Contour subtil (`Color.white.opacity(0.15)`)
- Overlay sur fond sombre

L'apparence visuelle reste très similaire, mais maintenant **vous contrôlez totalement le focus** ! 🟣✨

## Troubleshooting

### Le background est trop transparent
Ajustez `AppTheme.glassBackground` dans `Theme.swift` :
```swift
static let glassBackground = Color.white.opacity(0.12) // ← Augmentez
```

### Le background est trop opaque
```swift
static let glassBackground = Color.white.opacity(0.05) // ← Diminuez
```

### Le contour est trop visible
```swift
static let glassStroke = Color.white.opacity(0.10) // ← Diminuez
```

### Je veux quand même un léger blur
Ajoutez `.blur(radius: 1)` au background (attention aux performances).

## Conclusion

Le problème de surbrillance était causé par le **comportement natif du Material d'Apple**, pas par notre code. En remplaçant le Material par un background personnalisé, nous avons :

✅ **Éliminé** la surbrillance automatique  
✅ **Gardé** l'aspect glass moderne  
✅ **Obtenu** un contrôle total sur le focus  
✅ **Amélioré** légèrement les performances  

L'effet final est **propre et professionnel** : un contour violet électrique qui apparaît uniquement au focus, sans aucun effet parasite ! 🎯
