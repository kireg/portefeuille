# Plan d'Optimisation - 23 Novembre 2025

Ce document recense les problèmes identifiés dans l'application et propose un plan d'action détaillé pour les résoudre, classés par ordre de priorité.

---

## 1. 🔴 Architecture : Refactoring du `PortfolioProvider` (God Object)

**Problème :**
Le fichier `portfolio_provider.dart` est devenu un "God Object" (près de 900 lignes). Il centralise trop de responsabilités : gestion de l'état des portefeuilles, CRUD des transactions, logique métier des calculs, gestion des imports/exports, et synchronisation.
Cela viole le principe de responsabilité unique (SRP) et rend le code difficile à maintenir, à tester et à faire évoluer.

**Objectif :**
Découper ce provider en plusieurs unités logiques respectant la Clean Architecture et l'organisation Feature-First du projet, tout en maintenant la cohérence de l'état global.

**Tâches à accomplir :**

*   [x] **Création de `TransactionProvider`** (`lib/features/00_app/providers/transaction_provider.dart`) :
    *   Déplacer la logique CRUD (`add`, `update`, `delete`) des transactions.
    *   Ce provider utilisera `TransactionService` et `PortfolioRepository`.
    *   Il devra notifier `PortfolioProvider` (ou déclencher un rafraîchissement) après une modification pour mettre à jour les agrégats.

*   [x] **Création de `PortfolioCalculationProvider`** (ou `PortfolioStateProvider`) :
    *   Extraire la logique de calcul (`CalculationService`, getters calculés comme `totalValue`, `totalPL`).
    *   Ce provider prendra en entrée l'état brut du `PortfolioProvider` et retournera un objet `AggregatedPortfolioData`.
    *   Cela séparera la *donnée brute* de la *donnée dérivée*.

*   [x] **Allègement de `PortfolioProvider`** :
    *   Ne conserver que la gestion de la structure (Portefeuilles / Institutions / Comptes) et le chargement initial.
    *   Il reste la "Source de Vérité" pour la hiérarchie des objets.

*   [x] **Injection de Dépendances (`main.dart`)** :
    *   Enregistrer les nouveaux providers dans le `MultiProvider`.
    *   Gérer les dépendances entre providers (ex: `ProxyProvider` si nécessaire, ou injection via constructeur).

*   [x] **Mise à jour de l'UI** :
    *   Refactoriser les appels dans les vues (ex: `TransactionsView`, `AddTransactionScreen`) pour utiliser les nouveaux providers spécifiques.

---

## 2. 🔴 Performance Critique : Import en Masse (Batch Import)

**Problème :**
L'importation ligne par ligne (`addTransaction`) déclenche un recalcul complet de l'application à chaque itération. Avec le refactoring architectural (Point 1), cette logique doit être implémentée directement dans le nouveau `TransactionProvider` de manière optimisée.

**Tâches à accomplir :**

*   [x] **Core / Repository** :
    *   Ajouter `saveTransactions(List<Transaction> transactions)` dans `PortfolioRepository`.
    *   Optimiser pour une écriture groupée (Batch Write) dans Hive.

*   [x] **TransactionProvider** :
    *   Implémenter `addTransactions(List<Transaction> transactions)`.
    *   Cette méthode doit :
        1.  Sauvegarder toutes les transactions en une fois.
        2.  Mettre à jour les prix des assets concernés (si nécessaire).
        3.  Ne notifier les écouteurs qu'une seule fois à la fin.

*   [x] **UI Import (Crowdfunding / PDF / Wizard)** :
    *   Remplacer les boucles `for (tx in list) provider.addTransaction(tx)` par `provider.addTransactions(list)`.

---

## 2.5. 🎨 UI : Centrage des Cards Overview

**Demande :**
Centrer horizontalement et verticalement le contenu des cartes dans la section "Solde total" de l'onglet Overview.

**Tâches à accomplir :**

*   [x] **PortfolioHeader** :
    *   Modifier `_buildSummaryCard` pour centrer le contenu (Icon + Label et Valeur).

---

## 3. 🟡 Performance Graphique : Rendu de l'Arrière-plan

**Problème :**
Le widget `AppAnimatedBackground` utilise un `BackdropFilter` (flou temps réel) très coûteux en ressources GPU sur chaque écran.

**Tâches à accomplir :**

*   [x] **Optimisation** :
    *   Remplacer la stack `Container` + `BackdropFilter` par une solution performante.
    *   **Option A (Shader)** : Utiliser un `MeshGradient` pour un rendu natif fluide.
    *   **Option B (Image)** : Utiliser une image pré-calculée ou un asset statique animé par opacité.
    *   *Solution retenue : Remplacement des orbes solides + BackdropFilter par des orbes avec RadialGradient.*

---

## 4. 🟡 Fiabilité : Gestion des Erreurs de Conversion

**Problème :**
Les erreurs de taux de change sont silencieuses. L'utilisateur peut voir des valeurs incorrectes (fallback à 1.0) sans avertissement.

**Tâches à accomplir :**

*   [x] **PortfolioCalculationProvider (Nouveau)** :
    *   Ajouter un état d'erreur (`hasConversionError`, `failedCurrencies`).
    *   Stocker les paires de devises en échec lors du calcul.

*   [ ] **UI** :
    *   Afficher une alerte visuelle (icône warning) dans le Dashboard si une erreur de conversion est présente.
    *   Permettre à l'utilisateur de relancer la récupération des taux.

---

## 5. 🟢 UX : États Vides (Empty States)

**Problème :**
Manque de guidage utilisateur sur les écrans vides (Plans d'épargne, Institutions, Crowdfunding).

**Tâches à accomplir :**

*   [ ] **Création de Widgets** :
    *   `EmptySavingsPlanWidget` avec bouton d'action.
    *   `EmptyCrowdfundingWidget` avec bouton d'import.
    *   Améliorer l'état vide de la liste des institutions.

---

## 6. 🟢 UX : Feedback Visuel lors des Imports

**Problème :**
Loader indéterminé lors des imports longs.

**Tâches à accomplir :**

*   [ ] **UI Import** :
    *   Ajouter une barre de progression réelle (X / Y projets traités).
    *   Afficher l'étape en cours ("Analyse...", "Sauvegarde...", "Mise à jour des prix...").
