# Plan de Développement du Projet Portefeuille

## Architecture et Stack Technique
- **Framework** : Flutter
- **Langage** : Dart
- **Gestion d'état** : Provider
- **Base de données locale** : Hive
- **Structure** : Architecture feature-first avec isolation stricte des modules.

## Modèle de Données
- **Institution** : Nom, Identifiant unique, Liste de comptes.
- **Compte** : Nom, Solde, Type (épargne, courant, etc.), Identifiant unique.
- **Transaction** : Montant, Date, Type (dépôt, retrait, transfert), Compte source, Compte cible (optionnel).

## Phases de Développement
1. **Phase 1 : Mise en place de l'architecture**
   - Création de la structure feature-first.
   - Implémentation des providers globaux (PortfolioProvider, SettingsProvider).

2. **Phase 2 : Gestion des institutions et comptes**
   - Ajout, modification, suppression d'institutions.
   - Gestion des comptes associés.

3. **Phase 3 : Gestion des transactions**
   - Enregistrement des transactions.
   - Affichage de l'historique filtrable.

4. **Phase 4 : Tableau de bord et rapports**
   - Vue d'ensemble des finances.
   - Génération de rapports financiers.

## Contraintes Techniques
- Respect strict de la hiérarchie des dépendances définie dans `constitution.md`.
- Tests unitaires obligatoires pour les calculs financiers et les modifications critiques.
- Widgets réutilisables centralisés dans `core/ui/widgets/`.

## Notes
- Les phases doivent être validées individuellement avant de passer à la suivante.
- Toute modification du modèle de données doit être accompagnée de tests de migration.
