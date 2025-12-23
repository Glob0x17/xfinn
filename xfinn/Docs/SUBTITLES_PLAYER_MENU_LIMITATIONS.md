# 📱 Menu natif du player avec burn-in

## ❓ Le problème

Avec la méthode **burn-in**, les sous-titres sont intégrés dans l'image vidéo pendant le transcodage. Le flux HLS ne contient **pas de pistes de sous-titres séparées**.

**Résultat** : Le menu natif du player (icône CC ou menu) affiche seulement :
- Auto
- Off  
- CC

Ces options **ne font rien** car il n'y a pas de vraies pistes à sélectionner.

---

## 🚫 Pourquoi on ne peut pas synchroniser

### Ce qui ne fonctionne pas

#### Option 1 : Ajouter des pistes au menu natif ❌
```swift
// ❌ Impossible avec burn-in
// Les pistes sont déjà intégrées dans l'image
playerItem.select(option, in: legibleGroup)
```

**Problème** : Il n'y a pas de `AVMediaSelectionGroup` à peupler

#### Option 2 : Observer les changements du menu natif ❌
```swift
// ❌ Rien à observer
playerItem.publisher(for: \.currentMediaSelection)
```

**Problème** : Pas de changement à détecter, le menu est vide

#### Option 3 : Remplacer le menu natif ❌
```swift
// ❌ Pas d'API pour ça
controller.showsPlaybackControls = false // Masque TOUT
```

**Problème** : On perd tous les contrôles (play/pause, scrubbing, etc.)

---

## ✅ La solution actuelle

### Notre bouton 💬 dans MediaDetailView

**Emplacement** : Page de détails, à côté du bouton de qualité

**Fonctionnement** :
1. Affiche les sous-titres disponibles
2. Permet la sélection
3. Redémarre la vidéo avec burn-in des sous-titres choisis
4. Sauvegarde la préférence

**Avantages** :
- ✅ Fonctionne parfaitement
- ✅ Liste complète des pistes
- ✅ Tri intelligent (Full > SDH > Forced)
- ✅ Mémorisation de la préférence

**Inconvénient** :
- ⚠️ L'utilisateur doit revenir en arrière pour changer

---

## 💡 Solutions alternatives

### Option A : Afficher un avertissement dans le player

Ajouter un message qui indique à l'utilisateur d'utiliser notre bouton :

```swift
#if os(tvOS)
let menuItem = UIMenuElement(
    title: "Utilisez le bouton sous-titres sur la page de détails",
    image: UIImage(systemName: "captions.bubble")
)
controller.transportBarCustomMenuItems = [menuItem]
#endif
```

**Résultat** : Un item dans le menu qui explique où aller

---

### Option B : Bouton flottant dans le player (complexe)

Ajouter notre propre bouton de sous-titres PAR-DESSUS le player :

```swift
ZStack {
    PlayerViewControllerRepresentable(...)
    
    // Bouton flottant en haut à droite
    VStack {
        HStack {
            Spacer()
            Button(action: { showSubtitlePicker = true }) {
                Image(systemName: "captions.bubble")
                    .font(.title2)
            }
            .padding()
        }
        Spacer()
    }
}
```

**Avantages** :
- ✅ Accessible pendant la lecture
- ✅ Pas besoin de revenir en arrière

**Inconvénients** :
- ⚠️ Peut masquer du contenu
- ⚠️ Peut interférer avec les contrôles natifs
- ⚠️ Plus complexe à implémenter

---

### Option C : Player custom (très complexe)

Créer un lecteur complètement custom avec SwiftUI au lieu d'utiliser `AVPlayerViewController` :

```swift
struct CustomVideoPlayer: View {
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            // Vidéo
            VideoPlayer(player: player)
                .onTapGesture {
                    showControls.toggle()
                }
            
            // Contrôles custom
            if showControls {
                VStack {
                    HStack {
                        Spacer()
                        // Notre menu de sous-titres
                        Menu {
                            ForEach(subtitles) { subtitle in
                                Button(subtitle.name) {
                                    selectSubtitle(subtitle)
                                }
                            }
                        } label: {
                            Image(systemName: "captions.bubble")
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Contrôles de lecture custom
                    HStack {
                        Button(action: { ... }) {
                            Image(systemName: "backward.10")
                        }
                        Button(action: { ... }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        }
                        Button(action: { ... }) {
                            Image(systemName: "forward.10")
                        }
                    }
                }
            }
        }
    }
}
```

**Avantages** :
- ✅ Contrôle total sur l'UI
- ✅ Peut placer le menu où on veut
- ✅ Peut personnaliser tous les contrôles

