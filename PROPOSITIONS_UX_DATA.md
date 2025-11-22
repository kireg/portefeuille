# Plan d'Action Détaillé : UX & Data

Ce document sert de spécification technique complète pour l'implémentation des fonctionnalités d'amélioration de l'expérience utilisateur (ajout d'institutions) et d'import de données (PDF).

---

## Chantier 1 : Catalogue d'Institutions & API Robuste

### 1.1. Catalogue d'Institutions Pré-embarqué
**Objectif** : Offrir une expérience "Plug & Play" lors de la création d'un portefeuille, en proposant visuellement les acteurs majeurs du marché.

#### A. Structure de Données (`assets/data/institutions.json`)
Le fichier JSON servira de source de vérité. Il doit être extensible.

```json
[
  {
    "id": "boursorama",
    "name": "Boursorama Banque",
    "type": "Bank",
    "country": "FR",
    "logoAsset": "assets/logos/boursorama.png",
    "primaryColor": "#D40055",
    "website": "https://www.boursorama.com",
    "defaultAccountTypes": ["PEA", "CTO", "AssuranceVie", "LivretA"]
  },
  {
    "id": "trade_republic",
    "name": "Trade Republic",
    "type": "Broker",
    "country": "DE",
    "logoAsset": "assets/logos/trade_republic.png",
    "primaryColor": "#000000",
    "website": "https://traderepublic.com",
    "defaultAccountTypes": ["CTO"]
  },
  {
    "id": "binance",
    "name": "Binance",
    "type": "CryptoExchange",
    "country": "Global",
    "logoAsset": "assets/logos/binance.png",
    "primaryColor": "#F3BA2F",
    "defaultAccountTypes": ["CryptoWallet", "Staking"]
  }
]
```

**Liste Initiale des Institutions à intégrer :**
*   **Banques FR** : Boursorama, Fortuneo, Crédit Agricole, BNP Paribas, Société Générale, Hello Bank!, Monabanq.
*   **Néobanques** : Revolut, N26, Lydia.
*   **Courtiers** : Trade Republic, Degiro, Interactive Brokers, Saxo Banque, Bourse Direct.
*   **Crypto** : Binance, Kraken, Coinbase, Ledger (Cold Wallet).

#### B. Modèle Dart (`InstitutionMetadata`)
Créer `lib/core/data/models/institution_metadata.dart` :
```dart
class InstitutionMetadata {
  final String id;
  final String name;
  final InstitutionType type; // Enum: Bank, Broker, CryptoExchange, Wallet, Other
  final String country;
  final String logoAsset;
  final Color primaryColor;
  final List<String> defaultAccountTypes;
  // ... fromJson constructor
}
```

#### C. UI : Refonte de `AddInstitutionScreen`
1.  **Header** : "Ajouter une institution".
2.  **Barre de Recherche** : Filtrage temps réel sur le nom.
3.  **Section "Populaires"** : Grille (GridView) de logos ronds.
    *   *Comportement* : Au clic, remplit le formulaire, sélectionne le type automatiquement, et affiche une liste de checkboxes pour créer les comptes par défaut en un clic (ex: [x] PEA [ ] CTO).
4.  **Section "Autre"** : Bouton "Saisir manuellement" (comportement actuel) en bas de page.

---

### 1.2. API Service : Scraping Google Finance (Fallback)
**Objectif** : Pallier les manques de Yahoo/FMP (notamment sur les indices Euronext ou certaines Small Caps) via une méthode de secours.

#### A. Stratégie de Parsing (Regex)
Google Finance charge le prix côté serveur (SSR), ce qui rend le scraping HTML possible sans navigateur headless (Selenium/Puppeteer inutile).

*   **URL** : `https://www.google.com/finance/quote/{TICKER}:{EXCHANGE}`
*   **Mapping Exchange** :
    *   Yahoo `.PA` -> Google `:EPA` (Paris)
    *   Yahoo `.AS` -> Google `:AMS` (Amsterdam)
    *   Yahoo `BTC-USD` -> Google `BTC-USD` (Crypto)

*   **Sélecteurs Regex (à maintenir)** :
    *   *Prix* : `<div class="YMlKec fxKbKc">([\d,.\s]+)</div>` (Classe CSS souvent stable, mais à surveiller).
    *   *Devise* : Souvent déduite du symbole ou d'un span proche.

#### B. Implémentation dans `ApiService`
```dart
Future<PriceResult> _fetchFromGoogleFinance(String ticker) async {
  // 1. Conversion Ticker Yahoo -> Google
  final googleTicker = _convertToGoogleTicker(ticker);
  
  // 2. Requête HTTP (avec User-Agent "Browser" pour éviter blocage 403)
  final response = await http.get(
    Uri.parse('https://www.google.com/finance/quote/$googleTicker'),
    headers: {'User-Agent': 'Mozilla/5.0 ...'},
  );

  // 3. Regex Extraction
  final priceRegex = RegExp(r'<div class="YMlKec fxKbKc">([\d,.\s]+)</div>');
  final match = priceRegex.firstMatch(response.body);
  
  if (match != null) {
    // Nettoyage (remplacer ',' par '.' si format FR, supprimer espaces insecables)
    double price = _parseGooglePrice(match.group(1));
    return PriceResult(price: price, source: ApiSource.GoogleFinance, ...);
  }
  throw Exception("Google Finance parsing failed");
}
```

