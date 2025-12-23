# ✅ Plan de test - Synchronisation des sous-titres

## Objectif

Vérifier que le **menu des sous-titres dans le player tvOS** reste synchronisé avec l'état actuel des sous-titres, y compris après les changements de piste.

---

## 📋 Prérequis

### Environnement de test

- ✅ Apple TV ou simulateur tvOS
- ✅ Serveur Jellyfin accessible
- ✅ Vidéo de test avec **au moins 2 pistes de sous-titres** (ex: Français + English)
- ✅ Dernière version de xfinn compilée

### Préparation

1. Identifiez une vidéo dans votre bibliothèque Jellyfin qui a plusieurs pistes de sous-titres
2. Notez les noms des pistes (ex: "Français", "English", "Español")
3. Ouvrez la console Xcode pour voir les logs

---

## 🧪 Tests à effectuer

### Test 1 : Menu initial sans sous-titres

**Objectif :** Vérifier que le menu reflète l'absence de sous-titres au démarrage.

**Étapes :**
1. Ouvrez la page de détails d'une vidéo
2. **Ne sélectionnez PAS** de sous-titres
3. Lancez la lecture (bouton "Lire")
4. Une fois la vidéo lancée, appuyez sur **Menu** sur la télécommande
5. Naviguez vers **"Sous-titres"** dans le menu
6. Regardez les options disponibles

**Résultat attendu :**
- ✅ Une option **"Aucun"** avec un **checkmark ✓**
- ✅ Les autres pistes disponibles **sans checkmark**
- ✅ Total : 1 + nombre de pistes

**Console attendue :**
```
✅ Menu des sous-titres configuré avec 3 options
   → Aucun sous-titre sélectionné
```

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 2 : Sélection d'une piste depuis le menu du player

**Objectif :** Vérifier qu'on peut sélectionner une piste depuis le menu pendant la lecture.

**Étapes :**
1. Continuez depuis le Test 1 (vidéo en cours sans sous-titres)
2. Dans le menu "Sous-titres", sélectionnez **"Français"**
3. Observez la vidéo redémarrer
4. Une fois la lecture reprise, rouvrez le menu "Sous-titres"

**Résultat attendu :**
- ✅ La vidéo redémarre en ~2 secondes à la même position
- ✅ Les sous-titres français s'affichent
- ✅ Dans le menu : **"Français"** a maintenant un **checkmark ✓**
- ✅ **"Aucun"** n'a plus de checkmark

**Console attendue :**
```
💾 Préférence de sous-titre sauvegardée : fre
🔄 Redémarrage de la lecture pour appliquer les nouveaux sous-titres (burn-in)...
🎬 Nouvelle URL générée avec sous-titres burn-in
✅ Lecture redémarrée avec sous-titres burn-in
✅ Menu des sous-titres configuré avec 3 options
   → Sous-titre actuel : index 2
```

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 3 : Changement vers une autre piste

**Objectif :** Vérifier qu'on peut changer de piste plusieurs fois.

**Étapes :**
1. Continuez depuis le Test 2 (sous-titres français actifs)
2. Ouvrez le menu "Sous-titres"
3. Sélectionnez **"English"**
4. Attendez le redémarrage
5. Rouvrez le menu "Sous-titres"

**Résultat attendu :**
- ✅ La vidéo redémarre avec les sous-titres anglais
- ✅ Dans le menu : **"English"** a le **checkmark ✓**
- ✅ **"Français"** n'a plus de checkmark
- ✅ Les sous-titres à l'écran sont bien en anglais

**Console attendue :**
```
💾 Préférence de sous-titre sauvegardée : eng
🔄 Redémarrage de la lecture...
✅ Lecture redémarrée avec sous-titres burn-in
✅ Menu des sous-titres configuré avec 3 options
   → Sous-titre actuel : index 3
```

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 4 : Désactivation des sous-titres

**Objectif :** Vérifier qu'on peut désactiver les sous-titres.

**Étapes :**
1. Continuez depuis le Test 3 (sous-titres anglais actifs)
2. Ouvrez le menu "Sous-titres"
3. Sélectionnez **"Aucun"**
4. Attendez le redémarrage
5. Rouvrez le menu "Sous-titres"

**Résultat attendu :**
- ✅ La vidéo redémarre sans sous-titres
- ✅ Dans le menu : **"Aucun"** a le **checkmark ✓**
- ✅ Aucune autre piste n'a de checkmark
- ✅ Pas de sous-titres visibles à l'écran

**Console attendue :**
```
💾 Préférence de sous-titre supprimée
🔄 Redémarrage de la lecture...
✅ Lecture redémarrée avec sous-titres burn-in
✅ Menu des sous-titres configuré avec 3 options
   → Aucun sous-titre sélectionné
```

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 5 : Sélection avant le démarrage