**Inconvénients** :
- ❌ Beaucoup de travail
- ❌ Perd PiP natif
- ❌ Perd Now Playing natif
- ❌ Perd accessibilité native
- ❌ Perd gestes natifs

---

## 🎯 Recommandation : Solution actuelle + amélioration UX

### 1. Garder le bouton sur la page de détails ✅

C'est la solution la plus simple et fiable.

### 2. Améliorer la visibilité du bouton

Rendre le bouton plus visible avec une animation ou un badge :

```swift
Button(action: { showSubtitlePicker = true }) {
    HStack(spacing: 10) {
        Image(systemName: selectedSubtitleIndex != nil ? 
            "captions.bubble.fill" : "captions.bubble")
        Text(selectedSubtitleDisplayName)
        
        // Badge pour indiquer que c'est actif
        if selectedSubtitleIndex != nil {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}
```

### 3. Ajouter un tooltip ou un hint

Première fois que l'utilisateur ouvre la page :

```swift
.overlay(alignment: .topTrailing) {
    if showSubtitleHint {
        Text("Cliquez ici pour les sous-titres")
            .font(.caption)
            .padding(8)
            .background(Color.blue)
            .cornerRadius(8)
            .offset(x: 0, y: -40)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showSubtitleHint = false
                    }
                }
            }
    }
}
```

---

## 📋 État actuel du code

### Ce qui est implémenté ✅

1. **Bouton de sélection** sur la page de détails
2. **Auto-sélection** au lancement (excluant les forcés)
3. **Tri intelligent** des pistes (Full > SDH > Forced)
4. **Sauvegarde** de la préférence de langue
5. **Burn-in** fonctionnel avec Jellyfin
6. **Redémarrage** lors du changement de piste

### Ce qui n'est pas implémenté ⚠️

1. **Menu natif du player** → Vide et non fonctionnel
2. **Changement pendant la lecture** → Nécessite de revenir en arrière
3. **Indication visuelle** dans le player → Aucune

---

## 💬 Communication avec l'utilisateur

### Message dans l'alerte

Le message actuel est clair :

```
Choisissez les sous-titres à afficher.
Votre choix sera mémorisé pour les prochaines vidéos.

⚠️ Changer les sous-titres pendant la lecture redémarrera brièvement la vidéo.
```

### Amélioration possible

Ajouter une explication sur le menu natif :

```
Choisissez les sous-titres à afficher.
Votre choix sera mémorisé pour les prochaines vidéos.

ℹ️ Le menu du lecteur vidéo ne contient pas de sous-titres.
   Utilisez ce bouton pour les gérer.

⚠️ Changer les sous-titres pendant la lecture redémarrera brièvement la vidéo.
```

---

## 🔮 Évolution future possible

### Si Jellyfin ajoute le support HLS natif

Si un jour Jellyfin inclut les sous-titres dans le flux HLS master.m3u8 :

```swift
// Détecter automatiquement le support
func supportsNativeSubtitles(asset: AVAsset) async -> Bool {
    guard let legibleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
        return false
    }
    return legibleGroup.options.count > 1 // Plus que juste "Off"
}

// Choisir la bonne méthode
if await supportsNativeSubtitles(asset: asset) {
    // Utiliser HLS natif (pas de burn-in, changement instantané)
    useNativeSubtitles()
} else {
    // Utiliser burn-in (méthode actuelle)
    useBurninSubtitles()
}
```

---

## 📊 Comparaison des solutions

| Solution | Complexité | UX | Performance | Maintenance |
|----------|------------|-------|-------------|-------------|
| **Bouton sur page détails** (actuel) | 🟢 Faible | 🟡 Moyenne | 🟢 Bonne | 🟢 Facile |
| **Bouton flottant dans player** | 🟡 Moyenne | 🟢 Bonne | 🟢 Bonne | 🟡 Moyenne |
| **Player custom complet** | 🔴 Haute | 🟢 Excellente | 🟡 Moyenne | 🔴 Difficile |
| **HLS natif** (si supporté) | 🟢 Faible | 🟢 Excellente | 🟢 Excellente | 🟢 Facile |

---

## ✅ Conclusion

**Pour l'instant, la solution actuelle est la meilleure** :
- ✅ Simple et fiable
- ✅ Facile à maintenir
- ✅ Fonctionne parfaitement

**Le menu natif du player reste vide** mais c'est une limitation du burn-in.

**Améliorations recommandées** :
1. Rendre le bouton plus visible (animation, badge)
2. Ajouter un tooltip la première fois
3. Expliquer dans l'alerte que le menu natif est vide

**Alternative à considérer** : Bouton flottant dans le player (mais complexe)

---

*Documentation créée le 22 décembre 2024*
