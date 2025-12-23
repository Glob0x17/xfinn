# 🔀 Guide Git pour la Réorganisation

## 📋 Commandes Git Essentielles

### Avant de Commencer

#### 1. Sauvegarder l'État Actuel
```bash
# Vérifier qu'il n'y a pas de modifications non commitées
git status

# Si des modifications existent, les commiter
git add .
git commit -m "chore: Save work before reorganization"

# Créer une branche de sauvegarde (au cas où)
git branch backup-before-reorganization

# Créer une branche pour la réorganisation
git checkout -b refactor/project-structure
```

### Pendant la Réorganisation

#### 2. Vérifier les Changements
```bash
# Voir tous les fichiers modifiés/déplacés
git status

# Voir les détails des changements
git diff

# Voir les fichiers renommés (Git devrait les détecter)
git status -s
```

#### 3. Si Git ne Détecte pas les Renames Automatiquement
```bash
# Forcer Git à détecter les renames
git add -A

# Vérifier que les renames sont détectés
git status
# Devrait montrer "renamed:" au lieu de "deleted:" et "new file:"
```

### Après la Réorganisation

#### 4. Commiter les Changements
```bash
# Ajouter tous les changements
git add .

# Commiter avec un message descriptif
git commit -m "refactor: Reorganize project structure

- Create feature-based folder structure
- Split Extensions.swift into separate files
- Add AppTheme for centralized styling
- Extract shared components (LoadingView, ErrorView, EmptyContentView)
- Move documentation files to Documentation folder
- Organize by App/Core/Features/Shared structure"
```

#### 5. Vérifier que Tout Fonctionne
```bash
# Compiler le projet dans Xcode (⌘+B)
# Si tout compile et fonctionne :

# Merger dans main
git checkout main
git merge refactor/project-structure

# Pousser vers le remote
git push origin main

# Supprimer la branche de refactoring (optionnel)
git branch -d refactor/project-structure
```

---

## 🔍 Commandes de Vérification

### Voir l'Historique des Renames
```bash
# Afficher l'historique avec les renames
git log --follow --oneline -- <nom_du_fichier>

# Exemple pour NextEpisodeOverlay.swift
git log --follow --oneline -- NextEpisodeOverlay.swift
```

### Voir les Statistiques du Commit
```bash
# Nombre de fichiers modifiés, ajoutés, supprimés
git diff --stat HEAD~1

# Version détaillée
git show --stat
```

### Comparer Avant/Après
```bash
# Comparer avec le commit précédent
git diff HEAD~1

# Voir uniquement les noms de fichiers changés
git diff --name-only HEAD~1

# Voir les renames
git diff --name-status HEAD~1
```

---

## 🚨 En Cas de Problème

### Annuler Tous les Changements (DANGER !)
```bash
# ATTENTION : Ceci supprime TOUS les changements non commités
git reset --hard HEAD

# Ou retourner à la branche de sauvegarde
git checkout backup-before-reorganization
```

### Annuler le Dernier Commit (mais garder les changements)
```bash
git reset --soft HEAD~1
```

### Annuler le Dernier Commit (et supprimer les changements)
```bash
# DANGER : Supprime définitivement les changements
git reset --hard HEAD~1
```

### Restaurer un Fichier Spécifique
```bash
# Restaurer un fichier depuis le dernier commit
git checkout HEAD -- <nom_du_fichier>

# Exemple
git checkout HEAD -- Extensions.swift
```

---

## 📊 Message de Commit Recommandé

### Format Standard
```
refactor: Reorganize project structure

- Create modular folder structure (App/Core/Features/Shared)
- Split Extensions.swift into domain-specific extension files
- Add AppTheme.swift for centralized design system
- Extract shared components (LoadingView, ErrorView, EmptyContentView)
- Move NextEpisodeOverlay to Features/Media/Components
- Move NavigationCoordinator to Core/Coordinators
- Organize documentation in Documentation folder

Breaking changes: None
All functionality preserved, only structure improved.
```

### Format Court (si vous préférez)
```
refactor: Reorganize codebase into feature-based structure

Improved project organization for better maintainability
and scalability. No functional changes.
```

---

## 🎯 Bonnes Pratiques Git

