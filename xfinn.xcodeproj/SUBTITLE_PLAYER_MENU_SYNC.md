# 🔄 Synchronisation du menu des sous-titres dans le player

## 📋 Résumé

Cette amélioration garantit que le **bouton de sous-titres dans le menu du player tvOS** reste synchronisé avec l'état actuel des sous-titres, y compris après un changement de piste.

---

## ❌ Problème initial

### Comportement observé

1. L'utilisateur lance une vidéo **sans sous-titres**
2. Le menu du player montre "Aucun" avec un ✓
3. L'utilisateur sélectionne "Français" dans le menu
4. La vidéo redémarre avec les sous-titres français ✅
5. **MAIS** : Le menu montre toujours "Aucun" avec un ✓ ❌

### Pourquoi ça ne marchait pas

Le menu était créé **une seule fois** au démarrage initial du player, avec l'état des sous-titres à ce moment-là. Quand on redémarrait la lecture avec de nouveaux sous-titres :

```swift
// Dans restartPlaybackWithSubtitles()
let controller = AVPlayerViewController()
controller.player = newPlayer

#if os(tvOS)
controller.transportBarCustomMenuItems = []  // ❌ Menu vide !
#endif
```

Le nouveau player avait un **menu vide**, ce qui causait deux problèmes :
1. Pas de bouton de sous-titres après le redémarrage
2. Aucune indication visuelle de la piste actuellement active

---

## ✅ Solution implémentée

### 1. Fonction dédiée pour configurer le menu

Création d'une fonction réutilisable qui génère le menu dynamiquement :

```swift
/// Configure le menu des sous-titres dans le player tvOS
private func configureSubtitleMenu(for controller: AVPlayerViewController) {
    #if os(tvOS)
    guard !item.subtitleStreams.isEmpty else { return }
    
    var subtitleActions: [UIAction] = []
    
    // Option "Aucun"
    let noneAction = UIAction(
        title: "Aucun",
        image: selectedSubtitleIndex == nil ? UIImage(systemName: "checkmark") : nil,
        state: selectedSubtitleIndex == nil ? .on : .off
    ) { [weak self] _ in
        self?.playerCoordinator.onSubtitleChange?(nil)
    }
    subtitleActions.append(noneAction)
    
    // Une action pour chaque piste de sous-titres
    for subtitle in sortedSubtitleStreams {
        let isSelected = selectedSubtitleIndex == subtitle.index
        let action = UIAction(
            title: subtitle.displayName,
            image: isSelected ? UIImage(systemName: "checkmark") : nil,
            state: isSelected ? .on : .off
        ) { [weak self] _ in
            self?.playerCoordinator.onSubtitleChange?(subtitle.index)
        }
        subtitleActions.append(action)
    }
    
    let subtitleMenu = UIMenu(
        title: "Sous-titres",
        image: UIImage(systemName: "captions.bubble"),
        children: subtitleActions
    )
    
    controller.transportBarCustomMenuItems = [subtitleMenu]
    #endif
}
```

### 2. Appel lors de la création initiale du player

```swift
// Dans continueStartPlayback()
let controller = AVPlayerViewController()
controller.player = newPlayer
controller.allowsPictureInPicturePlayback = true

#if os(tvOS)
// ... configuration du coordinator ...

// Configurer le menu des sous-titres
configureSubtitleMenu(for: controller)
#endif
```

### 3. Appel lors du redémarrage avec nouveaux sous-titres

```swift
// Dans restartPlaybackWithSubtitles()
let controller = AVPlayerViewController()
controller.player = newPlayer
controller.allowsPictureInPicturePlayback = true

// Reconfigurer le menu avec le nouvel état
configureSubtitleMenu(for: controller)
```

---

## 🎯 Comportement maintenant

### Scénario 1 : Démarrage sans sous-titres

1. L'utilisateur lance une vidéo
2. `selectedSubtitleIndex = nil`
3. Le menu du player montre :
   ```
   Sous-titres
   ├─ ✓ Aucun
   ├─   Français
   └─   English
   ```

### Scénario 2 : Changement vers "Français"

