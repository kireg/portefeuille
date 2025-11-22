# Plan d'Optimisation et de Refactoring

Ce document détaille la feuille de route pour l'optimisation globale de l'application, visant à améliorer la performance, la maintenabilité et le respect de l'architecture "Feature-First".

## Phase 1 : Renforcement de la Qualité et Standards
**Objectif** : Durcir les règles de développement pour garantir un code propre, performant et uniforme.

- [x] **Mise à jour du Linter** : Configurer `analysis_options.yaml` avec des règles strictes (pedantic/lints).
    - Forcer l'utilisation de `const` pour les widgets (gain de performance majeur).
    - Forcer le typage statique.
    - Interdire les `print` en production.
- [x] **Correction des avertissements** : Appliquer les corrections automatiques (`dart fix`) et manuelles sur l'ensemble du projet.
    - [x] Correction automatique (`dart fix --apply`) : 41 corrections.
    - [x] Renommage des champs obsolètes (`stale_` -> `stale`) pour respecter le camelCase.
    - [x] Remplacement complet de `withOpacity` par `withValues` (Core UI & Features).
    - [x] Correction des `use_build_context_synchronously` et autres warnings.
- [x] **Standardisation** : Vérifier que tous les fichiers respectent les conventions de nommage définies dans `ARCHITECTURE.md`.

## Phase 2 : Optimisation du State Management (`PortfolioProvider`)
**Objectif** : Alléger le "God Object" `PortfolioProvider` et optimiser les calculs.

- [ ] **Extraction des Calculs** : Déplacer la logique lourde (totaux, performances) hors de la méthode `build` ou des getters synchrones appelés fréquemment.
    - Utiliser des variables mises en cache (`_cachedTotalValue`, etc.) mises à jour uniquement lors de la modification des données.
- [ ] **Optimisation des Getters** : Transformer les getters coûteux (ex: `hasCrowdfunding`) en propriétés calculées une seule fois lors du chargement/mise à jour du portefeuille.
- [ ] **Séparation des Responsabilités** : Si le provider reste trop gros, extraire certaines logiques (ex: Sync, Migration) dans des services dédiés ou des sous-providers si nécessaire (bien que l'architecture actuelle utilise des services injectés, le provider fait beaucoup de "passe-plat").

## Phase 3 : Optimisation de l'UI et des Rebuilds
**Objectif** : Réduire les reconstructions inutiles de l'interface utilisateur.

- [ ] **Utilisation de `Selector`** : Remplacer les `context.watch<PortfolioProvider>()` globaux par des `Selector<PortfolioProvider, T>` dans les widgets qui n'ont besoin que d'une partie spécifique de l'état (ex: `DashboardScreen`).
- [ ] **Découpage des Widgets** : Identifier les gros widgets qui rebuildent trop souvent et les découper en composants plus petits et constants (`const`).
- [ ] **Lazy Loading** : Vérifier que les onglets ou listes lourdes sont chargés de manière paresseuse si possible.

## Phase 4 : Nettoyage, Architecture et Maintenance
**Objectif** : Assurer la pérennité du code et le respect strict de l'architecture modulaire.

- [ ] **Vérification des Imports** : S'assurer qu'aucune feature n'importe directement le code d'une autre feature (doit passer par `core` ou `RouteManager`).
- [ ] **Nettoyage du Code Mort** : Supprimer les fichiers, modèles ou méthodes non utilisés.
- [ ] **Documentation** : Mettre à jour la documentation technique si des changements majeurs ont été effectués.