---

## Chantier 2 : Import PDF Intelligent (Smart Import)

**Objectif** : Automatiser la saisie des transactions via les relevés PDF.

### 2.1. Architecture Technique

#### A. Dépendance
Utiliser `syncfusion_flutter_pdf` (Licence Community possible) pour sa capacité à extraire le texte en gardant une notion de structure, ou `read_pdf_text` (wrapper natif iOS/Android) pour la simplicité.

#### B. Interface `StatementParser`
```dart
abstract class StatementParser {
  String get bankName;
  /// Vérifie si le contenu brut du PDF correspond à cette banque
  bool canParse(String rawText);
  /// Extrait les transactions
  List<ParsedTransaction> parse(String rawText);
}

class ParsedTransaction {
  final DateTime date;
  final TransactionType type;
  final String assetName;
  final String? isin;
  final String? ticker;
  final double quantity;
  final double price;
  final double amount;
  final double fees;
  final String currency;
}
```

### 2.2. Spécifications des Parsers

#### A. Trade Republic (Avis d'opéré / Relevé)
*   **Détection** : `rawText.contains("Trade Republic Bank GmbH")`
*   **Patterns Regex (Exemples)** :
    *   *Achat (Ordre)* : `(Achat|Kauf)\s+de\s+(\d+(?:,\d+)?)\s+titres\s+(.*?)\s+au\s+cours\s+de\s+(\d+(?:,\d+)?)\s+(EUR|USD)`
    *   *Plan d'épargne* : `Exécution\s+du\s+plan\s+d'épargne` (Logique similaire à l'achat).
    *   *Dividende* : `Dividende\s+pour\s+(\d+)\s+titres\s+(.*?)\s+Montant\s+par\s+titre`
*   **Subtilités** :
    *   Les montants utilisent la virgule comme séparateur décimal.
    *   L'ISIN est souvent sur une ligne séparée ou en bas de page.

#### B. Boursorama (Avis d'opéré)
*   **Détection** : `rawText.contains("Boursorama")` && `rawText.contains("Avis d'opéré")`
*   **Patterns** :
    *   Rechercher les mots clés "Sens : Achat" ou "Sens : Vente".
    *   Extraire le tableau : `Libellé valeur`, `Quantité`, `Cours`, `Montant Net`.
    *   Regex : `(Achat|Vente)\s+au\s+comptant\s+de\s+(\d+)\s+(.*?)\s+à\s+([\d,]+)\s+(EUR)`

### 2.3. Workflow UI (`ImportTransactionFlow`)

1.  **Upload** : Bouton "Importer PDF" -> File Picker.
2.  **Analyse** :
    *   Extraction texte (Loading spinner).
    *   Boucle sur les parsers : `parsers.firstWhere((p) => p.canParse(text))`.
    *   Si aucun parser trouvé -> Message d'erreur "Banque non reconnue".
3.  **Preview (Tableau Éditable)** :
    *   Afficher une liste de cartes ou un tableau.
    *   Chaque ligne a un statut :
        *   🟢 **Prêt** : Toutes les données sont valides, l'actif est reconnu (Ticker trouvé via ISIN).
        *   🟠 **Attention** : Actif inconnu (L'utilisateur doit rechercher le ticker manuellement).
        *   🔴 **Erreur** : Donnée manquante.
    *   L'utilisateur peut corriger les champs ou supprimer une ligne.
4.  **Validation** : Bouton "Importer X transactions".
    *   Création des objets `Transaction` finaux.
    *   Insertion en base via `PortfolioProvider`.

---

## To-Do List Technique (Priorisée)

### Phase 1 : Institutions & API (Est. 2 jours)
1.  [x] **Assets** : Télécharger et ajouter les logos (PNG 200x200) dans `assets/logos/`.
    *   *Note* : Dossiers créés. Les fichiers images doivent être ajoutés manuellement.
2.  [x] **Data** : Créer `assets/data/institutions.json` (commencer par 5 banques pour tester).
3.  [x] **Model** : Coder `InstitutionMetadata` et `InstitutionService` (chargement asynchrone du JSON).
4.  [ ] **UI** : Refondre `AddInstitutionScreen` (Grid Layout + Search).
5.  [ ] **API** : Implémenter `_fetchFromGoogleFinance` dans `ApiService` avec gestion des erreurs.

### Phase 2 : Moteur d'Import PDF (Est. 3-4 jours)
1.  [ ] **Package** : Ajouter `syncfusion_flutter_pdf` au `pubspec.yaml`.
2.  [ ] **Core** : Créer l'interface `StatementParser` et le modèle `ParsedTransaction`.
3.  [ ] **Parser TR** : Implémenter `TradeRepublicParser` (focus sur Achat/Vente standard).
    *   *Test* : Créer un test unitaire avec un string copié-collé d'un vrai PDF pour valider les Regex.
4.  [ ] **Parser Bourso** : Implémenter `BoursoramaParser`.
5.  [ ] **UI** : Créer `ImportPreviewScreen` (StatefulWidget avec liste éditable).
6.  [ ] **Intégration** : Ajouter le bouton d'action dans `TransactionsView`.