1. L'utilisateur sélectionne "Français" dans le menu
2. `onSubtitleChange?(2)` est appelé
3. `selectedSubtitleIndex = 2`
4. La vidéo redémarre avec sous-titres burn-in
5. `configureSubtitleMenu()` est appelé avec le nouvel état
6. Le menu du player montre maintenant :
   ```
   Sous-titres
   ├─   Aucun
   ├─ ✓ Français  ← Le checkmark est ici maintenant
   └─   English
   ```

### Scénario 3 : Changement vers "Aucun"

1. L'utilisateur sélectionne "Aucun"
2. `selectedSubtitleIndex = nil`
3. La vidéo redémarre sans sous-titres
4. Le menu revient à l'état initial avec ✓ sur "Aucun"

---

## 🎨 Améliorations visuelles

### États des actions

Chaque action UIAction a maintenant deux indicateurs visuels :

```swift
let action = UIAction(
    title: subtitle.displayName,
    image: isSelected ? UIImage(systemName: "checkmark") : nil,  // ← Checkmark
    state: isSelected ? .on : .off                                // ← État
)
```

- **`image`** : Affiche un ✓ à côté du nom
- **`state`** : Indique à tvOS que cette option est active (peut changer la mise en surbrillance)

### Logs de debug

Pour faciliter le débogage, des logs ont été ajoutés :

```swift
print("✅ Menu des sous-titres configuré avec \(subtitleActions.count) options")
if let selectedIndex = selectedSubtitleIndex {
    print("   → Sous-titre actuel : index \(selectedIndex)")
} else {
    print("   → Aucun sous-titre sélectionné")
}
```

**Exemple de sortie console :**
```
✅ Menu des sous-titres configuré avec 3 options
   → Sous-titre actuel : index 2

🔄 Redémarrage de la lecture pour appliquer les nouveaux sous-titres (burn-in)...
🎬 Nouvelle URL générée avec sous-titres burn-in
✅ Lecture redémarrée avec sous-titres burn-in
✅ Menu des sous-titres configuré avec 3 options
   → Sous-titre actuel : index 2
```

---

## 📊 Comparaison avant/après

| Aspect | Avant | Après |
|--------|-------|-------|
| **Menu initial** | ✅ Correct | ✅ Correct |
| **Après changement** | ❌ Menu vide ou incorrect | ✅ À jour avec checkmark |
| **Indicateurs visuels** | ⚠️ Checkmark statique | ✅ Checkmark dynamique |
| **Feedback utilisateur** | ❌ Aucune confirmation visuelle | ✅ Checkmark indique la sélection |
| **Code dupliqué** | ⚠️ Menu créé à 2 endroits | ✅ Fonction centralisée |
| **Maintenance** | ⚠️ Difficile (code dupliqué) | ✅ Facile (fonction unique) |

---

## 🧪 Comment tester

### Test 1 : Menu initial

1. Lancez une vidéo sans sélectionner de sous-titres
2. Pendant la lecture, ouvrez le menu du player (Menu button)
3. Sélectionnez "Sous-titres"

**Résultat attendu :**
- ✅ "Aucun" a un checkmark
- ✅ Les autres options n'ont pas de checkmark

### Test 2 : Changement de sous-titres

1. Sélectionnez "Français" dans le menu
2. Attendez que la vidéo redémarre
3. Ouvrez à nouveau le menu des sous-titres

**Résultat attendu :**
- ✅ "Français" a un checkmark
- ✅ "Aucun" n'a plus de checkmark
- ✅ Le menu est toujours présent (pas vide)

### Test 3 : Désactivation

1. Sélectionnez "Aucun"
2. Attendez que la vidéo redémarre
3. Ouvrez le menu

**Résultat attendu :**
- ✅ "Aucun" a un checkmark
- ✅ Le menu est présent et fonctionnel

### Test 4 : Changements multiples

1. Passez de "Aucun" → "Français" → "English" → "Aucun"
2. Vérifiez le menu après chaque changement

