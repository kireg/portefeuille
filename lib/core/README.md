# Core Module

Ce dossier `lib/core` contient les briques fondamentales de l'application, partagées entre toutes les fonctionnalités (features). Il est conçu pour être indépendant des fonctionnalités spécifiques métier autant que possible.

## Structure

### 1. Data (`lib/core/data`)
Contient la couche de données de l'application.
- **Models** : Les classes de données, principalement annotées pour Hive (base de données locale).
- **Repositories** : Le pattern Repository pour abstraire l'accès aux données (Hive). Le `PortfolioRepository` est le point d'entrée principal.
- **Services** : Services techniques (API externes, IA, etc.).

### 2. UI (`lib/core/ui`)
Contient les éléments d'interface réutilisables (Design System).
- **Theme** : Définitions des couleurs (`AppColors`), typographie (`AppTypography`) et dimensions (`AppDimens`).
- **Widgets** : Composants atomiques réutilisables (Boutons, Cards, Inputs, etc.).

### 3. Utils (`lib/core/utils`)
Fonctions utilitaires, validateurs, formateurs et constantes globales.

---

## Hive Type IDs

L'application utilise [Hive](https://docs.hivedb.dev/) comme base de données locale NoSQL. Chaque classe stockée doit avoir un `typeId` unique.

**ATTENTION :** Ne jamais modifier un `typeId` existant sous peine de corrompre les données des utilisateurs existants. Pour ajouter un nouveau modèle, choisissez un ID libre.

| TypeId | Classe | Description |
| :--- | :--- | :--- |
| **0** | `Portfolio` | Racine du portefeuille, contient les institutions. |
| **1** | `Institution` | Banque ou plateforme (ex: Boursorama, Binance). |
| **2** | `Account` | Compte spécifique (ex: PEA, CTO). |
| **3** | `Asset` | Actif détenu (Action, Crypto, Projet Immo). |
| **4** | `AccountType` | Enum des types de comptes (PEA, CTO, Crypto...). |
| **5** | `SavingsPlan` | Plan d'épargne programmé (DCA). |
| **6** | `TransactionType` | Enum des types de transactions (Achat, Vente, Dividende...). |
| **7** | `Transaction` | Une opération financière unitaire. |
| **8** | `AssetType` | Enum des types d'actifs (Action, ETF, Crypto, Crowdfunding...). |
| **9** | `AssetMetadata` | Données enrichies d'un actif (Secteur, Logo, Détails Crowdfunding). |
| **10** | `PriceHistoryPoint` | Point d'historique de prix pour un actif. |
| **11** | `ExchangeRateHistory` | Historique des taux de change. |
| **12** | `SyncStatus` | Enum de l'état de synchronisation d'un actif. |
| **13** | `SyncLog` | Log des tentatives de synchronisation. |
| **14** | `RepaymentType` | Enum des types de remboursement (In Fine, Amortissable...). |
| **20** | `PortfolioValueHistoryPoint` | Historique de la valeur totale du portefeuille. |

## Bonnes Pratiques

1. **Dépendances** : Le `core` ne doit jamais dépendre d'une `feature`. Les features dépendent du `core`.
2. **Modèles** : Lors de la modification d'un modèle Hive :
   - Ajoutez les nouveaux champs à la fin.
   - Ne changez pas les index `@HiveField(x)` existants.
   - Lancez `flutter packages pub run build_runner build` pour régénérer les adaptateurs.
3. **UI** : Utilisez toujours les composants de `core/ui` plutôt que les widgets Flutter bruts pour garantir la cohérence visuelle.