**Objectif :** Vérifier que le menu reflète correctement une sélection faite AVANT la lecture.

**Étapes :**
1. Quittez le player (appuyez sur Menu plusieurs fois)
2. Sur la page de détails, cliquez sur le bouton **💬 Sous-titres**
3. Sélectionnez **"Français"**
4. Lancez la lecture
5. Ouvrez le menu "Sous-titres"

**Résultat attendu :**
- ✅ Les sous-titres français s'affichent dès le début
- ✅ Dans le menu : **"Français"** a le **checkmark ✓**
- ✅ Le bouton sur la page de détails affichait "Français" en bleu

**Console attendue :**
```
✅ Sous-titres auto-sélectionnés: Français
🎬 URL de streaming générée avec sous-titres burn-in: index = 2
✅ Menu des sous-titres configuré avec 3 options
   → Sous-titre actuel : index 2
```

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 6 : Auto-sélection pour la vidéo suivante

**Objectif :** Vérifier que la préférence est mémorisée pour les vidéos suivantes.

**Prérequis :** Le Test 5 a défini "Français" comme préférence.

**Étapes :**
1. Quittez complètement la vidéo actuelle
2. Ouvrez une **autre vidéo** (avec des sous-titres français disponibles)
3. Lancez la lecture **sans sélectionner manuellement** les sous-titres
4. Ouvrez le menu "Sous-titres"

**Résultat attendu :**
- ✅ Les sous-titres français sont **automatiquement** sélectionnés
- ✅ Dans le menu : **"Français"** a le **checkmark ✓**
- ✅ Le bouton sur la page de détails affichait "Français" (auto-sélectionné)

**Console attendue :**
```
✅ Sous-titres auto-sélectionnés: Français
🎬 URL de streaming générée avec sous-titres burn-in: index = X
✅ Menu des sous-titres configuré avec Y options
   → Sous-titre actuel : index X
```

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 7 : Changements rapides successifs

**Objectif :** Vérifier la stabilité lors de changements rapides.

**Étapes :**
1. Lancez une vidéo
2. Ouvrez le menu "Sous-titres"
3. Changez rapidement : **Français** → **English** → **Aucun** → **Français**
4. Attendez ~2 secondes entre chaque changement
5. Vérifiez le menu après chaque changement

**Résultat attendu :**
- ✅ Chaque changement redémarre la vidéo
- ✅ Pas de crash
- ✅ Le checkmark suit toujours la dernière sélection
- ✅ Les sous-titres affichés correspondent au menu

**Console attendue :** Séquence de logs pour chaque changement.

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 8 : Menu sur une vidéo sans sous-titres

**Objectif :** Vérifier le comportement sur une vidéo sans sous-titres.

**Étapes :**
1. Ouvrez une vidéo **sans sous-titres** dans votre bibliothèque
2. Lancez la lecture
3. Ouvrez le menu du player

**Résultat attendu :**
- ✅ Pas de bouton "Sous-titres" dans le menu
- ✅ Le bouton 💬 n'apparaît pas sur la page de détails
- ✅ Pas d'erreur ou de crash

**Console attendue :**
```
🔍 DEBUG Sous-titres:
   - Nombre de MediaStreams: X
   - Nombre de sous-titres: 0
```

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 9 : Persistence après redémarrage de l'app

**Objectif :** Vérifier que la préférence est conservée après fermeture de l'app.

**Étapes :**
1. Sélectionnez "Français" sur une vidéo
2. Fermez complètement l'app (force quit)
3. Relancez l'app
4. Ouvrez une vidéo avec des sous-titres français
5. Regardez si les sous-titres sont auto-sélectionnés

**Résultat attendu :**
- ✅ Les sous-titres français sont auto-sélectionnés
- ✅ Le bouton sur la page de détails indique "Français"
- ✅ UserDefaults a conservé la préférence

**Console attendue :**
```
✅ Sous-titres auto-sélectionnés: Français
```

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

### Test 10 : Indicateurs visuels dans le menu

**Objectif :** Vérifier que tous les indicateurs visuels sont corrects.

**Étapes :**
1. Lancez une vidéo avec "Français" sélectionné
2. Ouvrez le menu "Sous-titres"
3. Vérifiez visuellement le menu

**Résultat attendu :**
- ✅ **Icône du menu** : 💬 (captions.bubble)
- ✅ **Titre du menu** : "Sous-titres"
- ✅ **Checkmark** : Visible à côté de "Français"
- ✅ **Pas de checkmark** sur les autres options
- ✅ **Un seul checkmark** visible à la fois

**Statut :** ⬜ Pas testé | ✅ Réussi | ❌ Échoué

