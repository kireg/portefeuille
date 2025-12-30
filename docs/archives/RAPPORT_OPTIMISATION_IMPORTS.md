# 📊 Rapport d'Analyse et Optimisation de la Logique d'Import

**Date:** 29 décembre 2025  
**Version:** 1.0  
**Scope:** Analyse complète du flux d'import (parsers → diff → sauvegarde)

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#1-vue-densemble)
2. [Analyse des Parsers](#2-analyse-des-parsers)
3. [Analyse du Service de Diff](#3-analyse-du-service-de-diff)
4. [Analyse du Service de Sauvegarde](#4-analyse-du-service-de-sauvegarde)
5. [Problèmes Identifiés](#5-problèmes-identifiés)
6. [Optimisations Recommandées](#6-optimisations-recommandées)
7. [Matrice de Cohérence des Signes](#7-matrice-de-cohérence-des-signes)
8. [Plan d'Action Priorisé](#8-plan-daction-priorisé)

---

## 1. Vue d'Ensemble

### Architecture Actuelle

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   PARSERS       │ ──▶ │  ImportDiff      │ ──▶ │  ImportSave      │
│   (5 sources)   │     │  Service         │     │  Service         │
└─────────────────┘     └──────────────────┘     └──────────────────┘
       │                        │                        │
       ▼                        ▼                        ▼
ParsedTransaction         ImportCandidate           Transaction
+ compensation           + duplicates             + auto-deposits
```

### Sources Analysées

| Parser | Format | Fichier | LOC |
|--------|--------|---------|-----|
| TradeRepublicParser | PDF | `trade_republic_parser.dart` | 318 |
| TradeRepublicAccountStatementParser | PDF | `trade_republic_account_statement_parser.dart` | 554 |
| BoursoramaParser | PDF | `boursorama_parser.dart` | 446 |
| RevolutParser | CSV | `revolut_parser.dart` | 247 |
| LaPremiereBriqueParser | Excel | `la_premiere_brique_parser.dart` | 288 |

---

## 2. Analyse des Parsers

### 2.1 Trade Republic Parser (PDF classique)

**Fichier:** `trade_republic_parser.dart`

#### Points Forts ✅
- Gestion des achats/ventes avec signes corrects
- Inférence automatique du type d'actif (ETF, Crypto, Stock)
- Gestion des dividendes

#### Problèmes Identifiés 🔴

| ID | Sévérité | Description |
|----|----------|-------------|
| TR-1 | 🟠 Moyenne | **Frais hardcodés à 1€** : `fees: 1.0` - Devrait être extrait du document |
| TR-2 | 🟠 Moyenne | **Ticker créé à partir du nom** : `assetName.replaceAll(...)` - Peu fiable pour matching |
| TR-3 | 🔴 Haute | **Date fallback = DateTime.now()** : Si date non trouvée, utilise aujourd'hui |
| TR-4 | 🟡 Faible | **Warning message pas assez visible** : L'utilisateur peut ignorer |

#### Code Concerné
```dart
// TR-1: Frais hardcodés
fees: 1.0, // TR a souvent 1€ de frais, mais c'est une supposition

// TR-3: Date fallback dangereuse
date: docDate ?? DateTime.now(), // Fallback si date non trouvée
```

---

### 2.2 Trade Republic Account Statement Parser (Relevé de Compte)

**Fichier:** `trade_republic_account_statement_parser.dart`

#### Points Forts ✅
- Gestion PEA/CTO/Crypto séparée
- Ignorance des virements internes (Versement PEA)
- Uniformisation correcte des signes

#### Problèmes Identifiés 🔴

| ID | Sévérité | Description |
|----|----------|-------------|
| TRAS-1 | 🔴 Haute | **Type par défaut = Deposit** : Risque de mauvaise classification |
| TRAS-2 | 🟠 Moyenne | **Quantité non parsée pour certains types** : quantity = 0 pour dividendes |
| TRAS-3 | 🟠 Moyenne | **Pas de gestion des Fees explicites** : `fees: 0` systématiquement |
| TRAS-4 | 🟡 Faible | **Default case retourne transactionAmount brut** : Peut avoir mauvais signe |

#### Code Concerné
```dart
// TRAS-1: Type par défaut dangereux
TransactionType type = TransactionType.Deposit; // Default

// TRAS-4: Default non signé
default:
  signedAmount = transactionAmount; // Peut être positif ou négatif selon parsing
```

---

### 2.3 Boursorama Parser

**Fichier:** `boursorama_parser.dart`

#### Points Forts ✅
- Détection portfolio vs avis d'opéré
- Extraction ISIN robuste
- Gestion des dividendes et coupons

#### Problèmes Identifiés 🔴

| ID | Sévérité | Description |
|----|----------|-------------|
| BOU-1 | 🔴 Haute | **Heuristique anti-collage fragile** : Peut mal calculer la quantité |
| BOU-2 | 🟠 Moyenne | **ISIN unique par document** : Premier ISIN trouvé utilisé pour toutes les transactions |
| BOU-3 | 🟡 Faible | **Frais = 0** : Pas d'extraction des frais de courtage |

#### Code Concerné
```dart
// BOU-1: Heuristique fragile
if (qty > 20) {
  // Chercher si juste avant il y a virgule/point
  final charBefore = prefix[qtyStart - 1];
  if (charBefore == ',' || charBefore == '.') {
    // Prendre 1 ou 2 derniers chiffres selon la longueur
    final takeCount = quantityStr.length >= 4 ? 2 : 1;
    quantityStr = quantityStr.substring(quantityStr.length - takeCount);
  }
}

// BOU-2: Un seul ISIN pour tout le document
final isinMatch = isinRegex.firstMatch(rawText); // Premier match seulement
```

---

### 2.4 Revolut Parser

**Fichier:** `revolut_parser.dart`

#### Points Forts ✅
- Format CSV structuré = parsing fiable
- Gestion de 8 types de transactions
- Bonne gestion des devises

#### Problèmes Identifiés 🔴

| ID | Sévérité | Description |
|----|----------|-------------|
| REV-1 | 🔴 Haute | **Montant toujours positif** : `amount.abs()` perd l'information de signe |
| REV-2 | 🟠 Moyenne | **Withdrawal montant positif** : Devrait être négatif |
| REV-3 | 🟡 Faible | **ISIN = null** : Pas de support ISIN |

#### Code Concerné
```dart
// REV-1: Perte d'information de signe
final amount = _parseNumber(totalAmountStr)?.abs() ?? 0.0;

// REV-2: Withdrawal positif (ERREUR!)
if (upperType.startsWith('CASH WITHDRAWAL')) {
  return _buildTransaction(
    type: TransactionType.Withdrawal,
    amount: amount, // amount.abs() = positif!
  );
}
```

---

### 2.5 La Première Brique Parser

**Fichier:** `la_premiere_brique_parser.dart`

#### Points Forts ✅
- Extraction complète des métadonnées (durée, taux, type remboursement)
- Parsing Excel robuste
- Calcul intelligent de la durée cible

#### Problèmes Identifiés 🔴

| ID | Sévérité | Description |
|----|----------|-------------|
| LPB-1 | 🟠 Moyenne | **Conversion ParsedCrowdfundingProject → ParsedTransaction** : Non visible |
| LPB-2 | 🟡 Faible | **Pas de gestion des intérêts reçus** : Uniquement l'investissement initial |

---

## 3. Analyse du Service de Diff

**Fichier:** `import_diff_service.dart`

### Logique de Clés

#### Clé d'Identité (Complète)
```dart
String _identityKeyParsed(ParsedTransaction tx) {
  final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day).toIso8601String();
  final assetRef = (tx.ticker ?? tx.isin ?? tx.assetName).toLowerCase();
  return '$dateKey|$assetRef|${tx.type}|${tx.quantity.toStringAsFixed(4)}|${tx.amount.toStringAsFixed(2)}';
}
```

#### Clé de Matching (Partielle)
```dart
String _matchKeyParsed(ParsedTransaction tx) {
  final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day).toIso8601String();
  final assetRef = (tx.ticker ?? tx.isin ?? tx.assetName).toLowerCase();
  return '$dateKey|$assetRef|${tx.type}';
}
```

### Problèmes Identifiés 🔴

| ID | Sévérité | Description |
|----|----------|-------------|
| DIFF-1 | 🔴 Haute | **assetRef inconsistant entre parsers** : TR utilise ISIN, Revolut utilise ticker, Bourso utilise nom |
| DIFF-2 | 🟠 Moyenne | **Date sans heure** : Deux transactions le même jour sur le même actif = conflit |
| DIFF-3 | 🟠 Moyenne | **Mode initial ignore existingMatch** : Toujours `existingMatch = null` |
| DIFF-4 | 🟡 Faible | **ISIN invalides signalés mais pas bloquants** : Peut créer des doublons |

#### Code Concerné
```dart
// DIFF-1: Fallback vers assetName si ticker/ISIN absent
final assetRef = (tx.ticker ?? tx.isin ?? tx.assetName).toLowerCase();
// Problème: "APPLE_INC" vs "AAPL" vs "US0378331005" = 3 actifs différents!

// DIFF-3: Mode initial n'utilise pas existingByMatchKey
if (mode == ImportMode.update) { // Seulement en mode update
  existingMatch = existingByMatchKey[matchKey];
}
```

---

## 4. Analyse du Service de Sauvegarde

**Fichier:** `import_save_service.dart`

### Logique de Compensation

```dart
// Compensation pour Buy ET Withdrawal avec montant négatif
if ((parsed.type == TransactionType.Buy || parsed.type == TransactionType.Withdrawal) 
    && parsed.amount < 0) {
  depositsByDate[dateKey] = (depositsByDate[dateKey] ?? 0) + parsed.amount.abs();
}
```

### Problèmes Identifiés 🔴

| ID | Sévérité | Description |
|----|----------|-------------|
| SAVE-1 | 🔴 Critique | **Revolut Withdrawal = montant positif** : Ne déclenche PAS la compensation |
| SAVE-2 | 🟠 Moyenne | **Fees transférées comme nullable** : `fees: parsed.fees ?? existing.fees` peut être null |
| SAVE-3 | 🟠 Moyenne | **Pas de validation des candidats** : Montants incohérents passent |
| SAVE-4 | 🟡 Faible | **Notes multilignes** : Peuvent poser problème à l'affichage |

#### Code Concerné
```dart
// SAVE-1: La condition ne se déclenche pas si amount > 0
if (parsed.amount < 0) { // Revolut Withdrawal a amount > 0!
  depositsByDate[dateKey] = ...
}
```

---

## 5. Problèmes Identifiés

### 5.1 Problèmes Critiques 🔴

| ID | Source | Description | Impact |
|----|--------|-------------|--------|
| REV-1 | Revolut | Montant Withdrawal positif | Liquidités négatives à l'import |
| SAVE-1 | ImportSave | Compensation conditionnée à amount < 0 | Withdrawal Revolut non compensé |
| DIFF-1 | ImportDiff | assetRef inconsistant | Doublons non détectés |
| TR-3 | TR Parser | Date fallback = now() | Transactions avec mauvaise date |
| TRAS-1 | TR Account | Default type = Deposit | Mauvaise classification |

### 5.2 Problèmes Moyens 🟠

| ID | Source | Description | Impact |
|----|--------|-------------|--------|
| TR-1 | TR Parser | Frais hardcodés 1€ | Calcul PRU inexact |
| BOU-1 | Boursorama | Heuristique quantité fragile | Quantité mal calculée |
| BOU-2 | Boursorama | Un seul ISIN par document | Mauvais matching |
| DIFF-2 | ImportDiff | Pas d'heure dans la clé | Conflits intra-journaliers |

### 5.3 Problèmes Mineurs 🟡

| ID | Source | Description |
|----|--------|-------------|
| TR-2 | TR Parser | Ticker créé depuis le nom |
| BOU-3 | Boursorama | Frais = 0 |
| REV-3 | Revolut | Pas de support ISIN |
| DIFF-4 | ImportDiff | ISIN invalides non bloquants |

---

## 6. Optimisations Recommandées

### 6.1 Correction Critique : Revolut Withdrawal

**Fichier:** `revolut_parser.dart`

```dart
// AVANT (BUG)
if (upperType.startsWith('CASH WITHDRAWAL')) {
  return _buildTransaction(
    type: TransactionType.Withdrawal,
    amount: amount, // POSITIF!
  );
}

// APRÈS (CORRIGÉ)
if (upperType.startsWith('CASH WITHDRAWAL')) {
  return _buildTransaction(
    type: TransactionType.Withdrawal,
    amount: -amount.abs(), // NÉGATIF pour cohérence
  );
}
```

### 6.2 Correction Critique : Compensation Alternative

**Fichier:** `import_save_service.dart`

```dart
// AVANT (incomplet)
if ((parsed.type == TransactionType.Buy || parsed.type == TransactionType.Withdrawal) 
    && parsed.amount < 0) {

// APRÈS (robuste)
// Compenser tout achat OU tout retrait, peu importe le signe
// Car certains parsers (Revolut) retournent des montants positifs
final needsCompensation = 
    (parsed.type == TransactionType.Buy) ||
    (parsed.type == TransactionType.Withdrawal);

if (needsCompensation) {
  final compensationAmount = parsed.amount.abs(); // Toujours positif
  depositsByDate[dateKey] = (depositsByDate[dateKey] ?? 0) + compensationAmount;
}
```

### 6.3 Amélioration : Normalisation des Asset References

**Nouvelle classe utilitaire recommandée:**

```dart
class AssetRefNormalizer {
  /// Normalise l'identifiant d'un actif pour matching cross-source
  static String normalize({
    String? isin,
    String? ticker,
    String? assetName,
  }) {
    // Priorité 1: ISIN (universel)
    if (isin != null && isin.isNotEmpty && _isValidIsin(isin)) {
      return 'ISIN:${isin.toUpperCase()}';
    }
    
    // Priorité 2: Ticker (si format standard)
    if (ticker != null && ticker.isNotEmpty && _isStandardTicker(ticker)) {
      return 'TICKER:${ticker.toUpperCase()}';
    }
    
    // Priorité 3: Nom normalisé
    if (assetName != null && assetName.isNotEmpty) {
      return 'NAME:${_normalizeName(assetName)}';
    }
    
    return 'UNKNOWN';
  }
  
  static bool _isValidIsin(String s) => RegExp(r'^[A-Z]{2}[A-Z0-9]{9}[0-9]$').hasMatch(s);
  static bool _isStandardTicker(String s) => RegExp(r'^[A-Z]{1,5}$').hasMatch(s);
  static String _normalizeName(String s) => s.toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '')
      .substring(0, min(s.length, 20));
}
```

### 6.4 Amélioration : Validation Pre-Save

**Nouvelle fonction de validation:**

```dart
class ImportValidator {
  static List<String> validate(List<ImportCandidate> candidates) {
    final errors = <String>[];
    
    for (final c in candidates) {
      final p = c.parsed;
      
      // Validation 1: Montant cohérent avec le type
      if (p.type == TransactionType.Buy && p.amount > 0) {
        errors.add('Achat ${p.assetName} avec montant positif (${p.amount})');
      }
      if (p.type == TransactionType.Sell && p.amount < 0) {
        errors.add('Vente ${p.assetName} avec montant négatif (${p.amount})');
      }
      if (p.type == TransactionType.Withdrawal && p.amount > 0) {
        errors.add('Retrait ${p.assetName} avec montant positif (${p.amount})');
      }
      
      // Validation 2: Date raisonnable
      if (p.date.isAfter(DateTime.now().add(Duration(days: 365)))) {
        errors.add('Date future > 1 an: ${p.assetName} (${p.date})');
      }
      if (p.date.isBefore(DateTime(1990, 1, 1))) {
        errors.add('Date trop ancienne: ${p.assetName} (${p.date})');
      }
      
      // Validation 3: Quantité positive pour Buy/Sell
      if ((p.type == TransactionType.Buy || p.type == TransactionType.Sell) 
          && p.quantity <= 0) {
        errors.add('${p.type} ${p.assetName} avec quantité nulle ou négative');
      }
    }
    
    return errors;
  }
}
```

### 6.5 Amélioration : Gestion des Frais

**Extraction des frais (exemple Trade Republic):**

```dart
// Pattern pour frais externes
final feesRegex = RegExp(r'Frais[:\s]+([\d,]+)\s*€', caseSensitive: false);
final feesMatch = feesRegex.firstMatch(description);
double fees = 0.0;
if (feesMatch != null) {
  fees = double.tryParse(feesMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
}
```

---

## 7. Matrice de Cohérence des Signes

### Convention Attendue

| TransactionType | Montant | Impact Liquidités | Compensé? |
|-----------------|---------|-------------------|-----------|
| Deposit | + | ↑ Augmente | ❌ Non |
| Withdrawal | - | ↓ Diminue | ✅ Oui |
| Buy | - | ↓ Diminue | ✅ Oui |
| Sell | + | ↑ Augmente | ❌ Non |
| Dividend | + | ↑ Augmente | ❌ Non |
| Interest | + | ↑ Augmente | ❌ Non |
| Fees | - | ↓ Diminue | ❌ Non |

### État Actuel par Parser

| Parser | Deposit | Withdrawal | Buy | Sell | Dividend | Fees |
|--------|---------|------------|-----|------|----------|------|
| Trade Republic | ✅ + | ✅ - | ✅ - | ✅ + | ✅ + | ⚠️ hardcodé |
| TR Account | ✅ + | ✅ - | ✅ - | ✅ + | ✅ + | ⚠️ = 0 |
| Boursorama | N/A | N/A | ✅ - | ✅ + | ✅ + | ⚠️ = 0 |
| Revolut | ✅ + | ❌ + | ✅ - | ✅ + | ✅ + | ✅ - |
| La Première Brique | N/A | N/A | ✅ - | N/A | N/A | = 0 |

**Légende:**
- ✅ Correct
- ❌ Incorrect (BUG)
- ⚠️ Approximatif
- N/A Non applicable

---

## 8. Plan d'Action Priorisé

### Phase 1 : Corrections Critiques (Immédiat)

| # | Action | Fichier | Effort |
|---|--------|---------|--------|
| 1 | **Corriger Revolut Withdrawal** | `revolut_parser.dart` | 5 min |
| 2 | **Compensation robuste** | `import_save_service.dart` | 10 min |
| 3 | **Validation pre-save** | Nouveau fichier | 30 min |

### Phase 2 : Améliorations Importantes (Court Terme)

| # | Action | Fichier | Effort |
|---|--------|---------|--------|
| 4 | Normalisation assetRef | Nouveau utilitaire | 1h |
| 5 | Extraction frais réels | Tous parsers PDF | 2h |
| 6 | Gestion date + heure | `import_diff_service.dart` | 30 min |

### Phase 3 : Optimisations (Moyen Terme)

| # | Action | Fichier | Effort |
|---|--------|---------|--------|
| 7 | Logs détaillés import | Service transversal | 2h |
| 8 | Mode dry-run | `import_save_service.dart` | 1h |
| 9 | Réconciliation post-import | Nouveau service | 3h |

---

## 📊 Résumé Exécutif

### État Global : 🟠 Fonctionnel mais Fragile

**Points Forts:**
- Architecture modulaire (parsers séparés)
- Compensation automatique fonctionnelle
- Détection des doublons opérationnelle

**Points Faibles:**
- Incohérence des signes entre parsers
- Condition de compensation trop restrictive
- Absence de validation pre-save
- Frais non extraits

### Effort Estimé Total

| Phase | Effort | Priorité |
|-------|--------|----------|
| Phase 1 | ~45 min | 🔴 Critique |
| Phase 2 | ~3.5h | 🟠 Important |
| Phase 3 | ~6h | 🟡 Nice to have |

**Recommandation:** Implémenter Phase 1 immédiatement pour garantir l'intégrité des imports.

---

**Auteur:** GitHub Copilot  
**Date:** 29 décembre 2025  
**Status:** 📋 Rapport d'analyse complet
