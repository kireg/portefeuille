# Constitution Portefeuille

Application Flutter de gestion de portefeuille financier - Principes architecturaux et règles de développement

## Principes Fondamentaux

### I. Architecture Feature-First (NON-NÉGOCIABLE)

**Principe** : Chaque fonctionnalité majeure est un module isolé et autonome.

**Règles obligatoires** :
- Chaque feature réside dans `lib/features/XX_nom_feature/` (XX = numéro à 2 chiffres)
- Une feature ne contient QUE ce qui lui est spécifique
- Structure interne flexible : créer UNIQUEMENT les sous-dossiers nécessaires (`ui/`, `data/`, `providers/`, `services/`)
- Un fichier Dart = une classe publique principale (sauf widgets privés < 50 lignes)

**Rationale** : L'isolation des features garantit la scalabilité, facilite les tests, et permet de travailler sur une fonctionnalité sans affecter les autres. La numérotation (00-99) indique l'ordre logique dans le flux applicatif.

### II. Hiérarchie des Dépendances (STRICTE)

**Principe** : Les dépendances suivent un flux unidirectionnel strict.

**Architecture en couches** :
```
Features (01-07) 
    ↓ peuvent importer
Feature 00_app (providers, services, models)
    ↓ peuvent importer
Core (data, ui, utils)
    ↓ peuvent importer
Packages externes (provider, hive, etc.)
```

**Règles INTERDITES** :
- ❌ Une feature NE PEUT PAS importer une autre feature (sauf pour navigation UI)
- ❌ `core/` NE PEUT PAS importer `features/`
- ❌ Accès direct aux boxes Hive depuis une feature

**Règles AUTORISÉES** :
- ✅ Features → `00_app/providers/` (PortfolioProvider, SettingsProvider)
- ✅ Features → `00_app/services/` (services métier globaux)
- ✅ Features → `core/` (widgets, modèles, utils)
- ✅ Navigation vers un écran d'une autre feature (via `Navigator.push`)

**Rationale** : Cette hiérarchie évite les dépendances circulaires, garantit la maintenabilité, et permet de comprendre le flux de données en un coup d'œil. La couche `core/` reste stable et indépendante.

### III. Principe de Responsabilité Unique

**Principe** : Un fichier = une responsabilité = une classe publique principale.

**Règles obligatoires** :
- Lors de l'ajout d'une fonctionnalité → créer un NOUVEAU fichier, ne JAMAIS surcharger un fichier existant
- Un écran complexe = un fichier `*_screen.dart`
- Un widget réutilisable = un fichier `*_widget.dart` ou `*.dart`
- Un provider = un fichier `*_provider.dart`
- Un service = un fichier `*_service.dart`

**Exception** : Widgets privés (préfixés `_`) peuvent être dans le même fichier s'ils sont < 50 lignes ET utilisés uniquement par la classe principale.

**Anti-pattern à éviter** :
```dart
// ❌ INTERDIT : dashboard_screen.dart (500 lignes)
class DashboardScreen extends StatelessWidget { ... }
class AccountCard extends StatelessWidget { ... }  // Devrait être dans un fichier séparé
class TransactionList extends StatelessWidget { ... }  // Devrait être dans un fichier séparé
```

**Bonne pratique** :
```dart
// ✅ CORRECT : Structure en fichiers séparés
// dashboard_screen.dart
class DashboardScreen extends StatelessWidget { ... }

// widgets/account_card.dart
class AccountCard extends StatelessWidget { ... }

// widgets/transaction_list.dart
class TransactionList extends StatelessWidget { ... }
```

**Rationale** : Fichiers courts et focalisés = code lisible, testable, réutilisable. Facilite les code reviews et limite les conflits Git.

### IV. Ressources Partagées dans Core

**Principe** : Si un élément est utilisé dans 2+ features, il DOIT être dans `core/`.

