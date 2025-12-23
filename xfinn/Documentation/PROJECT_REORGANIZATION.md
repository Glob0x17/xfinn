# 📁 Plan de Réorganisation du Projet xfinn

## 🎯 Objectif

Réorganiser la structure du projet pour améliorer :
- **Lisibilité** : Trouver rapidement les fichiers
- **Maintenabilité** : Faciliter l'ajout de nouvelles fonctionnalités
- **Scalabilité** : Préparer le projet pour grandir
- **Cohérence** : Suivre les conventions iOS/tvOS

---

## 📊 Structure Actuelle vs Proposée

### ❌ Actuelle (Tous les fichiers à la racine)
```
xfinn/
├── ContentView.swift
├── LoginView.swift
├── HomeView.swift
├── LibraryView.swift
├── NextEpisodeOverlay.swift
├── NavigationCoordinator.swift
├── JellyfinService.swift
├── Extensions.swift
└── ... (tous les autres fichiers)
```

### ✅ Proposée (Organisation par responsabilité)
```
xfinn/
├── App/
│   └── ContentView.swift
├── Core/
│   ├── Services/
│   │   └── JellyfinService.swift
│   ├── Models/
│   │   └── JellyfinModels.swift
│   └── Coordinators/
│       └── NavigationCoordinator.swift
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   └── LoginView.swift
│   │   └── Components/
│   │       ├── ServerConnectionView.swift
│   │       └── AuthenticationView.swift
│   ├── Home/
│   │   ├── Views/
│   │   │   └── HomeView.swift
│   │   └── Components/
│   │       └── MediaCarousel.swift
│   ├── Library/
│   │   ├── Views/
│   │   │   ├── LibraryView.swift
│   │   │   └── LibraryContentView.swift
│   │   └── Components/
│   │       └── LibraryCard.swift
│   ├── Series/
│   │   ├── Views/
│   │   │   ├── SeriesDetailView.swift
│   │   │   └── SeasonEpisodesView.swift
│   │   └── Components/
│   │       ├── SeasonCard.swift
│   │       └── EpisodeRow.swift
│   └── Media/
│       ├── Views/
│       │   └── MediaDetailView.swift
│       └── Components/
│           ├── MediaCard.swift
│           ├── CarouselMediaCard.swift
│           └── NextEpisodeOverlay.swift
├── Shared/
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── EmptyContentView.swift
│   ├── Theme/
│   │   └── AppTheme.swift
│   └── Extensions/
│       ├── View+Extensions.swift
│       ├── Color+Extensions.swift
│       ├── String+Extensions.swift
│       ├── TimeInterval+Extensions.swift
│       └── UserDefaults+Extensions.swift
├── Resources/
│   └── Assets.xcassets
└── Documentation/
    ├── ARCHITECTURE.md
    ├── BUILD_STATUS.md
    ├── FUTURE_IMPROVEMENTS.md
    ├── NAVIGATION_FIX.md
    ├── SUBTITLE_CODE_EXAMPLES.md
    └── ... (tous les autres .md)
```

---

## 🗂️ Guide de Réorganisation dans Xcode

### Étape 1 : Créer les Groupes (Dossiers) dans Xcode

#### 1.1 Groupes Principaux
Dans le navigateur de projet Xcode, cliquez droit sur le dossier `xfinn` et créez ces **New Group**s :

1. **App**
2. **Core** (puis ajoutez ces sous-groupes)
   - Services
   - Models
   - Coordinators
3. **Features** (puis ajoutez ces sous-groupes)
   - Authentication
   - Home
   - Library
   - Series
   - Media
4. **Shared** (puis ajoutez ces sous-groupes)
   - Components
   - Theme
   - Extensions
5. **Documentation**

#### 1.2 Sous-groupes des Features
Pour chaque feature (Authentication, Home, Library, Series, Media), créez :
- **Views**
- **Components**

---

### Étape 2 : Déplacer les Fichiers

> **Important** : Dans Xcode, il suffit de **glisser-déposer** les fichiers dans les groupes. Ne les déplacez PAS dans le Finder !

#### 📱 App/
```
✓ ContentView.swift
```

#### 🔧 Core/Services/
```
✓ JellyfinService.swift
```

