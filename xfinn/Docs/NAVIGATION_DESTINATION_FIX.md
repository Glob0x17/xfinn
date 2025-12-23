# Correction critique - navigationDestination en double

## 🐛 Problème

**Symptômes** :
- Cliquer sur une bibliothèque → retour immédiat à la liste des bibliothèques
- Erreurs "cancelled" répétées dans les logs
- Messages d'avertissement : `"A navigationDestination for xfinn.MediaItem was declared earlier on the stack"`

**Logs typiques** :
```
A navigationDestination for "xfinn.MediaItem" was declared earlier on the stack. 
Only the destination declared closest to the root view of the stack will be used.

A navigationDestination for "xfinn.LibraryItem" was declared earlier on the stack. 
Only the destination declared closest to the root view of the stack will be used.
```

## 🔍 Cause racine

Le problème était causé par **plusieurs déclarations de `navigationDestination`** pour le même type à différents niveaux de la hiérarchie :

```
NavigationStack (HomeView)
    │
    ├─ MediaCarousel
    │   └─ .navigationDestination(for: MediaItem.self) { } ← ❌ Déclaration #1
    │
    ├─ NavigationLink → LibraryView
    │   └─ .navigationDestination(for: LibraryItem.self) { } ← ❌ Déclaration #2
    │
    └─ NavigationLink → LibraryContentView  
        └─ .navigationDestination(for: MediaItem.self) { } ← ❌ Déclaration #3
```

SwiftUI ne savait pas quelle destination utiliser quand un `NavigationLink(value:)` était cliqué, ce qui causait des comportements erratiques.

## ⚠️ Règle d'or pour navigationDestination

> **UN SEUL `navigationDestination` PAR TYPE dans un `NavigationStack`**

SwiftUI n'autorise qu'**un seul** `navigationDestination` pour chaque type (`MediaItem`, `LibraryItem`, etc.) dans une même pile de navigation.

### ✅ Architecture correcte

```swift
NavigationStack {  // ← Racine
    // Contenu...
    
    // ✅ TOUS les navigationDestination au même endroit
    .navigationDestination(for: LibraryItem.self) { library in
        LibraryContentView(...)
    }
    .navigationDestination(for: MediaItem.self) { item in
        if item.type == "Series" {
            SeriesDetailView(...)
        } else {
            MediaDetailView(...)
        }
    }
}
```

### ❌ Architecture incorrecte

```swift
NavigationStack {
    VStack {
        // Vue enfant A
        .navigationDestination(for: MediaItem.self) { } // ❌ #1
        
        // Vue enfant B
        .navigationDestination(for: MediaItem.self) { } // ❌ #2 CONFLIT!
    }
}
```

## ✅ Solution appliquée

### Avant : Destinations dispersées ❌

**HomeView.swift** :
```swift
struct MediaCarousel: View {
    var body: some View {
        // ...
        .navigationDestination(for: MediaItem.self) { } // ❌
    }
}
```

**LibraryView.swift** :
```swift
var body: some View {
    // ...
    .navigationDestination(for: LibraryItem.self) { } // ❌
}
```

**LibraryContentView.swift** :
```swift
var body: some View {
    // ...
    .navigationDestination(for: MediaItem.self) { } // ❌
}
```

**SeriesDetailView.swift** :
```swift
var body: some View {
    // ...
    .navigationDestination(for: MediaItem.self) { } // ❌
}

struct SeasonEpisodesView: View {
    var body: some View {
        // ...
        .navigationDestination(for: MediaItem.self) { } // ❌
    }
}
```

### Après : Destinations centralisées ✅

**HomeView.swift** (seul endroit) :
```swift
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                // Tout le contenu...
            }
            .navigationTitle("Accueil")
            
            // ✅ TOUS les navigationDestination centralisés ICI
            .navigationDestination(for: LibraryItem.self) { library in
                LibraryContentView(library: library, jellyfinService: jellyfinService)
            }
            .navigationDestination(for: MediaItem.self) { item in
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
}
```

**Toutes les autres vues** :
```swift
// MediaCarousel, LibraryView, LibraryContentView, SeriesDetailView, etc.
var body: some View {
    VStack {
        // Contenu avec NavigationLink(value:)
        NavigationLink(value: item) { } // ✅ Fonctionne avec le destination central
    }
    .navigationTitle("Titre")
    // ❌ PLUS de .navigationDestination ici
}
```