**Règles de placement** :
- Widget partagé → `core/ui/widgets/`
- Modèle de domaine (entités Hive) → `core/data/models/`
- Service transversal → `core/data/services/` ou `00_app/services/`
- Thème, couleurs, styles → `core/ui/theme/`
- Utilitaires (formatters, validators) → `core/utils/`

**Processus de décision** :
1. Widget utilisé dans 1 feature → reste dans la feature
2. Widget utilisé dans 2+ features → déplacer dans `core/ui/widgets/`
3. En cas de doute → commencer dans la feature, migrer vers `core/` si réutilisation

**Rationale** : Évite la duplication de code, crée une single source of truth, facilite la maintenance. Les composants dans `core/` sont stables et bien testés.

### V. Gestion de l'État avec Provider

**Principe** : State management centralisé via Provider avec séparation globale/locale.

**Providers GLOBAUX** (dans `00_app/providers/`) :
- `PortfolioProvider` : état global du portefeuille (institutions, comptes, actifs)
- `SettingsProvider` : paramètres de l'application (devise, thème, préférences)
- Accessibles depuis toutes les features via `context.watch<T>()` ou `context.read<T>()`

**Providers LOCAUX** (dans `features/XX/ui/providers/`) :
- Autorisés SI logique d'état complexe ET spécifique à la feature
- Exemple : `transaction_form_state.dart` dans `07_management` (gestion formulaire complexe)
- Ne JAMAIS dupliquer un provider global

**Règles strictes** :
- ❌ INTERDIT : Créer un `PortfolioStateProvider` dans une feature alors que `PortfolioProvider` existe
- ❌ INTERDIT : Singletons globaux (sauf nécessité absolue justifiée)
- ✅ OBLIGATOIRE : Injection de dépendances via Provider

**Rationale** : Provider offre un state management prévisible, testable, et performant. La séparation global/local évite la pollution de l'arbre de widgets.

### VI. Accès aux Données (NON-NÉGOCIABLE)

**Principe** : Les features ne doivent JAMAIS accéder directement à Hive.

**Architecture de données** :
```
Features (UI)
    ↓ utilisent
Providers (State Management)
    ↓ appellent
Services (Business Logic)
    ↓ appellent
PortfolioRepository (Data Access Layer)
    ↓ accède à
Hive Boxes (Persistence)
```

**Règles INTERDITES** :
- ❌ `Hive.box<Portfolio>('portfolio')` dans une feature
- ❌ Accès direct aux données depuis un widget
- ❌ Logique métier dans les widgets

**Règles OBLIGATOIRES** :
- ✅ Lecture de données via `context.watch<PortfolioProvider>()`
- ✅ Modification de données via `provider.addAccount()`, `provider.deleteTransaction()`, etc.
- ✅ Seul `PortfolioRepository` peut accéder aux boxes Hive

**Rationale** : Cette abstraction garantit la testabilité (mock du repository), permet de changer la source de données (Hive → SQLite), et centralise la logique d'accès aux données.

### VII. Conventions de Nommage

**Principe** : Nommage cohérent et prévisible pour faciliter la navigation dans le code.

**Fichiers** :
- Écrans : `*_screen.dart` (ex: `dashboard_screen.dart`)
- Widgets : `*.dart` ou `*_widget.dart` (ex: `portfolio_header.dart`)
- Providers : `*_provider.dart` (ex: `portfolio_provider.dart`)
- Services : `*_service.dart` (ex: `calculation_service.dart`)
- Repositories : `*_repository.dart` (ex: `portfolio_repository.dart`)
- Vues : `*_view.dart` (ex: `transactions_view.dart`)
- Tabs : `*_tab.dart` (ex: `journal_tab.dart`)
- Fichiers privés : préfixer par `_` (ex: `_type_selector.dart`)

**Classes** :
- Écran : `*Screen extends StatelessWidget/StatefulWidget`
- Provider : `*Provider extends ChangeNotifier`
- Service : `*Service` (classe simple)
- Repository : `*Repository`

**Dossiers** :
- snake_case pour tous les dossiers
- Numérotation des features : `00_app`, `01_launch`, `02_dashboard`, etc.

