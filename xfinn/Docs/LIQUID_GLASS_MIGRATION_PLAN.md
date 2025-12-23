# 🌊 Plan de migration Liquid Glass - Vues restantes

*22 décembre 2024*

---

## 📊 État d'avancement

| Vue | Status | Priorité | Effort |
|-----|--------|----------|--------|
| **LoginView** | ✅ Terminé | - | - |
| **HomeView** | ✅ Terminé | - | - |
| **SearchView** | ✅ Terminé | - | - |
| **MediaDetailView** | ⏳ À faire | 🔥 Haute | 3h |
| **SeriesDetailView** | ⏳ À faire | 🔥 Haute | 2h |
| **LibraryView** | ⏳ À faire | ⚠️ Moyenne | 2h |
| **Player Controls** | ⏳ À faire | 🔥 Haute | 4h |
| **SeasonEpisodesView** | ⏳ À faire | ⚠️ Moyenne | 1h |
| **SettingsView** | ⏳ À créer | 🟢 Basse | 2h |

**Total estimé** : ~14 heures de développement

---

## 🎯 Priorité 1 : MediaDetailView (3h)

### Modifications à apporter

#### Background
- ✅ Gradient `AppTheme.backgroundGradient`
- ✅ Backdrop image avec blur
- ✅ Overlay gradient noir → transparent

#### Hero Section
```swift
ZStack(alignment: .bottom) {
    // Backdrop image full width
    AsyncImage(backdrop)
        .blur(radius: 20)
    
    // Gradient overlay
    LinearGradient(
        colors: [.clear, AppTheme.background],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Content card (glass)
    HStack {
        // Poster avec glass border
        posterImage
            .overlay(RoundedRectangle...stroke(glassStroke))
        
        // Info avec glass background
        VStack {
            title, metadata, synopsis
        }
        .glassCard()
    }
}
```

#### Boutons d'action
```swift
HStack {
    // Bouton Play (prominent)
    Button("▶ Lecture") { }
        .glassButton(prominent: true)
        .glowing(color: .appPrimary)
    
    // Bouton Reprendre (si applicable)
    Button("⏯ Reprendre") { }
        .glassButton(prominent: false)
    
    // Bouton Favoris
    Button("♥") { }
        .glassButton(prominent: false)
}
```

#### Liste Cast & Crew
```swift
ScrollView(.horizontal) {
    HStack {
        ForEach(people) { person in
            VStack {
                AsyncImage(avatar)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(glassStroke))
                Text(name)
            }
            .glassCard()
        }
    }
}
```

#### Recommendations
```swift
// Réutiliser MediaCarousel de HomeView
MediaCarousel(
    title: "Similaires",
    icon: "sparkles",
    items: similarItems,
    accentColor: .appSecondary
)
```

---

## 🎯 Priorité 2 : SeriesDetailView (2h)

### Modifications

#### Header
```swift
VStack {
    // Hero avec backdrop
    heroSection
    
    // Saisons et épisodes
    TabView {
        seasonsTab
        episodesTab
        infoTab
    }
    .glassCard()
}
```

#### Sélecteur de saison
```swift
ScrollView(.horizontal) {
    HStack {
        ForEach(seasons) { season in
            SeasonPill(season, isSelected: selected == season)
                .glassButton(prominent: selected == season)
        }
    }
}
```

#### Liste épisodes
```swift
LazyVStack {
    ForEach(episodes) { episode in
        EpisodeRow(episode)
            .glassCard()
            .environment(\.isFocused, focused == episode)
    }
}
```

---

## 🎯 Priorité 3 : Player Controls (4h)

### Architecture

#### Overlay principal
```swift
ZStack {
    // Video player (AVPlayer)
    videoPlayer
    
    // Controls overlay (glass)
    if showControls {
        VStack {
            topBar    // Titre, back
            Spacer()
            timeline  // Progress bar
            bottomBar // Play/pause, quality
        }
        .background(.ultraThinMaterial)
    }
}
```

#### Top Bar
```swift
HStack {
    Button("←") { dismiss() }
        .glassButton()
    
    VStack(alignment: .leading) {
        Text(title).font(.title)
        Text(subtitle).font(.caption)
    }
    
    Spacer()
    
    Button("⚙") { showSettings() }
        .glassButton()
}
.padding()
.glassCard(padding: 20)
```

#### Timeline
```swift
VStack {
    // Progress bar
    GeometryReader { geo in
        ZStack(alignment: .leading) {
            // Background
            Capsule()
                .fill(.white.opacity(0.3))
            
            // Progress
            Capsule()
                .fill(AppTheme.primary)
                .frame(width: geo.size.width * progress)
        }
    }
    .frame(height: 8)
    
    // Time labels
    HStack {
        Text(currentTime)
        Spacer()
        Text(duration)
    }
    .font(.caption)
    .foregroundColor(.appTextSecondary)
}
.padding()
```

#### Bottom Bar
```swift
HStack(spacing: 40) {
    // Rewind
    Button("⏪ 10s") { seek(-10) }
        .glassButton()
    
    // Play/Pause (prominent)
    Button(isPlaying ? "⏸" : "▶") { togglePlay() }
        .glassButton(prominent: true)
        .glowing(color: .appPrimary)
    
    // Forward
    Button("⏩ 10s") { seek(10) }
        .glassButton()
    
    // Quality
    Menu {
        ForEach(qualities) { q in
            Button(q.name) { setQuality(q) }
        }
    } label: {
        Text(currentQuality)
    }
    .glassButton()
}
```