**Résultat attendu :**
- ✅ Le checkmark suit toujours la sélection actuelle
- ✅ Un seul checkmark visible à la fois
- ✅ Pas de bugs ou de crashs

---

## 🛠 Détails techniques

### Capture de l'état actuel

La fonction `configureSubtitleMenu()` lit `selectedSubtitleIndex` au moment de son exécution :

```swift
let isSelected = selectedSubtitleIndex == subtitle.index
```

Comme elle est appelée **après** que `selectedSubtitleIndex` a été mis à jour, elle reflète toujours l'état actuel.

### Gestion mémoire

Les closures utilisent `[weak self]` pour éviter les cycles de rétention :

```swift
) { [weak self] _ in
    self?.playerCoordinator.onSubtitleChange?(subtitleIndex)
}
```

Le coordinator utilise aussi `[weak playerCoordinator]` dans les closures.

### Thread safety

Tous les appels à `configureSubtitleMenu()` se font sur le `@MainActor`, garantissant un accès thread-safe à `selectedSubtitleIndex`.

---

## 🔍 Logs de débogage

### Lors du démarrage initial

```
✅ Menu des sous-titres configuré avec 3 options
   → Aucun sous-titre sélectionné
```

### Lors d'un changement

```
💾 Préférence de sous-titre sauvegardée : fre
🔄 Redémarrage de la lecture pour appliquer les nouveaux sous-titres (burn-in)...
🎬 Nouvelle URL générée avec sous-titres burn-in
✅ Lecture redémarrée avec sous-titres burn-in
✅ Menu des sous-titres configuré avec 3 options
   → Sous-titre actuel : index 2
```

---

## 📝 Fichiers modifiés

### MediaDetailView.swift

**Nouvelles sections :**
- `// MARK: - Player Menu Configuration`
- Fonction `configureSubtitleMenu(for:)`

**Modifications :**
- `continueStartPlayback()` : Appel de `configureSubtitleMenu()`
- `restartPlaybackWithSubtitles()` : Appel de `configureSubtitleMenu()` au lieu de menu vide
- `playerCoordinator.onSubtitleChange` : Ajout de logs

**Lignes approximatives :**
- Ligne 49-109 : Nouvelle fonction `configureSubtitleMenu()`
- Ligne 665 : Appel dans `continueStartPlayback()`
- Ligne 821 : Appel dans `restartPlaybackWithSubtitles()`

---

## 🚀 Avantages de cette approche

### ✅ DRY (Don't Repeat Yourself)

Le code de création du menu est écrit **une seule fois** et réutilisé partout.

### ✅ Consistance

Le menu a toujours la même structure et le même comportement, peu importe où il est créé.

### ✅ Facilité de maintenance

Pour ajouter une fonctionnalité (ex: icône pour les sous-titres forcés), il suffit de modifier **un seul endroit**.

### ✅ Testabilité

La fonction peut être testée indépendamment du reste du code.

---

## 🔮 Améliorations futures possibles

### 1. Indication visuelle pour les sous-titres forcés

```swift
let icon: UIImage? = {
    if isSelected {
        return UIImage(systemName: "checkmark")
    } else if subtitle.isForced == true {
        return UIImage(systemName: "exclamationmark.circle")
    }
    return nil
}()
```

### 2. Sous-menus par langue

```swift
let languageMenus = Dictionary(grouping: item.subtitleStreams) { $0.language }
    .map { language, subtitles in
        UIMenu(title: language ?? "Unknown", children: /* actions */)
    }
```

### 3. Prévisualisation des sous-titres

Afficher un aperçu du style des sous-titres avant de sélectionner (nécessiterait des API supplémentaires).

---

## ✅ Conclusion

Le bouton de sous-titres dans le menu du player tvOS est maintenant **complètement synchronisé** avec l'état des sous-titres. Les utilisateurs ont un feedback visuel clair de la piste actuellement active, et le menu se met à jour dynamiquement après chaque changement.

Cette amélioration rend l'expérience utilisateur plus cohérente et intuitive, tout en simplifiant le code grâce à la centralisation de la logique de création du menu.

---

**Implémenté le 22 décembre 2024**
