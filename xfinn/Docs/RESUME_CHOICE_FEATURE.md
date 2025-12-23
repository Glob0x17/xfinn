# ✅ Amélioration : Choix de reprise de lecture

## 🎯 Objectif

Quand l'utilisateur clique sur "Lire" et qu'une position de lecture est déjà sauvegardée, afficher une popup pour choisir entre :
- **Continuer** : Reprendre à la position sauvegardée
- **Reprendre du début** : Recommencer depuis le début
- **Annuler** : Ne rien faire

## 📱 Interface utilisateur

### Avant

```
[▶ Lire]  →  Lecture automatique (avec reprise si position sauvegardée)
```

### Après

```
[▶ Lire]  →  
   Si position > 0:
     ┌─────────────────────────────────────┐
     │ Reprendre la lecture ?              │
     ├─────────────────────────────────────┤
     │ Voulez-vous reprendre la lecture    │
     │ à 2min 30s ?                        │
     │                                     │
     │ [Continuer]  [Reprendre du début]  │
     │ [Annuler]                           │
     └─────────────────────────────────────┘
   Sinon:
     Lecture directe
```

## 🔧 Implémentation

### 1. Ajout des états

```swift
@State private var showResumeAlert = false
@State private var isStoppingPlayback = false // Pour éviter les appels multiples
```

### 2. Modification du bouton "Lire"

```swift
Button(action: {
    // Vérifier s'il y a une position sauvegardée
    if let userData = item.userData,
       userData.playbackPositionTicks > 0,
       !userData.played { // Pas encore vu en entier
        showResumeAlert = true
    } else {
        startPlayback(resumePosition: false)
    }
}) {
    HStack {
        Image(systemName: "play.fill")
        Text(item.userData?.played == true ? "Revoir" : "Lire")
    }
}
```

### 3. Alerte de reprise

```swift
.alert("Reprendre la lecture ?", isPresented: $showResumeAlert) {
    Button("Continuer") {
        startPlayback(resumePosition: true)
    }
    Button("Reprendre du début") {
        startPlayback(resumePosition: false)
    }
    Button("Annuler", role: .cancel) {}
} message: {
    if let userData = item.userData, userData.playbackPositionTicks > 0 {
        Text("Voulez-vous reprendre la lecture à \(formatDuration(userData.playbackPosition)) ?")
    }
}
```

### 4. Modification de `startPlayback()`

```swift
private func startPlayback(resumePosition: Bool) {
    // ...
    
    print("🎬 Démarrage de la lecture pour: \(item.displayTitle)")
    if resumePosition, let userData = item.userData, userData.playbackPositionTicks > 0 {
        print("   📍 Mode reprise activé - Position: \(Int(userData.playbackPosition))s")
    } else {
        print("   📍 Lecture depuis le début")
    }
    
    // ...
    
    // Reprendre à la position sauvegardée (si demandé)
    if resumePosition, let itemUserData = item.userData, itemUserData.playbackPositionTicks > 0 {
        let startTime = CMTime(seconds: itemUserData.playbackPosition, preferredTimescale: 600)
        newPlayer.seek(to: startTime)
        print("⏩ Reprise à: \(itemUserData.playbackPosition)s")
    } else {
        print("▶️ Lecture depuis le début")
    }
}
```

## 🐛 Correction : Appels multiples à `stopPlayback()`

### Problème

`stopPlayback()` était appelé **2 fois** quand l'utilisateur quittait :
1. Par `playerViewControllerShouldDismiss` (delegate)
2. Par `onChange(of: isPlaybackActive)` (observer)

Résultat dans les logs :
```
🔙 L'utilisateur a quitté le player
🛑 isPlaybackActive désactivé, arrêt de la lecture
⏹️ Arrêt de la lecture demandé
📊 Position actuelle du player: 38s
✅ Arrêt signalé au serveur à la position 38s
📺 FullScreenCover fermé
⏹️ Arrêt de la lecture demandé              ← DEUXIÈME APPEL
⚠️ Player est déjà nil                       ← Player déjà nettoyé
✅ Arrêt signalé au serveur à la position 0s ← Mauvaise position !
```

### Solution

Ajouter un flag `isStoppingPlayback` pour éviter les appels multiples :

```swift
private func stopPlayback() {
    // Éviter les appels multiples
    guard !isStoppingPlayback else {
        print("⚠️ stopPlayback déjà en cours, ignoré")
        return
    }
    
    isStoppingPlayback = true
    
    // ... reste du code ...
    
    // Réinitialiser le flag après un court délai
    Task {
        try? await Task.sleep(for: .seconds(1))
        await MainActor.run {
            self.isStoppingPlayback = false
        }
    }
}
```

Et dans `onChange` :

```swift
.onChange(of: isPlaybackActive) { oldValue, newValue in
    if oldValue && !newValue && !isStoppingPlayback {
        print("🛑 isPlaybackActive désactivé, arrêt de la lecture")
        stopPlayback()
    }
}
```

## 📊 Logs attendus

### Cas 1 : Première lecture (pas de position sauvegardée)

```
🎬 Démarrage de la lecture pour: Under the Dome - S1E1
   📍 Lecture depuis le début
📺 URL: http://...master.m3u8?...
✅ Asset chargé - durée: 2562.685s
▶️ Lecture depuis le début
✅ Lecture signalée au serveur
```

### Cas 2 : Reprise de lecture (avec position sauvegardée)

