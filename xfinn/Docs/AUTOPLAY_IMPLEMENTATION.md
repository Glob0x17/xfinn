:AUTOPLAY_IMPLEMENTATION.md
# Implémentation de la lecture automatique du prochain épisode

## 📋 Résumé de l'implémentation

Cette fonctionnalité permet de passer automatiquement au prochain épisode d'une série, comme les plateformes de streaming modernes :
- **10 secondes avant la fin** : affichage d'un overlay avec le prochain épisode
- **Compte à rebours** : de 10 à 0 secondes
- **Actions possibles** : 
  - Laisser le timer arriver à 0 → lecture automatique du prochain épisode
  - Cliquer sur "Lire maintenant" → lecture immédiate
  - Cliquer sur "Annuler" → rester sur l'épisode actuel

## ✅ Fichiers créés

### 1. `NextEpisodeOverlay.swift`
Overlay SwiftUI affichant :
- Miniature du prochain épisode
- Titre et synopsis
- Compte à rebours animé
- Boutons d'action (Annuler / Lire maintenant)

### 2. `NavigationCoordinator.swift`
`@ObservableObject` pour gérer la navigation entre épisodes :
- `navigateTo(item:)` : naviguer vers un média
- `replaceLastWith(item:)` : remplacer le dernier élément (pour l'autoplay)
- `goBack()` : retour arrière
- `goToRoot()` : retour à l'accueil

## 🔧 Modifications effectuées

### 1. `JellyfinService.swift`
**Nouvelles méthodes ajoutées :**

```swift
// MARK: - Navigation entre épisodes

/// Récupère l'épisode suivant d'une série
func getNextEpisode(currentItemId: String) async throws -> MediaItem?

/// Récupère l'épisode suivant en utilisant les indices de saison/épisode
private func getNextEpisodeInSeries(currentItemId: String) async throws -> MediaItem?

