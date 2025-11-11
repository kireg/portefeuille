# Portefeuille — Gestionnaire de Finances Personnelles (Flutter)

Une application Flutter moderne et complète pour gérer vos comptes et investissements personnels. Suivez votre patrimoine en temps réel, analysez vos performances et planifiez votre avenir financier avec une interface intuitive et élégante.

## 📋 Vue d'ensemble

**Portefeuille** est une application de gestion financière personnelle basée sur une **architecture immuable par transactions**. Contrairement aux approches traditionnelles, l'état de votre portefeuille (soldes, quantités d'actifs, prix de revient unitaire) n'est pas stocké directement mais **calculé dynamiquement** à partir de l'historique complet de vos transactions.

### Caractéristiques Techniques

- **Langage** : Dart / Flutter (SDK >=3.4.0 <4.0.0)
- **Point d'entrée** : `lib/features/00_app/main.dart`
- **Stockage local** : Hive (base de données NoSQL embarquée, légère et performante)
- **Architecture** : Organisation par fonctionnalités (feature-first) avec séparation claire des responsabilités
- **Gestion d'état** : Provider avec ChangeNotifier
- **Génération de code** : build_runner pour les adapters Hive
- **Principales dépendances** : 
  - **Interface** : fl_chart, shimmer, animated_text_kit
  - **État** : provider
  - **Stockage** : hive, hive_flutter, flutter_secure_storage
  - **API** : http
  - **Utilitaires** : intl, uuid

## ✨ Fonctionnalités Principales

### 🏦 Gestion Multi-Portefeuilles
- Créez et gérez plusieurs portefeuilles d'investissement distincts
- Organisez vos comptes par institutions financières (banques, courtiers, plateformes crypto)
- Changement rapide de portefeuille actif depuis les paramètres

