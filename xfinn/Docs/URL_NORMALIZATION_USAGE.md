# Guide d'utilisation - Normalisation d'URL Jellyfin

## Fonction principale

La fonction `normalizedJellyfinURL()` est une extension de `String` définie dans `LoginView.swift`.

### Utilisation

```swift
let userInput = "192.168.1.10"
let normalizedURL = userInput.normalizedJellyfinURL()
// Résultat : "http://192.168.1.10:8096"
```

## Exemples de transformations

### Cas simples
```swift
"192.168.1.10".normalizedJellyfinURL()
// → "http://192.168.1.10:8096"

"jellyfin.local".normalizedJellyfinURL()
// → "http://jellyfin.local:8096"

"localhost".normalizedJellyfinURL()
// → "http://localhost:8096"
```

### URLs avec protocole
```swift
"http://192.168.1.10".normalizedJellyfinURL()
// → "http://192.168.1.10:8096"

"https://jellyfin.example.com".normalizedJellyfinURL()
// → "https://jellyfin.example.com:8096"
```

### URLs avec port personnalisé (inchangées)
```swift
"https://jellyfin.example.com:8920".normalizedJellyfinURL()
// → "https://jellyfin.example.com:8920"

"http://192.168.1.10:9000".normalizedJellyfinURL()
// → "http://192.168.1.10:9000"
```

### Gestion des espaces
```swift
"  192.168.1.10  ".normalizedJellyfinURL()
// → "http://192.168.1.10:8096"
```

## Implémentation

```swift
extension String {
    func normalizedJellyfinURL() -> String {
        var url = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !url.isEmpty else { return url }
        
        let hasScheme = url.lowercased().hasPrefix("http://") || 
                       url.lowercased().hasPrefix("https://")
        
        if !hasScheme {
            url = "http://" + url
        }
        
        guard let urlComponents = URLComponents(string: url) else {
            return url
        }
        
        if urlComponents.port != nil {
            return url
        }
        
        var newComponents = urlComponents
        newComponents.port = 8096
        
        return newComponents.url?.absoluteString ?? url
    }
}
```

## Logique de fonctionnement

1. **Nettoyage** : Supprime les espaces avant/après
2. **Vérification du protocole** : Détecte si `http://` ou `https://` est présent
3. **Ajout du protocole** : Si absent, ajoute `http://`
4. **Parsing de l'URL** : Utilise `URLComponents` pour parser l'URL
5. **Vérification du port** : Détecte si un port est déjà spécifié
6. **Ajout du port par défaut** : Si absent, ajoute `:8096`
7. **Retour** : Retourne l'URL normalisée

## Tests manuels

Vous pouvez tester la fonction en l'appelant directement dans votre code :

```swift
// Dans un Playground ou un fichier Swift temporaire
let testCases = [
    ("192.168.1.10", "http://192.168.1.10:8096"),
    ("jellyfin.local", "http://jellyfin.local:8096"),
    ("http://192.168.1.10", "http://192.168.1.10:8096"),
    ("https://jellyfin.example.com:8920", "https://jellyfin.example.com:8920"),
]

for (input, expected) in testCases {
    let result = input.normalizedJellyfinURL()
    if result == expected {
        print("✅ \(input) → \(result)")
    } else {
        print("❌ \(input) → \(result) (attendu: \(expected))")
    }
}
```

## Notes importantes

### Cas non gérés volontairement

- **URLs invalides** : Si l'URL ne peut pas être parsée par `URLComponents`, elle est retournée telle quelle
- **Ports non-standard** : Les ports personnalisés sont toujours respectés
- **Protocoles non-HTTP** : Seuls `http://` et `https://` sont reconnus

### Sécurité

⚠️ Cette fonction ne valide **PAS** :
- La validité de l'IP ou du domaine
- L'accessibilité du serveur
- La sécurité du protocole (HTTP vs HTTPS)

La validation réelle se fait lors de la connexion au serveur dans `JellyfinService`.

## Intégration dans LoginView

La fonction est automatiquement appelée dans `LoginView.swift` :

```swift
private func connectToServer() {
    let cleanedURL = serverURL.normalizedJellyfinURL()
    // ... connexion au serveur avec l'URL nettoyée
}
```

L'utilisateur n'a donc pas besoin de se soucier du formatage de l'URL.

---

**Fichier source** : `LoginView.swift` (ligne ~475)  
**Documentation complète** : `JELLYFIN_URL_NORMALIZATION.md`
