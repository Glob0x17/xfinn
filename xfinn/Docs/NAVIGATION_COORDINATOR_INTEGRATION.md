# Guide d'intégration du NavigationCoordinator

## 🎯 Objectif
Permettre à `MediaDetailView` d'accéder au `NavigationCoordinator` pour implémenter la lecture automatique du prochain épisode.

## ⚠️ Important : Ordre d'intégration

### Option 1 : Intégration complète (recommandée)
Toutes les vues qui créent un `NavigationLink` vers `MediaDetailView` doivent transmettre le `@EnvironmentObject`.

### Option 2 : Intégration optionnelle (fallback)
Rendre le `NavigationCoordinator` optionnel dans `MediaDetailView` et désactiver l'autoplay si non disponible.

## 📝 Modification de MediaDetailView pour support optionnel

Si vous préférez une intégration progressive, voici comment rendre le NavigationCoordinator optionnel :

```swift
struct MediaDetailView: View {
    let item: MediaItem
    @ObservedObject var jellyfinService: JellyfinService
    
    // NavigationCoordinator optionnel
    @Environment(\.navigationCoordinator) private var navigationCoordinator: NavigationCoordinator?
    
    // ... rest of the code
}
```

Créer une clé d'environnement personnalisée :

```swift
// NavigationCoordinatorEnvironmentKey.swift
import SwiftUI

private struct NavigationCoordinatorKey: EnvironmentKey {
    static let defaultValue: NavigationCoordinator? = nil
}

extension EnvironmentValues {
    var navigationCoordinator: NavigationCoordinator? {
        get { self[NavigationCoordinatorKey.self] }
        set { self[NavigationCoordinatorKey.self] = newValue }
    }
}

extension View {
    func navigationCoordinator(_ coordinator: NavigationCoordinator) -> some View {
        environment(\.navigationCoordinator, coordinator)
    }
}
```

Puis modifier `playNextEpisode()` :

```swift
private func playNextEpisode() {
    guard let nextEpisode = nextEpisode else {
        print("⚠️ Pas d'épisode suivant à lire")
        return
    }
    
    guard let coordinator = navigationCoordinator else {
        print("⚠️ NavigationCoordinator non disponible, autoplay désactivé")
        return
    }
    
    print("▶️ Lecture automatique de l'épisode suivant: \(nextEpisode.displayTitle)")
    
    // ... reste du code
    coordinator.replaceLastWith(item: nextEpisode)
}
```

## 🔄 Vues à mettre à jour

### 1. HomeViewNetflix.swift
```swift
struct HomeViewNetflix: View {
    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            // ... contenu existant
        }
        .navigationDestination(for: MediaItem.self) { item in
            if item.type == "Series" {
                SeriesDetailView(series: item, jellyfinService: jellyfinService)
            } else {
                MediaDetailView(item: item, jellyfinService: jellyfinService)
            }
        }
    }
}
```

### 2. LibraryViewNetflix.swift
Même principe que HomeViewNetflix - ajouter le support de navigation typée.

### 3. SeriesDetailView.swift
Si cette vue affiche des épisodes, elle doit aussi transmettre le NavigationCoordinator.

## 🎯 Approche recommandée : NavigationStack avec path

La meilleure approche est d'utiliser un `NavigationStack` avec un `path` bindé au `NavigationCoordinator` :

```swift
struct HomeViewNetflix: View {
    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            // Contenu de la page d'accueil
            ScrollView {
                // ...
            }
            .navigationDestination(for: MediaItem.self) { item in
                // Cette closure est appelée automatiquement lors de la navigation
                if item.type == "Series" {
                    SeriesDetailView(series: item, jellyfinService: jellyfinService)
                } else {
                    MediaDetailView(item: item, jellyfinService: jellyfinService)
                }
            }
        }
    }
}
```

Avec cette approche :
- Tous les `NavigationLink` fonctionnent automatiquement
- Le `NavigationCoordinator` peut contrôler la pile de navigation
- L'autoplay fonctionne out-of-the-box

## 🧩 Exemple complet d'intégration

### Étape 1 : Mettre à jour ContentView
```swift
struct ContentView: View {
    @StateObject private var jellyfinService = JellyfinService()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some View {
        Group {
            if jellyfinService.isAuthenticated {
                HomeViewNetflix(jellyfinService: jellyfinService)
                    .environmentObject(navigationCoordinator)
            } else {
                LoginView(jellyfinService: jellyfinService)
            }
        }
        .onAppear {
            jellyfinService.loadSavedCredentials()
        }
    }
}
```

### Étape 2 : Mettre à jour HomeViewNetflix
```swift
struct HomeViewNetflix: View {
    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            // ... contenu existant
            
            // Remplacer tous les NavigationLink par des boutons qui appellent :
            Button {
                navigationCoordinator.navigateTo(item: someItem)
            } label: {
                // ...
            }
        }
        .navigationDestination(for: MediaItem.self) { item in
            if item.type == "Series" {
                SeriesDetailView(series: item, jellyfinService: jellyfinService)
            } else {
                MediaDetailView(item: item, jellyfinService: jellyfinService)
            }
        }
    }
}
```

### Étape 3 : Mettre à jour MediaDetailView
```swift
struct MediaDetailView: View {
    let item: MediaItem
    @ObservedObject var jellyfinService: JellyfinService
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    // ... le reste du code fonctionne automatiquement
}
```

## 🐛 Debugging

Si l'autoplay ne fonctionne pas :

1. **Vérifier que le NavigationCoordinator est injecté** :
```swift
.onAppear {
    print("🧭 NavigationCoordinator disponible: \(navigationCoordinator != nil)")
}
```

2. **Vérifier que le prochain épisode est chargé** :
```swift
if let next = nextEpisode {
    print("✅ Prochain épisode: \(next.displayTitle)")
} else {
    print("❌ Pas de prochain épisode")
}
```

3. **Vérifier que l'overlay s'affiche** :
```swift
.onChange(of: showNextEpisodeOverlay) { oldValue, newValue in
    print("👁️ Overlay visible: \(newValue)")
}
```

4. **Vérifier la navigation** :
```swift
private func playNextEpisode() {
    print("🔄 Navigation vers: \(nextEpisode?.displayTitle ?? "nil")")
    navigationCoordinator.replaceLastWith(item: nextEpisode)
    print("📊 Taille de la pile: \(navigationCoordinator.navigationPath.count)")
}
```

## ✅ Checklist d'intégration

- [ ] `ContentView` crée et injecte le `NavigationCoordinator`
- [ ] `HomeViewNetflix` utilise `NavigationStack(path:)` lié au coordinator
- [ ] `HomeViewNetflix` définit `.navigationDestination(for: MediaItem.self)`
- [ ] `MediaDetailView` reçoit le `@EnvironmentObject`
- [ ] Les `NavigationLink` utilisent des `MediaItem` directement
- [ ] Le prochain épisode se charge automatiquement (logs)
- [ ] L'overlay s'affiche 10s avant la fin (test)
- [ ] La navigation fonctionne lors du clic ou du timeout (test)

## 🎬 Test final

Créez un épisode de test court (1-2 minutes) et vérifiez :
1. L'overlay apparaît 10s avant la fin ✅
2. Le compte à rebours fonctionne ✅
3. Le clic sur "Annuler" fonctionne ✅
4. Le clic sur "Lire maintenant" fonctionne ✅
5. Le timeout lance automatiquement le prochain épisode ✅
6. Le nouvel épisode se charge et commence immédiatement ✅
7. La position de lecture est bien sauvegardée sur le serveur ✅
