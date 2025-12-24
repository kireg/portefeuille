# Plan d’implémentation Import (Actualisation, Trade Republic Crypto/PEA/CTO)

## Objectifs
- Offrir deux modes : **Initial** (comme aujourd’hui) et **Actualisation** (n’ajouter que les nouveautés ou modifications).
- Pour Trade Republic (relevé de compte) : permettre de filtrer par famille **Crypto**, **PEA**, **CTO** avant import.
- Préserver l’UX de l’assistant, limiter les doublons, tracer les décisions.

## Modes d’import
- **Initial** : importe tout le fichier comme actuellement.
- **Actualisation** :
  - Calcule les diffs vs les transactions existantes.
  - Propose uniquement les transactions nouvelles ou modifiées.
  - Ne duplique jamais un doublon strict.
- Textes UX : choix clair du mode, avertissement sur doublons et champs modifiés.

## Détection de doublons / modifications
- Clé d’identité transaction : source + date normalisée + (ticker/isin/assetId) + type + quantité + montant arrondi.
- Doublon : même clé complète → ignorer en actualisation.
- Modifiée : même clé partielle (date+assetId+type) mais montant/prix/notes différents → présenter en “Modifiés”.
- Normalisation : arrondi montants, gestion devise, nettoyage des séparateurs, dates éclatées.

## Assistant d’import (wizard)
- Ajout d’un choix de **mode** (Initial/Actualisation) dans l’étape Source ou Validation.
- En mode Actualisation :
  - Afficher deux listes : "Nouveaux" et "Modifiés" (compteurs).
  - Permettre d’inclure/exclure chaque transaction.
- Sauvegarde :
  - Initial → ajoute tout.
  - Actualisation → ajoute nouveaux, met à jour modifiés (montant/prix/notes) sans créer de doublons.
- Gestion des avertissements et confirmation pour ignorer les doublons détectés.

## Trade Republic : catégories Crypto / PEA / CTO
- Catégories proposées lors de l’import TR (radio/segmented control).
- Classification par parser relevé de compte :
  - Crypto : déjà détecté (mots-clés/ISIN XF) → marquer `category=Crypto`.
  - PEA/CTO : ajouter heuristiques (en-têtes PEA vs compte titres, IBAN/identifiants). Fallback : choix utilisateur.
- Filtrage : une fois la catégorie choisie, le wizard ne montre que les transactions de cette famille.
- Compte destination : suggérer le compte cohérent avec la catégorie (editable).

## Implémentation prévue
- Étendre `ParsedTransaction` avec `category` (Crypto/PEA/CTO).
- Parser TR relevé de compte : ajouter classification PEA/CTO, garder crypto existante.
- Wizard :
  - Nouveau champ `importMode`.
  - UI de sélection catégorie TR.
  - Application du filtre catégorie avant validation.
  - Calcul des diffs en mode Actualisation et rendu UI (Nouveaux/Modifiés).
- Sauvegarde : appliquer décisions (ajout/mise à jour), ignorer doublons.

## Tests à couvrir
- Diff/Doublons : cas exact, montant variant faiblement, devise différente, date scindée.
- Mode Actualisation : n’affiche que nouveautés/modifiés, sauvegarde correcte.
- Trade Republic : classification crypto/PEA/CTO sur échantillons synthétiques; filtrage UI; suggestion de compte.
- Flux complet wizard : source → mode → catégorie → validation → sauvegarde.

## Documentation
- Mettre à jour `docs/HubImport.md` (flux, modes, UX).
- Mettre à jour `docs/ParserTradeRepublic.md` (classification catégories, limites, heuristiques).
- Rappeler l’impact éventuel sur calculs/projections si l’historique change (référence `lib/features/00_app/LogiqueCalculs.md`).

## I18n / Logs
- Ajouter les chaînes pour le mode d’import, catégories TR, avertissements.
- Journaliser les décisions (doublon ignoré, modifié mis à jour) pour diagnostic.

## Checkpoints
- ✅ Ajout des champs (category, importMode) + classification TR (crypto/PEA/CTO) dans les parsers.
- ✅ UI wizard : choix du mode + catégorie TR + filtrage en amont de la validation.
- ⏳ Diff/déduplication + rendu "Nouveaux/Modifiés" en mode Actualisation.
- ⏳ Sauvegarde : appliquer les décisions (ajout/mise à jour), ignorer les doublons, tests unitaires/intégration.
- ⏳ Docs (HubImport, ParserTradeRepublic), i18n et logs/telemetry.
