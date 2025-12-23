# 🌊 Guide de Design : Liquid Glass pour XFINN

## 📐 Vue d'ensemble

XFINN adopte le design **Liquid Glass**, le style visuel le plus moderne d'Apple, combinant :
- Effets de verre fluides et dynamiques
- Gradients lumineux et immersifs
- Accessibilité maximale
- Animations douces et naturelles

---

## 🎨 Palette de couleurs

### Couleurs principales

| Nom | Hex | Usage |
|-----|-----|-------|
| **Primary** | `#0A84FF` | Bleu électrique - Boutons principaux, liens actifs |
| **Accent** | `#64C8FF` | Cyan lumineux - Highlights, accents visuels |
| **Secondary** | `#BF5AF2` | Violet/Magenta - Badges, éléments spéciaux |
| **Tertiary** | `#FF4585` | Rose vif - Alertes, favoris |

### Backgrounds

| Nom | Description |
|-----|-------------|
| **Background** | Noir profond (`rgb(0, 0, 13)`) avec teinte bleue |
| **Glass** | `.ultraThinMaterial` avec bordure blanche à 15% d'opacité |
| **Gradient** | Dégradé bleu foncé → noir → violet foncé |

### Textes (optimisés pour l'accessibilité)

| Niveau | Opacité | Usage |
|--------|---------|-------|
| **Primary** | 100% | Titres, texte important |
| **Secondary** | 85% | Sous-titres, descriptions |
| **Tertiary** | 60% | Informations complémentaires |
| **Disabled** | 30% | États désactivés |

---

## 🧩 Composants

### 1. Glass Card
```swift
.glassCard(cornerRadius: 20, padding: 20)
```
- Background: `.ultraThinMaterial`
- Bordure: Blanc 15% d'opacité
- Corners: 20pt par défaut
- Ombre: Légère avec blur

### 2. Glass Button
```swift
.glassButton(prominent: true/false)
```
- **Prominent**: Background bleu primaire avec glow
- **Standard**: `.ultraThinMaterial` avec bordure
- Padding: 30px horizontal, 15px vertical
- Corner radius: 25pt (capsule)

### 3. Glowing Effect
```swift
.glowing(color: .appPrimary, radius: 20)
```
- Double shadow pour effet lumineux
- Utilisé pour les éléments interactifs
- Radius variable selon l'importance

---

## 📱 Écrans

### LoginView ✅
- **Redesigné** avec particules flottantes en background
- Logo animé avec effet glow
- Transitions fluides entre étapes
- Bannière d'erreur glass avec fond rouge translucide

### HomeView 🔄
- En cours de redesign
- Grille de médias avec glass cards
- Carousel horizontal pour les catégories
- Navigation simplifiée et accessible

### MediaDetailView 🔄
- En cours de redesign
- Hero image en backdrop
- Informations en glass card overlay
- Boutons d'action avec glass effect

---

## ✨ Animations

### Standard
```swift
AppTheme.standardAnimation // smooth(duration: 0.4)
```
Usage: Transitions générales, changements d'état

### Glass
```swift
AppTheme.glassAnimation // smooth(duration: 0.6)
```
Usage: Apparition/disparition des effets glass

### Spring
```swift
AppTheme.springAnimation // spring(response: 0.5, dampingFraction: 0.7)
```
Usage: Interactions utilisateur, rebonds

---

## ♿️ Accessibilité

### Contrastes
- Tous les textes respectent WCAG AAA
- Ratio minimum : 7:1 pour le texte principal
- Ratio minimum : 4.5:1 pour le texte secondaire

### Tailles
- Texte minimum : 18pt (tvOS)
- Boutons minimum : 70pt de hauteur
- Espacement : minimum 20pt entre éléments interactifs

### Labels
- Tous les boutons ont des labels explicites
- Images décoratives marquées `.accessibilityHidden(true)`
- Navigation logique avec VoiceOver

### Focus
- Indicateurs de focus visibles
- Couleur de focus : Cyan (`#64C8FF`)
- Border width : 3pt minimum

---

## 🎭 Particules de fond

Les particules flottantes créent une ambiance immersive :
- 15 cercles avec blur
- Tailles aléatoires : 100-300pt
- Opacité : 40%
- Gradients : Primary → Accent
- Position aléatoire dans l'espace

---

## 📐 Grilles et espacements

### Grilles tvOS
- Colonnes : 6 (landscape)
- Gutter : 40pt
- Margin : 100pt

### Espacements standard
- XS : 8pt
- S : 12pt
- M : 20pt
- L : 30pt
- XL : 40pt
- XXL : 60pt

---

## 🔄 Transitions

### Types de transitions
1. **Asymmetric** : Entrée par la droite, sortie par la gauche
2. **Opacity** : Fade in/out combiné avec move
3. **Scale** : Zoom in/out pour les modals

### Durées
- Courte : 0.2s (feedback immédiat)
- Moyenne : 0.4s (transitions standard)
- Longue : 0.6s (animations glass)

---

## 📚 Bonnes pratiques

### ✅ À faire
- Utiliser `.ultraThinMaterial` pour les glass cards
- Ajouter des glows aux éléments interactifs
- Animer toutes les transitions
- Tester avec VoiceOver
- Respecter les tailles minimales

### ❌ À éviter
- Trop d'éléments glass superposés (max 3)
- Animations trop rapides (< 0.2s)
- Contrastes insuffisants
- Textes en dessous de 18pt (tvOS)
- Boutons sans labels explicites

---

## 🎯 Prochaines étapes

1. ✅ LoginView redesigné
2. 🔄 HomeView en cours
3. ⏳ MediaDetailView à venir
4. ⏳ Player controls à venir
5. ⏳ Settings screen à venir

---

*Dernière mise à jour : 22 décembre 2024*
