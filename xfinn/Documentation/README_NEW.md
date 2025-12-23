# 🎬 xfinn - Client Jellyfin pour tvOS

Client Jellyfin natif pour Apple TV, développé en SwiftUI.

---

## 🚨 RÉORGANISATION DU PROJET EN COURS

### 📋 Début Rapide

Ce projet est en cours de réorganisation pour améliorer sa structure et sa maintenabilité.

**👉 Commencez par lire : [`START_HERE.md`](START_HERE.md)**

### 📚 Documentation de Réorganisation

| Fichier | Description | Temps |
|---------|-------------|-------|
| **[START_HERE.md](START_HERE.md)** | 🎯 Point de départ - Résumé ultra-simple | 2 min |
| **[VISUAL_ARCHITECTURE.md](VISUAL_ARCHITECTURE.md)** | 🏗️ Architecture visuelle avant/après | 5 min |
| **[QUICK_REORGANIZATION_GUIDE.md](QUICK_REORGANIZATION_GUIDE.md)** | ⚡ Guide pratique de réorganisation | 30 min |
| **[REORGANIZATION_SUMMARY.md](REORGANIZATION_SUMMARY.md)** | 📊 Vue d'ensemble détaillée | 10 min |
| **[REORGANIZATION_CHECKLIST.md](REORGANIZATION_CHECKLIST.md)** | ✅ Checklist imprimable | - |
| **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** | 🗂️ Index de toute la documentation | 5 min |

---

## 📁 Structure Actuelle

```
xfinn/
├── Tous les fichiers à la racine (à réorganiser)
└── Documentation de réorganisation créée
```

## 🎯 Structure Cible

```
xfinn/
├── App/              # Point d'entrée
├── Core/             # Services, Modèles, Coordinateurs
├── Features/         # Fonctionnalités (Auth, Home, Library, Series, Media)
├── Shared/           # Composants, Thème, Extensions
└── Documentation/    # Toute la doc technique
```

**Détails complets :** [`VISUAL_ARCHITECTURE.md`](VISUAL_ARCHITECTURE.md)

---

## ✨ Fonctionnalités

- ✅ Connexion à un serveur Jellyfin
- ✅ Authentification utilisateur
- ✅ Navigation dans les bibliothèques
- ✅ Lecture de films et séries
- ✅ Reprise de lecture
- ✅ Progression synchronisée
- ✅ Lecture automatique de l'épisode suivant
- ✅ Interface optimisée tvOS

---

## 🛠️ Technologies

- **SwiftUI** - Interface utilisateur
- **Combine** - Gestion de l'état
- **AVFoundation** - Lecture vidéo
- **URLSession** - Appels API
- **UserDefaults** - Persistance locale
- **Swift Concurrency** - Async/await

---

## 📱 Configuration Requise

- tvOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Serveur Jellyfin accessible

---

## 🚀 Installation

### 1. Cloner le Projet
```bash
git clone [votre-repo-url]
cd xfinn
```

### 2. Ouvrir dans Xcode
```bash
open xfinn.xcodeproj
```

### 3. (Optionnel) Réorganiser le Projet
Suivez le guide [`QUICK_REORGANIZATION_GUIDE.md`](QUICK_REORGANIZATION_GUIDE.md) pour mettre en place la nouvelle structure.

### 4. Compiler et Lancer
- Sélectionnez le simulateur Apple TV
- Appuyez sur ⌘+R

---

## 📖 Documentation

### Documentation Générale
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architecture globale de l'application
- **[BUILD_STATUS.md](BUILD_STATUS.md)** - État du build et fonctionnalités
- **[FUTURE_IMPROVEMENTS.md](FUTURE_IMPROVEMENTS.md)** - Améliorations prévues

### Documentation de Réorganisation
- **[START_HERE.md](START_HERE.md)** - Point de départ
- **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** - Index complet
- **[VISUAL_ARCHITECTURE.md](VISUAL_ARCHITECTURE.md)** - Vue visuelle

### Guides Techniques
- **[NAVIGATION_FIX.md](NAVIGATION_FIX.md)** - Correctifs de navigation
- **[SUBTITLE_CODE_EXAMPLES.md](SUBTITLE_CODE_EXAMPLES.md)** - Exemples sous-titres
- **[USERDEFAULTS_KEYS.md](USERDEFAULTS_KEYS.md)** - Clés UserDefaults
- **[JELLYFIN_URL_NORMALIZATION.md](JELLYFIN_URL_NORMALIZATION.md)** - Normalisation URLs

---

## 🤝 Contribution

### Avant de Contribuer

1. **Lisez la documentation de réorganisation** (surtout si le projet n'est pas encore réorganisé)
2. Familiarisez-vous avec l'architecture dans [`ARCHITECTURE.md`](ARCHITECTURE.md)
3. Suivez les conventions Swift et tvOS

### Workflow

1. Fork le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Pushez vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

---

## 📝 TODO

### Haute Priorité
- [ ] **Réorganiser le projet** (suivre QUICK_REORGANIZATION_GUIDE.md)
- [ ] Créer les README.md dans chaque dossier Features
- [ ] Ajouter des tests unitaires par feature

### Moyenne Priorité
- [ ] Support des sous-titres
- [ ] Sélection de qualité de streaming
- [ ] Interface de recherche
- [ ] Support de la musique

### Basse Priorité
- [ ] Thèmes personnalisables
- [ ] Multi-profils
- [ ] Téléchargement hors ligne

**Liste complète :** [`FUTURE_IMPROVEMENTS.md`](FUTURE_IMPROVEMENTS.md)

---

## 🐛 Problèmes Connus

Aucun problème critique connu actuellement.

Pour rapporter un bug, ouvrez une issue sur GitHub.

---

## 📜 Licence

[Votre licence ici]

---

## 👨‍💻 Auteur

**Dorian Galiana**

Créé le 23 novembre 2025
Réorganisation proposée le 23 décembre 2025

---

## 🙏 Remerciements

- **Jellyfin** - Pour l'excellente plateforme de streaming
- **Apple** - Pour SwiftUI et les outils de développement tvOS

---

## 📞 Support

Pour toute question :
1. Consultez la [documentation](DOCUMENTATION_INDEX.md)
2. Cherchez dans les [issues GitHub](votre-repo-url/issues)
3. Ouvrez une nouvelle issue

---

## ⭐ Star History

Si ce projet vous aide, n'oubliez pas de lui donner une étoile ! ⭐

---

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🎬 xfinn - Votre Jellyfin sur Apple TV                     ║
║                                                               ║
║   Développé avec ❤️ en SwiftUI                               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

**Note Importante :** Ce projet est en cours de réorganisation pour améliorer sa structure. 
Consultez [`START_HERE.md`](START_HERE.md) pour commencer !
