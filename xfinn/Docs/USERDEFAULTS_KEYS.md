# Clés UserDefaults - Référence

## 📋 Vue d'ensemble

Ce document liste toutes les clés utilisées dans UserDefaults pour la persistance des données de l'application xfinn.

## 🔑 Clés disponibles

### Authentification Jellyfin

Les extensions personnalisées suivantes sont probablement définies quelque part dans le projet :

```swift
extension UserDefaults {
    var jellyfinServerURL: String? { get set }
    var jellyfinAccessToken: String? { get set }
    var jellyfinUserId: String? { get set }
    var deviceId: String { get }
    
    func clearJellyfinData()
}
```

### Préférences de streaming

#### `"preferredStreamQuality"` - Type: String
Stocke la qualité de streaming préférée de l'utilisateur.

**Valeurs possibles :**
- `"Auto"`
- `"Original (qualité maximale)"`
- `"Haute (1080p)"`
- `"Moyenne (720p)"`
- `"Basse (480p)"`

**Utilisation :**
```swift
// Sauvegarde
UserDefaults.standard.set(newQuality.rawValue, forKey: "preferredStreamQuality")

// Chargement
if let savedQuality = UserDefaults.standard.string(forKey: "preferredStreamQuality"),
   let quality = StreamQuality(rawValue: savedQuality) {
    // Utiliser la qualité
}
```

**Fichiers concernés :**
- `JellyfinService.swift` (ligne ~45 et ~60)

---

### Préférences de sous-titres

#### `"preferredSubtitleLanguage"` - Type: String
Stocke la langue de sous-titres préférée de l'utilisateur pour auto-sélection.

**Valeurs possibles :**
- Code de langue (ex: `"fra"`, `"eng"`, `"spa"`)
- Nom de langue (ex: `"French"`, `"English"`, `"Spanish"`)
- `nil` si aucune préférence

**Utilisation :**
```swift
// Sauvegarde
UserDefaults.standard.set(language, forKey: "preferredSubtitleLanguage")

// Chargement
let savedLanguage = UserDefaults.standard.string(forKey: "preferredSubtitleLanguage")

// Suppression
UserDefaults.standard.removeObject(forKey: "preferredSubtitleLanguage")
```

**Fichiers concernés :**
- `MediaDetailView.swift` (nouvelle fonctionnalité des sous-titres)

---

## 🔄 Migration des données

Si les clés changent dans le futur, voici un exemple de code de migration :

```swift
extension UserDefaults {
    func migrateKeys() {
        // Exemple : Migration d'une ancienne clé vers une nouvelle
        if let oldValue = string(forKey: "oldKey") {
            set(oldValue, forKey: "newKey")
            removeObject(forKey: "oldKey")
        }
    }
}
```

## 🧪 Débogage

Pour inspecter toutes les valeurs sauvegardées :

```swift
func printAllUserDefaults() {
    let domain = Bundle.main.bundleIdentifier!
    let defaults = UserDefaults.standard.persistentDomain(forName: domain)
    print("UserDefaults content:")
    defaults?.forEach { print("  \($0): \($1)") }
}
```

Pour réinitialiser toutes les données (utile en développement) :

```swift
func resetUserDefaults() {
    let domain = Bundle.main.bundleIdentifier!
    UserDefaults.standard.removePersistentDomain(forName: domain)
    UserDefaults.standard.synchronize()
}
```

## ⚠️ Bonnes pratiques

1. **Toujours utiliser des constantes** pour les clés :
   ```swift
   extension String {
       static let preferredSubtitleLanguageKey = "preferredSubtitleLanguage"
       static let preferredStreamQualityKey = "preferredStreamQuality"
   }
   
   // Utilisation
   UserDefaults.standard.set(value, forKey: .preferredSubtitleLanguageKey)
   ```

2. **Vérifier nil avant d'utiliser** :
   ```swift
   guard let value = UserDefaults.standard.string(forKey: key) else {
       return defaultValue
   }
   ```

3. **Synchroniser après les modifications critiques** :
   ```swift
   UserDefaults.standard.set(value, forKey: key)
   UserDefaults.standard.synchronize()
   ```

4. **Ne jamais stocker de données sensibles** (mots de passe en clair, etc.)
   - Utiliser le Keychain pour les données sensibles

## 📊 Taille des données

UserDefaults est optimisé pour de petites quantités de données. Pour référence :

| Type de donnée | Taille recommandée | Notre usage |
|----------------|-------------------|-------------|
| Strings        | < 1 KB            | ✅ Conforme |
| Dictionaries   | < 10 KB           | N/A         |
| Arrays         | < 10 KB           | N/A         |
| Images         | ❌ Non recommandé  | N/A         |

## 🔐 Sécurité

Les données stockées dans UserDefaults sont :
- ✅ Persistantes entre les lancements de l'app
- ✅ Spécifiques à l'app (inaccessibles par d'autres apps)
- ❌ **Non chiffrées** sur l'appareil
- ❌ Supprimées lors de la désinstallation de l'app

Pour les tokens d'authentification, considérer l'utilisation du **Keychain** plutôt que UserDefaults.

## 📝 TODO

- [ ] Créer une extension UserDefaults avec des propriétés typées pour toutes les clés
- [ ] Migrer les tokens vers le Keychain pour plus de sécurité
- [ ] Implémenter une fonction de réinitialisation pour les paramètres de l'app
- [ ] Ajouter des tests unitaires pour la persistance des préférences
- [ ] Documenter toutes les extensions UserDefaults existantes
