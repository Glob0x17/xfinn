# 🎯 Gestion des sous-titres forcés (Forced Subtitles)

## ⚠️ Problème identifié

Lors de la lecture de "Designated Survivor", cette erreur apparaissait dans la console :

```
*** -[AVPlayerController(AVMediaSelection) currentLegibleMediaSelectionOption] 
Received a non-forced-only media selection (...) when display type was forced-only. ***
```

**Cause** : L'app auto-sélectionnait "French Forced" au lieu de "French Full", ce qui créait un conflit avec AVPlayer.

---

## 📚 Qu'est-ce qu'un sous-titre "forcé" ?

### Définition

Les **sous-titres forcés** (Forced Subtitles) sont des sous-titres qui ne s'affichent que pour :
- Les dialogues en langue étrangère
- Les panneaux/textes à l'écran
- Les éléments importants qu'on ne peut pas comprendre autrement

**Exemple** : Dans une série en anglais, quand un personnage parle en chinois, seul ce dialogue aura des sous-titres.

### Types de sous-titres

| Type | Description | Utilisation |
|------|-------------|-------------|
| **Full** / **SDH** | Tous les dialogues + sons | Usage normal |
| **Forced** | Seulement parties étrangères | Avec audio dans la langue principale |
| **SDH** (Hearing Impaired) | Tous dialogues + descriptions de sons | Pour malentendants |

---

## ✅ Solution implémentée

### 1. Exclusion des sous-titres forcés de l'auto-sélection

**Modification dans `autoSelectSubtitles()`** :

```swift
private func autoSelectSubtitles() {
    guard let preferredLanguage = preferredSubtitleLanguage,
          !item.subtitleStreams.isEmpty else {
        return
    }
    
    // ⚠️ EXCLURE les sous-titres "forcés" (forced) par défaut
    if let matchingSubtitle = item.subtitleStreams.first(where: { subtitle in
        let isMatchingLanguage = subtitle.language?.lowercased() == preferredLanguage.lowercased()
        let isNotForced = subtitle.isForced != true // Exclure les sous-titres forcés
        return isMatchingLanguage && isNotForced
    }) {
        selectedSubtitleIndex = matchingSubtitle.index
        print("✅ Sous-titres auto-sélectionnés: \(matchingSubtitle.displayName)")
    } else if let firstDefault = item.subtitleStreams.first(where: { 
        $0.isDefault == true && $0.isForced != true // Exclure les forcés aussi ici
    }) {
        selectedSubtitleIndex = firstDefault.index
        print("✅ Sous-titres par défaut sélectionnés: \(firstDefault.displayName)")
    } else {
        print("ℹ️ Aucun sous-titre non-forcé trouvé pour la langue: \(preferredLanguage)")
    }
}
```

**Ce qui change** :
- ✅ Ne sélectionne plus automatiquement les sous-titres "Forced"
- ✅ Préfère les sous-titres "Full" ou "SDH"
- ✅ Évite les conflits avec AVPlayer

---

### 2. Tri des sous-titres dans l'alerte

**Nouvelle propriété `sortedSubtitleStreams`** :

```swift
private var sortedSubtitleStreams: [MediaStream] {
    return item.subtitleStreams.sorted { subtitle1, subtitle2 in
        let isForced1 = subtitle1.isForced ?? false
        let isForced2 = subtitle2.isForced ?? false
        
        // Les non-forcés en premier
        if isForced1 != isForced2 {
            return !isForced1
        }
        
        // Sinon, trier par nom
        return subtitle1.displayName < subtitle2.displayName
    }
}
```

**Résultat dans l'alerte** :
```
Sous-titres disponibles :
1. French Full - SRT              ← En premier
2. English SDH - SRT              ← Ensuite
3. French Forced - SRT            ← En dernier
```

**Utilisation dans l'UI** :
```swift
ForEach(sortedSubtitleStreams) { subtitle in
    Button(subtitle.displayName) {
        // ...
    }
}
```

---

## 🎯 Comportement attendu maintenant

### Cas 1 : Vidéo avec sous-titres Full et Forced

**Sous-titres disponibles** :
- French Full (tous les dialogues)
- French Forced (seulement parties étrangères)
- English SDH

**Comportement** :
1. ✅ Au lancement, auto-sélection de "French Full" (pas Forced)
2. ✅ Dans l'alerte, "French Full" apparaît en premier
3. ✅ L'utilisateur peut choisir "French Forced" s'il le veut

### Cas 2 : Vidéo avec seulement des sous-titres Forced

**Sous-titres disponibles** :
- French Forced

**Comportement** :
1. ℹ️ Aucune auto-sélection (car tous sont forcés)
2. 👤 L'utilisateur peut manuellement sélectionner "French Forced"
3. ✅ Pas de conflit avec AVPlayer

---

## 🧪 Test de la solution

### Logs attendus

