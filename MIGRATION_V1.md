# 📋 Migration V1 : Système de Transactions

## 🎯 Objectif

Cette migration transforme le modèle de données de l'application pour adopter une architecture **immuable basée sur les transactions**. L'état du portefeuille (soldes, quantités d'actifs, PRU) n'est plus stocké directement mais **calculé dynamiquement** à partir de l'historique des transactions.

---

## 🚀 Changements Majeurs

### 1. **Nouveaux Modèles de Données**

#### `Transaction` (typeId: 7)
Représente une opération financière dans un compte.

**Champs :**
- `id` : Identifiant unique
- `accountId` : Compte parent
- `type` : Type de transaction (voir `TransactionType`)
- `date` : Date de l'opération
- `amount` : Montant en liquidités (positif = entrée, négatif = sortie)
- `fees` : Frais associés (toujours positifs)
- `assetTicker` : Ticker de l'actif (pour Achat/Vente/Dividende)
- `assetName` : Nom de l'actif
- `assetType` : Type d'actif (voir `AssetType`)
- `quantity` : Quantité d'actifs (pour Achat/Vente)
- `price` : Prix unitaire
- `notes` : Notes personnalisées

**Getter :**
- `totalAmount` : Retourne `amount - fees` (montant net après frais)

#### `TransactionType` (typeId: 6)
Énumération des types de transactions :
- `Deposit` : Dépôt de liquidités
- `Withdrawal` : Retrait de liquidités
- `Buy` : Achat d'actif
- `Sell` : Vente d'actif
- `Dividend` : Dividende reçu
- `Interest` : Intérêts perçus
- `Fees` : Frais divers

#### `AssetType` (typeId: 8)
Énumération des types d'actifs :
- `Stock` : Action
- `ETF` : Fonds négocié en bourse
- `Crypto` : Crypto-monnaie
- `Bond` : Obligation
- `Cash` : Liquidités
- `Other` : Autre

---

### 2. **Modifications des Modèles Existants**

#### `Account`
**Avant :**
```dart
class Account {
  List<Asset> assets;
  double cashBalance;
}
```

**Après :**
```dart
class Account {
  List<Transaction> transactions; // Injecté par le Repository
  
  // Getters calculés dynamiquement
  double get cashBalance { ... }
  List<Asset> get assets { ... }
}
```

**Champs dépréciés (pour migration) :**
- `stale_assets` : Ancienne liste d'actifs
- `stale_cashBalance` : Ancien solde de liquidités

#### `Asset`
**Avant :**
```dart
class Asset {
  double quantity;
  double averagePrice;
}
```

**Après :**
```dart
class Asset {
  List<Transaction> transactions; // Injecté par Account.assets
  
  // Getters calculés dynamiquement
  double get quantity { ... }
  double get averagePrice { ... }
}
```

**Champs dépréciés (pour migration) :**
- `stale_quantity` : Ancienne quantité
- `stale_averagePrice` : Ancien PRU

**Nouveau champ :**
- `type` : Type d'actif (AssetType)

---

### 3. **Logique de Migration Automatique**

La migration s'exécute **une seule fois** au premier lancement de la nouvelle version.

#### Processus :
1. **Détection** : Le système vérifie si des données `stale_*` existent.
2. **Conversion** :
   - **Liquidités** : Création d'une transaction `Deposit` pour le `stale_cashBalance`.
   - **Actifs** : Pour chaque actif :
     - Calcul du coût total : `qty * pru`
     - Création d'une transaction `Buy` avec les paramètres :
       - `quantity` = `stale_quantity`
       - `price` = `stale_averagePrice`
       - `assetType` = type de l'actif
3. **Consolidation** : Un **seul dépôt initial** est créé pour couvrir le solde de liquidités + le coût de tous les actifs.
4. **Nettoyage** : Les champs `stale_*` sont mis à `null`.
5. **Finalisation** : Un flag `migrationV1Done` est enregistré pour éviter une nouvelle migration.

#### Exemple de Migration :
**Avant :**
```
Compte "PEA" :
- stale_cashBalance = 500€
- stale_assets = [
    { ticker: "AAPL", stale_quantity: 5, stale_averagePrice: 100€ }
  ]
```

**Transactions créées :**
```
1. Dépôt : 1000€ (500€ de liquidités + 500€ pour l'achat d'AAPL)
   Date : 2020-01-01
   Notes : "Migration v1 - Dépôt initial (Solde: 500.00€)"

2. Achat AAPL : -500€ (5 actions à 100€)
   Date : 2020-01-01
   Notes : "Migration v1 - Achat AAPL"
```

**Résultat :**
```
cashBalance (calculé) = 1000€ - 500€ = 500€ ✅
assets[0].quantity (calculé) = 5 ✅
assets[0].averagePrice (calculé) = 100€ ✅
```

---

## 🆕 Nouvelles Fonctionnalités

### 1. **Onglet "Journal"** (remplace "Correction")
- **Vue "Synthèse Actifs"** : DataTable affichant tous les actifs agrégés par ticker avec PRU, P/L, et valeur.
- **Vue "Transactions"** : Liste complète et triable de toutes les transactions avec options de modification/suppression.

### 2. **Planificateur Fonctionnel**
- Graphique de projection (BarChart empilé) simulant la croissance du portefeuille.
- Composantes : Capital initial, Capital investi (via plans d'épargne), Gains.
- Sélection de durée : 5, 10, 20, 30 ans.

### 3. **Nouveaux Formulaires**
- **AddTransactionScreen** : Création de transactions avec :
  - Recherche de tickers via API (auto-complétion)
  - Sélection de compte groupée par institution
  - Champs dynamiques selon le type de transaction
- **EditTransactionScreen** : Modification des transactions existantes.

### 4. **Graphique d'Allocation par Type d'Actif**
- Visualisation de la répartition du portefeuille par `AssetType` (Actions, ETF, Crypto, Liquidités, etc.).

---

## ⚠️ Points d'Attention

### 1. **Dates de Migration Fictives**
Les transactions migrées ont toutes la date du **1er janvier 2020**. Cela permet de :
- Ne pas perturber l'historique récent
- Faciliter l'identification visuelle des données migrées

**Impact** : L'historique réel des achats n'est pas conservé.

### 2. **Type d'Actif par Défaut**
Lors de l'ajout manuel d'une transaction `Buy`, le type d'actif est par défaut `Stock`. **Pensez à le changer** si vous achetez un ETF, une crypto, etc.

### 3. **Performance**
Les getters `assets` et `cashBalance` recalculent leurs valeurs à chaque appel. Pour un nombre raisonnable de transactions (< 1000 par compte), la performance est acceptable. Des optimisations pourront être ajoutées si nécessaire.

### 4. **Suppression de Portefeuille**
⚠️ **Actuellement, la suppression d'un portefeuille ne supprime pas automatiquement les transactions associées.** Ceci sera corrigé dans une prochaine version.

---

## 🧪 Tests Effectués

### Tests Unitaires
✅ Calcul du `cashBalance` avec différents types de transactions
✅ Calcul de la `quantity` et du `averagePrice` (PRU)
✅ Gestion des achats multiples (mise à jour du PRU)
✅ Gestion des ventes partielles et complètes

### Tests Manuels Recommandés
1. **Migration** : Créer un portefeuille avec l'ancienne version, mettre à jour, vérifier que les données sont correctement migrées.
2. **Ajout de transactions** : Tester tous les types (Dépôt, Achat, Vente, Dividende, etc.).
3. **Modification de transactions** : Modifier une transaction existante et vérifier que les soldes/PRU se mettent à jour.
4. **Suppression de transactions** : Supprimer une transaction et vérifier la cohérence.
5. **Planificateur** : Créer un plan d'épargne et vérifier que le graphique se met à jour.

---

## 📚 Ressources

### Fichiers Modifiés
- `lib/core/data/models/account.dart` : Ajout des getters calculés
- `lib/core/data/models/asset.dart` : Ajout des getters calculés et du champ `type`
- `lib/core/data/models/transaction.dart` : **NOUVEAU**
- `lib/core/data/models/transaction_type.dart` : **NOUVEAU**
- `lib/core/data/models/asset_type.dart` : **NOUVEAU**
- `lib/core/data/repositories/portfolio_repository.dart` : Gestion de la `transaction_box`
- `lib/features/00_app/providers/portfolio_provider.dart` : Logique de migration V1
- `lib/features/02_dashboard/ui/dashboard_screen.dart` : Bouton + dans l'AppBar
- `lib/features/03_overview/ui/overview_tab.dart` : Nouveau graphique par type d'actif
- `lib/features/04_journal/` : **NOUVEAU** (remplace `04_correction`)
- `lib/features/05_planner/ui/planner_tab.dart` : Graphique fonctionnel
- `lib/features/07_management/ui/screens/add_transaction_screen.dart` : **NOUVEAU**
- `lib/features/07_management/ui/screens/edit_transaction_screen.dart` : **NOUVEAU**

### Fichiers Supprimés
- `lib/features/04_correction/` : Remplacé par `04_journal`
- `lib/features/07_management/ui/screens/add_asset_screen.dart` : Remplacé par `add_transaction_screen.dart`

---

## 🐛 Bugs Connus

1. **Suppression de portefeuille** : Les transactions orphelines ne sont pas supprimées automatiquement.
2. **Synchronisation des prix** : La synchronisation des prix API ne fonctionne qu'après que les actifs soient calculés via les transactions.

---

## 🔮 Améliorations Futures

1. **Cache des getters** : Implémenter un système de mémorisation pour éviter les recalculs inutiles.
2. **Import/Export de transactions** : Permettre l'import de fichiers CSV de transactions bancaires.
3. **Filtrage avancé** : Ajouter des filtres par période, type de transaction, compte, etc. dans l'onglet Journal.
4. **Graphiques supplémentaires** : Évolution du solde dans le temps, répartition sectorielle, etc.

---

## 📧 Support

En cas de problème lié à la migration, vous pouvez :
1. Consulter les logs de debug (activer le mode développeur)
2. Vérifier que le flag `migrationV1Done` est bien enregistré
3. Sauvegarder vos données avant de relancer l'application