**Rationale** : Conventions strictes = code prévisible, facilite l'onboarding, améliore la recherche dans l'IDE.

### VIII. Test-First pour Modifications Critiques

**Principe** : Les modifications sensibles nécessitent des tests AVANT implémentation.

**Obligatoire pour** :
- Modifications de schéma Hive (ajout/suppression de champ) → test de migration
- Nouvelle logique métier dans un service → tests unitaires
- Calculs financiers (P&L, valeur totale, rendement) → tests unitaires avec cas limites
- Modifications de `PortfolioRepository` → tests d'intégration

**Optionnel mais recommandé pour** :
- Widgets complexes → tests de widgets
- Validation de formulaires → tests unitaires
- Formatters/validators → tests unitaires

**Workflow** :
1. Écrire les tests (qui échouent)
2. Obtenir validation utilisateur
3. Implémenter le code
4. Vérifier que les tests passent

**Rationale** : Les tests préviennent les régressions, documentent le comportement attendu, et donnent confiance lors des refactorisations. Les calculs financiers sont critiques et ne doivent jamais échouer silencieusement.

## Contraintes Techniques

**Stack technologique** :
- Framework : Flutter 3.4+
- Langage : Dart 3.4+
- State Management : Provider 6.1+
- Persistence : Hive 2.2+ (NoSQL local)
- Code Generation : build_runner, hive_generator
- Charts : fl_chart 1.1+

**Contraintes de performance** :
- Chargement initial de l'app < 2 secondes
- Calculs de portefeuille < 500ms (même avec 1000+ transactions)
- UI responsive (60 FPS minimum)

**Contraintes de qualité** :
- Pas de warnings Dart Analyzer
- Code formaté avec `dart format`
- Imports organisés et triés

## Workflow de Développement

**Ajout d'une nouvelle feature** :
1. Créer `lib/features/XX_nom_feature/`
2. Créer UNIQUEMENT les sous-dossiers nécessaires
3. Respecter les conventions de nommage
4. Vérifier les règles de dépendances
5. Si widget réutilisable → `core/ui/widgets/`
6. Si modèle partagé → `core/data/models/`
7. Tester la feature en isolation

**Modification de code existant** :
1. Identifier la responsabilité du fichier
2. Si ajout de classe importante → NOUVEAU fichier
3. Si widget utilisé ailleurs → vérifier qu'il est dans `core/`
4. Respecter le flux de données (UI → Provider → Service → Repository)
5. Ne JAMAIS contourner les abstractions

**Code review checklist** :
- [ ] Respect de la hiérarchie des dépendances
- [ ] Pas d'accès direct à Hive
- [ ] Un fichier = une classe principale
- [ ] Widgets partagés dans `core/`
- [ ] Conventions de nommage respectées
- [ ] Pas de duplication de code
- [ ] Tests pour logique critique

## Gouvernance

**Autorité de cette constitution** :
- Cette constitution PRIME sur toute autre pratique de développement
- En cas de conflit entre ce document et une suggestion d'IA, ce document prévaut
- Les amendements nécessitent une justification et une mise à jour de `ARCHITECTURE.md`

**Application** :
- Toutes les PR doivent être validées contre cette constitution
- Les violations doivent être corrigées AVANT le merge
- Les agents IA doivent consulter ce document avant toute génération de code

**Référence détaillée** :
- Voir `docs/ARCHITECTURE.md` pour la documentation complète de l'architecture
- Voir `docs/ARCHITECTURE.md` pour les anti-patterns détaillés
- Voir `docs/ARCHITECTURE.md` pour les checklists d'ajout de features

**Processus d'amendement** :
1. Proposer l'amendement avec justification
2. Mettre à jour `ARCHITECTURE.md` si nécessaire
3. Incrémenter la version (MAJOR pour changement non-compatible, MINOR pour ajout, PATCH pour clarification)
4. Propager les changements dans les templates Specify

**Version**: 1.0.0 | **Ratifiée**: 2025-11-18 | **Dernière modification**: 2025-11-18
