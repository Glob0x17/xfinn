# 🔍 Diagnostic de l'effet de focus tvOS

## 🎯 Problème persistant

Un **carré bleu clair** continue d'apparaître sur les éléments interactifs malgré les corrections apportées.

## 🔎 Causes possibles et solutions

### 1. **Focus Effect par défaut du système tvOS**

Sur tvOS, même avec `.focusEffectDisabled()` et un modificateur personnalisé, le système peut quand même appliquer un effet de focus minimal.

#### Test de diagnostic :

Ajoutez temporairement ceci à votre `ModernMediaCard` pour identifier le problème :

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 0) {
        // ... votre contenu existant
    }
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .stroke(AppTheme.glassStroke, lineWidth: 1.5)
    )
    .frame(width: 400)
    // DIAGNOSTIC: Ajouter une bordure rouge quand focusé pour voir ce qui se passe
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(isFocused ? .red : .clear, lineWidth: 10)
    )
}
```

Si vous voyez **à la fois** la bordure rouge **ET** le carré bleu, alors le problème vient du `NavigationLink` parent, pas de la carte elle-même.

### 2. **Button Style sur le NavigationLink**

Le `.buttonStyle(.plain)` sur tvOS ne désactive pas complètement l'effet de focus. 

#### Solution Alternative 1 : Utiliser `ButtonStyle` personnalisé

Remplacez dans **HomeView.swift**, **LibraryView.swift**, etc. :

```swift
// ❌ ANCIEN CODE
NavigationLink { ... } label: { ... }
    .buttonStyle(.plain)
    .focusEffect(cornerRadius: 20, scale: 1.08, borderWidth: 6)
```

Par :

```swift
// ✅ NOUVEAU CODE
Button {
    // Navigation manuelle
} label: {
    NavigationLink(value: item) { ... }
}
.buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
```

**Mais** cela nécessite d'utiliser `.navigationDestination` dans la vue parente.

#### Solution Alternative 2 : Ajouter `.focusable(false)` sur la carte

Dans `ModernMediaCard` et `LibraryCard`, ajoutez :

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 0) {
        // ... contenu
    }
    .focusable(false) // ← Empêche la carte elle-même d'être focusable
    .clipShape(RoundedRectangle(cornerRadius: 20))
    // ...
}
```

### 3. **Effet de focus du `AsyncImage`**

Les `AsyncImage` peuvent avoir leur propre effet de focus sur tvOS.

#### Solution :

Dans `ModernMediaCard` et `LibraryCard`, ajoutez `.focusable(false)` à l'AsyncImage :

```swift
AsyncImage(url: URL(string: jellyfinService.getImageURL(itemId: item.id))) { phase in
    // ...
}
.focusable(false) // ← Empêche l'image d'être focusable
```

### 4. **Overlay ou Background qui capture le focus**

Les `.overlay()` et `.background()` peuvent parfois capturer le focus sur tvOS.

#### Solution :

Ajoutez `.allowsHitTesting(false)` à tous les overlays décoratifs :

```swift
.overlay(
    RoundedRectangle(cornerRadius: 20)
        .stroke(AppTheme.glassStroke, lineWidth: 1.5)
        .allowsHitTesting(false) // ← Important !
)
```

### 5. **Effet de focus cumulé**

Si vous avez **plusieurs modificateurs de focus** sur le même élément, ils peuvent s'accumuler.

#### Solution :

Assurez-vous de n'avoir **qu'un seul** modificateur de focus par élément. Par exemple :

```swift
// ❌ MAUVAIS (plusieurs modificateurs)
NavigationLink { ... }
    .buttonStyle(.plain)
    .focusEffect(...)
    .focusEffectDisabled()  // ← Conflit !
```

```swift
// ✅ BON (un seul modificateur)
NavigationLink { ... }
    .buttonStyle(.plain)
    .focusEffect(...)
```

## 🛠️ Solution recommandée (étape par étape)

### Étape 1 : Modifier `Theme.swift`

Utilisez le nouveau `CustomCardButtonStyle` au lieu du `.focusEffect()` :

```swift
extension ButtonStyle where Self == CustomCardButtonStyle {
    static var customCard: CustomCardButtonStyle {
        CustomCardButtonStyle()
    }
    
    static func customCard(cornerRadius: CGFloat) -> CustomCardButtonStyle {
        CustomCardButtonStyle(cornerRadius: cornerRadius)
    }
}
```

### Étape 2 : Utiliser `Button` + `.navigationDestination` au lieu de `NavigationLink`

Dans `HomeView.swift` (exemple pour le carrousel) :

```swift
struct MediaCarousel: View {
    // ... propriétés existantes
    @State private var selectedItem: MediaItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // ... en-tête
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(items) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            ModernMediaCard(
                                item: item,
                                jellyfinService: jellyfinService,
                                accentColor: accentColor
                            )
                        }
                        .buttonStyle(.customCard)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 5)
            }
        }
        .navigationDestination(item: $selectedItem) { item in
            if item.type == "Series" {
                SeriesDetailView(series: item, jellyfinService: jellyfinService)
            } else if item.type == "Season" {
                SeasonEpisodesView(season: item, jellyfinService: jellyfinService)
            } else {
                MediaDetailView(item: item, jellyfinService: jellyfinService)
            }
        }
    }
}
```

### Étape 3 : Désactiver le focus sur les éléments décoratifs

Dans `ModernMediaCard` et `LibraryCard`, ajoutez `.focusable(false)` partout où c'est nécessaire :

```swift
AsyncImage(...) { phase in
    // ...
}
.focusable(false)

// Pour tous les overlays décoratifs
.overlay(
    LinearGradient(...)
        .allowsHitTesting(false)
)
```

## 🧪 Tests à effectuer

1. **Testez avec la bordure rouge** (code diagnostic ci-dessus) pour identifier l'origine du focus
2. **Désactivez temporairement tous les modificateurs de focus** pour voir si le carré bleu disparaît
3. **Testez avec un NavigationLink simple** sans style pour voir le comportement par défaut
4. **Utilisez Accessibility Inspector dans Xcode** pour voir quels éléments sont focusables

## 📊 Checklist de diagnostic

- [ ] Le carré bleu apparaît-il **uniquement** sur les cartes de média/bibliothèque ?
- [ ] Le carré bleu apparaît-il **aussi** sur les boutons (ex: bouton "Toutes les bibliothèques") ?
- [ ] Le carré bleu a-t-il une **forme spécifique** (carré parfait, rectangle, arrondi) ?
- [ ] Le carré bleu apparaît-il **en même temps** que votre effet de focus personnalisé (bordure violette) ?
- [ ] Y a-t-il **plusieurs effets** qui se superposent ?

## 💡 Solution rapide (workaround)

Si rien ne fonctionne, vous pouvez temporairement **masquer** le carré bleu avec un overlay :

```swift
.overlay(
    RoundedRectangle(cornerRadius: 20)
        .fill(Color.clear)
        .allowsHitTesting(false)
)
```

Mais ce n'est pas une solution idéale car elle ne résout pas le problème root cause.

## 🎯 Prochaines étapes

1. Effectuez le test de diagnostic avec la bordure rouge
2. Partagez le résultat (capture d'écran si possible)
3. Vérifiez la checklist ci-dessus
4. Essayez la solution avec `Button` + `.navigationDestination`

---

**Note :** Le carré bleu clair est souvent un effet de focus **par défaut du système tvOS** qui apparaît quand il n'arrive pas à déterminer comment afficher le focus. Il faut identifier précisément quel élément reçoit ce focus pour pouvoir le corriger.
