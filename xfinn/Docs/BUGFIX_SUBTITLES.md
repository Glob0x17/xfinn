# 🐛 Correction du bug des sous-titres

## Le problème

Vous ne voyiez pas le bouton de sélection des sous-titres apparaître dans l'interface, même après avoir ajouté tout le code nécessaire.

## La cause racine

**Le code de l'interface était correct**, mais les données n'arrivaient jamais ! 

L'API Jellyfin **ne renvoie pas les `MediaStreams` par défaut**. Il faut explicitement demander ce champ dans le paramètre `Fields` de chaque requête.

### Ce qui se passait :

```swift
// ❌ AVANT - Ne récupérait PAS les MediaStreams
let url = URL(string: "\(baseURL)/Users/\(userId)/Items/\(itemId)")!

// Résultat : item.mediaStreams == nil
// Donc : item.subtitleStreams.isEmpty == true
// Donc : Le bouton n'apparaissait jamais !
```

### Condition dans le code :

```swift
// Cette condition était toujours FALSE car subtitleStreams était vide
if !item.subtitleStreams.isEmpty {
    Button("Sous-titres") { ... }
}
```

---

## ✅ La solution

Ajouter `MediaStreams` au paramètre `Fields` dans **toutes** les requêtes qui récupèrent des médias vidéo.

### Modifications apportées

#### 1. JellyfinService.swift - fonction `getItem()`

```swift
// ✅ APRÈS - Récupère les MediaStreams
var urlComponents = URLComponents(string: "\(baseURL)/Users/\(userId)/Items/\(itemId)")!

urlComponents.queryItems = [
    URLQueryItem(name: "Fields", value: "Overview,MediaStreams")
]
```

#### 2. Toutes les autres fonctions

Les fonctions suivantes ont été mises à jour pour inclure `,MediaStreams` dans leur paramètre `Fields` :

- ✅ `getItem(itemId:)` - Détails d'un média
- ✅ `getItems(parentId:...)` - Liste de médias
- ✅ `getResumeItems(limit:)` - Médias en cours
- ✅ `getLatestItems(parentId:limit:)` - Médias récents
- ✅ `search(query:...)` - Recherche
- ✅ `getNextEpisode(currentItem:)` - Épisode suivant

---

## 🔍 Debug ajouté

Pour vous aider à diagnostiquer, j'ai ajouté des logs de debug dans `MediaDetailView.onAppear` :

```swift
print("🔍 DEBUG Sous-titres:")
print("   - Nombre de MediaStreams: \(item.mediaStreams?.count ?? 0)")
print("   - Nombre de sous-titres: \(item.subtitleStreams.count)")
if !item.subtitleStreams.isEmpty {
    for subtitle in item.subtitleStreams {
        print("   - Sous-titre: \(subtitle.displayName) (index: \(subtitle.index), langue: \(subtitle.language ?? "nil"))")
    }
}
```

### Comment utiliser ces logs :

1. Compilez et lancez l'app
2. Ouvrez la page de détails d'une vidéo
3. Regardez la console Xcode (Cmd+Shift+Y)

**Vous devriez maintenant voir :**
```
🔍 DEBUG Sous-titres:
   - Nombre de MediaStreams: 3
   - Nombre de sous-titres: 1
   - Sous-titre: Français (index: 2, langue: fre)
```

Si vous voyez toujours `Nombre de sous-titres: 0`, cela signifie que le média n'a vraiment pas de sous-titres.

---

## ✅ Test de vérification

### Étape 1 : Compilation
1. Nettoyez le build : **Product > Clean Build Folder** (Cmd+Shift+K)
2. Compilez : **Product > Build** (Cmd+B)
3. Il ne devrait y avoir **aucune erreur**

### Étape 2 : Exécution
1. Lancez l'app
2. Naviguez vers une vidéo qui a des sous-titres
3. Ouvrez la page de détails

### Étape 3 : Vérification visuelle
**Vous devriez maintenant voir :**

1. Un nouveau bouton avec une icône de sous-titres (💬) à côté du bouton de qualité
2. Le texte du bouton indique le sous-titre actuel ou "Aucun"
3. Cliquer dessus ouvre une alerte avec la liste des sous-titres disponibles

### Étape 4 : Vérification dans la console
Regardez les logs :
- ✅ Vous voyez le nombre de MediaStreams > 0
- ✅ Vous voyez le nombre de sous-titres > 0
- ✅ Vous voyez la liste des sous-titres

---

## 🎯 Pourquoi ça marchera maintenant

**Avant :**
```
API Jellyfin → JellyfinService → MediaItem (mediaStreams = nil)
                                      ↓
                            item.subtitleStreams = []
                                      ↓
                            Bouton ne s'affiche pas
```

**Maintenant :**
```
API Jellyfin (avec Fields=MediaStreams) 
      ↓
JellyfinService → MediaItem (mediaStreams = [stream1, stream2, ...])
                        ↓
              item.subtitleStreams = [subtitle1, ...]
                        ↓
              ✅ Bouton s'affiche !
```

---

## 📝 Résumé des fichiers modifiés

### JellyfinService.swift
- ✅ 6 fonctions mises à jour pour demander `MediaStreams`
- ✅ Aucune modification des structures ou signatures

### MediaDetailView.swift
- ✅ Ajout de logs de debug dans `onAppear()`
- ✅ Tout le reste du code était déjà correct

### Aucun autre fichier modifié
Les structures dans `JellyfinModels.swift` étaient déjà parfaites !

---

## 🚀 Prochaines étapes

1. **Compilez et testez** avec les modifications ci-dessus
2. **Regardez la console** pour voir les logs de debug
3. Si vous voyez des sous-titres dans les logs mais pas le bouton :
   - Prenez une capture d'écran
   - Copiez les logs de la console
   - Et on debuggera ensemble !

4. Si tout fonctionne :
   - Vous pouvez retirer les logs de debug (ou les laisser pour plus tard)
   - Testez la sélection des sous-titres
   - Testez la lecture avec sous-titres

---

## ❓ Questions fréquentes

### Q: Pourquoi ça ne marchait pas avant ?
**R:** L'API Jellyfin ne renvoie que les champs demandés. Sans `Fields=MediaStreams`, le tableau `mediaStreams` était `nil`.

### Q: Est-ce que ça va ralentir les requêtes ?
**R:** Non, les `MediaStreams` sont des métadonnées légères. L'impact sur la performance est négligeable.

### Q: Pourquoi tous les médias n'ont pas de sous-titres ?
**R:** Ça dépend de votre bibliothèque Jellyfin. Tous les médias n'ont pas forcément de sous-titres intégrés ou externes.

### Q: Comment ajouter des sous-titres à mes vidéos ?
**R:** Utilisez l'interface web Jellyfin pour uploader des fichiers `.srt`, `.vtt` ou `.ass` pour vos vidéos.

---

## 🎉 Conclusion

Le bug n'était **pas dans votre code UI**, mais dans la **récupération des données** depuis l'API.

C'est un problème classique avec les APIs REST : il faut savoir exactement quels champs demander !

**Les modifications sont minimales et ciblées** - juste l'ajout de `,MediaStreams` dans 6 endroits.

---

*Correction appliquée le 22 décembre 2024*
