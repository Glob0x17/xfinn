# Correction du problème de chevauchement des cartes de bibliothèque

## Problème identifié

Les cartes des bibliothèques (Films et Séries) se chevauchaient dans la grille de `LibraryView`.

## Causes identifiées

### 1. Configuration incorrecte du LazyVGrid
Le `LazyVGrid` utilisait :
```swift
LazyVGrid(
    columns: [
        GridItem(.adaptive(minimum: 400, maximum: 500), spacing: 30)
    ],
    spacing: 30
)
```

**Problèmes** :
- `.adaptive` peut créer un nombre variable de colonnes selon l'espace disponible
- L'espacement vertical de 30 était trop petit pour des cartes avec ombre et effet de focus
- Pas de hauteur fixe sur les cartes, ce qui peut causer des problèmes de layout

### 2. Hauteur de carte non contrainte
Les cartes n'avaient pas de hauteur totale fixe, ce qui pouvait causer des variations de taille et des chevauchements.

### 3. Même problème de MainActor.run
Comme dans les autres vues, `loadLibraries()` utilisait incorrectement `await MainActor.run`.

## Solutions apportées

### 1. Configuration du LazyVGrid avec colonnes fixes

**Avant** :
```swift
LazyVGrid(
    columns: [
        GridItem(.adaptive(minimum: 400, maximum: 500), spacing: 30)
    ],
    spacing: 30
)
```

**Après** :
```swift
LazyVGrid(
    columns: [
        GridItem(.flexible(minimum: 400, maximum: 600), spacing: 40),
        GridItem(.flexible(minimum: 400, maximum: 600), spacing: 40)
    ],
    spacing: 50 // Espacement vertical entre les rangées
)
```

**Changements** :
- ✅ Passage de `.adaptive` à `.flexible` avec 2 colonnes fixes
- ✅ Augmentation de l'espacement horizontal à 40
- ✅ Augmentation de l'espacement vertical à 50
- ✅ Augmentation de la largeur maximale à 600

### 2. Hauteur fixe pour les cartes

Ajout de hauteurs fixes dans `LibraryCard` :
```swift
VStack(alignment: .leading, spacing: 0) {
    // Image de la bibliothèque
    ZStack(alignment: .bottomLeading) {
        // ...
    }
    .frame(height: 300) // Hauteur fixe pour l'image
    .clipped()
    
    // Informations
    VStack(alignment: .leading, spacing: 12) {
        // ...
    }
    .padding(20)
    .frame(height: 100) // Hauteur fixe pour les infos
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Material.ultraThinMaterial)
}
.frame(height: 400) // Hauteur totale fixe (300 + 100)
```

### 3. Amélioration du padding et spacing

```swift
ScrollView(.vertical, showsIndicators: true) {
    VStack(alignment: .leading, spacing: 40) { // ← Augmenté de 30 à 40
        // En-tête
        VStack(alignment: .leading, spacing: 10) {
            // ...
        }
        .padding(.horizontal, 60)
        .padding(.top, 20)
        
        // Grille
        LazyVGrid(/* ... */) {
            // ...
        }
        .padding(.horizontal, 60)
        .padding(.bottom, 80) // ← Augmenté de 60 à 80
    }
}
```

### 4. Ajout de l'ID pour forcer le rafraîchissement

```swift
NavigationLink {
    LibraryContentView(library: library, jellyfinService: jellyfinService)
        .id(library.id) // ← Force le rafraîchissement lors du changement de bibliothèque
} label: {
    LibraryCard(library: library, jellyfinService: jellyfinService)
}
```

### 5. Correction de loadLibraries() avec @MainActor

**Avant** :
```swift
private func loadLibraries() async {
    // ...
    await MainActor.run {
        withAnimation(AppTheme.standardAnimation) {
            isLoading = false
        }
    }
}
```

**Après** :
```swift
@MainActor
private func loadLibraries() async {
    // ...
    withAnimation(AppTheme.standardAnimation) {
        self.libraries = loadedLibraries
        self.isLoading = false
    }
}
```

## Visualisation des changements

### Avant
```
┌─────────────┐ ┌─────────────┐
│   Films     │ │   Séries    │ ← Les cartes se chevauchent
└─────────────┘ └─────────────┘
      │               │
      └───────┬───────┘
          Overlap!
```

### Après
```
┌─────────────┐     ┌─────────────┐
│             │     │             │
│   Films     │     │   Séries    │
│             │     │             │
└─────────────┘     └─────────────┘
      ↑                   ↑
   400px              400px
   (fixe)             (fixe)
   
   ←────50px────→  Espacement vertical
```

## Résultats attendus

Après ces corrections :
1. ✅ Les cartes de bibliothèque ne se chevauchent plus
2. ✅ L'espacement entre les cartes est uniforme et suffisant
3. ✅ Les cartes ont une taille cohérente et prévisible
4. ✅ L'effet de focus (scale) a assez d'espace pour fonctionner
5. ✅ Le chargement est plus fiable avec les logs de débogage
6. ✅ La grille s'adapte bien à différentes tailles d'écran

## Paramètres clés à retenir

Pour une grille de cartes sans chevauchement :

```swift
LazyVGrid(
    columns: [
        GridItem(.flexible(minimum: W_MIN, maximum: W_MAX), spacing: H_SPACING),
        GridItem(.flexible(minimum: W_MIN, maximum: W_MAX), spacing: H_SPACING)
    ],
    spacing: V_SPACING
)
```

**Recommandations** :
- `H_SPACING` (horizontal) : au moins 40px pour les cartes avec ombre
- `V_SPACING` (vertical) : au moins 50px pour les cartes avec effet de focus
- Toujours définir une hauteur fixe sur les cartes : `.frame(height: FIXED_HEIGHT)`
- Ajouter du padding en bas : `.padding(.bottom, 80)` minimum

## Test

Pour vérifier que tout fonctionne :
1. Ouvrez la vue des bibliothèques
2. Vérifiez que les cartes sont bien espacées
3. Testez l'effet de focus (hover) - la carte doit grandir sans chevaucher les autres
4. Vérifiez les logs dans la console :
   ```
   📚 [LibraryView] Début du chargement des bibliothèques
   ✅ [LibraryView] 2 bibliothèque(s) chargée(s)
      📋 Bibliothèque: Films [Type: movies] [ID: xxx]
      📋 Bibliothèque: Séries [Type: tvshows] [ID: yyy]
   ```

## Notes sur le design responsive

Si vous voulez adapter le nombre de colonnes selon la taille d'écran, vous pouvez utiliser `GeometryReader` :

```swift
GeometryReader { geometry in
    let columnCount = geometry.size.width > 2000 ? 3 : 2
    LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(minimum: 400, maximum: 600), spacing: 40), count: columnCount),
        spacing: 50
    ) {
        // ...
    }
}
```

Mais pour tvOS (si c'est votre cible), 2 colonnes fixes est généralement optimal.
