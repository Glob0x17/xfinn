# Guide de démarrage rapide - xfinn

## 🚀 Installation et configuration

### Prérequis

1. **Serveur Jellyfin** : Assurez-vous d'avoir un serveur Jellyfin en cours d'exécution
   - Version recommandée : Jellyfin 10.8 ou supérieure
   - Le serveur doit être accessible depuis votre réseau local

2. **Apple TV** : Un appareil Apple TV avec tvOS 17.0 ou supérieur

3. **Xcode** : Xcode 15 ou supérieur pour compiler l'application

### Configuration du serveur Jellyfin

Si vous n'avez pas encore de serveur Jellyfin :

1. Téléchargez Jellyfin depuis [jellyfin.org](https://jellyfin.org)
2. Installez-le sur un ordinateur ou NAS de votre réseau local
3. Configurez vos bibliothèques de médias
4. Créez un compte utilisateur

### Installation de l'application

1. Ouvrez le projet dans Xcode
2. Sélectionnez votre Apple TV comme destination
3. Cliquez sur "Run" (▶️) ou appuyez sur Cmd+R
4. L'application sera installée automatiquement sur votre Apple TV

## 📱 Première utilisation

### Connexion au serveur

1. Lancez xfinn sur votre Apple TV
2. Sur l'écran de connexion, entrez l'URL de votre serveur :
   ```
   Exemples d'URL valides :
   http://192.168.1.100:8096
   http://monserveur.local:8096
   https://jellyfin.example.com
   ```

3. Cliquez sur "Continuer"
4. Si la connexion réussit, vous verrez l'écran d'authentification

### Authentification

1. Entrez votre nom d'utilisateur Jellyfin
2. Entrez votre mot de passe (laissez vide si aucun mot de passe)
3. Cliquez sur "Se connecter"

✅ Vos identifiants seront sauvegardés pour les prochaines sessions !

## 🎬 Utilisation de l'application

### Page d'accueil

La page d'accueil affiche :
- **À reprendre** : Les vidéos que vous avez commencées
- **Récemment ajoutés** : Les derniers médias ajoutés à votre serveur
- **Toutes les bibliothèques** : Accès à toutes vos bibliothèques

### Navigation

#### Avec la télécommande Siri Remote :
- **Pavé tactile** : Naviguez entre les éléments
- **Clic** : Sélectionner un élément
- **Menu/Retour** : Revenir en arrière
- **Play/Pause** : Contrôler la lecture vidéo
- **Glissement** : Avancer/reculer pendant la lecture

#### Navigation dans les bibliothèques :
1. Sélectionnez une bibliothèque sur la page d'accueil
2. Parcourez les médias disponibles
3. Sélectionnez un film ou une série

#### Pour les séries TV :
1. Sélectionnez une série
2. Choisissez une saison
3. Sélectionnez un épisode
4. Profitez !

### Lecture de vidéos

1. Sélectionnez un média
2. Sur la page de détails, vous verrez :
   - Poster et image de fond
   - Synopsis
   - Note communautaire
   - Durée
   - Progression (si déjà commencé)

3. Cliquez sur le bouton **"Lire"** (ou **"Revoir"**)
4. La vidéo démarre automatiquement
5. Si vous aviez déjà commencé la vidéo, elle reprend à la dernière position

### Fonctionnalités de lecture

- ✅ **Reprise automatique** : Reprenez exactement où vous vous étiez arrêté
- ✅ **Synchronisation** : La progression est sauvegardée sur le serveur
- ✅ **Lecture native** : Utilise le lecteur vidéo natif d'Apple TV
- ✅ **Contrôles standards** : Play, pause, avance rapide, retour rapide

## 🔧 Paramètres

Pour accéder aux paramètres (fonctionnalité à venir) :
- Informations sur le serveur
- Informations sur l'utilisateur
- Version de l'application
- Se déconnecter

### Se déconnecter

Pour vous déconnecter :
1. Allez sur la page d'accueil
2. Appuyez sur le bouton power (⚡️) en haut à droite
3. Confirmez la déconnexion

## 🐛 Résolution des problèmes

### Impossible de se connecter au serveur

**Problème** : "Impossible de se connecter au serveur"

**Solutions** :
1. Vérifiez que votre serveur Jellyfin est en cours d'exécution
2. Vérifiez l'URL du serveur (doit inclure http:// ou https://)
3. Vérifiez que votre Apple TV est sur le même réseau
4. Testez l'URL dans Safari sur un autre appareil
5. Vérifiez que le pare-feu n'bloque pas la connexion

### Échec de l'authentification

**Problème** : "Échec de l'authentification"

**Solutions** :
1. Vérifiez votre nom d'utilisateur (sensible à la casse)
2. Vérifiez votre mot de passe
3. Essayez de vous connecter via l'interface web Jellyfin
4. Vérifiez que votre compte n'est pas désactivé

### La vidéo ne se charge pas

**Problème** : La vidéo ne démarre pas ou se bloque

**Solutions** :
1. Vérifiez votre connexion réseau
2. Le format vidéo est peut-être incompatible (essayez un autre média)
3. Vérifiez les logs du serveur Jellyfin
4. Redémarrez l'application

### Pas d'image/poster

**Problème** : Les images ne s'affichent pas

**Solutions** :
1. Les métadonnées ne sont peut-être pas téléchargées sur le serveur
2. Actualisez les métadonnées dans Jellyfin
3. Vérifiez la connexion réseau

## 📊 Formats supportés

### Vidéo
L'application utilise AVPlayer natif d'Apple TV, qui supporte :
- MP4 (H.264, H.265/HEVC)
- MOV (QuickTime)
- M4V
- Et tous les formats supportés par tvOS

### Audio
- AAC
- MP3
- Dolby Digital (AC-3)
- Dolby Digital Plus (E-AC-3)
- Dolby Atmos (si compatible)

### Notes
- Le transcodage est géré par le serveur Jellyfin
- Si un format n'est pas supporté nativement, Jellyfin le transcodera automatiquement

## 💡 Astuces

1. **Réseau local** : Pour de meilleures performances, utilisez une connexion Ethernet sur votre Apple TV
2. **Qualité vidéo** : Ajustez les paramètres de qualité dans Jellyfin selon votre bande passante
3. **Organisation** : Organisez bien vos bibliothèques Jellyfin pour une meilleure expérience
4. **Métadonnées** : Assurez-vous que les métadonnées sont téléchargées pour tous vos médias

## 🔄 Mises à jour

Pour mettre à jour l'application :
1. Récupérez la dernière version du code
2. Recompilez dans Xcode
3. L'application sera automatiquement mise à jour sur votre Apple TV

## 📝 Notes importantes

- L'application nécessite une connexion réseau permanente
- Les mots de passe ne sont jamais stockés localement
- Seul le token d'accès est sauvegardé
- La progression de lecture est synchronisée avec le serveur

## 🆘 Support

Pour toute question ou problème :
1. Vérifiez d'abord ce guide
2. Consultez les logs de l'application dans Xcode
3. Vérifiez les logs du serveur Jellyfin
4. Consultez la documentation Jellyfin officielle

## 🎉 Profitez de vos médias !

Vous êtes maintenant prêt à profiter de tous vos films et séries sur votre Apple TV avec xfinn !

---

*Guide créé pour xfinn v1.0.0 - 23 novembre 2025*
