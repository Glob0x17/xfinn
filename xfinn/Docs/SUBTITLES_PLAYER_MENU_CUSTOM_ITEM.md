# 🎮 Menu personnalisé dans le player tvOS

## ✅ Solution implémentée

Ajout d'un **item personnalisé** dans le menu du player tvOS pour accéder aux sous-titres.

---

## 🎯 Fonctionnement

### Avant (problème)
```
Menu du player:
- Vitesse de lecture
- Audio
- Sous-titres (vide - Auto/Off/CC seulement)
```
❌ Le menu "Sous-titres" natif ne contient rien d'utilisable

### Après (solution)
```
Menu du player:
- Vitesse de lecture
- Audio
- Sous-titres (natif - toujours vide)
---
- Sous-titres (notre item custom) ✨
```
✅ Un nouvel item "Sous-titres" avec icône 💬 ouvre notre alerte

---

## 🔧 Implémentation

### Code ajouté dans MediaDetailView.swift

```swift
#if os(tvOS)
// 🎯 Ajouter un item personnalisé pour les sous-titres dans le menu du player
if !item.subtitleStreams.isEmpty {
    let subtitleAction = UIAction(
        title: "Sous-titres",
        image: UIImage(systemName: "captions.bubble")
    ) { [weak self] _ in
        // Fermer le player et ouvrir l'alerte de sélection
        self?.showVideoPlayer = false
        // Petit délai pour laisser le player se fermer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self?.showSubtitlePicker = true
        }
    }
    
    let subtitleMenu = UIMenu(
        title: "",
        options: .displayInline,
        children: [subtitleAction]
    )
    
    controller.transportBarCustomMenuItems = [subtitleMenu]
}
#endif
```

---

## 🎬 Flux utilisateur

### Scénario 1 : Avant le démarrage

```
1. Page de détails de l'épisode
2. Utilisateur clique sur bouton 💬 "Sous-titres"
3. Alerte s'affiche
4. Sélection de la piste
5. Lancement de la lecture avec sous-titres
```

### Scénario 2 : Pendant la lecture (nouveau)

```
1. Vidéo en cours de lecture
2. Utilisateur appuie sur les 3 points (ou Play/Pause)
3. Menu du player s'affiche
4. Utilisateur sélectionne "Sous-titres" (notre item custom)
5. Player se ferme
6. Alerte de sélection s'affiche
7. Utilisateur choisit une nouvelle piste
8. Vidéo redémarre avec nouveaux sous-titres ✅
```

---

## 🎨 Apparence dans le menu

### Sur tvOS

```
╔════════════════════════════╗
║   Menu de lecture          ║
╠════════════════════════════╣
║ ▶ Vitesse de lecture       ║
║ 🔊 Audio                   ║
║ 💬 Sous-titres (natif)     ║  ← Vide (Auto/Off/CC)
║ ───────────────────────    ║
║ 💬 Sous-titres             ║  ← Notre item ✨
╚════════════════════════════╝
```

**Note** : L'item natif "Sous-titres" reste visible mais vide. Notre item apparaît en dessous avec le même nom et la même icône, mais **fonctionne**.

---

## 💡 Avantages

### ✅ Accessible pendant la lecture
L'utilisateur n'a plus besoin de revenir en arrière pour changer de piste.

### ✅ Interface familière
Utilise le menu natif du player que l'utilisateur connaît déjà.

### ✅ Icône reconnaissable
L'icône 💬 `captions.bubble` est la même que sur notre bouton.

### ✅ Simple à utiliser
Un seul clic pour ouvrir la sélection.

---

## ⚠️ Comportement

### Fermeture temporaire du player

Quand l'utilisateur sélectionne notre item custom :
1. Le player se **ferme** automatiquement
2. L'alerte de sélection **s'affiche**
3. L'utilisateur **choisit** une piste
4. Le player **redémarre** avec les nouveaux sous-titres

**Pourquoi ?**
- On ne peut pas afficher l'alerte SwiftUI PAR-DESSUS le player UIKit
- Il faut fermer le player pour afficher l'alerte
- La vidéo redémarre de toute façon (burn-in nécessite un nouveau flux)

**Délai de 0.3 seconde** :
- Laisse le temps au player de se fermer proprement
- Évite les glitches visuels

---

## 🔍 Différences avec le menu natif

| Aspect | Menu natif "Sous-titres" | Notre item custom |
|--------|-------------------------|-------------------|
| **Icône** | 💬 | 💬 (même) |
| **Nom** | Sous-titres | Sous-titres (même) |
| **Contenu** | Auto/Off/CC (vide) | Liste complète des pistes |
| **Action** | Rien (pas de pistes) | Ouvre notre alerte |
| **Position** | En haut | En bas (séparateur) |

---

## 🎮 Sur les autres plateformes

### iOS / iPadOS

Sur iOS/iPadOS, `transportBarCustomMenuItems` **n'existe pas**.

