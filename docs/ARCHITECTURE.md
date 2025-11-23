# Architecture de l'Application Portefeuille

**Version**: 1.0.0  
**Date de création**: 18 novembre 2025  
**Dernière mise à jour**: 18 novembre 2025

---

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Principes architecturaux](#principes-architecturaux)
3. [Structure des dossiers](#structure-des-dossiers)
4. [Organisation par Features](#organisation-par-features)
5. [Couche Core](#couche-core)
6. [Règles de dépendances](#règles-de-dépendances)
7. [Conventions de nommage](#conventions-de-nommage)
8. [Gestion de l'état](#gestion-de-létat)
9. [Anti-patterns à éviter](#anti-patterns-à-éviter)

---

## Vue d'ensemble

L'application Portefeuille suit une **architecture modulaire basée sur les features**, inspirée de la Clean Architecture et du Domain-Driven Design (DDD). Chaque fonctionnalité est isolée dans son propre module, avec une couche `core/` partagée pour les éléments communs.

### Principes clés
- **Isolation des features** : Chaque feature est autonome et découplée
- **Réutilisabilité** : Les composants partagés sont dans `core/`
- **Séparation des responsabilités** : UI, logique métier et données sont séparées
- **Scalabilité** : Facilite l'ajout de nouvelles fonctionnalités sans impacter l'existant

---

## Principes architecturaux

### 1. **Feature-First Organization**
Chaque fonctionnalité majeure est un module indépendant dans `lib/features/`. Les features sont numérotées pour indiquer leur ordre logique dans le flux applicatif.

### 2. **Single Responsibility Principle**
- Chaque fichier a une responsabilité unique
- Un écran = un fichier
- Un widget complexe = un fichier dédié
- Un service = une responsabilité métier claire

### 3. **Dependency Injection via Provider**
- Les providers sont définis au niveau `00_app`
- Les dépendances sont injectées via le contexte
- Pas de singletons globaux (sauf nécessité absolue)

### 4. **Testing Strategy**
- **Tests Unitaires** : Obligatoires pour toute modification de logique métier ou de widget complexe.
- **Non-régression** : Chaque nouvelle fonctionnalité ou correction de bug doit être accompagnée de son test.

### 5. **Separation of Concerns**
```
UI (Widgets/Screens) → Providers (State Management) → Services/Repositories → Models
```

---

## Structure des dossiers

```
lib/
├── main.dart                    # Point d'entrée (réexporte 00_app/main.dart)
├── core/                        # Code partagé entre toutes les features
│   ├── data/                    # Couche de données partagée
│   │   ├── models/              # Modèles de domaine (Hive entities)
│   │   ├── repositories/        # Accès aux données (Hive boxes)
│   │   └── services/            # Services métier transversaux
│   ├── ui/                      # Composants UI réutilisables
│   │   ├── theme/               # Thème de l'application
│   │   ├── widgets/             # Widgets partagés
│   │   └── splash_screen.dart   # Écran de démarrage
│   └── utils/                   # Utilitaires et helpers
│       ├── constants.dart       # Constantes globales
│       ├── formatters/          # Formateurs (currency, date, etc.)
│       └── validators/          # Validateurs (ISIN, etc.)
│
└── features/                    # Modules fonctionnels
    ├── 00_app/                  # Configuration et bootstrap de l'app
    ├── 01_launch/               # Écran de lancement et onboarding
    ├── 02_dashboard/            # Tableau de bord principal
    ├── 03_overview/             # Vue d'ensemble du portefeuille
    ├── 04_journal/              # Journal des transactions
    ├── 05_planner/              # Planificateur financier
    ├── 06_settings/             # Paramètres de l'application
    └── 07_management/           # Gestion des entités (CRUD)
```

---

## Organisation par Features

### Structure standard d'une feature

Chaque feature **PEUT** contenir les dossiers suivants selon ses besoins :

```
features/XX_feature_name/
├── data/                        # (Optionnel) Modèles spécifiques à la feature
│   └── *_models.dart            # Modèles temporaires/locaux
├── ui/                          # Interface utilisateur
│   ├── screens/                 # (Optionnel) Écrans complets
│   │   └── *_screen.dart
│   ├── widgets/                 # (Optionnel) Widgets spécifiques
│   │   └── *.dart
│   ├── views/                   # (Optionnel) Vues réutilisables
│   │   └── *_view.dart
│   ├── providers/               # (Optionnel) Providers locaux
│   │   └── *_provider.dart
│   └── *_tab.dart ou *_screen.dart  # Fichier principal de la feature
├── logic/                       # (Optionnel) Logique métier isolée
└── services/                    # (Optionnel) Services spécifiques
```

**IMPORTANT** : Cette structure n'est **pas rigide**. Une feature peut :
- N'avoir qu'un seul fichier (ex: `05_planner/ui/planner_tab.dart`)
- Ne pas avoir de dossier `data/` si elle n'a pas de modèles spécifiques
- Ne pas avoir de `providers/` si elle utilise uniquement les providers globaux

### Description des features existantes

#### `00_app` - Application Core
**Responsabilité** : Configuration globale, bootstrap, providers principaux

**Structure** :
```
00_app/
├── main.dart                    # Point d'entrée principal avec setup Hive
├── providers/                   # Providers globaux
│   ├── portfolio_provider.dart  # État du portefeuille
│   └── settings_provider.dart   # Paramètres de l'app
├── services/                    # Services métier principaux
│   ├── calculation_service.dart # Calculs financiers
│   ├── transaction_service.dart # Gestion des transactions
│   ├── sync_service.dart        # Synchronisation API
│   ├── hydration_service.dart   # Hydratation des données
│   ├── migration_service.dart   # Migration de schéma
│   └── demo_data_service.dart   # Génération de données de démo
└── models/
    └── background_activity.dart # Modèles d'activité en arrière-plan
```

**Règle** : C'est la **seule feature** qui peut définir des providers globaux.

#### `01_launch` - Lancement et Onboarding
**Responsabilité** : Écran de lancement, wizard d'initialisation

**Structure** :
```
01_launch/
├── data/
│   └── wizard_models.dart       # Modèles temporaires pour le wizard
└── ui/
    ├── launch_screen.dart       # Écran principal
    └── widgets/
        └── initial_setup_wizard.dart  # Assistant de configuration
```

**Note** : Contient des modèles temporaires (`WizardInstitution`, `WizardAccount`) qui ne sont **pas persistés** dans Hive.

#### `02_dashboard` - Tableau de bord
**Responsabilité** : Vue principale de l'application

**Structure** :
```
02_dashboard/
└── ui/
    ├── dashboard_screen.dart    # Écran principal avec onglets
    └── widgets/                 # Widgets du dashboard
```

#### `03_overview` - Vue d'ensemble du portefeuille
**Responsabilité** : Affichage de la synthèse du portefeuille

**Structure** :
```
03_overview/
└── ui/
    └── widgets/
        └── portfolio_header.dart  # En-tête avec valeur totale
```

#### `04_journal` - Journal des transactions
**Responsabilité** : Historique et synthèse des transactions

**Structure** :
```
04_journal/
└── ui/
    ├── journal_tab.dart         # Onglet principal
    ├── views/
    │   ├── synthese_view.dart   # Vue synthétique
    │   └── transactions_view.dart  # Liste des transactions
    └── widgets/                 # Widgets spécifiques
```

#### `05_planner` - Planificateur financier
**Responsabilité** : Planification et projections

**Structure** :
```
05_planner/
└── ui/
    └── planner_tab.dart         # Onglet planificateur (minimal pour l'instant)
```

#### `06_settings` - Paramètres
**Responsabilité** : Configuration de l'application

**Structure** :
```
06_settings/
└── ui/
    ├── settings_screen.dart     # Écran de paramètres
    └── widgets/
        ├── app_settings.dart
        ├── appearance_settings.dart
        ├── portfolio_management_settings.dart
        └── reset_app_section.dart
```

#### `07_management` - Gestion CRUD
**Responsabilité** : Création, édition, suppression des entités

**Structure** :
```
07_management/
└── ui/
    ├── screens/                 # Écrans de formulaires
    │   ├── add_institution_screen.dart
    │   ├── add_account_screen.dart
    │   ├── add_transaction_screen.dart
    │   ├── edit_transaction_screen.dart
    │   └── add_savings_plan_screen.dart
    ├── widgets/
    │   ├── transaction_form_body.dart  # Formulaire principal
    │   └── form_sections/       # Sections du formulaire
    │       ├── _type_selector.dart
    │       ├── _account_selector.dart
    │       ├── _common_fields.dart
    │       ├── _asset_fields.dart
    │       ├── _cash_fields.dart
    │       └── _dividend_fields.dart
    └── providers/
        └── transaction_form_state.dart  # État du formulaire
```

**Note** : Cette feature contient un provider local (`transaction_form_state.dart`) car la logique du formulaire est complexe et spécifique à cette feature.

---

## Couche Core

### `core/data/`

#### `models/` - Modèles de domaine
**Responsabilité** : Entités métier persistées dans Hive

**Fichiers** :
- `portfolio.dart` - Portefeuille principal
- `institution.dart` - Institution financière
- `account.dart` - Compte
- `asset.dart` - Actif (action, obligation, etc.)
- `transaction.dart` - Transaction
- `savings_plan.dart` - Plan d'épargne
- `asset_metadata.dart` - Métadonnées d'actifs (prix, taux de change)
- `price_history_point.dart` - Point d'historique de prix
- `exchange_rate_history.dart` - Historique de taux de change
- `sync_log.dart` - Journal de synchronisation
- `*_type.dart` - Énumérations (AccountType, AssetType, TransactionType)
- `aggregated_*.dart` - Modèles d'agrégation (non persistés)
- `projection_data.dart` - Données de projection (non persistées)
- `app_data_backup.dart` - Modèle de sauvegarde

**Convention Hive** :
- Chaque modèle Hive a un `@HiveType(typeId: X)`
- Un fichier `.g.dart` généré par `build_runner`
- Les énumérations ont aussi des adapters

#### `repositories/` - Accès aux données
**Responsabilité** : Interface entre les providers et Hive

**Fichiers** :
- `portfolio_repository.dart` - CRUD du portefeuille

**Règle** : Les repositories sont les **seuls** à accéder directement aux boxes Hive.

#### `services/` - Services transversaux
**Responsabilité** : Services utilisables par toutes les features

**Fichiers** :
- `api_service.dart` - Communication avec APIs externes
- `backup_service.dart` - Sauvegarde/restauration
- `sync_log_export_service.dart` - Export des logs

### `core/ui/`

#### `theme/`
**Responsabilité** : Thème visuel de l'application

**Fichiers** :
- `app_theme.dart` - Configuration du thème Material

#### `widgets/`
**Responsabilité** : Widgets réutilisables dans toute l'app

**Fichiers** :
- `account_type_chip.dart` - Chip d'affichage du type de compte

**Règle** : Un widget est dans `core/ui/widgets/` **uniquement** s'il est utilisé dans **au moins 2 features différentes**.

#### Fichiers racine
- `splash_screen.dart` - Écran de démarrage (utilisé avant le chargement de l'app)

### `core/utils/`

#### Fichiers
- `constants.dart` - Constantes globales (noms de boxes Hive, clés, etc.)
- `currency_formatter.dart` - Formatage de devises
- `enum_helpers.dart` - Helpers pour énumérations
- `isin_validator.dart` - Validation de codes ISIN

**Règle** : Les utils sont des fonctions **pure** (sans état) et **réutilisables**.

---

## Règles de dépendances

### Hiérarchie des dépendances

```
Features (07, 06, 05, 04, 03, 02, 01)
    ↓ (peuvent importer)
Feature 00_app (providers, services)
    ↓ (peuvent importer)
Core (data, ui, utils)
    ↓ (peuvent importer)
Packages externes (provider, hive, etc.)
```

### Règles strictes

#### ✅ **AUTORISÉ**

1. **Toutes les features peuvent importer `core/`**
   ```dart
   import 'package:portefeuille/core/data/models/portfolio.dart';
   import 'package:portefeuille/core/ui/widgets/account_type_chip.dart';
   import 'package:portefeuille/core/utils/currency_formatter.dart';
   ```

2. **Toutes les features peuvent importer les providers de `00_app/providers/`**
   ```dart
   import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
   import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
   ```

3. **Toutes les features peuvent importer les services de `00_app/services/`**
   ```dart
   import 'package:portefeuille/features/00_app/services/calculation_service.dart';
   ```

4. **Une feature peut naviguer vers une autre feature** (via navigation Flutter)
   ```dart
   // Depuis 06_settings, navigation vers 01_launch
   import 'package:portefeuille/features/01_launch/ui/launch_screen.dart';
   Navigator.push(context, MaterialPageRoute(builder: (_) => LaunchScreen()));
   ```

5. **`00_app` peut importer `core/`**
   ```dart
   import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
   ```

6. **Une feature peut avoir des providers locaux** (si logique complexe et spécifique)
   ```dart
   // Exemple : 07_management/ui/providers/transaction_form_state.dart
   ```

#### ❌ **INTERDIT**

1. **Une feature ne peut PAS importer une autre feature** (sauf pour navigation)
   ```dart
   // ❌ INTERDIT
   import 'package:portefeuille/features/03_overview/ui/widgets/portfolio_header.dart';
   ```
   **Solution** : Si un widget doit être partagé, le déplacer dans `core/ui/widgets/`.

2. **`core/` ne peut PAS importer `features/`**
   ```dart
   // ❌ INTERDIT dans core/
   import 'package:portefeuille/features/00_app/providers/portfolio_provider.dart';
   ```
   **Raison** : `core/` est la couche de base, elle ne doit pas dépendre des features.

3. **Une feature ne peut PAS accéder directement aux boxes Hive**
   ```dart
   // ❌ INTERDIT
   final box = Hive.box<Portfolio>('portfolio');
   ```
   **Solution** : Passer par `PortfolioRepository` ou `PortfolioProvider`.

4. **Pas de logique métier dans les widgets**
   ```dart
   // ❌ INTERDIT
   class MyWidget extends StatelessWidget {
     void calculateTotalValue() {
       // Logique métier complexe ici
     }
   }
   ```
   **Solution** : Déplacer la logique dans un provider ou un service.

5. **Pas de providers multiples pour la même responsabilité**
   - Il existe **un seul** `PortfolioProvider` (dans `00_app`)
   - Il existe **un seul** `SettingsProvider` (dans `00_app`)

### Graphe de dépendances autorisées

```
┌─────────────────────────────────────────────────┐
│  Features 01-07                                 │
│  ├─ UI (screens, widgets)                       │
│  ├─ Providers locaux (optionnel)                │
│  └─ Data locale (optionnel)                     │
└────────────┬────────────────────────────────────┘
             │ imports ↓
┌────────────▼────────────────────────────────────┐
│  Feature 00_app                                 │
│  ├─ providers/ (GLOBAUX)                        │
│  ├─ services/ (métier principal)                │
│  └─ main.dart (bootstrap)                       │
└────────────┬────────────────────────────────────┘
             │ imports ↓
┌────────────▼────────────────────────────────────┐
│  Core                                           │
│  ├─ data/ (models, repos, services)             │
│  ├─ ui/ (theme, widgets)                        │
│  └─ utils/ (helpers, formatters)                │
└────────────┬────────────────────────────────────┘
             │ imports ↓
┌────────────▼────────────────────────────────────┐
│  Packages externes                              │
│  (provider, hive, fl_chart, etc.)               │
└─────────────────────────────────────────────────┘
```

---

## Conventions de nommage

### Fichiers

| Type | Convention | Exemple |
|------|-----------|---------|
| **Écran** | `*_screen.dart` | `dashboard_screen.dart` |
| **Widget** | `*.dart` ou `*_widget.dart` | `portfolio_header.dart` |
| **Provider** | `*_provider.dart` | `portfolio_provider.dart` |
| **Service** | `*_service.dart` | `calculation_service.dart` |
| **Repository** | `*_repository.dart` | `portfolio_repository.dart` |
| **Modèle** | `*.dart` (nom de l'entité) | `portfolio.dart`, `account.dart` |
| **Énumération** | `*_type.dart` | `account_type.dart` |
| **Vue** | `*_view.dart` | `transactions_view.dart` |
| **Tab** | `*_tab.dart` | `journal_tab.dart` |
| **Fichiers privés** | Préfixer par `_` | `_type_selector.dart` |

### Classes

| Type | Convention | Exemple |
|------|-----------|---------|
| **Screen** | `*Screen extends StatelessWidget/StatefulWidget` | `class DashboardScreen extends StatelessWidget` |
| **Widget** | `*Widget` ou nom descriptif | `class PortfolioHeader extends StatelessWidget` |
| **Provider** | `*Provider extends ChangeNotifier` | `class PortfolioProvider extends ChangeNotifier` |
| **Service** | `*Service` | `class CalculationService` |
| **Repository** | `*Repository` | `class PortfolioRepository` |
| **Modèle Hive** | Nom de l'entité + `@HiveType` | `@HiveType(typeId: 0) class Portfolio` |

### Dossiers

- **snake_case** : `transaction_service.dart`
- **Numérotation des features** : `00_app`, `01_launch`, etc.
- **Dossiers privés** : Pas de préfixe `_` pour les dossiers (uniquement pour les fichiers)

---

## Gestion de l'état

### Architecture Provider

L'application utilise **Provider** pour la gestion d'état.

#### Providers globaux (dans `00_app/providers/`)

1. **`PortfolioProvider`**
   - **Responsabilité** : État global du portefeuille
   - **Données** : Portfolio, institutions, comptes, actifs
   - **Méthodes** : CRUD via `PortfolioRepository`, calculs via `CalculationService`
   - **Utilisation** : Lecture via `context.watch<PortfolioProvider>()`

2. **`SettingsProvider`**
   - **Responsabilité** : Paramètres de l'application
   - **Données** : Devise de base, couleur du thème, préférences
   - **Persistance** : Hive box `settings`
   - **Utilisation** : Lecture via `context.watch<SettingsProvider>()`

#### Providers locaux (dans `features/XX/ui/providers/`)

Exemple : `transaction_form_state.dart` (dans `07_management`)
- **Quand créer** : Si la logique d'état est complexe **ET** spécifique à une feature
- **Scope** : Limité à la feature, ne pas exposer globalement

#### Services (dans `00_app/services/` ou `core/data/services/`)

Les services sont des classes **stateless** qui encapsulent de la logique métier :
- `CalculationService` : Calculs financiers (valeur totale, P&L, etc.)
- `TransactionService` : Logique de traitement des transactions
- `SyncService` : Synchronisation avec API
- `ApiService` : Communication HTTP

**Règle** : Les services sont injectés via Provider et consommés par les providers.

### Flux de données

```
UI (Widget)
  ↓ watch/read
Provider (State Management)
  ↓ appelle
Service (Business Logic)
  ↓ appelle
Repository (Data Access)
  ↓ lit/écrit
Hive Box (Persistence)
```

---

## Anti-patterns à éviter

### ❌ 1. Ajouter du code dans un fichier existant au lieu de créer un nouveau fichier

**Problème** :
```dart
// ❌ Dans dashboard_screen.dart
class DashboardScreen extends StatelessWidget { ... }

// Ajouter un nouveau widget ici au lieu de créer un fichier
class NewComplexWidget extends StatelessWidget { ... }
```

**Solution** :
```dart
// ✅ Créer widgets/new_complex_widget.dart
class NewComplexWidget extends StatelessWidget { ... }

// Puis importer dans dashboard_screen.dart
import 'widgets/new_complex_widget.dart';
```

**Règle** : Un fichier Dart ne doit contenir qu'une **seule classe publique principale** (sauf classes helper très petites).

### ❌ 2. Mettre un widget partagé dans une feature au lieu de `core/ui/widgets/`

**Problème** :
```dart
// ❌ Dans features/03_overview/ui/widgets/account_card.dart
// Mais ce widget est aussi utilisé dans 02_dashboard et 07_management
```

**Solution** :
```dart
// ✅ Déplacer dans core/ui/widgets/account_card.dart
```

**Règle** : Si un widget est utilisé dans **2+ features**, il doit être dans `core/ui/widgets/`.

### ❌ 3. Importer une feature depuis une autre (sauf navigation)

**Problème** :
```dart
// ❌ Dans features/02_dashboard/ui/dashboard_screen.dart
import 'package:portefeuille/features/03_overview/ui/widgets/portfolio_header.dart';
```

**Solution** :
```dart
// ✅ Déplacer portfolio_header.dart dans core/ui/widgets/
import 'package:portefeuille/core/ui/widgets/portfolio_header.dart';
```

### ❌ 4. Accéder directement aux boxes Hive depuis une feature

**Problème** :
```dart
// ❌ Dans un widget
final box = Hive.box<Portfolio>('portfolio');
final portfolio = box.get('default');
```

**Solution** :
```dart
// ✅ Utiliser le provider
final provider = context.watch<PortfolioProvider>();
final portfolio = provider.portfolio;
```

### ❌ 5. Dupliquer la logique métier

**Problème** :
```dart
// ❌ Même calcul dans plusieurs widgets
double calculateTotalValue() {
  // Logique complexe répétée partout
}
```

**Solution** :
```dart
// ✅ Centraliser dans CalculationService ou PortfolioProvider
final totalValue = provider.totalValue; // Calculé une fois
```

### ❌ 6. Créer plusieurs providers pour la même responsabilité

**Problème** :
```dart
// ❌ Créer un PortfolioStateProvider dans 02_dashboard
// Alors qu'il existe déjà PortfolioProvider dans 00_app
```

**Solution** :
```dart
// ✅ Utiliser le provider existant
context.watch<PortfolioProvider>();
// OU MIEUX (Optimisation) :
context.select<PortfolioProvider, Portfolio?>((p) => p.activePortfolio);
```

**Exception** : Providers locaux pour état de formulaire complexe (ex: `transaction_form_state.dart`).

### ❌ 7. Mettre de la logique métier dans les widgets

**Problème** :
```dart
// ❌ Dans un widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Logique métier complexe ici
    double totalValue = 0;
    for (var account in accounts) {
      for (var asset in account.assets) {
        totalValue += asset.value * asset.quantity;
      }
    }
    return Text('$totalValue');
  }
}
```

**Solution** :
```dart
// ✅ Logique dans provider ou service
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final totalValue = context.watch<PortfolioProvider>().totalValue;
    return Text('$totalValue');
  }
}
```

### ❌ 8. Modèles dans les features au lieu de `core/data/models/`

**Problème** :
```dart
// ❌ Créer features/04_journal/data/transaction_summary.dart
// Alors que c'est un modèle métier partagé
```

**Solution** :
```dart
// ✅ Mettre dans core/data/models/transaction_summary.dart
```

**Exception** : Modèles **temporaires** spécifiques à une feature (ex: `wizard_models.dart` dans `01_launch`).

---

## Checklist pour ajouter une nouvelle feature

- [ ] Créer le dossier `features/XX_feature_name/`
- [ ] Créer uniquement les sous-dossiers nécessaires (`ui/`, `data/`, etc.)
- [ ] Respecter les conventions de nommage
- [ ] Vérifier que les imports respectent les règles de dépendances
- [ ] Si widget réutilisable → le mettre dans `core/ui/widgets/`
- [ ] Si modèle partagé → le mettre dans `core/data/models/`
- [ ] Si service transversal → le mettre dans `core/data/services/` ou `00_app/services/`
- [ ] Documenter les nouveaux modèles Hive dans cette architecture
- [ ] Tester que la feature fonctionne en isolation

---

## Checklist pour modifier du code existant

- [ ] Identifier la responsabilité du fichier à modifier
- [ ] Si ajout d'une classe importante → créer un nouveau fichier
- [ ] Si widget utilisé ailleurs → vérifier qu'il est dans `core/`
- [ ] Si logique métier → vérifier qu'elle est dans un service/provider
- [ ] Respecter le flux de données (UI → Provider → Service → Repository)
- [ ] Ne pas contourner les abstractions (ex: accès direct à Hive)

---

## Annexes

### Technologies utilisées

- **Framework** : Flutter 3.4+
- **Langage** : Dart 3.4+
- **State Management** : Provider 6.1+
- **Persistence** : Hive 2.2+ (NoSQL local)
- **Code Generation** : build_runner, hive_generator
- **Charts** : fl_chart 1.1+
- **Localisation** : intl 0.20+

### Références

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

**Maintenu par** : L'équipe Portefeuille  
**Contact** : [À définir]  
**Licence** : [À définir]
