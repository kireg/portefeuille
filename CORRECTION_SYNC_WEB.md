# 🌐 Correction : Synchronisation Yahoo Finance sur la Version Web

## 📋 Problème Identifié

La synchronisation avec Yahoo Finance ne fonctionnait pas sur la version web de l'application déployée sur GitHub Pages (`kireg.github.io/portefeuille`).

### Cause Racine : CORS (Cross-Origin Resource Sharing)

Les navigateurs web modernes bloquent les requêtes HTTP vers des domaines externes (comme `query1.finance.yahoo.com`) si ces serveurs ne renvoient pas les **headers CORS appropriés**. C'est une mesure de sécurité standard.

**Erreur typique dans la console du navigateur :**
```
Access to fetch at 'https://query1.finance.yahoo.com/...' from origin 'https://kireg.github.io' 
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

### Pourquoi ça fonctionne sur mobile/desktop mais pas sur web ?

- **Mobile/Desktop** : Les applications natives Flutter (Android, iOS, Windows, etc.) ne sont **pas soumises aux restrictions CORS**. Elles font des requêtes HTTP directes comme n'importe quel client HTTP.
- **Web (Navigateur)** : Le code Flutter tourne dans un navigateur, donc les requêtes HTTP sont soumises aux **politiques de sécurité CORS** du navigateur.

---

## ✅ Solution Implémentée

### Proxy CORS avec Détection de Plateforme

Utilisation du flag `kIsWeb` de Flutter pour détecter si l'application tourne dans un navigateur et adapter les URLs :

#### Avant (Code Original)
```dart
Future<double?> _fetchFromYahoo(String ticker) async {
  final yahooUrl = Uri.parse(
      'https://query1.finance.yahoo.com/v7/finance/spark?symbols=$ticker&range=1d&interval=1d');
  // ...
}
```

#### Après (Code Corrigé)
```dart
Future<double?> _fetchFromYahoo(String ticker) async {
  // Utiliser un proxy CORS uniquement sur web
  final String baseUrl = kIsWeb 
      ? 'https://corsproxy.io/?https://query1.finance.yahoo.com'
      : 'https://query1.finance.yahoo.com';
  
  final yahooUrl = Uri.parse(
      '$baseUrl/v7/finance/spark?symbols=$ticker&range=1d&interval=1d');
  // ...
}
```

### Service de Proxy Utilisé

**[corsproxy.io](https://corsproxy.io/)** - Un service gratuit et fiable qui :
- ✅ Ajoute les headers CORS nécessaires aux réponses
- ✅ Préfixe simple : `https://corsproxy.io/?<URL_CIBLE>`
- ✅ Pas de clé API requise
- ✅ Open source et sans limitation pour usage raisonnable

### Endpoints Corrigés

1. **Récupération des prix** (`_fetchFromYahoo`)
   - Endpoint Yahoo : `/v7/finance/spark`
   - Utilisé pour obtenir les prix en temps réel

2. **Recherche de tickers** (`searchTicker`)
   - Endpoint Yahoo : `/v1/finance/search`
   - Utilisé pour l'auto-complétion lors de l'ajout de transactions

---

## 🔧 Fichiers Modifiés

| Fichier | Lignes modifiées | Description |
|---------|------------------|-------------|
| `lib/core/data/services/api_service.dart` | 153-173, 181-197 | Ajout de la détection `kIsWeb` et du proxy CORS |

---

## 🧪 Comment Tester

### 1. Version Web Locale

```powershell
# Build et servir localement
flutter build web --release --base-href "/portefeuille/"
cd build\web
python -m http.server 8080
```

Ouvrez `http://localhost:8080` dans votre navigateur et :
1. Activez le **Mode en ligne** dans les Paramètres
2. Allez dans le **Journal** > **Synthèse Actifs**
3. Vérifiez que les prix s'affichent correctement
4. Ouvrez la console du navigateur (F12) et vérifiez qu'il n'y a **pas d'erreurs CORS**

### 2. Version Déployée sur GitHub Pages

Testez directement sur : **[https://kireg.github.io/portefeuille/](https://kireg.github.io/portefeuille/)**

### 3. Console de Debug (Attendu)

```
🔍 Recherche de ticker: 'AAPL' - URL: https://corsproxy.io/?https://query1.finance.yahoo.com/...
✅ Réponse reçue - Status: 200
📊 5 résultats trouvés
✅ 3 suggestions valides
```

**Pas d'erreur CORS attendue !**

---

## ⚠️ Limitations et Alternatives

### Limitations de corsproxy.io

- **Disponibilité** : Service tiers, peut avoir des temps d'arrêt occasionnels
- **Latence** : Ajoute ~50-200ms de délai par requête (redirection)
- **Quota** : Pas de limite officielle mais éviter les abus

### Alternatives Possibles

Si `corsproxy.io` devient indisponible, remplacer par :

1. **allorigins.win**
   ```dart
   final baseUrl = kIsWeb 
       ? 'https://api.allorigins.win/raw?url=https://query1.finance.yahoo.com'
       : 'https://query1.finance.yahoo.com';
   ```

2. **Proxy CORS auto-hébergé**
   - Déployer votre propre instance de [cors-anywhere](https://github.com/Rob--W/cors-anywhere)
   - Plus de contrôle mais nécessite un serveur (Heroku, Vercel, etc.)

3. **Serveur Backend dédié**
   - Créer un backend Firebase Functions ou Vercel Serverless
   - Proxy personnalisé pour Yahoo Finance
   - Meilleure sécurité (masquer les clés API)

---

## 📊 Impact sur les Performances

| Plateforme | Avant | Après | Impact |
|------------|-------|-------|--------|
| **Mobile/Desktop** | Requête directe (~100ms) | Requête directe (~100ms) | ✅ **Aucun** |
| **Web** | ❌ Bloqué par CORS | Requête via proxy (~200-300ms) | ⚠️ Latence +100-200ms |

### Optimisation Déjà en Place

Le **cache de 15 minutes** limite l'impact de la latence supplémentaire :
- Premier chargement : ~200-300ms
- Rechargements suivants (< 15 min) : Cache instantané

---

## 📝 Notes Techniques

### Pourquoi `kIsWeb` et pas une variable d'environnement ?

- `kIsWeb` est une **constante de compilation** Flutter (`const bool`)
- Le compilateur Dart élimine le code non utilisé (**tree shaking**)
- Le code du proxy CORS n'est **jamais compilé** dans les versions natives
- **Aucun overhead** sur mobile/desktop

### FMP (Financial Modeling Prep) et CORS

Si l'utilisateur configure une **clé API FMP**, les requêtes vers FMP fonctionnent généralement **sans proxy** car FMP supporte CORS nativement. Le proxy n'est nécessaire que pour Yahoo Finance.

---

## ✅ Checklist de Validation

- [x] Code modifié dans `api_service.dart`
- [x] Utilisation de `kIsWeb` pour détecter la plateforme
- [x] Proxy CORS appliqué à `_fetchFromYahoo`
- [x] Proxy CORS appliqué à `searchTicker`
- [ ] Test sur version web locale (à faire par l'utilisateur)
- [ ] Test sur GitHub Pages (à faire par l'utilisateur)
- [ ] Vérification absence d'erreurs CORS dans la console navigateur

---

## 🚀 Prochaines Étapes

1. **Tester** la correction sur `kireg.github.io/portefeuille`
2. **Surveiller** les logs de la console navigateur
3. Si problème, envisager une **alternative de proxy** (voir section Alternatives)
4. **Considérer** un backend dédié pour version production (optionnel)

---

Made with ❤️ for Portefeuille Web v1
