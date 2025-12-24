## Catégories Crypto / PEA / CTO

Le parser Trade Republic (relevé de compte) renseigne une `category` par transaction :
- `Crypto` : détection par mots-clés spécifiques et/ou ISIN commençant par `XF`.
- `PEA` / `CTO` : heuristiques basées sur les en-têtes de relevés (mention PEA, IBAN/identifiants), avec repli sur le choix utilisateur dans l’assistant.

Lors de l’import, l’assistant propose une sélection de catégorie. Une fois choisie, seules les transactions de cette famille sont listées à la validation. Le compte destination suggéré doit rester cohérent avec la catégorie, mais reste modifiable.
# Analyse et Plan d'Action : Parser Trade Republic (Relevé de Compte)

## 1. Objectif
Créer un nouveau parser capable de traiter le "Relevé de compte" (Account Statement) de Trade Republic. Ce document est plus complet que le "Relevé de titres" car il contient l'historique exhaustif de toutes les transactions (espèces, actions, ETF, crypto) et permet de reconstruire fidèlement l'historique du portefeuille.

## 2. Analyse du Fichier Source (`EXTRACTED_Relevé de compte_Anonyme.txt`)

### Structure Générale
Le fichier est une extraction textuelle d'un PDF multipages.
- **En-tête** : Informations sur la banque et le client, Période du relevé.
- **Synthèse** : Tableau récapitulatif (Solde début, Entrées, Sorties, Solde fin).
- **Transactions** : Tableau principal listant les opérations chronologiquement.
- **Pied de page / En-tête de page suivante** : Répétition des infos légales et numérotation de page (ex: "Page 2 de 14").

### Format des Données
- **Dates** : Format français "dd MMM yyyy" (ex: "01 mai 2025"). Nécessite une conversion des mois français.
- **Montants** : Format européen "1 234,56 €" (virgule décimale, espace séparateur milliers, symbole €).
- **Colonnes du tableau Transactions** :
  1. DATE
  2. TYPE (ex: "Exécution d'ordre", "Intérêts créditeur")
  3. DESCRIPTION (Contient les détails cruciaux : ISIN, Nom, Quantité)
  4. ENTRÉE D'ARGENT
  5. SORTIE D'ARGENT
  6. SOLDE

### Types de Transactions Identifiés
1.  **Exécution d'ordre (Savings plan execution)** :
    -   *Description* : "Savings plan execution [ISIN] [Nom de l'actif], quantity: [Quantité]"
    -   *Exemple* : "Savings plan execution XF000BTC0017 Bitcoin, quantity: 0.000113"
    -   *Action* : Achat (Buy).
    -   *Données à extraire* : ISIN, Nom, Quantité. Le prix unitaire se déduit de (Sortie d'argent / Quantité).
2.  **Intérêts créditeur** :
    -   *Description* : "Your interest payment"
    -   *Action* : Intérêts (Interest/Dividend selon modèle).
3.  **Dividendes** (Probable, non visible dans l'extrait mais structure similaire attendue).
4.  **Virements** (Entrée/Sortie d'espèces).

## 3. Stratégie de Parsing

### Étape 1 : Nettoyage et Pré-traitement
-   Ignorer les en-têtes et pieds de page récurrents ("TRADE REPUBLIC BANK GMBH", "Page X de Y", adresses).
-   Identifier le début du tableau des transactions (après la ligne d'en-tête "DATE TYPE DESCRIPTION...").

### Étape 2 : Extraction des Blocs de Transaction
Le format texte peut avoir des sauts de ligne au sein d'une même transaction.
-   **Détection de nouvelle transaction** : Une ligne commençant par une date valide (ex: "02 mai 2025").
-   **Accumulation** : Lire les lignes suivantes jusqu'à la prochaine date pour constituer le bloc complet de la transaction (Description multi-lignes).

### Étape 3 : Parsing des Champs
Pour chaque bloc transaction :
1.  **Date** : Parser "dd MMM yyyy".
2.  **Type** : Lire la colonne TYPE.
    -   Si "Exécution d'ordre" : Analyser la DESCRIPTION.
    -   Si "Intérêts créditeur" : Transaction de type Interest.
3.  **Description** : Utiliser des Regex pour extraire :
    -   ISIN : `[A-Z]{2}[A-Z0-9]{9}[0-9]` (ex: LU0380865021, XF000BTC0017).
    -   Quantité : `quantity: ([0-9.]+)`.
    -   Nom : Texte entre "execution" et l'ISIN, ou après l'ISIN.
4.  **Montants** :
    -   Identifier si c'est une ENTRÉE ou une SORTIE.
    -   Nettoyer le montant (enlever "€", remplacer "," par ".").

### Étape 4 : Création de l'objet `ParsedTransaction`
-   **Type** :
    -   "Savings plan execution" + Sortie d'argent = `TransactionType.Buy`.
    -   "Intérêts" = `TransactionType.Dividend` (ou type spécifique Interest si dispo).
-   **AssetType** :
    -   Inférence basée sur l'ISIN ou le nom (ex: "XF..." souvent crypto chez TR, "Bitcoin" -> Crypto, "ETF" -> ETF).
-   **Prix** : `Montant Total / Quantité`.

## 4. Plan d'Implémentation

1.  **Créer `TradeRepublicAccountStatementParser`** : Une nouvelle classe implémentant `StatementParser`.
2.  **Implémenter `canParse`** : Détecter "SYNTHÈSE DU RELEVÉ DE COMPTE" ou "TRADE REPUBLIC" + structure spécifique.
3.  **Implémenter `parse`** :
    -   Logique de lecture ligne par ligne avec machine à états (State Machine) pour gérer les blocs multi-lignes.
    -   Regex robustes pour l'extraction des données dans la description.
4.  **Tests** : Créer un test unitaire avec le contenu de `EXTRACTED_Relevé de compte_Anonyme.txt` pour valider l'extraction.

## 5. Tâches à Suivre
- [ ] Créer le fichier `lib/features/09_imports/services/pdf/parsers/trade_republic_account_statement_parser.dart`.
- [ ] Implémenter la logique de parsing décrite ci-dessus.
- [ ] Ajouter ce nouveau parser dans `FileImportWizard` (ou remplacer l'ancien, ou laisser le choix). *Note: L'application doit choisir correctement le bon parser en fonction du fichier en entrée poru trade republic.*
- [ ] Ajouter le message d'avertissement sur l'ANCIEN parser (`TradeRepublicParser`).