**Avant (avec le bug)** :
```
🔍 DEBUG Sous-titres:
   - Sous-titre: French Forced - SRT (index: 3, langue: fra)
   - Sous-titre: French Full - SRT (index: 4, langue: fra)
✅ Sous-titres auto-sélectionnés: French Forced - SRT
❌ ERREUR: Received a non-forced-only media selection when display type was forced-only
```

**Après (corrigé)** :
```
🔍 DEBUG Sous-titres:
   - Sous-titre: French Forced - SRT (index: 3, langue: fra)
   - Sous-titre: French Full - SRT (index: 4, langue: fra)
✅ Sous-titres auto-sélectionnés: French Full - SRT
✅ Pas d'erreur !
```

### Vérifications

1. **Compilez** et lancez l'app
2. **Ouvrez** "Designated Survivor" Saison 1 Épisode 1
3. **Vérifiez** la console :

**Vous devriez voir** :
```
✅ Sous-titres auto-sélectionnés: French Full - SRT - Français - SUBRIP
```

**Et NON** :
```
❌ Sous-titres auto-sélectionnés: French Forced - SRT - Français - Forcé - SUBRIP
```

4. **Ouvrez** l'alerte de sélection des sous-titres

**Ordre attendu** :
1. Aucun
2. French Full
3. English SDH
4. French Forced ← En dernier maintenant

---

## 📊 Comparaison des types de sous-titres

### Pour l'utilisateur français regardant une série en anglais

| Piste audio | Sous-titres | Résultat |
|-------------|-------------|----------|
| 🇬🇧 Anglais | ❌ Aucun | Comprend l'anglais mais pas les parties en chinois |
| 🇬🇧 Anglais | ✅ French **Forced** | Comprend tout + sous-titres pour parties chinoises seulement |
| 🇬🇧 Anglais | ✅ French **Full** | Tous les dialogues sous-titrés (redondant si on parle anglais) |
| 🇫🇷 Français | ❌ Aucun | Tout doublé en français |
| 🇫🇷 Français | ✅ French **Forced** | Doublage français + sous-titres pour textes à l'écran |

**Cas d'usage typique des "Forced"** :
```
Audio: Anglais original
Sous-titres: French Forced
→ Parfait pour quelqu'un qui parle anglais mais veut comprendre les parties étrangères
```

---

## 🎨 Interface utilisateur

### Amélioration possible : Badge pour identifier les Forced

On pourrait ajouter un badge visuel :

```swift
Button(action: { ... }) {
    HStack {
        Text(subtitle.displayName)
        
        if subtitle.isForced == true {
            Text("Forcé")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.3))
                .cornerRadius(4)
        }
    }
}
```

**Résultat** :
```
[ ] Aucun
[ ] French Full
[ ] English SDH
[ ] French Forced [Forcé]
```

---

## 🔍 Détection des sous-titres forcés

### Dans JellyfinModels.swift

La propriété `isForced` existe déjà :

```swift
struct MediaStream: Codable {
    let isForced: Bool?  // ← Déjà présent
    
    enum CodingKeys: String, CodingKey {
        case isForced = "IsForced"
    }
}
```

**Jellyfin détecte automatiquement** les sous-titres forcés depuis :
- Le nom du fichier (ex: "movie.forced.srt")
- Les métadonnées du fichier mkv
- Le flag dans le fichier de sous-titres

---

## ⚠️ Cas edge à considérer

### 1. Vidéo avec SEULEMENT des sous-titres forcés

**Scénario** : Film avec uniquement "French Forced.srt"

**Comportement actuel** :
- ❌ Aucune auto-sélection
- 👤 L'utilisateur doit sélectionner manuellement

**Alternative possible** :
```swift
// Si TOUS les sous-titres sont forcés, sélectionner quand même le premier
if item.subtitleStreams.allSatisfy({ $0.isForced == true }) {
    selectedSubtitleIndex = item.subtitleStreams.first?.index
}
```

### 2. Sous-titres SDH (Hearing Impaired)

Les sous-titres SDH ne sont **pas** forcés mais incluent :
- Tous les dialogues
- Descriptions de sons : [Door slams], [Music playing]

**Ils devraient être auto-sélectionnés** si la langue correspond.

---

## 📝 Résumé des modifications

| Fichier | Fonction | Modification |
|---------|----------|--------------|
| MediaDetailView.swift | `autoSelectSubtitles()` | Exclure `isForced == true` |
| MediaDetailView.swift | `sortedSubtitleStreams` | Nouvelle propriété pour trier |
| MediaDetailView.swift | Alert "Sous-titres" | Utiliser `sortedSubtitleStreams` |

---

## 🎉 Résultat final

✅ **Pas d'erreur AVPlayer** avec les sous-titres forcés
✅ **Auto-sélection intelligente** (Full > SDH > rien si que Forced)
✅ **Interface organisée** (Full en haut, Forced en bas)
✅ **Flexibilité** pour l'utilisateur qui peut toujours choisir manuellement

---

**Modification appliquée le 22 décembre 2024**

**Testez avec "Designated Survivor" et vérifiez qu'il n'y a plus d'erreur ! 🎬**