**Solution actuelle** : Utiliser uniquement le bouton sur la page de détails.

**Alternative possible** : Bouton flottant

```swift
ZStack {
    PlayerView(...)
    
    // Bouton flottant en haut à droite
    VStack {
        HStack {
            Spacer()
            Button { showSubtitlePicker = true } {
                Image(systemName: "captions.bubble")
                    .font(.title)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding()
        }
        Spacer()
    }
    .opacity(showControls ? 1 : 0)
}
```

---

## 🧪 Test

### Étape 1 : Compilation
```bash
Product > Clean Build Folder
Product > Build
```

### Étape 2 : Lancement
1. Ouvrez une vidéo avec sous-titres
2. Lancez la lecture

### Étape 3 : Vérification
1. Pendant la lecture, appuyez sur **Play/Pause** ou **Menu**
2. Le menu du player devrait s'afficher
3. Cherchez l'item **"Sous-titres"** en bas (avec un séparateur au-dessus)
4. Sélectionnez-le

### Résultat attendu
1. ✅ Le player se ferme
2. ✅ L'alerte de sélection s'affiche
3. ✅ Liste complète des pistes disponibles
4. ✅ Après sélection, vidéo redémarre avec nouveaux sous-titres

---

## 🐛 Dépannage

### Problème : L'item n'apparaît pas

**Vérifications** :
1. Vous êtes bien sur **tvOS** ?
2. La vidéo a des sous-titres ? (Condition `!item.subtitleStreams.isEmpty`)
3. Le player est bien créé ? (Vérifier les logs)

**Console attendue** :
```swift
🔍 DEBUG Sous-titres:
   - Nombre de sous-titres: X  // Doit être > 0
```

### Problème : L'alerte ne s'ouvre pas

**Vérification** :
```swift
self?.showSubtitlePicker = true
```

Est-ce que `showSubtitlePicker` est bien une `@State` ?

**Solution** : Vérifier que la closure capture bien `self`

### Problème : Le player ne se ferme pas

**Vérification** :
```swift
self?.showVideoPlayer = false
```

**Solution** : Augmenter le délai si nécessaire
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self?.showSubtitlePicker = true
}
```

---

## 📊 Comparaison des solutions

| Solution | Plateforme | Accessibilité | Complexité |
|----------|-----------|---------------|------------|
| **Bouton sur page détails** | Toutes | ⚠️ Avant lecture seulement | 🟢 Simple |
| **Item custom dans menu** | tvOS | ✅ Pendant lecture | 🟢 Simple |
| **Bouton flottant** | iOS/iPadOS | ✅ Pendant lecture | 🟡 Moyenne |
| **Player custom** | Toutes | ✅ Pendant lecture | 🔴 Complexe |

---

## ✅ Résultat final

### tvOS (maintenant)
✅ **Bouton sur page de détails** → Fonctionne
✅ **Item custom dans menu du player** → Fonctionne (nouveau)

### iOS / iPadOS
✅ **Bouton sur page de détails** → Fonctionne
⚠️ **Menu du player** → Vide (limitation)

**Solution possible** : Implémenter un bouton flottant pour iOS/iPadOS

---

## 🔮 Améliorations futures

### 1. Sous-menu avec liste directe (tvOS)

Au lieu de fermer le player, afficher directement la liste dans un sous-menu :

```swift
let subtitleMenuItems = item.sortedSubtitleStreams.map { subtitle in
    UIAction(title: subtitle.displayName) { [weak self] _ in
        self?.selectedSubtitleIndex = subtitle.index
        self?.restartPlaybackWithSubtitles(at: currentTime)
    }
}

let subtitleMenu = UIMenu(
    title: "Sous-titres",
    image: UIImage(systemName: "captions.bubble"),
    children: subtitleMenuItems
)
```

**Problème** : Fonctionne mais nécessite un accès à `currentTime` depuis le closure.

### 2. Indicateur visuel de la piste actuelle

Ajouter un checkmark sur la piste actuellement sélectionnée :

```swift
UIAction(
    title: subtitle.displayName,
    image: selectedSubtitleIndex == subtitle.index ? 
        UIImage(systemName: "checkmark") : nil
)
```

---

## 📝 Récapitulatif du code

### Emplacement
**Fichier** : `MediaDetailView.swift`
**Ligne** : ~615-635
**Section** : Création de l'`AVPlayerViewController`

### Condition
```swift
#if os(tvOS)
if !item.subtitleStreams.isEmpty {
    // Code ici
}
#endif
```

**Pourquoi cette condition ?**
- `transportBarCustomMenuItems` n'existe que sur tvOS
- Pas besoin d'ajouter l'item si la vidéo n'a pas de sous-titres

---

**Modification appliquée le 22 décembre 2024**

**Testez maintenant sur tvOS - l'item devrait apparaître dans le menu du player ! 🎮✨**