#### 📦 Core/Models/
```
✓ JellyfinModels.swift (à créer si séparé, sinon chercher où sont définis ServerInfo, User, MediaItem, etc.)
```

#### 🧭 Core/Coordinators/
```
✓ NavigationCoordinator.swift
```

#### 🔐 Features/Authentication/Views/
```
✓ LoginView.swift
```

#### 🔐 Features/Authentication/Components/
```
✓ ServerConnectionView.swift (si existe)
✓ AuthenticationView.swift (si existe)
```

#### 🏠 Features/Home/Views/
```
✓ HomeView.swift
```

#### 🏠 Features/Home/Components/
```
✓ MediaCarousel.swift (si existe en tant que fichier séparé)
```

#### 📚 Features/Library/Views/
```
✓ LibraryView.swift
✓ LibraryContentView.swift (si existe)
```

#### 📚 Features/Library/Components/
```
✓ LibraryCard.swift (si existe en tant que composant séparé)
```

#### 📺 Features/Series/Views/
```
✓ SeriesDetailView.swift (si existe)
✓ SeasonEpisodesView.swift (si existe)
```

#### 📺 Features/Series/Components/
```
✓ SeasonCard.swift (si existe)
✓ EpisodeRow.swift (si existe)
```

#### 🎬 Features/Media/Views/
```
✓ MediaDetailView.swift (si existe)
```

#### 🎬 Features/Media/Components/
```
✓ MediaCard.swift (si existe)
✓ CarouselMediaCard.swift (si existe)
✓ NextEpisodeOverlay.swift
```

#### 🔄 Shared/Components/
```
✓ LoadingView.swift (défini dans Extensions.swift - à extraire)
✓ ErrorView.swift (défini dans Extensions.swift - à extraire)
✓ EmptyContentView.swift (défini dans Extensions.swift - à extraire)
```

#### 🎨 Shared/Theme/
```
✓ AppTheme.swift (à créer - regroupera les couleurs et styles)
```

#### 🔧 Shared/Extensions/
```
Créer ces fichiers en séparant Extensions.swift :

✓ View+Extensions.swift
  - cardStyle()
  - focusableCard()
  
✓ Color+Extensions.swift
  - jellyfinPurple
  - jellyfinBlue
  - appError, appSuccess, etc.
  
✓ String+Extensions.swift
  - isValidURL
  - cleanedJellyfinURL
  
✓ TimeInterval+Extensions.swift
  - formattedDuration
  - toTicks
  
✓ Int64+Extensions.swift (ou dans TimeInterval)
  - fromTicks
  
✓ Array+Extensions.swift
  - unwatched, inProgress, groupedBySeason
  
✓ UserDefaults+Extensions.swift
  - jellyfinServerURL
  - jellyfinAccessToken
  - jellyfinUserId
  - deviceId
```

#### 📖 Documentation/
```
✓ ARCHITECTURE.md
✓ BUILD_STATUS.md
✓ FINAL_NAVIGATION_FIX.md
✓ FOCUS_EFFECT_DOCUMENTATION.md
✓ FUTURE_IMPROVEMENTS.md
✓ HEADER_LAYOUT_FIX.md
✓ JELLYFIN_URL_NORMALIZATION.md
✓ NAVIGATION_DESTINATION_FIX.md
✓ NAVIGATION_FIX.md
✓ PROJECT_REORGANIZATION.md (ce fichier)
✓ SUBTITLE_CODE_EXAMPLES.md
✓ URL_NORMALIZATION_USAGE.md
✓ USERDEFAULTS_KEYS.md
```

---

## 🔨 Étape 3 : Scinder le Fichier Extensions.swift

Le fichier `Extensions.swift` actuel contient beaucoup de code. Voici comment le diviser :

### 3.1 Créer View+Extensions.swift
```swift
//  View+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

extension View {
    /// Applique un effet de carte pour tvOS
    func cardStyle() -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.3), radius: 10)
    }
    
    /// Applique un effet de focus pour tvOS
    func focusableCard() -> some View {
        self
            .buttonStyle(.card)
            .hoverEffect()
    }
}
```

