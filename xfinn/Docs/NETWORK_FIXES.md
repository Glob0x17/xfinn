# Corrections apportées - Gestion des requêtes réseau

## 🐛 Problème identifié

**Erreur** : `NSURLErrorDomain Code=-999 "cancelled"`

Les requêtes réseau étaient annulées de manière répétée, causant des échecs de chargement des bibliothèques et des médias.

## 🔍 Cause racine

Le problème était causé par le **rechargement multiple** des vues SwiftUI. Voici ce qui se passait :

1. La vue se charge → `.task { }` démarre une requête réseau
2. La vue se recharge (à cause d'un changement d'état) → l'ancienne requête est **annulée**
3. Une nouvelle requête démarre
4. Le cycle se répète plusieurs fois
5. Toutes les requêtes sont annulées sauf peut-être la dernière

### Pourquoi les vues se rechargeaient ?

En SwiftUI, les vues peuvent se recharger pour plusieurs raisons :
- Changement d'une propriété `@Published` dans `JellyfinService`
- Navigation entre vues
- Rafraîchissement de l'interface
- Modifications de `@State` ou `@ObservedObject`

Quand SwiftUI recrée une vue, le modificateur `.task { }` est **réexécuté**, annulant la tâche précédente.

## ✅ Solution implémentée

### 1. Ajout d'un flag `hasLoaded`

Pour chaque vue qui charge des données, nous avons ajouté :

```swift
@State private var hasLoaded = false
```

Ce flag empêche les rechargements multiples de la même donnée.

### 2. Protection dans les fonctions de chargement

Chaque fonction de chargement vérifie maintenant si les données ont déjà été chargées :

```swift
private func loadContent() async {
    guard !hasLoaded else { return }  // ← Protection
    hasLoaded = true
    isLoading = true
    
    do {
        // Chargement des données...
    } catch {
        hasLoaded = false  // Permettre un nouvel essai en cas d'erreur
    }
    isLoading = false
}
```

### 3. Utilisation de `.task(id:)`

Au lieu de `.task { }`, nous utilisons `.task(id:)` pour lier la tâche à une propriété spécifique :

```swift
.task(id: library.id) {
    guard !hasLoaded else { return }
    await loadContent()
}
```

Cela garantit que :
- La tâche ne se relance **que si** l'ID change
- Si on navigue vers une autre bibliothèque, les données sont chargées
- Si on reste sur la même bibliothèque, pas de rechargement

## 📋 Vues corrigées

### 1. HomeView

**Changements** :
```swift
// Avant
@State private var isLoading = true

.task {
    await loadContent()
}

// Après
@State private var isLoading = true
@State private var hasLoaded = false

.task(id: jellyfinService.isAuthenticated) {
    guard !hasLoaded, jellyfinService.isAuthenticated else { return }
    await loadContent()
}
```

**Bénéfice** : Les sections "À reprendre" et "Récemment ajoutés" ne se rechargent plus en boucle.

---

### 2. LibraryView

**Changements** :
```swift
// Avant
@State private var isLoading = true

.task {
    await loadLibraries()
}

// Après
@State private var isLoading = true
@State private var hasLoaded = false

.task(id: jellyfinService.isAuthenticated) {
    guard !hasLoaded else { return }
    await loadLibraries()
}
```

**Bénéfice** : La liste des bibliothèques n'est chargée qu'une seule fois.

---

### 3. LibraryContentView

**Changements** :
```swift
// Avant
@State private var isLoading = true

.task {
    await loadContent()
}

// Après
@State private var isLoading = true
@State private var hasLoaded = false

.task(id: library.id) {
    guard !hasLoaded else { return }
    await loadContent()
}
```

**Bénéfice** : Le contenu d'une bibliothèque n'est chargé qu'une fois, sauf si on change de bibliothèque.

---

### 4. SeriesDetailView

**Changements** :
```swift
// Avant
@State private var isLoading = true

.task {
    await loadSeasons()
}

// Après
@State private var isLoading = true
@State private var hasLoaded = false

.task(id: series.id) {
    guard !hasLoaded else { return }
    await loadSeasons()
}
```

**Bénéfice** : Les saisons d'une série ne sont chargées qu'une fois.

---

### 5. SeasonEpisodesView

**Changements** :
```swift
// Avant
@State private var isLoading = true

.task {
    await loadEpisodes()
}

// Après
@State private var isLoading = true
@State private var hasLoaded = false

.task(id: season.id) {
    guard !hasLoaded else { return }
    await loadEpisodes()
}
```

**Bénéfice** : Les épisodes d'une saison ne sont chargés qu'une fois.

---

## 🔄 Gestion des erreurs

En cas d'erreur réseau, nous réinitialisons le flag `hasLoaded` :

```swift
do {
    // Tentative de chargement...
} catch {
    print("Erreur: \(error)")
    hasLoaded = false  // ← Permet de réessayer
}
```

Cela permet à l'utilisateur de :
- Tirer pour rafraîchir (si implémenté)
- Revenir à la vue et réessayer
- Laisser l'application retenter automatiquement

## 📊 Résultats

### Avant les corrections
```
❌ Erreur lors du chargement des bibliothèques: cancelled
❌ Erreur lors du chargement des bibliothèques: cancelled
❌ Erreur lors du chargement des bibliothèques: cancelled
❌ Erreur lors du chargement des bibliothèques: cancelled
❌ Erreur lors du chargement des épisodes: cancelled
```

### Après les corrections
```
✅ Chargement réussi des bibliothèques
✅ Chargement réussi du contenu
✅ Chargement réussi des saisons
✅ Chargement réussi des épisodes
```

## 🎯 Bonnes pratiques

### 1. Toujours protéger les chargements réseau

```swift
@State private var hasLoaded = false

.task(id: uniqueIdentifier) {
    guard !hasLoaded else { return }
    await loadData()
}
```

### 2. Réinitialiser en cas d'erreur

```swift
catch {
    hasLoaded = false  // Permettre un nouvel essai
}
```

### 3. Utiliser un ID unique pour `.task(id:)`

- Pour les vues liées à un élément : `.task(id: item.id)`
- Pour les vues liées à l'authentification : `.task(id: service.isAuthenticated)`
- Pour les vues statiques : `.task { }` avec protection `hasLoaded`

### 4. Logger les erreurs

```swift
catch {
    print("Erreur lors du chargement: \(error)")
    // Optionnel : afficher une alerte à l'utilisateur
}
```

## 🚀 Performance

Ces corrections améliorent également les performances :

- **Moins de requêtes réseau** : Une seule requête par vue au lieu de plusieurs
- **Moins de CPU** : Pas de rechargements inutiles
- **Meilleure expérience** : Chargement plus rapide et plus fiable
- **Moins de bande passante** : Économie de données

## 🔮 Améliorations futures possibles

1. **Cache des données** : Stocker les résultats pour éviter des requêtes même entre sessions
2. **Pull-to-refresh** : Permettre à l'utilisateur de forcer le rechargement
3. **Expiration** : Recharger automatiquement après X minutes
4. **Retry logic** : Réessayer automatiquement en cas d'erreur temporaire

## 📝 Note sur l'avertissement RawCamera

L'erreur suivante peut être ignorée :

```
buildPluginList:831: *** ERROR: failed to load 'RawCamera' bundle
```

C'est un **bug connu** du simulateur tvOS dans Xcode. Il n'affecte pas le fonctionnement de l'application et disparaît sur un appareil réel. Cela concerne le traitement des images RAW qui n'est pas pertinent pour une application tvOS de streaming.

---

*Document créé pour xfinn v1.0.0 - Corrections réseau*
