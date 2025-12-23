# Guide de test - Sous-titres

## ✅ Tests à effectuer

### 1. Test de sélection de base

**Étapes :**
1. Ouvrir une vidéo qui contient des sous-titres
2. Vérifier que le bouton "Sous-titres" apparaît à côté du sélecteur de qualité
3. Cliquer sur le bouton
4. Vérifier que toutes les pistes disponibles sont listées
5. Sélectionner une piste
6. Vérifier que le bouton affiche maintenant le nom de la piste
7. Lancer la lecture
8. Vérifier que les sous-titres apparaissent

**Résultat attendu :**
- ✅ Le bouton change d'apparence (icône remplie, couleur primaire)
- ✅ Le nom de la piste est affiché sur le bouton
- ✅ Les sous-titres sont visibles pendant la lecture

### 2. Test d'auto-sélection

**Étapes :**
1. Sélectionner des sous-titres dans une langue (ex: Français)
2. Quitter la vidéo
3. Ouvrir une autre vidéo qui a aussi des sous-titres français
4. Vérifier que les sous-titres français sont automatiquement sélectionnés

**Résultat attendu :**
- ✅ Les sous-titres sont pré-sélectionnés
- ✅ Le bouton affiche déjà le nom de la piste
- ✅ Pas besoin de re-sélectionner manuellement

### 3. Test de désactivation

**Étapes :**
1. Sélectionner des sous-titres
2. Cliquer à nouveau sur le bouton
3. Sélectionner "Aucun"
4. Vérifier que le bouton affiche "Aucun"
5. Lancer la lecture
6. Vérifier qu'aucun sous-titre n'apparaît

**Résultat attendu :**
- ✅ Le bouton revient à son état initial
- ✅ Aucun sous-titre n'est affiché
- ✅ La préférence est supprimée

### 4. Test de persistance

**Étapes :**
1. Sélectionner une langue de sous-titres
2. Fermer complètement l'application
3. Rouvrir l'application
4. Naviguer vers une vidéo avec sous-titres

**Résultat attendu :**
- ✅ La langue préférée est toujours sauvegardée
- ✅ Les sous-titres sont automatiquement sélectionnés

### 5. Test sans sous-titres

**Étapes :**
1. Ouvrir une vidéo qui n'a pas de sous-titres
2. Vérifier que le bouton de sous-titres n'apparaît pas

**Résultat attendu :**
- ✅ Le bouton est caché
- ✅ Pas d'erreur affichée

### 6. Test des contrôles natifs

**Sur tvOS uniquement**

**Étapes :**
1. Lancer une vidéo
2. Pendant la lecture, appuyer sur le bouton Menu de la télécommande
3. Naviguer vers "Audio et sous-titres"
4. Vérifier que les pistes sont listées

**Résultat attendu :**
- ✅ Les sous-titres sont disponibles dans les contrôles natifs
- ✅ Le changement de piste fonctionne en temps réel

## 🐛 Problèmes potentiels et solutions

### Problème : Les sous-titres ne s'affichent pas

**Causes possibles :**
1. Format de sous-titres non supporté par AVPlayer
2. URL du sous-titre incorrecte
3. Erreur réseau lors du chargement

**Solution :**
- Vérifier les logs de la console pour voir les messages de debug
- Chercher : `"📝 Chargement des sous-titres depuis"` et `"✅ Piste de sous-titres externe chargée"`
- Si l'URL est correcte, vérifier que le serveur Jellyfin renvoie bien le fichier VTT

### Problème : L'auto-sélection ne fonctionne pas

**Causes possibles :**
1. La langue dans les métadonnées ne correspond pas exactement
2. UserDefaults n'est pas sauvegardé correctement

**Solution :**
- Vérifier les logs : `"✅ Langue de sous-titres préférée sauvegardée"`
- Vérifier que la langue est bien enregistrée : 
  ```swift
  print(UserDefaults.standard.string(forKey: "preferredSubtitleLanguage") ?? "Aucune")
  ```

### Problème : Le bouton n'apparaît pas

**Causes possibles :**
1. Le média n'a pas de sous-titres
2. Les métadonnées ne sont pas chargées correctement

**Solution :**
- Vérifier que `item.subtitleStreams` n'est pas vide
- Vérifier que le champ `MediaStreams` est bien inclus dans la requête API

### Problème : Crash lors de la sélection

**Causes possibles :**
1. Index de sous-titre invalide
2. Problème de synchronisation avec AVPlayer

**Solution :**
- Vérifier que l'index sélectionné existe bien dans `item.subtitleStreams`
- S'assurer que le player est dans l'état `readyToPlay` avant d'activer les sous-titres

## 📊 Métriques de succès

- [ ] Les sous-titres s'affichent correctement pour au moins 95% des vidéos
- [ ] L'auto-sélection fonctionne dans 100% des cas où une langue préférée est définie
- [ ] Aucun crash lié aux sous-titres
- [ ] Temps de chargement des sous-titres < 2 secondes
- [ ] Les sous-titres sont synchronisés avec l'audio (pas de décalage)

## 🎯 Checklist finale

Avant de considérer l'implémentation terminée :

- [ ] Tous les tests ci-dessus passent
- [ ] Les logs de debug sont propres (pas d'erreurs)
- [ ] L'interface est cohérente avec le reste de l'app
- [ ] La documentation est à jour
- [ ] Les commentaires dans le code sont clairs
- [ ] Aucune régression sur les fonctionnalités existantes
- [ ] Testé sur tvOS (plateforme principale)
- [ ] Testé avec différentes langues de sous-titres
- [ ] Testé avec des vidéos sans sous-titres
- [ ] Testé l'auto-sélection avec plusieurs vidéos

## 📝 Notes de test

**Vidéos de test recommandées :**
- Une vidéo avec plusieurs pistes de sous-titres (3+)
- Une vidéo avec sous-titres forcés uniquement
- Une vidéo sans sous-titres
- Une vidéo avec sous-titres dans une langue rare

**Environnements de test :**
- tvOS 17.0+
- iOS 17.0+ (si supporté)
- Avec et sans connexion rapide
- Serveur Jellyfin 10.8+

---

*Ce document doit être mis à jour après chaque session de test avec les résultats obtenus.*