### 3.2 Créer Color+Extensions.swift
```swift
//  Color+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import SwiftUI

extension Color {
    // Couleurs Jellyfin
    static let jellyfinPurple = Color(red: 0.67, green: 0.27, blue: 0.82)
    static let jellyfinBlue = Color(red: 0.0, green: 0.64, blue: 0.87)
    
    // Couleurs de l'app
    static let appError = Color.red
    static let appSuccess = Color.green
    static let appWarning = Color.orange
}
```

### 3.3 Créer String+Extensions.swift
```swift
//  String+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import Foundation

extension String {
    /// Valide si la chaîne est une URL valide
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    /// Nettoie une URL pour l'utilisation avec Jellyfin
    var cleanedJellyfinURL: String {
        // ... (code existant)
    }
}
```

### 3.4 Créer TimeInterval+Extensions.swift
```swift
//  TimeInterval+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import Foundation

extension TimeInterval {
    /// Formate une durée en texte lisible
    var formattedDuration: String {
        // ... (code existant)
    }
    
    /// Convertit TimeInterval en ticks Jellyfin
    var toTicks: Int64 {
        return Int64(self * 10_000_000)
    }
}

extension Int64 {
    /// Convertit les ticks Jellyfin en TimeInterval
    var fromTicks: TimeInterval {
        return TimeInterval(self) / 10_000_000
    }
}
```

### 3.5 Créer UserDefaults+Extensions.swift
```swift
//  UserDefaults+Extensions.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/11/2025.
//

import Foundation

extension UserDefaults {
    // Clés Jellyfin
    var jellyfinServerURL: String? {
        get { string(forKey: "jellyfinServerURL") }
        set { set(newValue, forKey: "jellyfinServerURL") }
    }
    
    var jellyfinAccessToken: String? {
        get { string(forKey: "jellyfinAccessToken") }
        set { set(newValue, forKey: "jellyfinAccessToken") }
    }
    
    var jellyfinUserId: String? {
        get { string(forKey: "jellyfinUserId") }
        set { set(newValue, forKey: "jellyfinUserId") }
    }
    
    var deviceId: String {
        if let existingId = string(forKey: "deviceId") {
            return existingId
        }
        let newId = UUID().uuidString
        set(newId, forKey: "deviceId")
        return newId
    }
}
```

### 3.6 Créer AppTheme.swift
```swift
//  AppTheme.swift
//  xfinn
//
//  Created by Dorian Galiana on 23/12/2025.
//

import SwiftUI

struct AppTheme {
    // MARK: - Colors
    
    static let primaryColor = Color.jellyfinPurple
    static let secondaryColor = Color.jellyfinBlue
    
    static let backgroundGradient = LinearGradient(
        colors: [.black, Color(white: 0.1)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Typography
    
    static let largeTitle = Font.system(size: 50, weight: .bold)
    static let title = Font.system(size: 40, weight: .semibold)
    static let headline = Font.system(size: 28, weight: .medium)
    static let body = Font.system(size: 24)
    static let caption = Font.system(size: 20)
    
    // MARK: - Spacing
    
    static let smallSpacing: CGFloat = 10
    static let mediumSpacing: CGFloat = 20
    static let largeSpacing: CGFloat = 40
    static let extraLargeSpacing: CGFloat = 60
    
    // MARK: - Corner Radius
    
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 15
    
    // MARK: - Animations
    
    static let standardAnimation = Animation.easeInOut(duration: 0.3)
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
}
```

### 3.7 Extraire les composants partagés

Déplacez `LoadingView`, `ErrorView`, et `EmptyContentView` depuis `Extensions.swift` vers leurs propres fichiers dans `Shared/Components/`.

---

## ✅ Checklist de Réorganisation

### Phase 1 : Préparation
- [ ] Faire un commit Git avant de commencer
- [ ] Créer une branche pour la réorganisation : `git checkout -b refactor/project-structure`
- [ ] S'assurer que le projet compile sans erreur

### Phase 2 : Création des Groupes
- [ ] Créer le groupe `App/`
- [ ] Créer le groupe `Core/` et ses sous-groupes
- [ ] Créer le groupe `Features/` et ses sous-groupes
- [ ] Créer le groupe `Shared/` et ses sous-groupes
- [ ] Créer le groupe `Documentation/`