## 📋 Fichiers modifiés

### 1. HomeView.swift
- ✅ **Ajouté** : `.navigationDestination(for: LibraryItem.self)`
- ✅ **Ajouté** : `.navigationDestination(for: MediaItem.self)` (centralisé)
- ✅ **Supprimé** : `navigationDestination` de `MediaCarousel`

### 2. LibraryView.swift
- ✅ **Supprimé** : `.navigationDestination(for: LibraryItem.self)`

### 3. LibraryContentView.swift
- ✅ **Supprimé** : `.navigationDestination(for: MediaItem.self)`

### 4. SeriesDetailView.swift
- ✅ **Supprimé** : `.navigationDestination(for: MediaItem.self)` (SeriesDetailView)
- ✅ **Supprimé** : `.navigationDestination(for: MediaItem.self)` (SeasonEpisodesView)

## 🎯 Flux de navigation après correction

```
1. HomeView (avec NavigationStack)
   ↓
   [Clic sur bibliothèque via NavigationLink(value: LibraryItem)]
   ↓
   navigationDestination(for: LibraryItem.self) détecte
   ↓
   ✅ LibraryContentView s'affiche
   ↓
   [Clic sur média via NavigationLink(value: MediaItem)]
   ↓
   navigationDestination(for: MediaItem.self) détecte
   ↓
   ✅ MediaDetailView / SeriesDetailView s'affiche
```

## 🧪 Test de validation

1. ✅ Lancer l'application
2. ✅ Se connecter
3. ✅ Aller sur "Toutes les bibliothèques"
4. ✅ **Cliquer sur une bibliothèque**
5. ✅ **LibraryContentView doit rester affichée** (plus de retour!)
6. ✅ Les médias doivent se charger
7. ✅ Cliquer sur un film ou une série
8. ✅ La vue de détail doit s'afficher
9. ✅ Le bouton retour doit fonctionner normalement

## 💡 Comprendre NavigationLink et navigationDestination

### NavigationLink avec value

```swift
NavigationLink(value: myItem) {
    Text("Cliquez-moi")
}
```

Ce lien **ne spécifie PAS où aller**. Il dit juste : "J'ai une valeur de type `Item`".

### navigationDestination

```swift
.navigationDestination(for: Item.self) { item in
    DetailView(item: item)
}
```

Cette destination dit : "Quand quelqu'un clique sur un `NavigationLink` avec une valeur de type `Item`, affiche `DetailView`".

### ⚠️ Conflit

Si vous avez **deux** `navigationDestination` pour le même type :

```swift
.navigationDestination(for: Item.self) { DetailView1() } // Lequel choisir ?
.navigationDestination(for: Item.self) { DetailView2() } // Lequel choisir ?
```

SwiftUI ne sait pas lequel utiliser → comportement imprévisible !

## 🚀 Bénéfices de la correction

1. **Navigation stable** : Plus de retours automatiques
2. **Pas de conflit** : Un seul `navigationDestination` par type
3. **Code plus clair** : Toute la logique de navigation au même endroit
4. **Débogage facile** : Voir d'un coup d'œil toutes les routes
5. **Performance** : Pas de requêtes annulées

## 📚 Règles pour éviter ce problème

### ✅ À FAIRE

1. **Centraliser** tous les `navigationDestination` dans le `NavigationStack` racine
2. **Un seul** `navigationDestination` par type de données
3. **Documenter** la structure de navigation dans un commentaire
4. **Tester** les flux de navigation complets

### ❌ À ÉVITER

1. **NE PAS** mettre `navigationDestination` dans les vues enfants
2. **NE PAS** dupliquer `navigationDestination` pour le même type
3. **NE PAS** créer plusieurs `NavigationStack` imbriqués
4. **NE PAS** oublier de tester la navigation en profondeur

## 🔮 Pattern recommandé

Pour un projet de grande taille, créez une extension :

```swift
extension View {
    func appNavigation(jellyfinService: JellyfinService) -> some View {
        self
            .navigationDestination(for: LibraryItem.self) { library in
                LibraryContentView(library: library, jellyfinService: jellyfinService)
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

// Usage
NavigationStack {
    ContentView()
}
.appNavigation(jellyfinService: service)
```

---

*Correction critique appliquée pour xfinn v1.0.0*
