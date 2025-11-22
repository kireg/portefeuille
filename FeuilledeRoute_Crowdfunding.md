# Feuille de Route : Intégration du Crowdfunding Immobilier

## 1. Contexte et Objectifs
L'objectif est d'intégrer une nouvelle classe d'actifs : le **Crowdfunding Immobilier**.
Cette classe d'actifs nécessite un suivi spécifique en raison de sa nature (durée définie, illiquidité, flux de trésorerie prévisibles) et de ses modes de remboursement.

## 2. Spécificités du Crowdfunding Immobilier
*   **Valorisation** : Basée sur le Capital Restant Dû (CRD).
*   **Revenus** : Intérêts (coupons) ou plus-value in fine.
*   **Horizon** : Défini par des durées cibles, mais sujet à retards.
*   **Localisation** : Importance géographique du projet.
*   **Remboursement** : Plusieurs modes (In Fine total, ou Intérêts mensuels + Capital in fine).

## 3. Modifications du Modèle de Données

### 3.1. AssetType (Enum)
*   Ajouter `RealEstateCrowdfunding` dans `lib/core/data/models/asset_type.dart`.

### 3.2. Nouveaux Enums
Créer `lib/core/data/models/repayment_type.dart` :
*   `InFine` : Capital + Intérêts versés en une seule fois à la clôture.
*   `MonthlyInterest` : Intérêts versés mensuellement (ou périodiquement), Capital remboursé à la fin (Bond-like).
*   *(Optionnel) Amortizing : Capital + Intérêts remboursés mensuellement (type prêt classique).*

### 3.3. Asset (Classe)
Ajouter les champs suivants dans `lib/core/data/models/asset.dart` (nullables, spécifiques au Crowdfunding) :

**Identification & Localisation**
*   `platform` (String) : Nom de la plateforme (ex: ClubFunding, Anaxago).
*   `projectName` (String) : Nom du projet (peut utiliser le champ `name` existant).
*   `location` (String) : Adresse ou Ville/Pays du projet (pour la future vue Carte).

**Durées (en mois)**
*   `minDuration` (int) : Durée minimale contractuelle.
*   `targetDuration` (int) : Durée cible (utilisée pour les projections de base).
*   `maxDuration` (int) : Durée maximale contractuelle (au-delà, des pénalités s'appliquent souvent).

**Financier**
*   `expectedYield` (double) : Taux de rendement annuel cible (ex: 10.0 pour 10%).
*   `repaymentType` (RepaymentType) : Mode de remboursement (`InFine` ou `MonthlyInterest`).
*   `riskRating` (String) : Note de risque (ex: "A+", "B").

### 3.4. TransactionType (Enum)
Adapter `lib/core/data/models/transaction_type.dart` pour gérer les flux :
*   `InterestPayment` : Encaissement d'intérêts (ne diminue pas le capital investi).
*   `CapitalRepayment` : Remboursement partiel ou total du capital (diminue le CRD).
*   `EarlyRepayment` : Remboursement anticipé (fermeture du projet avant la date cible).

## 4. Logique Métier et Calculs

### 4.1. Valorisation (Portfolio)
*   **Valeur Actuelle** = Quantité détenue (Capital Restant).
    *   Investissement initial : Achat de X unités à 1€.
    *   Remboursement capital : Vente de Y unités à 1€.
*   Le prix unitaire (`currentPrice`) reste fixe à 1€ (ou valeur nominale) sauf défaut.

### 4.2. Projections (Planner)
Le module "Planner" affichera une **section dédiée** au Crowdfunding Immobilier, séparée des autres actifs pour le moment.
*   **Base de temps** : Utiliser `targetDuration` par défaut.
*   **Calcul des revenus** :
    *   Si `MonthlyInterest` : Générer des flux de trésorerie mensuels prévisionnels = (Capital Restant * Taux Annuel) / 12.
        *   *Note* : Gérer le cas des projets sur X mois (ex: 12% sur 7 mois).
    *   Si `InFine` : Générer un flux unique à la date de fin (`startDate` + `targetDuration`) comprenant Capital + Intérêts cumulés.
*   **Pénalités** : Si la date actuelle dépasse `targetDuration`, basculer sur `maxDuration` et potentiellement appliquer un taux majoré (si info disponible).
*   **Fusion** : La consolidation avec les autres projections d'actifs se fera dans une étape ultérieure.

### 4.3. Gestion des Remboursements Anticipés
*   Si un projet est remboursé avant `targetDuration`, la transaction de type `CapitalRepayment` (ou `EarlyRepayment`) solde la position.
*   Les projections futures pour cet actif doivent s'arrêter immédiatement.

## 5. Interface Utilisateur (UI)

### 5.1. Liste des Actifs
*   Afficher : Plateforme, Taux, Type de remboursement.
*   Indicateur de temps : Barre de progression (Temps écoulé / Durée Cible).

### 5.2. Détail de l'Actif
*   Afficher les 3 durées (Min, Cible, Max).
*   Afficher la localisation.
*   Tableau d'amortissement théorique vs réel (Intérêts perçus vs prévus).

### 5.3. Visualisations Spécifiques (Futur)
*   **Carte des Projets** : Vue géographique (Google Maps ou autre) avec marqueurs.
    *   Couleur selon statut : En cours (Vert), En retard (Orange), Terminé (Gris).
*   **Frise Chronologique (Timeline)** :
    *   Axe horizontal temporel.
    *   Barres représentant la durée de chaque projet.
    *   Possibilité de trier/filtrer par date de fin (Cible vs Max).

## 6. Plan d'Implémentation Détaillé

### Phase 1 : Fondations (Modèles)
1.  Créer l'enum `RepaymentType` et son adapter Hive.
2.  Mettre à jour `AssetType` avec `RealEstateCrowdfunding`.
3.  Mettre à jour `TransactionType` avec `InterestPayment`.
4.  Mettre à jour le modèle `Asset` avec les nouveaux champs (durées, localisation, repaymentType, etc.) et régénérer l'adapter Hive.

### Phase 2 : Saisie et Affichage Basique
1.  Mettre à jour le formulaire d'ajout d'actif pour afficher les champs spécifiques si "Crowdfunding Immo" est sélectionné.
2.  Mettre à jour le formulaire de transaction pour permettre la saisie d'intérêts (`InterestPayment`).
3.  Adapter `AssetListItem` pour afficher les infos clés (Taux, Plateforme).

### Phase 3 : Logique Financière & Planner (Dédié)
1.  Implémenter le calcul des revenus prévisionnels dans le `CalculationService` ou un service dédié `CrowdfundingService`.
2.  Créer une **section dédiée** dans l'onglet "Planner" pour afficher uniquement les flux du Crowdfunding (Tableau ou Graphique spécifique).
3.  Gérer la logique de "Remboursement Anticipé" (arrêt des prévisions).

### Phase 4 : Visualisations Avancées
1.  Créer la vue "Carte" (intégration librairie map).
2.  Créer la vue "Timeline".