### Phase 3 : Déplacement des Fichiers
- [ ] Déplacer ContentView.swift → `App/`
- [ ] Déplacer JellyfinService.swift → `Core/Services/`
- [ ] Déplacer NavigationCoordinator.swift → `Core/Coordinators/`
- [ ] Déplacer LoginView.swift → `Features/Authentication/Views/`
- [ ] Déplacer HomeView.swift → `Features/Home/Views/`
- [ ] Déplacer LibraryView.swift → `Features/Library/Views/`
- [ ] Déplacer NextEpisodeOverlay.swift → `Features/Media/Components/`
- [ ] Déplacer tous les fichiers .md → `Documentation/`

### Phase 4 : Scinder Extensions.swift
- [ ] Créer View+Extensions.swift
- [ ] Créer Color+Extensions.swift
- [ ] Créer String+Extensions.swift
- [ ] Créer TimeInterval+Extensions.swift
- [ ] Créer UserDefaults+Extensions.swift
- [ ] Créer Array+Extensions.swift (si applicable)
- [ ] Supprimer l'ancien Extensions.swift

### Phase 5 : Créer AppTheme
- [ ] Créer AppTheme.swift dans `Shared/Theme/`
- [ ] Migrer les constantes de style existantes

### Phase 6 : Extraire les Composants Partagés
- [ ] Extraire LoadingView → `Shared/Components/LoadingView.swift`
- [ ] Extraire ErrorView → `Shared/Components/ErrorView.swift`
- [ ] Extraire EmptyContentView → `Shared/Components/EmptyContentView.swift`

### Phase 7 : Vérification
- [ ] Compiler le projet (⌘+B)
- [ ] Résoudre les erreurs de compilation (normalement aucune)
- [ ] Lancer l'app et tester les fonctionnalités principales
- [ ] Vérifier que les imports sont corrects

### Phase 8 : Finalisation
- [ ] Mettre à jour ARCHITECTURE.md avec la nouvelle structure
- [ ] Faire un commit : `git commit -m "refactor: Reorganize project structure"`
- [ ] Merger dans main : `git checkout main && git merge refactor/project-structure`

---

## 🎓 Bénéfices de cette Organisation

### 1. **Clarté** 📖
- Chaque fichier a une place logique
- Les développeurs trouvent rapidement ce qu'ils cherchent
- Facilite l'onboarding de nouveaux contributeurs

### 2. **Scalabilité** 📈
- Facile d'ajouter de nouvelles features
- Structure modulaire qui grandit bien
- Prépare pour une éventuelle extraction de modules

### 3. **Maintenabilité** 🔧
- Les responsabilités sont claires
- Modifications localisées à un dossier
- Réduction du couplage entre composants

### 4. **Testabilité** 🧪
- Structure des tests miroir de la structure du code
- Facilite l'écriture de tests unitaires par feature
- Composants partagés facilement mockables

### 5. **Réutilisabilité** ♻️
- Les composants partagés sont identifiables
- Extensions séparées par type
- Theme centralisé facilite les changements globaux

---

## 📝 Notes Importantes

### ⚠️ Attention lors du Déplacement
1. **Toujours déplacer dans Xcode**, pas dans le Finder
2. Vérifier que les fichiers restent dans le bon target (xfinn)
3. Compiler fréquemment pour détecter les problèmes tôt

### 🔄 Si Vous Utilisez Git
- Les déplacements de fichiers dans Xcode sont généralement bien détectés par Git
- Si Git pense que vous avez supprimé et créé des fichiers, utilisez `git add -A` pour qu'il détecte les renames

### 🧪 Tests
- Si vous avez des tests, créez également une structure miroir :
  ```
  xfinnTests/
  ├── CoreTests/
  ├── FeaturesTests/
  └── SharedTests/
  ```

---

## 🚀 Prochaines Étapes Après Réorganisation

1. **Créer des README.md** dans chaque dossier Features pour documenter le rôle
2. **Extraire des protocoles** pour les services (ex: `JellyfinServiceProtocol`)
3. **Créer un dossier Networking** séparé si l'API grandit
4. **Ajouter Dependency Injection** pour faciliter les tests
5. **Envisager Swift Package Modules** pour vraiment découpler le code

---

*Document créé le 23/12/2025 pour la réorganisation du projet xfinn*