### 1. Commiter Fréquemment
```bash
# Après avoir créé les groupes
git add .
git commit -m "refactor: Create folder structure"

# Après avoir ajouté les nouveaux fichiers
git add Shared/Extensions/*.swift Shared/Theme/AppTheme.swift Shared/Components/*.swift
git commit -m "refactor: Add split extension files and theme"

# Après avoir déplacé les fichiers existants
git add -A
git commit -m "refactor: Move files to feature folders"

# Après avoir supprimé l'ancien Extensions.swift
git rm Extensions.swift
git commit -m "refactor: Remove old monolithic Extensions file"
```

### 2. Utiliser des Branches
```bash
# Toujours travailler sur une branche
git checkout -b refactor/project-structure

# Jamais directement sur main (sauf si vous êtes seul)
```

### 3. Vérifier Avant de Pousser
```bash
# Voir ce qui va être poussé
git log origin/main..HEAD

# Tester l'app une dernière fois
# Compiler dans Xcode
# Lancer l'app et vérifier les fonctionnalités
```

---

## 📈 Visualiser les Changements

### Outils Graphiques

#### Dans Terminal
```bash
# Visualiser l'arborescence des commits
git log --graph --oneline --all

# Avec plus de détails
git log --graph --decorate --all
```

#### Dans Xcode
1. Ouvrir le Source Control Navigator (⌘+2)
2. Cliquer sur "main" ou votre branche
3. Voir l'historique visuel des commits

#### Outils Externes (optionnel)
- **GitKraken** : Interface graphique moderne
- **SourceTree** : Client Git visuel gratuit
- **GitHub Desktop** : Simple et intégré avec GitHub

---

## ✅ Checklist Git Complète

### Avant
- [ ] `git status` → Tout est clean
- [ ] `git branch backup-before-reorganization` → Backup créé
- [ ] `git checkout -b refactor/project-structure` → Branche créée

### Pendant
- [ ] Modifications effectuées dans Xcode
- [ ] `git status` → Vérifier les changements
- [ ] `git add -A` → Ajouter tous les changements

### Après
- [ ] Xcode compile sans erreur (⌘+B)
- [ ] App fonctionne correctement
- [ ] `git status` → Vérifier que tout est staged
- [ ] `git commit -m "..."` → Commit avec message descriptif
- [ ] `git checkout main` → Retour sur main
- [ ] `git merge refactor/project-structure` → Merger
- [ ] `git push origin main` → Pousser vers remote

---

## 🎓 Comprendre les Renames dans Git

### Comment Git Détecte les Renames

Git détecte automatiquement les renames si :
1. **Le contenu du fichier est presque identique** (>50% de similitude)
2. **Vous utilisez `git add -A`** au lieu de `git add .`

### Exemple de Sortie
```bash
# Mauvais (Git pense que c'est suppression + création)
deleted:    Extensions.swift
new file:   Shared/Extensions/View+Extensions.swift

# Bon (Git détecte le rename)
renamed:    Extensions.swift -> Shared/Extensions/View+Extensions.swift
```

### Forcer la Détection
```bash
# Si Git ne détecte pas automatiquement
git add -A

# Ou configurer Git pour être plus sensible
git config diff.renamelimit 999999
```

---

## 💡 Conseils Professionnels

### 1. Toujours Faire un Backup
```bash
# Créer un tag avant la réorganisation
git tag before-reorganization
git tag -a v1.0-pre-refactor -m "Before project reorganization"
```

### 2. Tester Après Chaque Étape
Ne faites pas tout d'un coup. Testez régulièrement.

### 3. Documenter le Pourquoi
Dans le message de commit, expliquez pourquoi vous réorganisez.

### 4. Communiquer avec l'Équipe
Si vous travaillez en équipe, prévenez-les de la réorganisation majeure.

---

## 🔗 Ressources Git

- [Git Documentation Officielle](https://git-scm.com/doc)
- [Git Rename Detection](https://git-scm.com/docs/git-diff#Documentation/git-diff.txt--Mltngt)
- [Pro Git Book (gratuit)](https://git-scm.com/book/en/v2)

---

*N'oubliez pas : Git est votre filet de sécurité. Utilisez-le ! 🚀*
