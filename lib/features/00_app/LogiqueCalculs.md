# Logique de calculs – Crowdfunding Immobilier

Ce document décrit les règles de calcul utilisées par l’application pour les projets de Crowdfunding immobilier.

## Durée de référence des projets
- Avant: les projections et graphiques utilisaient la `durée cible` (`targetDuration`).
- Maintenant: tous les calculs et visualisations utilisent la `durée maximale` (`maxDuration`) lorsqu’elle est disponible. À défaut, la `durée cible` est utilisée en repli.
- Raison: certaines plateformes (ex: La Première Brique) ne fournissent pas systématiquement la durée cible mais exposent une fenêtre min/max. La durée maximale offre une borne supérieure fiable pour les projections.

## Fin de projet anticipée
- Si un projet se termine avant la date maximale, l’utilisateur peut marquer le projet comme terminé (via les transactions de remboursement du capital ou la gestion de l’actif).
- L’application recalculera automatiquement les gains sur la période réelle (historique des transactions prévaudra sur les projections).

## Détails d’implémentation
- Service: `features/00_app/services/crowdfunding_service.dart`
  - Les méthodes `generateFutureEvents()` et `generateProjections()` utilisent désormais `asset.maxDuration ?? asset.targetDuration ?? 0` pour déterminer la durée en mois.
- UI: `features/05_planner/ui/widgets/crowdfunding_timeline_widget.dart`
  - Le calcul de la date de fin affichée sur la timeline utilise `maxDuration` en priorité.

## Import La Première Brique
- Le parser Excel calcule `durationMonths` à partir des dates min/max (min + 6 mois, plafonné par max) et renseigne aussi `minDurationMonths` et `maxDurationMonths`.
- Lors de l’hydratation, `asset.maxDuration` est enregistrée si disponible et devient la base des projections.
## Import Trade Republic
- Les parsers Trade Republic (`TradeRepublicParser` et `TradeRepublicAccountStatementParser`) utilisent désormais l'ISIN comme ticker par défaut.
- Cela permet de regrouper correctement les transactions par actif et de calculer le capital investi.
- Sans ticker, les transactions n'étaient pas associées à des actifs et impactaient uniquement les liquidités.

## Gestion des Liquidités lors des Imports
- **Principe général** : Lors d'un **import initial** (mode `ImportMode.initial`), on importe des positions DÉJÀ achetées historiquement avec de l'argent qui était disponible.
- **Dépôt compensatoire automatique** : Pour tous les achats (`TransactionType.Buy`) importés en mode initial, un dépôt compensatoire est créé automatiquement par date pour neutraliser l'impact sur les liquidités.
- **Raison** : Sans ce dépôt, les liquidités seraient artificiellement négatives. Par exemple, importer 5000€ d'actifs sans historique créerait -5000€ de liquidités, ce qui est incorrec t car cet argent a bien été déposé à un moment donné.
- **Mode Actualisation** : En mode `ImportMode.update`, aucun dépôt compensatoire n'est créé car on ajoute des transactions récentes à un historique existant.
- **Tous types d'actifs** : Le mécanisme s'applique uniformément aux actions, ETF, crypto ET crowdfunding en mode initial.
## Hypothèses
- 1 mois ≈ 30 jours pour le calcul des dates de fin (cohérence globale des widgets existants).
- Le prix unitaire du crowdfunding est considéré à 1 (la quantité représente le montant investi).

Si vous ajustez une règle (liquidité, PRU, rendement, durée…), veuillez mettre à jour ce document en conséquence.