### 📊 Types de Comptes Supportés
- **PEA** (Plan d'Épargne en Actions)
- **CTO** (Compte-Titres Ordinaire)
- **Assurance Vie**
- **PER** (Plan Épargne Retraite)
- **Crypto-monnaies**
- **Autres** comptes personnalisés

### 💼 Types d'Actifs Gérés
- **Actions** (Stock)
- **ETF** (Exchange-Traded Funds)
- **Crypto-monnaies**
- **Obligations** (Bonds)
- **Liquidités** (Cash)
- **Autres** actifs

### 📈 Système de Transactions Immuable
Architecture révolutionnaire basée sur l'historique des transactions :
- **7 types de transactions** : Dépôt, Retrait, Achat, Vente, Dividende, Intérêts, Frais
- Calcul dynamique des soldes, quantités et prix de revient unitaire (PRU)
- Historique complet et traçable de toutes vos opérations
- Modification et suppression de transactions avec recalcul automatique

### 🌐 Mode En Ligne et Synchronisation des Prix
- **Récupération automatique** des prix en temps réel via API
- **Stratégie de fallback intelligente** : Financial Modeling Prep (FMP) → Yahoo Finance
- **Cache optimisé** : 15 minutes pour les prix, 24 heures pour la recherche de tickers
- **Recherche de tickers** avec auto-complétion lors de l'ajout de transactions
- Tableau de suivi des métadonnées (prix, rendements, dernière mise à jour)

### 📊 Visualisations et Analyses
- **Graphiques interactifs** (fl_chart) :
  - Évolution de la valeur du portefeuille
  - Répartition par type d'actif (Actions, ETF, Crypto, Liquidités)
  - Répartition par compte
- **Calcul automatique** des plus/moins-values (P/L) et rendements
- **Vue synthétique** des actifs avec tri et filtrage

### 📅 Planificateur d'Investissements
- Création de **plans d'épargne programmés** (mensuels, trimestriels, annuels)
- **Simulation** de croissance du portefeuille sur 5, 10, 20 ou 30 ans
- **Graphique de projection** montrant le capital initial, investi et les gains estimés

### 🎨 Personnalisation et Ergonomie
- **Choix de la couleur** principale de l'interface
- **Mode démo** pour découvrir l'application sans engagement
- Interface adaptative et responsive
- **Animations fluides** et retours visuels (shimmer, animated_text_kit)

### 🔒 Sécurité et Confidentialité
- Stockage **100% local** des données (aucune connexion serveur)
- **Clé API FMP** stockée de manière sécurisée (Keystore/Keychain/Credential Manager)
- Aucune collecte de données personnelles

## 🌐 Mode En Ligne et Synchronisation des Prix

L'application propose un **mode en ligne optionnel** qui permet de synchroniser automatiquement les prix de vos actifs et de bénéficier d'une aide à la saisie lors de l'ajout de nouvelles transactions.

### Activation du Mode En Ligne

1. Ouvrez l'écran des **Paramètres** (icône ⚙️ en haut à droite)
2. Activez l'option **"Mode en ligne"**
3. L'indicateur de statut dans l'AppBar affiche maintenant **"En ligne"**

### Fonctionnement

#### Récupération des Prix

L'application utilise une **stratégie de fallback intelligente** :

1. **Financial Modeling Prep (FMP)** : Si vous avez configuré une clé API (optionnel)
    - Plus fiable et complète
    - Requiert une inscription gratuite sur [financialmodelingprep.com](https://financialmodelingprep.com)

2. **Yahoo Finance** : Utilisé automatiquement en fallback ou si aucune clé FMP n'est configurée
    - Gratuit et sans inscription
    - Fonctionne pour la majorité des tickers (actions, ETF, cryptos)

#### Cache Intelligent

Pour optimiser les performances et limiter les appels API :
- **Prix** : Mis en cache pendant **15 minutes**
- **Recherche de tickers** : Mise en cache pendant **24 heures**

### Configuration de la Clé API FMP (Optionnel)

Pour améliorer la fiabilité de la synchronisation, vous pouvez configurer une clé API Financial Modeling Prep :

1. Créez un compte gratuit sur [financialmodelingprep.com](https://financialmodelingprep.com)
2. Récupérez votre clé API depuis votre tableau de bord
3. Dans l'application :
    - Ouvrez **Paramètres** > **Paramètres de l'Application**
    - Activez le **Mode en ligne**
    - Dans le champ **"Clé API FMP (Optionnel)"**, saisissez votre clé
    - Cliquez sur l'icône 💾 pour sauvegarder

**Sécurité** : La clé API est stockée de manière sécurisée dans le Keystore (Android) / Keychain (iOS) / Credential Manager (Windows).

### Recherche de Tickers et Auto-complétion

Lors de l'ajout d'une transaction (écran "Nouvelle Transaction") :

1. Commencez à taper un **ticker** (ex: "AAPL") ou un **ISIN** dans le champ dédié
2. Après 500ms, des suggestions apparaissent automatiquement (si le mode en ligne est actif)
3. Sélectionnez une suggestion pour :
    - Remplir automatiquement le **nom** de l'actif
    - Récupérer le **prix actuel** en temps réel
    - Pré-remplir le **prix unitaire** avec le prix actuel

**Types de résultats supportés** : Actions (EQUITY), ETF, Crypto-monnaies

### Synchronisation Automatique

Les prix sont synchronisés automatiquement dans les cas suivants :
- **Au démarrage** de l'application (si le mode en ligne est actif)
- **À l'activation** du mode en ligne
- L'indicateur **"Synchro..."** s'affiche pendant la mise à jour

**Mode hors ligne** : L'application fonctionne parfaitement sans connexion internet. Les prix restent ceux saisis manuellement ou récupérés lors de la dernière synchronisation.

### Indicateur de Statut

L'AppBar du Dashboard affiche l'état actuel de la connectivité :
- ☁️ **"En ligne"** : Mode en ligne actif, synchronisation disponible
- 🚫 **"Hors ligne"** : Mode hors ligne, pas de synchronisation
- ⏳ **"Synchro..."** : Synchronisation en cours

### Limitations et Bonnes Pratiques

#### API Gratuites
- **Yahoo Finance** : Aucune limitation officielle mais évitez les requêtes excessives
- **FMP (gratuit)** : Généralement limité à 250 requêtes/jour (vérifiez votre plan)

#### Recommandations
- Le cache évite la plupart des appels répétés
- La synchronisation est optimisée (appels en parallèle)
- En cas d'échec, les prix existants sont conservés
- Les erreurs sont loguées dans la console (mode debug)

## 🚀 Installation et Configuration

### Prérequis

- **Flutter SDK** (compatible avec Dart >=3.4.0 <4.0.0)  
  Installez depuis [https://flutter.dev](https://flutter.dev)
- Un appareil ou émulateur (Android / iOS / Windows / macOS / Linux)
- **Git** pour cloner le dépôt
- **Visual Studio** (pour Windows desktop) ou **Android Studio** (pour Android)

### Installation

1. **Clonez le dépôt** :
```powershell
git clone <URL_DU_DEPOT_GIT>
cd Portefeuille
```

2. **Récupérez les dépendances** :
```powershell
flutter pub get
```

3. **Générez les fichiers Hive** (adapters et sérialisation) :
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Lancez l'application** :
```powershell
# Sur un émulateur/appareil connecté
flutter run

# Sur Windows
flutter run -d windows

# Sur Android (APK debug)
flutter run -d <DEVICE_ID>
```

### Vérification de l'Installation

Exécutez `flutter doctor` pour vérifier que votre environnement est correctement configuré :
```powershell
flutter doctor
```

### Notes de Développement

- **Point d'entrée** : `lib/features/00_app/main.dart`
- Le main initialise Hive, enregistre les adapters et ouvre les boxes avant d'instancier le repository
- En **mode debug**, la base de données Hive **n'est pas supprimée** au démarrage, permettant de tester la persistance
- Pour **régénérer les fichiers .g.dart** après modification des modèles :
  ```powershell
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

### Boxes Hive Utilisées

L'application utilise **quatre boxes Hive** :

| Box | Constante | Description |
|-----|-----------|-------------|
| **Portfolio** | `kPortfolioBoxName` | Données de portefeuille (institutions, comptes) |
| **Settings** | `kSettingsBoxName` | Paramètres de l'application (couleur, mode en ligne, etc.) |
| **Transaction** | `kTransactionBoxName` | Historique complet des transactions |
| **AssetMetadata** | `kAssetMetadataBoxName` | Prix et rendements des actifs (cache API) |

## 📦 Compilation — Générer des Binaires

### Android (APK / App Bundle)

#### Prérequis
- **Android SDK** et **Android Studio** installés
- Un device ou un émulateur configuré
- Vérifiez avec `flutter doctor`

#### Commandes de Compilation

**APK Release (tous les ABIs)** :
```powershell
flutter build apk --release
```

**APKs séparés par ABI** (réduit la taille) :
```powershell
flutter build apk --split-per-abi --release
```

**Android App Bundle (AAB)** pour le Play Store :
```powershell
flutter build appbundle --release
```

#### Configuration de la Signature

Pour créer un APK signé pour la distribution :

1. Créez un keystore :
```powershell
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Créez le fichier `android/key.properties` :
```properties
storePassword=<mot_de_passe>
keyPassword=<mot_de_passe>
keyAlias=upload
storeFile=<chemin_vers_keystore>
```

3. Configurez `android/app/build.gradle` (section `signingConfigs`)

📍 **Binaire généré** : `build/app/outputs/flutter-apk/app-release.apk`

### Windows (EXE)

#### Prérequis
- Machine **Windows** avec **Visual Studio** installé (Desktop development with C++)
- Support desktop activé :
```powershell
flutter config --enable-windows-desktop
flutter doctor
```

#### Commande de Build
```powershell
flutter build windows --release
```

📍 **Exécutable généré** : `build\windows\x64\runner\Release\`

#### Distribution
Pour distribuer l'exécutable :
- Incluez **tous les fichiers** du dossier `Release\`
- Les utilisateurs peuvent avoir besoin des **VC++ Redistributables**

### iOS / macOS

```powershell
# iOS
flutter build ios --release

# macOS
flutter build macos --release
```

### Linux

```powershell
flutter build linux --release
```

### ⚠️ Recommandations
- Testez toujours en **mode debug** puis **profile** avant de compiler en **release**
- Vérifiez les **permissions** dans les manifestes (Android, iOS)
- Sur Windows, testez l'exécutable sur une machine **sans environnement de développement**

## 🏗️ Architecture et Structure du Projet

### Architecture Globale

Le projet suit une **architecture feature-first** modulaire avec séparation claire des responsabilités :

```
lib/
├── core/                    # Fondations partagées
│   ├── data/               # Couche données
│   ├── ui/                 # Composants UI réutilisables
│   └── utils/              # Utilitaires globaux
│
└── features/               # Organisation par fonctionnalités
    ├── 00_app/            # Configuration de l'application
    ├── 01_launch/         # Écran d'accueil
    ├── 02_dashboard/      # Tableau de bord principal
    ├── 03_overview/       # Vue d'ensemble détaillée
    ├── 04_journal/        # Journal des transactions
    ├── 05_planner/        # Planificateur financier
    ├── 06_settings/       # Paramètres
    └── 07_management/     # Gestion des entités
```

### Structure Détaillée

```
lib/
├── core/
│   ├── data/
│   │   ├── models/                          # 📦 Modèles Hive avec génération de code
│   │   │   ├── portfolio.dart               # Portefeuille principal
│   │   │   ├── institution.dart             # Institution financière
│   │   │   ├── account.dart                 # Compte d'investissement (getters calculés)
│   │   │   ├── account_type.dart            # Enum : PEA, CTO, Assurance Vie, etc.
│   │   │   ├── asset.dart                   # Actif/Position (getters calculés)
│   │   │   ├── asset_type.dart              # Enum : Stock, ETF, Crypto, etc.
│   │   │   ├── transaction.dart             # Transaction financière
│   │   │   ├── transaction_type.dart        # Enum : Buy, Sell, Deposit, etc.
│   │   │   ├── asset_metadata.dart          # Métadonnées (Prix, Rendement, Cache API)
│   │   │   ├── savings_plan.dart            # Plan d'épargne programmé
│   │   │   └── *.g.dart                     # Fichiers générés par build_runner
│   │   │
│   │   ├── repositories/
│   │   │   └── portfolio_repository.dart    # 🗄️ Repository principal (CRUD)
│   │   │
│   │   └── services/
│   │       └── api_service.dart             # 🌐 Service API (FMP + Yahoo Finance)
│   │
│   ├── ui/
│   │   ├── splash_screen.dart               # Écran de démarrage animé
│   │   └── theme/
│   │       └── app_theme.dart               # Thème Material personnalisé
│   │
│   └── utils/
│       ├── constants.dart                   # Constantes globales (noms des boxes)
│       └── currency_formatter.dart          # Formatage des montants en euros
│
├── features/
│   ├── 00_app/                              # 🚀 Configuration de l'application
│   │   ├── main.dart                        # Point d'entrée (init Hive, Providers)
│   │   └── providers/
│   │       ├── portfolio_provider.dart      # Gestion d'état du portefeuille
│   │       ├── portfolio_sync_logic.dart    # Logique de synchronisation API
│   │       ├── portfolio_migration_logic.dart # Migration V1 (transactions)
│   │       └── settings_provider.dart       # Gestion des paramètres
│   │
│   ├── 01_launch/                           # 🎬 Écran de lancement
│   │   └── ui/
│   │       └── launch_screen.dart           # Onboarding (démo ou nouveau portefeuille)
│   │
│   ├── 02_dashboard/                        # 📊 Tableau de bord principal
│   │   └── ui/
│   │       ├── dashboard_screen.dart        # Écran principal avec onglets
│   │       └── widgets/
│   │           └── dashboard_app_bar.dart   # AppBar personnalisée (statut en ligne)
│   │
│   ├── 03_overview/                         # 📈 Vue d'ensemble
│   │   └── ui/
│   │       ├── overview_tab.dart            # Onglet Vue d'ensemble
│   │       └── widgets/
│   │           ├── total_value_card.dart    # Carte valeur totale
│   │           ├── allocation_chart.dart    # Graphique répartition par compte
│   │           ├── asset_type_chart.dart    # Graphique répartition par type
│   │           └── ...                      # Autres widgets
│   │
│   ├── 04_journal/                          # 📖 Journal des transactions
│   │   └── ui/
│   │       ├── journal_tab.dart             # Onglet Journal (2 vues)
│   │       ├── views/
│   │       │   ├── synthese_view.dart       # Vue "Synthèse Actifs" (DataTable)
│   │       │   └── transactions_view.dart   # Vue "Transactions" (Liste)
│   │       └── widgets/
│   │           └── transaction_list_item.dart # Item de transaction
│   │
│   ├── 05_planner/                          # 📅 Planificateur financier
│   │   └── ui/
│   │       └── planner_tab.dart             # Simulateur d'investissements (BarChart)
│   │
│   ├── 06_settings/                         # ⚙️ Paramètres
│   │   └── ui/
│   │       ├── settings_screen.dart         # Écran principal des paramètres
│   │       └── widgets/
│   │           ├── appearance_settings.dart # Paramètres d'apparence
│   │           ├── app_settings.dart        # Paramètres de l'application (API)
│   │           ├── portfolio_management_settings.dart # Gestion portefeuilles
│   │           └── reset_app_section.dart   # Réinitialisation
│   │
│   └── 07_management/                       # 🛠️ Gestion des entités
│       └── ui/
│           ├── screens/
│           │   ├── add_institution_screen.dart
│           │   ├── add_account_screen.dart
│           │   ├── add_transaction_screen.dart  # ⭐ Avec recherche de tickers
│           │   ├── edit_transaction_screen.dart
│           │   └── add_savings_plan_screen.dart
│           └── widgets/
│               └── transaction_form_body.dart   # Formulaire partagé (add/edit)
│
└── main.dart                                # Export vers features/00_app/main.dart
```

### 🔑 Modèles de Données Clés

#### Transaction (typeId: 7)
Modèle central de l'architecture immuable :
- `id`, `accountId`, `type`, `date`
- `amount`, `fees` (montants en euros)
- `assetTicker`, `assetName`, `assetType` (pour Buy/Sell)
- `quantity`, `price` (pour Buy/Sell)
- `notes` (notes personnalisées)
- Getter `totalAmount` = `amount - fees`

#### Account (typeId: 2)
- Getters calculés : `cashBalance`, `assets` (basés sur `transactions`)
- Champs dépréciés : `stale_assets`, `stale_cashBalance` (migration V1)

#### Asset (typeId: 3)
- Getters calculés : `quantity`, `averagePrice` (PRU)
- Champs en mémoire : `currentPrice`, `estimatedAnnualYield` (mis à jour par API)

#### AssetMetadata (typeId: 9)
- Cache des prix et rendements récupérés via API
- `lastUpdated` pour gérer l'expiration du cache

### 🔄 Flux de Données

```
User Action
    ↓
UI (Screen/Widget)
    ↓
Provider (PortfolioProvider)
    ↓
Repository (PortfolioRepository)
    ↓
Hive Boxes (Persistence)

API Sync:
PortfolioProvider → ApiService → FMP/Yahoo → AssetMetadata (cache)
```

### 🧩 Providers

- **SettingsProvider** : Paramètres de l'application (couleur, mode en ligne, clé API)
- **PortfolioProvider** : État du portefeuille, synchronisation, migration
- **ApiService** : Injection via Provider (non ChangeNotifier)

---

## 📚 Documentation Complémentaire

### 📖 Migration V1 - Architecture par Transactions

L'application a migré vers une **architecture immuable basée sur les transactions**. Consultez le fichier **`MIGRATION_V1.md`** pour tous les détails :

- **Nouveaux modèles** : `Transaction`, `TransactionType`, `AssetType`
- **Modifications des modèles** : `Account` et `Asset` avec getters calculés
- **Logique de migration automatique** : Conversion des anciennes données
- **Nouvelles fonctionnalités** : Onglet Journal, Planificateur fonctionnel
- **Tests et bonnes pratiques**

#### Résumé de la Migration

**Avant** (stockage direct) :
```dart
Account {
  cashBalance: 500€
  assets: [
    { ticker: "AAPL", quantity: 5, averagePrice: 100€ }
  ]
}
```

**Après** (calculé depuis les transactions) :
```dart
Account {
  transactions: [
    { type: Deposit, amount: 1000€, date: 2020-01-01 },
    { type: Buy, ticker: "AAPL", quantity: 5, price: 100€, amount: -500€ }
  ]
  
  // Getters calculés dynamiquement
  cashBalance => 500€  (1000€ - 500€)
  assets[0].quantity => 5
  assets[0].averagePrice => 100€  (PRU)
}
```

### 🔧 Suivi des Bugs et Corrections

- **`Corrections bug.md`** : Liste des bugs identifiés et corrigés
- **`CORRECTIONS_PR12.md`** : Dernières améliorations et corrections apportées

---

## 🧪 Tests et Qualité

### Tests Unitaires

L'application dispose de tests unitaires pour les composants critiques :

```powershell
# Lancer tous les tests
flutter test

# Lancer un fichier de test spécifique
flutter test test/core/data/services/api_service_test.dart
```

#### Tests Existants

- **`api_service_test.dart`** : Tests de récupération de prix (FMP/Yahoo), cache, recherche de tickers
- Tests des modèles : Calcul de `cashBalance`, `quantity`, `averagePrice` (PRU)
- Tests de migration V1

### Analyse Statique

Le projet utilise `flutter_lints` pour garantir la qualité du code :

```powershell
flutter analyze
```

Configuration dans `analysis_options.yaml`.

---

## 🚦 Utilisation de l'Application

### Premier Lancement

1. **Écran de lancement** : Choisissez entre :
   - **Mode Démo** : Explore l'application avec des données fictives
   - **Nouveau Portefeuille** : Créez votre portefeuille vierge

2. **Créez une institution** (ex: "Boursorama", "Binance")

3. **Ajoutez un compte** :
   - Choisissez le type (PEA, CTO, Crypto, etc.)
   - Nommez-le (ex: "PEA Principal")

4. **Ajoutez votre première transaction** :
   - Cliquez sur le bouton **+** dans l'AppBar
   - Type **Dépôt** pour ajouter des liquidités
   - Ou type **Achat** pour acheter un actif (avec recherche de ticker)

### Navigation

#### 🏠 Onglet "Vue d'ensemble"
- **Valeur totale** du portefeuille
- **Graphiques** : Répartition par compte et par type d'actif
- **Liste des comptes** avec valeur et P/L

#### 📅 Onglet "Planificateur"
- **Créez des plans d'épargne** (mensuels, trimestriels, annuels)
- **Simulez** la croissance de votre portefeuille (5 à 30 ans)
- **Graphique** de projection avec capital investi et gains estimés

#### 📖 Onglet "Journal"
- **Vue "Synthèse Actifs"** : Table complète de tous vos actifs avec PRU, P/L
- **Vue "Transactions"** : Historique complet des transactions
- **Actions** : Modifier ou supprimer une transaction

#### ⚙️ Paramètres (icône en haut à droite)
- **Apparence** : Changer la couleur principale
- **Mode en ligne** : Activer/désactiver la synchronisation des prix
- **Clé API FMP** : Configurer votre clé (optionnel)
- **Gestion des portefeuilles** : Créer, changer, supprimer
- **Tableau de métadonnées** : Suivi des prix/rendements (mode en ligne actif)

### Mode En Ligne - Guide Rapide

1. **Activez le mode** dans Paramètres > Mode en ligne
2. L'indicateur **"En ligne"** s'affiche dans l'AppBar
3. Les prix se synchronisent automatiquement au démarrage
4. Lors de l'ajout d'une transaction **Achat** :
   - Tapez un ticker (ex: "AAPL")
   - Sélectionnez dans les suggestions
   - Le prix actuel se pré-remplit automatiquement

---

## 🤝 Contribution et Développement

### Workflow de Développement

1. **Créer une branche** pour votre fonctionnalité :
```powershell
git checkout -b feature/ma-fonctionnalite
```

2. **Modifier le code** et tester localement

3. **Régénérer les fichiers Hive** si modèles modifiés :
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Analyser le code** :
```powershell
flutter analyze
```

5. **Lancer les tests** :
```powershell
flutter test
```

6. **Commit et push** :
```powershell
git add .
git commit -m "feat: description de la fonctionnalité"
git push origin feature/ma-fonctionnalite
```

### Conventions de Code

- **Langue** : Code et commentaires en français
- **Formatage** : Utilisez le formateur Dart (`dart format`)
- **Nommage** :
  - Classes : `PascalCase`
  - Variables/fonctions : `camelCase`
  - Constantes : `kConstantName`
- **Imports** : Groupez les imports (Flutter > Package > Relatif)

### Ajout de Nouvelles Fonctionnalités

#### Ajouter un nouveau type de transaction
1. Modifiez `transaction_type.dart`
2. Régénérez avec `build_runner`
3. Mettez à jour la logique de calcul dans `account.dart` et `asset.dart`
4. Ajoutez le type dans le formulaire `transaction_form_body.dart`

#### Ajouter un nouveau Provider
1. Créez le fichier dans `lib/features/00_app/providers/`
2. Étendez `ChangeNotifier`
3. Ajoutez-le au `MultiProvider` dans `main.dart`

---

## 🐛 Dépannage

### Problèmes Courants

#### "MissingPluginException"
**Cause** : Plugins natifs non synchronisés

**Solution** :
```powershell
flutter clean
flutter pub get
flutter run
```

#### Erreur de génération Hive
**Cause** : Fichiers `.g.dart` obsolètes ou corrompus

**Solution** :
```powershell
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Les prix ne se synchronisent pas
**Vérifications** :
1. Mode en ligne activé ? (Paramètres)
2. Connexion internet active ?
3. Vérifiez les logs dans la console (`debugPrint`)

#### Erreur "Box already open"
**Cause** : Tentative d'ouvrir une box déjà ouverte

**Solution** : Redémarrez l'application (Hot Restart, pas Hot Reload)

### Logs et Debug

Activez les logs détaillés :
```dart
// Dans main.dart
debugPrint("🔍 Debug actif");
```

Mode verbose :
```powershell
flutter run -v
```

---

## 📄 Licence et Crédits

### Dépendances Open Source

Ce projet utilise les packages suivants :

- **[provider](https://pub.dev/packages/provider)** - Gestion d'état
- **[hive](https://pub.dev/packages/hive)** & **[hive_flutter](https://pub.dev/packages/hive_flutter)** - Base de données locale
- **[fl_chart](https://pub.dev/packages/fl_chart)** - Graphiques interactifs
- **[http](https://pub.dev/packages/http)** - Requêtes HTTP
- **[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)** - Stockage sécurisé
- **[shimmer](https://pub.dev/packages/shimmer)** - Animations de chargement
- **[animated_text_kit](https://pub.dev/packages/animated_text_kit)** - Animations de texte
- **[intl](https://pub.dev/packages/intl)** - Internationalisation et formatage
- **[uuid](https://pub.dev/packages/uuid)** - Génération d'identifiants uniques

### APIs Utilisées

- **[Financial Modeling Prep (FMP)](https://financialmodelingprep.com)** - Données financières (optionnel, clé API requise)
- **[Yahoo Finance](https://finance.yahoo.com)** - Données financières (gratuit, fallback automatique)

### Auteur

**Portefeuille** est développé et maintenu par [kireg].

---

## 📞 Support et Contact

### Problèmes et Suggestions

- **GitHub Issues** : [Lien vers le repo]
- Consultez d'abord la section **Dépannage**
- Incluez les logs et la version de Flutter dans votre rapport

### Ressources

- **Documentation Flutter** : [https://docs.flutter.dev](https://docs.flutter.dev)
- **Documentation Hive** : [https://docs.hivedb.dev](https://docs.hivedb.dev)
- **Guide Provider** : [https://pub.dev/packages/provider](https://pub.dev/packages/provider)

---

## 🗺️ Roadmap et Améliorations Futures

### Fonctionnalités Prévues

- [ ] **Import/Export** de transactions (CSV, JSON)
- [ ] **Graphiques supplémentaires** : Évolution historique, répartition sectorielle
- [ ] **Notifications** : Alertes de prix, rappels de plans d'épargne
- [ ] **Multi-devises** : Support EUR, USD, GBP, etc.
- [ ] **Mode sombre** : Thème clair/sombre
- [ ] **Synchronisation cloud** : Backup automatique (Firebase/Supabase)
- [ ] **Analyse fiscale** : Calcul automatique des déclarations (IFU, etc.)
- [ ] **Widget iOS/Android** : Affichage de la valeur du portefeuille sur l'écran d'accueil

### Optimisations Techniques

- [ ] **Cache des getters** : Mémorisation pour éviter les recalculs inutiles
- [ ] **Pagination** : Pour les grandes listes de transactions
- [ ] **Tests end-to-end** : Tests d'intégration complets
- [ ] **CI/CD** : Pipeline automatique de tests et déploiement

---

**Version** : 1.0.0+1  
**Dernière mise à jour de la documentation** : Novembre 2025

---

Made with ❤️ using Flutter