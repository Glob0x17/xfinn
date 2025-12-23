# Technical Notes - XFINN

> Consolidated technical documentation and important fixes

---

## Table of Contents

1. [Focus Effects System](#focus-effects-system)
2. [Material Background Fix](#material-background-fix)
3. [Navigation System](#navigation-system)
4. [Search Implementation](#search-implementation)
5. [tvOS Compatibility](#tvos-compatibility)

---

## Focus Effects System

### Problem: Default tvOS Focus Effect

On tvOS, buttons and NavigationLinks have an automatic white/blue outline focus effect that cannot be disabled with `.buttonStyle(.plain)` alone.

### Solution: `.focusEffectDisabled()`

```swift
Button {
    action()
} label: {
    Content()
        .background(...) // Background INSIDE label
}
.buttonStyle(.plain)
#if os(tvOS)
.focusEffectDisabled() // Required to disable system effect
#endif
.focusEffect() // Custom purple effect
```

### Key Rules

1. **Background placement**: Must be inside the button label, not on the button itself
2. **Order of modifiers**:
   - `.buttonStyle(.plain)` first
   - `.focusEffectDisabled()` second (tvOS only)
   - Custom focus effects last

3. **Custom focus with glow**:
```swift
struct CustomCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
        configuration.label
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? AppTheme.focusBorder.opacity(0.8) : .clear, radius: 25)
            .shadow(color: isFocused ? AppTheme.focusBorder.opacity(0.5) : .clear, radius: 40)
            .shadow(color: isFocused ? AppTheme.focusBorder.opacity(0.2) : .clear, radius: 60)
            .animation(AppTheme.springAnimation, value: isFocused)
            .focusEffectDisabled()
        #else
        configuration.label
        #endif
    }
}
```

---

## Material Background Fix

### Problem: Material Auto-Highlight

`Material.ultraThinMaterial` and other Material types automatically become brighter and more opaque when focused on tvOS/iOS. This behavior cannot be disabled.

### Solution: Custom Glass Background

Replace:
```swift
.background(Material.ultraThinMaterial)
```

With:
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

Where:
```swift
static let glassBackground = Color.white.opacity(0.08)
static let glassStroke = Color.white.opacity(0.15)
```

### Advantages

- No automatic highlight on focus
- Complete control over appearance
- Better performance (no dynamic blur)
- Consistent across platforms

---

## Navigation System

### NavigationCoordinator Pattern

Centralized navigation state management:

```swift
class NavigationCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    func navigate(to item: MediaItem) {
        navigationPath.append(item)
    }
    
    func goBack() {
        navigationPath.removeLast()
    }
    
    func resetToRoot() {
        navigationPath = NavigationPath()
    }
}
```

### Usage in Views

```swift
struct HomeView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            // Content
            .navigationDestination(for: MediaItem.self) { item in
                MediaDetailView(item: item)
                    .id(item.id) // Force recreation on ID change
            }
        }
    }
}
```

### Button Navigation Pattern

For toolbar buttons on tvOS:

```swift
@State private var showDestination = false

Button {
    showDestination = true
} label: {
    // Label
}
.buttonStyle(CustomCardButtonStyle())

// Outside toolbar
.navigationDestination(isPresented: $showDestination) {
    DestinationView()
}
```

**Note**: Direct `NavigationLink` in toolbars doesn't work reliably on tvOS.

---

## Search Implementation

### SearchView Architecture

```swift
struct SearchView: View {
    @State private var searchQuery = ""
    @State private var searchResults: [MediaItem] = []
    @State private var selectedFilter: SearchFilter = .all
    
    enum SearchFilter: String, CaseIterable {
        case all = "Tout"
        case movies = "Films"
        case series = "Séries"
        case episodes = "Épisodes"
    }
}
```

### Search Pattern

```swift
private func performSearch() {
    guard !searchQuery.isEmpty else { return }
    
    isSearching = true
    
    Task {
        do {
            let results = try await jellyfinService.search(query: searchQuery)
            
            await MainActor.run {
                withAnimation(AppTheme.standardAnimation) {
                    searchResults = results
                    isSearching = false
                }
            }
        } catch {
            await MainActor.run {
                isSearching = false
            }
        }
    }
}
```

### Filter Implementation

```swift
private var filteredResults: [MediaItem] {
    guard selectedFilter != .all else { return searchResults }
    
    return searchResults.filter { item in
        switch selectedFilter {
        case .movies: return item.type == "Movie"
        case .series: return item.type == "Series"
        case .episodes: return item.type == "Episode"
        case .all: return true
        }
    }
}
```

---

## tvOS Compatibility

### Focus Management

**FocusState for explicit focus**:
```swift
@FocusState private var focusedItem: String?

// In view
.focused($focusedItem, equals: item.id)
.prefersDefaultFocus(isFirst, in: namespace)
```

**FocusSection for grouping**:
```swift
#if os(tvOS)
.focusSection() // Creates focus group
#endif
```

### Button Styles

**Plain style** (no system styling):
```swift
.buttonStyle(.plain)
```

**Custom card style** (with glow):
```swift
.buttonStyle(CustomCardButtonStyle(cornerRadius: 20))
```

### Typography Sizes for tvOS

```swift
static let largeTitle = Font.system(size: 70, weight: .bold)
static let title = Font.system(size: 58, weight: .bold)
static let headline = Font.system(size: 32, weight: .medium)
static let body = Font.system(size: 28)
static let caption = Font.system(size: 24)
```

### Safe Areas and Padding

tvOS requires larger padding for comfortable viewing distance:

```swift
static let screenPadding: CGFloat = 60
static let cardPadding: CGFloat = 30
```

### Remote Control Gestures

- **Play/Pause**: Toggle playback
- **Swipe Up/Down**: Scrubbing in player
- **Swipe Left/Right**: Navigation
- **Click**: Select/Activate
- **Menu**: Back/Cancel

---

## Design System

### Colors

```swift
// Jellyfin brand colors
static let jellyfinPurple = Color(red: 0.67, green: 0.27, blue: 0.82) // #AA5CC3
static let jellyfinBlue = Color(red: 0.0, green: 0.64, blue: 0.87)    // #00A4DF

// Focus color
static let focusBorder = Color(red: 0.75, green: 0.35, blue: 0.95)    // #BF5AF2

// Glass effects
static let glassBackground = Color.white.opacity(0.08)
static let glassStroke = Color.white.opacity(0.15)
```

### Animations

```swift
static let standardAnimation = Animation.easeInOut(duration: 0.3)
static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
```

### Focus Effects

- Scale: 1.05
- Glow: Multiple purple shadows (25px, 40px, 60px radius)
- Border: 4px electric purple
- Animation: Spring

---

## Performance Tips

### Image Loading

**Preload critical images**:
```swift
await imagePreloader.preloadImage(from: url)
```

**Use placeholder**:
```swift
AsyncImage(url: url) { phase in
    switch phase {
    case .empty: PlaceholderView()
    case .success(let image): image
    case .failure: ErrorView()
    }
}
```

### List Performance

**LazyVGrid for large grids**:
```swift
LazyVGrid(columns: [GridItem(.adaptive(minimum: 350))]) {
    ForEach(items) { item in
        // Item view
    }
}
```

**Limit initial load**:
```swift
let resumeItems = try await jellyfinService.getResumeItems(limit: 10)
```

---

## Common Issues & Solutions

### Issue: White outline on buttons (tvOS)

**Solution**: Add `.focusEffectDisabled()` after `.buttonStyle()`

### Issue: Navigation not working in toolbar

**Solution**: Use `Button` + `.navigationDestination(isPresented:)` instead of direct `NavigationLink`

### Issue: Background changes color on focus

**Solution**: Replace `Material` with custom glass background

### Issue: Focus jumps unexpectedly

**Solution**: Use `.focusSection()` to create logical focus groups

### Issue: Images don't load

**Solution**: Check server URL and network connectivity, verify image URLs are correct

---

## Testing Checklist

### Focus Testing
- [ ] All buttons respond to focus
- [ ] Purple outline visible on focus
- [ ] No white/blue system outline
- [ ] Smooth animations
- [ ] Focus navigation logical

### Navigation Testing
- [ ] All links navigate correctly
- [ ] Back button works
- [ ] Deep linking preserved
- [ ] No duplicate views in stack

### Performance Testing
- [ ] Smooth scrolling
- [ ] Images load quickly
- [ ] No lag on focus changes
- [ ] Memory usage stable

### UI Testing
- [ ] All text readable at 10ft
- [ ] Touch targets large enough
- [ ] Consistent spacing
- [ ] No clipping or overflow

---

**Last Updated**: December 23, 2024
