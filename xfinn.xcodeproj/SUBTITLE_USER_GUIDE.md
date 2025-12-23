# 📺 Guide utilisateur - Gestion des sous-titres

## Comment utiliser les sous-titres dans xfinn

---

## 🎯 Deux façons de gérer les sous-titres

### 1️⃣ Avant de lancer la vidéo (Toutes plateformes)

Sur la page de détails de l'épisode ou du film :

1. Repérez le bouton **💬 Sous-titres** à côté du bouton de qualité
2. Cliquez dessus
3. Choisissez la piste de sous-titres souhaitée
4. Lancez la lecture → Les sous-titres s'afficheront automatiquement

**Avantage :** Votre choix est mémorisé pour les prochaines vidéos !

### 2️⃣ Pendant la lecture (tvOS uniquement)

Pendant que la vidéo joue :

1. Appuyez sur **Menu** ou **Play/Pause** sur la télécommande
2. Le menu du player s'affiche
3. Sélectionnez **Sous-titres** (icône 💬)
4. Choisissez la piste souhaitée
5. La vidéo redémarre brièvement avec les nouveaux sous-titres

**Avantage :** Pas besoin de quitter le player !

---

## 🎨 Indicateurs visuels

### Sur la page de détails

Le bouton de sous-titres change d'apparence selon votre sélection :

| État | Apparence | Signification |
|------|-----------|---------------|
| **Aucun sous-titre** | 💬 "Aucun" (grisé) | Pas de sous-titres actifs |
| **Sous-titre sélectionné** | 💬 "Français" (bleu) | Sous-titres français actifs |

### Dans le menu du player (tvOS)

Un **checkmark ✓** indique la piste actuellement active :

```
Sous-titres
├─   Aucun
├─ ✓ Français          ← Piste active
└─   English
```

---

## 🔄 Auto-sélection des sous-titres

### Comment ça fonctionne ?

Quand vous sélectionnez une piste de sous-titres, **l'application mémorise votre langue préférée**.

**Exemple :**
1. Vous regardez un épisode et choisissez "Français"
2. Vous passez à l'épisode suivant
3. → Les sous-titres français sont **automatiquement sélectionnés** ! ✨

### Pour changer de langue par défaut

1. Ouvrez n'importe quelle vidéo
2. Sélectionnez une nouvelle langue de sous-titres
3. → Cette langue devient votre nouveau choix par défaut

### Pour désactiver l'auto-sélection

1. Ouvrez les sous-titres
2. Choisissez **"Aucun"**
3. → Les prochaines vidéos n'auront pas de sous-titres automatiquement

---

## 🎮 Raccourcis tvOS

| Action | Bouton télécommande |
|--------|---------------------|
| Ouvrir le menu du player | **Menu** ou **Play/Pause** |
| Naviguer dans le menu | **↑ ↓** |
| Sélectionner | **Touch surface** (clic) |
| Fermer le menu | **Menu** |

---

## ⚙️ Types de sous-titres

Votre bibliothèque Jellyfin peut contenir différents types de sous-titres :

### Sous-titres normaux

Les pistes classiques que vous pouvez activer/désactiver.

**Exemples :**
- "Français"
- "English"
- "Español"

### Sous-titres forcés

Affichent uniquement les dialogues en langue étrangère (par exemple, quand un personnage parle une autre langue).

**Exemples :**
- "Français (forcé)"
- "English (forced)"

⚠️ Les sous-titres forcés sont généralement destinés à des situations spécifiques et ne traduisent pas tous les dialogues.

### Sous-titres par défaut

Certains médias ont une piste marquée comme "par défaut" par le serveur Jellyfin.

Si vous n'avez **pas de langue préférée configurée**, cette piste sera sélectionnée automatiquement.

---

## ⏱ Pourquoi la vidéo redémarre-t-elle ?

Quand vous changez de sous-titres **pendant la lecture**, vous remarquerez que :

1. La vidéo **s'arrête** brièvement
2. Elle **redémarre** à la même position
3. Les nouveaux sous-titres apparaissent

### Pourquoi ?

L'application utilise une technologie appelée **"burn-in"** qui intègre les sous-titres directement dans le flux vidéo. Cela garantit :

✅ Compatibilité maximale avec tous les formats
✅ Synchronisation parfaite audio/sous-titres
✅ Meilleure performance

Pour changer de sous-titres, il faut **générer un nouveau flux vidéo**, d'où le redémarrage.

**Durée typique :** 1-2 secondes

---

## 📖 Langues disponibles

Les langues de sous-titres disponibles dépendent de votre **bibliothèque Jellyfin**.

### Comment ajouter des sous-titres ?