#### Gestes
```swift
.gesture(
    DragGesture()
        .onChanged { dragTimeline($0) }
)
.onTapGesture {
    withAnimation { showControls.toggle() }
}
```

---

## 🎯 Priorité 4 : LibraryView (2h)

### Grid moderne
```swift
ScrollView {
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 400))],
        spacing: 30
    ) {
        ForEach(items) { item in
            ModernMediaCard(item)
                .environment(\.isFocused, focused == item)
        }
    }
}
.background(AppTheme.backgroundGradient)
```

### Filtres et tri
```swift
HStack {
    // Filtres de type
    Menu("Type: \(selected)") {
        ForEach(types) { type in
            Button(type.name) { filterBy(type) }
        }
    }
    .glassButton()
    
    // Tri
    Menu("Tri: \(sortBy)") {
        ForEach(sortOptions) { option in
            Button(option.name) { sortBy(option) }
        }
    }
    .glassButton()
    
    Spacer()
    
    // Vue : Grid/List
    Button(viewMode.icon) { toggleViewMode() }
        .glassButton()
}
.padding()
```

---

## 🎯 Priorité 5 : SeasonEpisodesView (1h)

Simple car similaire à SeriesDetailView.

### Liste épisodes
```swift
ScrollView {
    LazyVStack(spacing: 20) {
        ForEach(episodes) { episode in
            EpisodeCard(episode)
                .glassCard()
        }
    }
    .padding()
}
```

### Carte épisode
```swift
HStack {
    // Thumbnail
    AsyncImage(thumbnail)
        .frame(width: 200, height: 113)
        .cornerRadius(12)
    
    // Info
    VStack(alignment: .leading) {
        Text("E\(episode.number) - \(episode.name)")
            .font(.title3)
        Text(episode.overview)
            .lineLimit(3)
        Text(episode.runtime)
            .foregroundColor(.appTextTertiary)
    }
    
    Spacer()
    
    // Play button
    Button("▶") { play() }
        .glassButton(prominent: true)
}
```

---

## 🎯 Bonus : SettingsView (2h)

Nouvelle vue à créer.

### Structure
```swift
NavigationStack {
    List {
        // Compte
        Section("Compte") {
            accountRow
            logoutButton
        }
        
        // Qualité
        Section("Lecture") {
            qualityPicker
            autoPlayToggle
        }
        
        // Apparence
        Section("Apparence") {
            themeSelector
            animationsToggle
        }
        
        // À propos
        Section("À propos") {
            versionRow
            creditsRow
        }
    }
    .glassCard()
}
```

---

## 🔧 Checklist par vue

### Pour chaque vue

#### Background
- [ ] Remplacer par `AppTheme.backgroundGradient`
- [ ] Ajouter `.ignoresSafeArea()`
- [ ] Vérifier contraste textes

#### Cartes/Containers
- [ ] Utiliser `.glassCard()` pour conteneurs
- [ ] Bordure avec `AppTheme.glassStroke`
- [ ] Padding cohérent (20-30pt)

#### Boutons
- [ ] `.glassButton(prominent:)` selon importance
- [ ] `.glowing()` pour actions principales
- [ ] Tailles minimales (70pt hauteur)

#### Textes
- [ ] `.foregroundColor(.appTextPrimary/Secondary/Tertiary)`
- [ ] Tailles adaptées tvOS (min 18pt)
- [ ] Poids de police cohérents

#### Focus tvOS
- [ ] `@Environment(\.isFocused)` pour éléments interactifs
- [ ] `.scaleEffect()` au focus (1.05-1.08)
- [ ] `.shadow()` amplifié au focus
- [ ] `.animation()` avec spring

#### Images
- [ ] `AsyncImage` avec placeholder
- [ ] `.cornerRadius()` selon style
- [ ] Overlay glass stroke si besoin

---

## ⚡ Quick wins

### Composants réutilisables

Créer dans Theme.swift :

```swift
// Bouton standard
struct GlassActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isProminent: Bool
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .glassButton(prominent: isProminent)
    }
}

// Carte média standard
// Déjà fait : ModernMediaCard dans HomeView

// Header de section
struct SectionHeader: View {
    let title: String
    let icon: String
    let count: Int?
    
    var body: some View {
        HStack {
            Image(systemName: icon).glowing()
            Text(title).font(.title)
            Spacer()
            if let count = count {
                Text("\(count)").badge()
            }
        }
    }
}
```

---

## 🚀 Plan d'action

### Semaine 1
- [x] LoginView ✅
- [x] HomeView ✅
- [x] SearchView ✅
- [ ] MediaDetailView
- [ ] Player Controls (base)

### Semaine 2
- [ ] SeriesDetailView
- [ ] LibraryView
- [ ] SeasonEpisodesView
- [ ] Player Controls (finitions)

### Semaine 3
- [ ] SettingsView
- [ ] Polish général
- [ ] Tests et optimisations
- [ ] Documentation finale

---

## 📝 Notes importantes

### Cohérence
- Toujours utiliser les modifiers du Theme
- Respecter les espacements standards
- Animations identiques partout

### Performance
- Lazy loading obligatoire pour listes
- Cache images avec AsyncImage
- Debounce pour recherches/filtres

### Accessibilité
- VoiceOver sur tous les éléments
- Contrastes WCAG AAA
- Focus indicators clairs

---

*Ready to continue the Liquid Glass journey! 🌊✨*
