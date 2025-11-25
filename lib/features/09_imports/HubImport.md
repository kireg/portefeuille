# Module 09_Imports : Hub d'Import Unifié

## 1. Vision & Concept
Ce module centralise toutes les méthodes d'ajout de transactions dans l'application. L'objectif est de simplifier l'expérience utilisateur en remplaçant les multiples points d'entrée par un **Hub unique**.

### Écran Principal : `ImportHubScreen`
Point d'entrée unique proposant deux voies claires :
1.  **Saisie Manuelle** : Pour l'ajout rapide d'une transaction unitaire.
2.  **Importer un Fichier** : Pour le traitement de masse (Relevés bancaires, Exports CSV/Excel).

### Le "File Import Wizard"
Un assistant étape par étape pour guider l'import de fichiers :
1.  **Sélection du fichier** (Drag & Drop ou Explorateur).
2.  **Identification de la source** (Banque/Courtier).
3.  **Analyse & Validation** (Parsing et prévisualisation avant enregistrement).

---

## 2. État des Lieux (Current Status)

### Existant (✅)
*   **Saisie Manuelle :** L'écran `AddTransactionScreen` existe dans `features/07_management`.
*   **Parsers (Logique métier) :**
    *   `BoursoramaParser` (PDF) : ✅
    *   `TradeRepublicParser` (PDF) : ✅
    *   `RevolutParser` (CSV) : ✅
    *   `LaPremiereBriqueParser` (Excel) : ✅
*   **Services d'import :** `CsvImportService`, `PdfImportService` existent.

### Manquant / À Faire (❌)
*   **ImportHubScreen :** L'écran d'accueil du hub n'existe pas.
*   **FileImportWizard :** L'assistant étape par étape n'existe pas.
*   **Unification :** Les écrans d'import actuels (`CsvImportScreen`, `PdfImportScreen`, etc.) sont dispersés et doivent être remplacés par le Wizard.

---

## 3. Plan d'Implémentation (Phases)

### Phase 1 : Structure & Navigation (Priorité Haute)
*Objectif : Mettre en place la coquille vide du Hub et la navigation.*

- [x] **Tâche 1.1 :** Créer `ImportHubScreen` dans `features/09_imports/ui/screens/`.
    - Design : Deux grandes cartes ("Saisie Manuelle", "Importer Fichier").
- [x] **Tâche 1.2 :** Connecter la carte "Saisie Manuelle" vers `AddTransactionScreen` (situé dans `07_management`).
- [x] **Tâche 1.3 :** Créer la structure de base du `FileImportWizard` (Stepper ou PageView).
- [x] **Tâche 1.4 :** Nettoyage & Point d'entrée.
    - Supprimer les multiples icônes d'import (CSV, PDF, etc.) sur l'écran des transactions.
    - Ajouter un bouton "Importer / Ajouter" plus visible qui redirige vers `ImportHubScreen`.

### Phase 2 : Le Wizard d'Import (Cœur du système)
*Objectif : Rendre l'import de fichier fonctionnel avec sélection manuelle de la source.*

- [x] **Tâche 2.1 : Étape 1 - Sélection Fichier.**
    - Implémenter le File Picker (extensions autorisées : .pdf, .csv, .xlsx).
    - Afficher le nom/taille du fichier sélectionné.
- [x] **Tâche 2.2 : Étape 2 - Sélection Source.**
    - Créer une liste déroulante ou une grille de choix (Bourso, Revolut, Trade Republic, LPB, Autre).
    - Quand on clique sur "Autre", on accède à l'écran actuel ai_import (en BottomSheet).
- [x] **Tâche 2.3 : Étape 3 - Orchestration.**
    - Au clic sur "Analyser", instancier le bon Parser en fonction de la source choisie.
    - Appeler la méthode `parse()` du service correspondant.

### Phase 3 : Validation & Enregistrement
*Objectif : Connecter le résultat du parsing à l'écran de validation existant.*

- [x] **Tâche 3.1 :** Réutiliser ou adapter `ImportTransactionScreen` (ou l'écran de prévisualisation existant) pour afficher les résultats du Wizard.
    - *Note : Intégré directement dans `_buildValidationStep()` du Wizard pour une UX fluide.*
- [x] **Tâche 3.2 :** Gérer la persistance (enregistrement en base de données).
    - *Note : Implémenté dans `_saveTransactions()` via `PortfolioProvider.addTransaction()`.*
- [x] **Tâche 3.3 :** Nettoyage : Supprimer les anciens écrans d'import individuels (`CsvImportScreen`, `PdfImportScreen`) une fois le Wizard validé.
    - *Note : Fichiers supprimés : `csv_import_screen.dart`, `pdf_import_screen.dart`, `crowdfunding_import_screen.dart` et leurs widgets associés.*

### Phase 4 : Intelligence & UX (Futur)
*Objectif : Améliorer l'automatisation.*

- [ ] **Tâche 4.1 :** Détection automatique de la source (ex: analyse du nom de fichier ou des premières lignes).
- [ ] **Tâche 4.2 :** Intégration complète de `AiImportService` pour les sources inconnues.
- [ ] **Tâche 4.3 :** Drag & Drop sur Desktop/Web.

---

## 4. Architecture Technique

### Dossiers
```
lib/features/09_imports/
├── data/                   # Repositories (si besoin)
├── services/               # Parsers existants (à conserver/organiser)
│   ├── csv/
│   ├── pdf/
│   └── excel/
├── ui/
│   ├── screens/
│   │   ├── import_hub_screen.dart       <-- NOUVEAU
│   │   ├── file_import_wizard.dart      <-- NOUVEAU
│   │   └── transaction_review_screen.dart (Validation)
│   └── widgets/
│       ├── hub_option_card.dart
│       └── wizard_steps/
```

## 5. Analyse des fichiers existants (À supprimer en Phase 3.3)
*   `pdf_import_screen.dart` : Contient la logique de sélection de fichier PDF et l'appel à `PdfImportService`. Cette logique est maintenant dans `FileImportWizard` (Step 1) et sera dans l'orchestrateur (Step 3).
*   `csv_import_screen.dart` : Idem pour CSV.
*   `crowdfunding_import_screen.dart` : Idem pour Excel/LPB.
*   **Conclusion :** Ces fichiers contiennent principalement de la logique d'UI (File Picker, Loading State, Error Handling) qui est en train d'être réécrite dans le Wizard. La logique métier (Parsers) est bien séparée dans les services et sera réutilisée. Ces écrans pourront être supprimés sans perte de code métier.