---

## 📊 Résumé des tests

| Test | Description | Statut |
|------|-------------|--------|
| 1 | Menu initial sans sous-titres | ⬜ |
| 2 | Sélection depuis le menu | ⬜ |
| 3 | Changement vers autre piste | ⬜ |
| 4 | Désactivation | ⬜ |
| 5 | Sélection avant démarrage | ⬜ |
| 6 | Auto-sélection vidéo suivante | ⬜ |
| 7 | Changements rapides | ⬜ |
| 8 | Vidéo sans sous-titres | ⬜ |
| 9 | Persistence après redémarrage | ⬜ |
| 10 | Indicateurs visuels | ⬜ |

**Légende :**
- ⬜ Pas testé
- ✅ Réussi
- ❌ Échoué

---

## 🐛 Bugs potentiels à surveiller

### Bug 1 : Checkmark multiple

**Symptôme :** Plusieurs checkmarks visibles en même temps.

**Cause probable :** Logique de comparaison `isSelected` incorrecte.

**Solution :** Vérifier que `selectedSubtitleIndex` est bien mis à jour avant `configureSubtitleMenu()`.

### Bug 2 : Menu vide après changement

**Symptôme :** Le menu n'a plus d'options après un changement.

**Cause probable :** `configureSubtitleMenu()` n'est pas appelé dans `restartPlaybackWithSubtitles()`.

**Solution :** Vérifier l'appel dans la fonction de redémarrage.

### Bug 3 : Crash lors du changement

**Symptôme :** L'app crash quand on change de sous-titres.

**Cause probable :** Référence faible (`weak self`) devenue nil.

**Solution :** Ajouter `guard let self = self else { return }` dans les closures.

### Bug 4 : Pas de redémarrage

**Symptôme :** On sélectionne une piste mais rien ne se passe.

**Cause probable :** `playerCoordinator.onSubtitleChange` n'est pas défini.

**Solution :** Vérifier que le coordinator est configuré avant le menu.

### Bug 5 : Checkmark sur mauvaise piste

**Symptôme :** Le checkmark est sur "English" alors que "Français" est actif.

**Cause probable :** `selectedSubtitleIndex` pas synchronisé avec l'index réel.

**Solution :** Vérifier les logs pour voir l'index actuel vs affiché.

---

## 🔍 Vérifications supplémentaires

### Console Xcode

Pendant les tests, surveillez :
- ✅ Pas d'erreurs ou de warnings
- ✅ Logs `configureSubtitleMenu` apparaissent
- ✅ Logs `restartPlaybackWithSubtitles` lors des changements
- ✅ Index des sous-titres cohérents

### Performance

- ✅ Temps de redémarrage < 3 secondes
- ✅ Pas de freeze de l'interface
- ✅ Fluidité de navigation dans le menu

### Mémoire

- ✅ Pas de fuite mémoire (utiliser Instruments si nécessaire)
- ✅ L'app ne crash pas après plusieurs changements

---

## ✅ Critères de validation

Pour que la feature soit considérée comme **validée**, il faut :

- ✅ **10/10 tests réussis**
- ✅ Aucun crash observé
- ✅ Logs cohérents dans la console
- ✅ Checkmark toujours sur la bonne piste
- ✅ Sous-titres affichés correspondent au menu
- ✅ Auto-sélection fonctionne correctement
- ✅ Redémarrages fluides (< 3s)

---

## 📝 Rapport de test

### Testeur

**Nom :** _________________________

**Date :** _________________________

### Environnement

- **Plateforme :** tvOS ___.___ (simulateur / device réel)
- **Version xfinn :** _________
- **Serveur Jellyfin :** Version _________

### Résultats

| Test | Résultat | Notes |
|------|----------|-------|
| 1 | ⬜ ✅ ❌ | |
| 2 | ⬜ ✅ ❌ | |
| 3 | ⬜ ✅ ❌ | |
| 4 | ⬜ ✅ ❌ | |
| 5 | ⬜ ✅ ❌ | |
| 6 | ⬜ ✅ ❌ | |
| 7 | ⬜ ✅ ❌ | |
| 8 | ⬜ ✅ ❌ | |
| 9 | ⬜ ✅ ❌ | |
| 10 | ⬜ ✅ ❌ | |

### Bugs trouvés

1. _____________________________________________
2. _____________________________________________
3. _____________________________________________

### Conclusion

⬜ **Validé** - Prêt pour production
⬜ **À corriger** - Bugs mineurs à résoudre
⬜ **Bloquant** - Bugs critiques, ne pas déployer

### Commentaires

___________________________________________________
___________________________________________________
___________________________________________________

---

**Plan de test créé le 22 décembre 2024**