1. Connectez-vous à **Jellyfin Web** (via navigateur)
2. Ouvrez le média souhaité
3. Cliquez sur **"Modifier"**
4. Allez dans **"Sous-titres"**
5. Uploadez un fichier `.srt`, `.vtt` ou `.ass`

Les nouveaux sous-titres apparaîtront automatiquement dans xfinn !

---

## 🐛 Problèmes courants

### Les sous-titres ne s'affichent pas

**Vérifications :**
1. Avez-vous bien **sélectionné** une piste ?
2. Le bouton de sous-titres affiche-t-il la bonne piste ?
3. Le média a-t-il vraiment des sous-titres ? (vérifiez sur Jellyfin Web)

**Solution :**
- Retournez à la page de détails
- Sélectionnez à nouveau la piste
- Relancez la lecture

### Les sous-titres sont décalés

**Cause possible :** Fichier de sous-titres mal synchronisé dans votre bibliothèque Jellyfin.

**Solution :**
- Vérifiez le fichier de sous-titres dans Jellyfin Web
- Remplacez-le par un fichier mieux synchronisé si nécessaire

### Le bouton de sous-titres est absent

**Cause :** Le média n'a pas de sous-titres.

**Solution :**
- Ajoutez des sous-titres via Jellyfin Web (voir section ci-dessus)

### La vidéo redémarre toujours au début

**Cause possible :** Problème de connectivité avec le serveur Jellyfin.

**Solution :**
- Vérifiez votre connexion réseau
- Vérifiez que le serveur Jellyfin est accessible

---

## 💡 Astuces

### Astuce 1 : Configurer votre langue une fois pour toutes

1. Ouvrez n'importe quelle vidéo
2. Sélectionnez votre langue préférée (ex: "Français")
3. → Toutes les vidéos suivantes auront les sous-titres français automatiquement !

### Astuce 2 : Changer rapidement pendant la lecture (tvOS)

Au lieu de quitter le player :
1. Appuyez sur **Menu**
2. Sélectionnez **Sous-titres**
3. Choisissez la nouvelle piste
4. → La vidéo redémarre en ~2 secondes

### Astuce 3 : Pas besoin de sous-titres pour un film en particulier ?

1. Ouvrez les sous-titres
2. Sélectionnez **"Aucun"**
3. Lancez la lecture
4. → Le film suivant aura de nouveau vos sous-titres par défaut (la préférence est conservée)

---

## 📊 Comparaison des méthodes

| Aspect | Avant la lecture | Pendant la lecture (tvOS) |
|--------|------------------|---------------------------|
| **Plateformes** | iOS, iPadOS, tvOS | tvOS uniquement |
| **Facilité** | 🟢 Simple | 🟡 Nécessite le menu |
| **Rapidité** | 🟢 Instantané | 🟡 Redémarrage ~2s |
| **Feedback** | 🟢 Bouton change de couleur | 🟢 Checkmark dans le menu |

---

## ❓ FAQ

### Q: Les sous-titres fonctionnent-ils hors ligne ?

**R:** Non, xfinn nécessite une connexion au serveur Jellyfin pour charger les sous-titres. Assurez-vous d'être connecté.

### Q: Puis-je ajuster la taille ou la couleur des sous-titres ?

**R:** Ces paramètres dépendent du serveur Jellyfin et du format des sous-titres. Vous pouvez les configurer dans Jellyfin Web.

### Q: Combien de pistes de sous-titres puis-je avoir ?

**R:** Autant que vous le souhaitez ! Il n'y a pas de limite dans xfinn. Toutes les pistes disponibles dans Jellyfin apparaîtront.

### Q: Les sous-titres consomment-ils plus de bande passante ?

**R:** Non, les sous-titres sont des fichiers texte très légers (quelques Ko). L'impact sur la bande passante est négligeable.

### Q: Puis-je utiliser des sous-titres personnalisés ?

**R:** Oui ! Uploadez vos fichiers `.srt` ou `.vtt` via Jellyfin Web, et ils apparaîtront automatiquement dans xfinn.

---

## 📱 Support par plateforme

| Fonctionnalité | iOS | iPadOS | tvOS |
|----------------|-----|--------|------|
| Sélection avant lecture | ✅ | ✅ | ✅ |
| Sélection pendant lecture | ❌ | ❌ | ✅ |
| Auto-sélection | ✅ | ✅ | ✅ |
| Mémorisation langue | ✅ | ✅ | ✅ |
| Indicateurs visuels | ✅ | ✅ | ✅ |

---

## 🎬 Prêt à regarder avec des sous-titres ?

1. Ouvrez une vidéo
2. Cliquez sur 💬 **Sous-titres**
3. Choisissez votre langue
4. Appuyez sur **Lire**
5. Profitez ! 🍿

---

*Guide utilisateur - Mise à jour du 22 décembre 2024*
