# Système de Focus avec Surbrillance Bleue et Contour Vif

## Vue d'ensemble

Un nouveau système d'effet de focus a été ajouté à l'application pour améliorer la visibilité et l'interaction avec les éléments interactifs. Le système utilise une **surbrillance bleue claire** en arrière-plan et un **contour cyan électrique** très vif.

## Caractéristiques visuelles

### Couleurs de focus
Trois nouvelles couleurs ont été ajoutées au thème :

```swift
// Dans AppTheme
static let focusHighlight = Color(red: 0.4, green: 0.85, blue: 1.0)  // #66D9FF - Bleu cyan lumineux
static let focusBorder = Color(red: 0.0, green: 0.9, blue: 1.0)     // #00E5FF - Cyan électrique vif
static let focusGlow = Color(red: 0.2, green: 0.7, blue: 1.0)       // #33B3FF - Bleu électrique
```

Accessibles via les extensions :
```swift
Color.appFocusHighlight
Color.appFocusBorder
Color.appFocusGlow
```

### Effets visuels

Lorsqu'un élément reçoit le focus :

1. **Surbrillance bleue claire** : Un fond bleu cyan lumineux avec 15% d'opacité et blur de 8px
2. **Contour vif cyan électrique** : Une bordure de 3-4px dans un cyan très vif (#00E5FF)
3. **Double glow** : Deux ombres superposées créant un effet lumineux autour de l'élément
4. **Animation de scale** : Agrandissement léger de l'élément (1.03x à 1.08x selon le type)
5. **Animation spring** : Transition fluide et naturelle

## Utilisation

### Modifier `.focusEffect()`

Le nouveau modifier est simple à utiliser :

```swift
.focusEffect(
    cornerRadius: 20,    // Rayon des coins (défaut: 20)
    scale: 1.05,         // Facteur d'agrandissement (défaut: 1.05)
    borderWidth: 3       // Épaisseur du contour (défaut: 3)
)
```

### Exemples d'utilisation

#### Cartes de média (HomeView)
```swift
ModernMediaCard(item: item, jellyfinService: jellyfinService, accentColor: .appPrimary)
    .focusEffect(cornerRadius: 20, scale: 1.08, borderWidth: 4)
```

#### Cartes de bibliothèque (LibraryView)
```swift
LibraryCard(library: library, jellyfinService: jellyfinService)
    .focusEffect(cornerRadius: 20, scale: 1.05, borderWidth: 4)
```

#### Boutons (HomeView)
```swift
libraryButton
    .focusEffect(cornerRadius: 20, scale: 1.03, borderWidth: 3)
```

#### Cartes de saison (SeriesDetailView)
```swift
SeasonCard(season: season, jellyfinService: jellyfinService)
    .focusEffect(cornerRadius: 20, scale: 1.05, borderWidth: 3)
```

#### Lignes d'épisodes (SeriesDetailView)
```swift
ModernEpisodeRow(episode: episode, jellyfinService: jellyfinService)
    .focusEffect(cornerRadius: 20, scale: 1.03, borderWidth: 3)
```

## Détails techniques

### Le modifier `FocusEffectModifier`

```swift
struct FocusEffectModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var scale: CGFloat = 1.05
    var borderWidth: CGFloat = 3
    @Environment(\.isFocused) private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            // Surbrillance bleue claire en arrière-plan
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        isFocused ?
                        AppTheme.focusHighlight.opacity(0.15) :
                        Color.clear
                    )
                    .blur(radius: 8)
                    .padding(-10)
            )
            // Contour vif cyan électrique
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isFocused ?
                        AppTheme.focusBorder :
                        Color.clear,
                        lineWidth: borderWidth
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
            // Effet de glow autour
            .shadow(
                color: isFocused ? AppTheme.focusGlow.opacity(0.6) : .clear,
                radius: isFocused ? 25 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: isFocused ? AppTheme.focusBorder.opacity(0.4) : .clear,
                radius: isFocused ? 40 : 0,
                x: 0,
                y: 0
            )
            // Animation de scale
            .scaleEffect(isFocused ? scale : 1.0)
            .animation(AppTheme.springAnimation, value: isFocused)
    }
}
```

### Comment ça fonctionne

1. **Détection du focus** : Utilise `@Environment(\.isFocused)` pour détecter le focus
2. **Surbrillance** : Un `RoundedRectangle` avec fill et blur en arrière-plan
3. **Contour** : Un `strokeBorder` qui apparaît au focus
4. **Glow** : Deux `shadow` superposées pour l'effet lumineux
5. **Scale** : `scaleEffect` pour agrandir l'élément
6. **Animation** : Utilise `AppTheme.springAnimation` pour la fluidité

## Remplacement de l'ancien système

### Avant (ancien système)
```swift
.scaleEffect(isFocused ? 1.05 : 1.0)
.shadow(
    color: accentColor.opacity(isFocused ? 0.5 : 0.2),
    radius: isFocused ? 25 : 10,
    x: 0,
    y: isFocused ? 12 : 5
)
.animation(AppTheme.springAnimation, value: isFocused)
```

**Problèmes** :
- Pas assez visible
- Pas de contour clair
- Couleur variable selon l'élément
- Nécessite `@Environment(\.isFocused)` dans chaque vue

### Après (nouveau système)
```swift
.focusEffect(cornerRadius: 20, scale: 1.05, borderWidth: 3)
```

**Avantages** :
- ✅ Surbrillance très visible
- ✅ Contour cyan électrique distinctif
- ✅ Couleur cohérente dans toute l'app
- ✅ Une seule ligne de code
- ✅ Paramétrable facilement
- ✅ Gère automatiquement le focus

## Vues mises à jour

### Theme.swift
- ✅ Ajout des couleurs de focus
- ✅ Ajout du `FocusEffectModifier`
- ✅ Ajout de l'extension `.focusEffect()`

### HomeView.swift
- ✅ `ModernMediaCard` : Remplacement de l'ancien système
- ✅ `libraryButton` : Ajout du nouvel effet

### LibraryView.swift
- ✅ `LibraryCard` : Remplacement de l'ancien système

### SeriesDetailView.swift
- ✅ `SeasonCard` : Remplacement de l'ancien système
- ✅ `ModernEpisodeRow` : Remplacement de l'ancien système

### LibraryContentView.swift
- ℹ️ Utilise `ModernMediaCard` qui a déjà été mis à jour

## Personnalisation

### Ajuster l'intensité du glow
Modifiez les opacités dans `FocusEffectModifier` :
```swift
.shadow(
    color: isFocused ? AppTheme.focusGlow.opacity(0.6) : .clear,  // ← Changez 0.6
    radius: isFocused ? 25 : 0,
    x: 0,
    y: 0
)
```

### Ajuster la surbrillance
Modifiez l'opacité du background :
```swift
.fill(
    isFocused ?
    AppTheme.focusHighlight.opacity(0.15) :  // ← Changez 0.15
    Color.clear
)
```

### Ajuster l'épaisseur du contour
Passez un paramètre différent :
```swift
.focusEffect(borderWidth: 5)  // Plus épais
.focusEffect(borderWidth: 2)  // Plus fin
```

### Changer le facteur de scale
```swift
.focusEffect(scale: 1.1)   // Agrandissement plus prononcé
.focusEffect(scale: 1.02)  // Agrandissement subtil
```

## Recommandations d'usage

### Par type d'élément

| Type d'élément | cornerRadius | scale | borderWidth |
|----------------|--------------|-------|-------------|
| Grandes cartes | 20 | 1.08 | 4 |
| Cartes moyennes | 20 | 1.05 | 3-4 |
| Boutons | 20 | 1.03 | 3 |
| Lignes | 20 | 1.03 | 3 |
| Petits éléments | 15 | 1.02 | 2 |

### Cohérence visuelle
- Utilisez toujours le même `cornerRadius` que l'élément sous-jacent
- Les éléments plus grands peuvent avoir un scale plus important
- Les éléments de liste devraient avoir un scale plus subtil (1.02-1.03)
- Les cartes isolées peuvent avoir un scale plus prononcé (1.05-1.08)

## Accessibilité

L'effet de focus améliore l'accessibilité :
- ✅ Contour très visible pour les utilisateurs malvoyants
- ✅ Animation fluide pour éviter les distractions
- ✅ Cohérence dans toute l'application
- ✅ Compatible avec VoiceOver (n'interfère pas)
- ✅ Fonctionne sur tvOS avec la télécommande

## Performance

L'effet est optimisé pour les performances :
- Animations GPU-accelerated
- Pas de recalculs inutiles
- Utilise les APIs natives SwiftUI
- Pas d'impact sur le framerate

## Compatibilité

- ✅ iOS 17+
- ✅ tvOS 17+
- ✅ macOS 14+ (Sonoma)
- ✅ Fonctionne avec `.focusable()`
- ✅ Compatible avec `NavigationLink`
- ✅ Compatible avec `Button`

## Exemples visuels

### État normal
```
┌────────────────────┐
│                    │
│   Contenu de la    │
│      carte         │
│                    │
└────────────────────┘
```

### État focusé
```
    ╔══════════════════════╗   ← Glow bleu
    ║ ┌──────────────────┐ ║   ← Contour cyan vif (#00E5FF)
    ║ │   ░░░░░░░░░░░░   │ ║   ← Surbrillance bleue
    ║ │   Contenu de la  │ ║
    ║ │      carte       │ ║   (Légèrement agrandi)
    ║ │   ░░░░░░░░░░░░   │ ║
    ║ └──────────────────┘ ║
    ╚══════════════════════╝
```

## Migration

Si vous avez d'autres vues avec l'ancien système de focus, voici comment migrer :

### Étape 1 : Identifier le code à remplacer
Recherchez :
```swift
.scaleEffect(isFocused ? ... : ...)
.shadow(...opacity(isFocused ? ... : ...)...)
.animation(..., value: isFocused)
```

### Étape 2 : Remplacer par
```swift
.focusEffect()
```

### Étape 3 : Ajuster si nécessaire
Si l'élément a un `cornerRadius` différent de 20 :
```swift
.focusEffect(cornerRadius: VotreValeur)
```

### Étape 4 : Supprimer l'ancienne variable
Si `@Environment(\.isFocused)` n'est plus utilisée ailleurs, vous pouvez la supprimer.

## Troubleshooting

### Le focus ne fonctionne pas
- Vérifiez que l'élément parent est dans un `NavigationLink` ou un `Button`
- Sur tvOS, vérifiez que `.focusable()` est bien défini si nécessaire

### Le contour est coupé
- Ajoutez du padding autour de l'élément
- Vérifiez que l'élément parent n'a pas `.clipped()`

### L'animation saccade
- Vérifiez qu'il n'y a pas trop d'éléments animés en même temps
- Utilisez `.drawingGroup()` sur les éléments complexes

### La couleur ne correspond pas
- Vérifiez que vous utilisez bien `AppTheme.focusBorder` et pas une autre couleur
- Vérifiez les opacités dans le modifier

## Future évolutions

Améliorations possibles :
- [ ] Variante pour les éléments circulaires
- [ ] Effet de "pulse" pour les notifications
- [ ] Support des gradients dans le contour
- [ ] Mode sombre/clair automatique
- [ ] Variante "subtle" pour les interfaces encombrées
