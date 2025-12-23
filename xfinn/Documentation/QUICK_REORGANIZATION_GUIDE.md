# 📦 Checklist de déplacement des fichiers xfinn

Déplacez chaque fichier dans Xcode vers le dossier indiqué, puis cochez au fur et à mesure.

## Shared/Extensions
- [ ] View+Extensions.swift
- [ ] Color+Extensions.swift
- [ ] String+Extensions.swift
- [ ] TimeInterval+Extensions.swift
- [ ] UserDefaults+Extensions.swift
- [ ] Date+Extensions.swift
- [ ] Array+Extensions.swift

## Shared/Components
- [ ] LoadingView.swift
- [ ] ErrorView.swift
- [ ] EmptyContentView.swift

## Shared/Theme
- [ ] AppTheme.swift

## App
- [ ] ContentView.swift
- [ ] (optionnel : xfinnApp.swift)

## Core/Services
- [ ] JellyfinService.swift

## Core/Coordinators
- [ ] NavigationCoordinator.swift

## Features/Authentication/Views
- [ ] LoginView.swift

## Features/Home/Views
- [ ] HomeView.swift

## Features/Library/Views
- [ ] LibraryView.swift

## Features/Media/Components
- [ ] NextEpisodeOverlay.swift

## Documentation
- [ ] Tous les fichiers .md de documentation (hors README.md principal)

## À supprimer après déplacement
- [ ] Extensions.swift (ancien fichier global)

---

### Rappels importants
- Vérifier la membership dans la target après déplacement
- Compiler et tester, puis commit Git final !