**L'utilisateur clique sur "Lire"** → Popup s'affiche

**L'utilisateur clique sur "Continuer"** :
```
🎬 Démarrage de la lecture pour: Under the Dome - S1E1
   📍 Mode reprise activé - Position: 120s
📺 URL: http://...master.m3u8?...
✅ Asset chargé - durée: 2562.685s
⏩ Reprise à: 120s (soit 2min)
✅ Lecture signalée au serveur
```

**L'utilisateur clique sur "Reprendre du début"** :
```
🎬 Démarrage de la lecture pour: Under the Dome - S1E1
   📍 Lecture depuis le début
📺 URL: http://...master.m3u8?...
✅ Asset chargé - durée: 2562.685s
▶️ Lecture depuis le début
✅ Lecture signalée au serveur
```

### Cas 3 : Arrêt de la lecture (sans appels multiples)

```
🔙 L'utilisateur a quitté le player
⏹️ Arrêt de la lecture demandé
📊 Position actuelle du player: 120s (soit 2min)
🧹 Nettoyage de la lecture
✅ Arrêt signalé au serveur à la position 120s (soit 2min)
📺 FullScreenCover fermé
⚠️ stopPlayback déjà en cours, ignoré  ← Deuxième appel ignoré ✅
```

## 🧪 Tests à effectuer

### Test 1 : Première lecture

1. Sélectionner un média jamais regardé
2. Cliquer sur "Lire"
3. **Résultat attendu** : La lecture démarre immédiatement (pas de popup)

### Test 2 : Reprise après arrêt

1. Regarder un média pendant 2 minutes
2. Quitter avec "retour"
3. Revenir sur le même média
4. Cliquer sur "Lire"
5. **Résultat attendu** : Popup "Reprendre la lecture à 2min ?"
6. Cliquer sur "Continuer"
7. **Résultat attendu** : La lecture reprend à 2 minutes

### Test 3 : Recommencer depuis le début

1. Sur un média avec position sauvegardée
2. Cliquer sur "Lire"
3. **Résultat attendu** : Popup affichée
4. Cliquer sur "Reprendre du début"
5. **Résultat attendu** : La lecture démarre à 0s

### Test 4 : Annuler

1. Sur un média avec position sauvegardée
2. Cliquer sur "Lire"
3. **Résultat attendu** : Popup affichée
4. Cliquer sur "Annuler"
5. **Résultat attendu** : Rien ne se passe, on reste sur la page de détails

### Test 5 : Média déjà vu en entier

1. Sur un média avec `userData.played = true`
2. Cliquer sur "Lire" (qui affiche maintenant "Revoir")
3. **Résultat attendu** : La lecture démarre immédiatement depuis le début (pas de popup)

### Test 6 : Pas d'appels multiples

1. Lancer une vidéo
2. Quitter avec "retour"
3. **Vérifier dans les logs** :
   - Un seul message `⏹️ Arrêt de la lecture demandé`
   - Un seul message `✅ Arrêt signalé au serveur`
   - Pas de `⚠️ Player est déjà nil`

## 🎨 Expérience utilisateur

### Avantages

✅ **Choix clair** : L'utilisateur contrôle comment il reprend la lecture  
✅ **Pas de surprise** : On ne reprend pas automatiquement si l'utilisateur veut revoir depuis le début  
✅ **Information visible** : La position de reprise est affichée dans la popup  
✅ **Médias terminés** : Les médias déjà vus en entier ne demandent pas de reprise

### Comportements spéciaux

| Situation | Comportement |
|-----------|--------------|
| Première lecture | Démarre directement |
| Position > 0 mais pas fini | Popup de reprise |
| Média vu en entier (`played = true`) | Démarre directement |
| Position < 10s | Optionnel : Peut démarrer directement |

### Amélioration future possible

Ignorer la popup si la position est < 10 secondes :

```swift
let minimumResumePosition: TimeInterval = 10 // 10 secondes

if let userData = item.userData,
   userData.playbackPositionTicks > 0,
   userData.playbackPosition > minimumResumePosition,
   !userData.played {
    showResumeAlert = true
} else {
    startPlayback(resumePosition: userData.playbackPositionTicks > 0)
}
```

## 🔍 Débogage

### Si la popup ne s'affiche pas

**Vérifier** :
1. `item.userData` existe ?
2. `playbackPositionTicks > 0` ?
3. `userData.played` est `false` ?

**Logs de diagnostic** :
```swift
if let userData = item.userData {
    print("📊 UserData check:")
    print("   - Position: \(userData.playbackPosition)s")
    print("   - Ticks: \(userData.playbackPositionTicks)")
    print("   - Played: \(userData.played)")
}
```

### Si la reprise ne fonctionne pas

**Vérifier les logs** :
- `📍 Mode reprise activé` devrait apparaître
- `⏩ Reprise à: Xs` devrait apparaître

**Si absent** : Le paramètre `resumePosition` n'est pas passé correctement.

## 🎉 Résultat

L'utilisateur a maintenant **le contrôle total** sur la reprise de lecture :

1. 🎬 **Clic sur "Lire"** → Détection automatique de la position
2. 💬 **Popup** (si position > 0) → Choix clair pour l'utilisateur
3. ▶️ **Lecture** → Démarre exactement comme demandé
4. 💾 **Sauvegarde** → La nouvelle position est enregistrée
5. 🔄 **Répéter** → Le cycle continue parfaitement

**Plus de confusion, plus de frustration !** ✨
