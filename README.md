# Portefeuille — Gestionnaire de Finances Personnelles (Flutter)

[cite_start]Une application Flutter moderne et complète pour gérer vos comptes et investissements personnels. [cite: 2675] [cite_start]Suivez votre patrimoine en temps réel, analysez vos performances et planifiez votre avenir financier avec une interface intuitive et élégante. [cite: 2675]
## 📋 Vue d'ensemble

[cite_start]**Portefeuille** est une application de gestion financière personnelle basée sur une **architecture immuable par transactions**. [cite: 2676] [cite_start]Contrairement aux approches traditionnelles, l'état de votre portefeuille (soldes, quantités d'actifs, prix de revient unitaire) n'est pas stocké directement mais **calculé dynamiquement** à partir de l'historique complet de vos transactions. [cite: 2677]
### Caractéristiques Techniques

- [cite_start]**Langage** : Dart / Flutter (SDK >=3.4.0 <4.0.0) [cite: 2678]
- [cite_start]**Point d'entrée** : `lib/features/00_app/main.dart` [cite: 2678]
- [cite_start]**Stockage local** : Hive (base de données NoSQL embarquée, légère et performante) [cite: 2678]
- [cite_start]**Architecture** : Organisation par fonctionnalités (feature-first) avec séparation claire des responsabilités [cite: 2678]
- [cite_start]**Gestion d'état** : Provider avec ChangeNotifier [cite: 2678]
- [cite_start]**Génération de code** : build_runner pour les adapters Hive [cite: 2678]
- [cite_start]**Principales dépendances** : [cite: 2678]
    - [cite_start]**Interface** : fl_chart, shimmer, animated_text_kit [cite: 2678]
    - [cite_start]**État** : provider [cite: 2678]
    - [cite_start]**Stockage** : hive, hive_flutter, flutter_secure_storage [cite: 2678]
    - [cite_start]**API** : http [cite: 2678]
    - [cite_start]**Utilitaires** : intl, uuid [cite: 2678]

## ✨ Fonctionnalités Principales

### 🏦 Gestion Multi-Portefeuilles
- Créez et gérez plusieurs portefeuilles d'investissement distincts
- [cite_start]Organisez vos comptes par institutions financières (banques, courtiers, plateformes crypto) [cite: 2679]
- [cite_start]Changement rapide de portefeuille actif depuis les paramètres [cite: 2679]

### 📊 Types de Comptes Supportés
- **PEA** (Plan d'Épargne en Actions)
- **CTO** (Compte-Titres Ordinaire)
- **Assurance Vie**
- **PER** (Plan Épargne Retraite)
- **Crypto-monnaies**
- **Autres** comptes personnalisés
- **Support multi-devises** : Chaque compte peut être configuré dans sa devise (EUR, USD, GBP, etc.)

### 💼 Types d'Actifs Gérés
- **Actions** (Stock)
- **ETF** (Exchange-Traded Funds)
- **Crypto-monnaies**
- **Obligations** (Bonds)
- **Liquidités** (Cash)
- **Autres** actifs

### 📈 Système de Transactions Immuable
Architecture révolutionnaire basée sur l'historique des transactions :
- [cite_start]**7 types de transactions** : Dépôt, Retrait, Achat, Vente, Dividende, Intérêts, Frais [cite: 2679]
- [cite_start]Calcul dynamique des soldes, quantités et prix de revient unitaire (PRU) [cite: 2680]
- [cite_start]Historique complet et traçable de toutes vos opérations [cite: 2680]
- [cite_start]**Gestion multi-devises** : Support des transactions dans différentes devises avec conversion automatique [cite: 2680]
- [cite_start]Taux de change historiques et conversions transparentes [cite: 2680]
- [cite_start]Modification et suppression de transactions avec recalcul automatique [cite: 2680]

### 🌐 Mode En Ligne et Synchronisation des Prix
- [cite_start]**Récupération automatique** des prix en temps réel via API [cite: 2680]
- [cite_start]**Stratégie de fallback intelligente** : Financial Modeling Prep (FMP) → Yahoo Finance [cite: 2680]
- [cite_start]**Cache optimisé** : 15 minutes pour les prix, 24 heures pour la recherche de tickers [cite: 2680]
- [cite_start]**Recherche de tickers** avec auto-complétion lors de l'ajout de transactions [cite: 2680]
- [cite_start]Tableau de suivi des métadonnées (prix, rendements, dernière mise à jour) [cite: 2681]

### 📊 Visualisations et Analyses
- [cite_start]**Graphiques interactifs** (fl_chart) : [cite: 2681]
    - Évolution de la valeur du portefeuille
    - [cite_start]Répartition par type d'actif (Actions, ETF, Crypto, Liquidités) [cite: 2681]
    - Répartition par compte
- [cite_start]**Calcul automatique** des plus/moins-values (P/L) et rendements [cite: 2681]
- [cite_start]**Vue synthétique** des actifs avec tri et filtrage [cite: 2681]

### 📅 Planificateur d'Investissements
- [cite_start]Création de **plans d'épargne programmés** (mensuels, trimestriels, annuels) [cite: 2681]
- [cite_start]**Simulation** de croissance du portefeuille sur 5, 10, 20 ou 30 ans [cite: 2681]
- [cite_start]**Graphique de projection** montrant le capital initial, investi et les gains estimés [cite: 2681]

### 🎨 Personnalisation et Ergonomie
- [cite_start]**Choix de la couleur** principale de l'interface [cite: 2681]
- [cite_start]**Mode démo** pour découvrir l'application sans engagement [cite: 2682]
- [cite_start]Interface adaptative et responsive [cite: 2682]
- [cite_start]**Animations fluides** et retours visuels (shimmer, animated_text_kit) [cite: 2682]

### 🔒 Sécurité et Confidentialité
- [cite_start]Stockage **100% local** des données (aucune connexion serveur) [cite: 2682]
- [cite_start]**Clé API FMP** stockée de manière sécurisée (Keystore/Keychain/Credential Manager) [cite: 2682]
- [cite_start]Aucune collecte de données personnelles [cite: 2682]

### 🌐 Mode En Ligne et Synchronisation des Prix

[cite_start]L'application propose un **mode en ligne optionnel** qui permet de synchroniser automatiquement les prix de vos actifs et de bénéficier d'une aide à la saisie lors de l'ajout de nouvelles transactions. [cite: 2682]
[cite_start]**Nouveauté** : Gestion intelligente des devises avec récupération automatique des prix dans leur devise native (USD, EUR, etc.) et conversion automatique selon la devise de votre compte. [cite: 2683]

#### Activation du Mode En Ligne

1. [cite_start]Ouvrez l'écran des **Paramètres** (icône ⚙️ en haut à droite) [cite: 2684]
2. [cite_start]Activez l'option **"Mode en ligne"** [cite: 2684]
3. [cite_start]L'indicateur de statut dans l'AppBar affiche maintenant **"En ligne"** [cite: 2684]

#### Fonctionnement

##### Récupération des Prix

[cite_start]L'application utilise une **stratégie de fallback intelligente** : [cite: 2684]

1. [cite_start]**Financial Modeling Prep (FMP)** : Si vous avez configuré une clé API (optionnel) [cite: 2684]
    - [cite_start]Plus fiable et complète [cite: 2684]
    - [cite_start]Requiert une inscription gratuite sur [financialmodelingprep.com](https://financialmodelingprep.com) [cite: 2684]

2. [cite_start]**Yahoo Finance** : Utilisé automatiquement en fallback ou si aucune clé FMP n'est configurée [cite: 2684]
    - [cite_start]Gratuit et sans inscription [cite: 2684]
    - [cite_start]Fonctionne pour la majorité des tickers (actions, ETF, cryptos) [cite: 2685]
    - [cite_start]**Récupère automatiquement la devise** de chaque actif (USD, EUR, GBP, etc.) [cite: 2685]

##### Taux de Change (NOUVEAU)
- [cite_start]L'application utilise l'API **Frankfurter (https://api.frankfurter.app)** pour récupérer les taux de change réels.
- [cite_start]Ces données proviennent de la **Banque Centrale Européenne (BCE)**.
- [cite_start]Les taux sont mis en cache pendant **24 heures** pour optimiser les performances. [cite: 430, 2747]

##### Cache Intelligent

Pour optimiser les performances et limiter les appels API :
- [cite_start]**Prix** : Mis en cache pendant **15 minutes** [cite: 2685, 350]
- [cite_start]**Recherche de tickers** : Mise en cache pendant **24 heures** [cite: 2685, 439]
- [cite_start]**Taux de change** : Mis en cache pendant **24 heures** [cite: 430]

### Configuration de la Clé API FMP (Optionnel)

[cite_start]Pour améliorer la fiabilité de la synchronisation, vous pouvez configurer une clé API Financial Modeling Prep : [cite: 2685]

1. [cite_start]Créez un compte gratuit sur [financialmodelingprep.com](https://financialmodelingprep.com) [cite: 2685]
2. [cite_start]Récupérez votre clé API depuis votre tableau de bord [cite: 2685]
3. Dans l'application :
    - [cite_start]Ouvrez **Paramètres** [cite: 2686]
    - [cite_start]Activez le **Mode en ligne** [cite: 2686]
    - [cite_start]Dans le champ **"Clé API FMP (Optionnel)"**, saisissez votre clé [cite: 2686]
    - [cite_start]Cliquez sur l'icône 💾 pour sauvegarder [cite: 2686]

[cite_start]**Sécurité** : La clé API est stockée de manière sécurisée dans le Keystore (Android) / Keychain (iOS) / Credential Manager (Windows). [cite: 2686]

### Recherche de Tickers et Auto-complétion

[cite_start]Lors de l'ajout d'une transaction (écran "Nouvelle Transaction") : [cite: 2687]

1. [cite_start]Commencez à taper un **ticker** (ex: "AAPL") ou un **ISIN** dans le champ dédié [cite: 2687]
2. [cite_start]Après 500ms, des suggestions apparaissent automatiquement (si le mode en ligne est actif) [cite: 2687]
3. Sélectionnez une suggestion pour :
    - [cite_start]Remplir automatiquement le **nom** de l'actif [cite: 2687]
    - [cite_start]Récupérer le **prix actuel** en temps réel [cite: 2687]
    - [cite_start]Pré-remplir le **prix unitaire** avec le prix actuel [cite: 2687]

[cite_start]**Types de résultats supportés** : Actions (EQUITY), ETF, Crypto-monnaies [cite: 2687]

### Synchronisation Automatique

Les prix sont synchronisés automatiquement dans les cas suivants :
- [cite_start]**Au démarrage** de l'application (si le mode en ligne est actif) [cite: 2688]
- [cite_start]**À l'activation** du mode en ligne [cite: 2688]
- [cite_start]L'indicateur **"Synchro..."** s'affiche pendant la mise à jour [cite: 2688]

[cite_start]**Mode hors ligne** : L'application fonctionne parfaitement sans connexion internet. [cite: 2689] [cite_start]Les prix restent ceux saisis manuellement ou récupérés lors de la dernière synchronisation. [cite: 2689]

### Indicateur de Statut

[cite_start]L'AppBar du Dashboard affiche l'état actuel de la connectivité : [cite: 2690]
- [cite_start]☁️ **"En ligne"** : Mode en ligne actif, synchronisation disponible [cite: 2690]
- [cite_start]🚫 **"Hors ligne"** : Mode hors ligne, pas de synchronisation [cite: 2690]
- [cite_start]⏳ **"Synchro..."** : Synchronisation en cours [cite: 2690]

### Limitations et Bonnes Pratiques

#### API Gratuites
- [cite_start]**Yahoo Finance** : Aucune limitation officielle mais évitez les requêtes excessives [cite: 2690]
- [cite_start]**FMP (gratuit)** : Généralement limité à 250 requêtes/jour (vérifiez votre plan) [cite: 2690]
- [cite_start]**Frankfurter** : API gratuite et sans limite d'utilisation. [cite: 2747, 2753]

#### Recommandations
- [cite_start]Le cache évite la plupart des appels répétés [cite: 2690]
- [cite_start]La synchronisation est optimisée (appels en parallèle) [cite: 2690]
- [cite_start]En cas d'échec, les prix existants sont conservés [cite: 2690]
- [cite_start]Les erreurs sont loguées dans la console (mode debug) [cite: 2690]

## 🚀 Installation et Configuration

### Prérequis

- [cite_start]**Flutter SDK** (compatible avec Dart >=3.4.0 <4.0.0)
  [cite_start]Installez depuis [https://flutter.dev](https://flutter.dev)
- [cite_start]Un appareil ou émulateur (Android / iOS / Windows / macOS / Linux)
- [cite_start]**Git** pour cloner le dépôt
- [cite_start]**Visual Studio** (pour Windows desktop) ou **Android Studio** (pour Android)

### Installation

1. [cite_start]**Clonez le dépôt** :
```powershell
git clone <URL_DU_DEPOT_GIT>
cd Portefeuille

    Récupérez les dépendances : 

PowerShell

flutter pub get

    Générez les fichiers Hive (adapters et sérialisation) : 

PowerShell

flutter pub run build_runner build --delete-conflicting-outputs

    Lancez l'application : 

PowerShell

# Sur un émulateur/appareil connecté
flutter run

# Sur Windows
flutter run -d windows

# Sur Android (APK debug)
flutter run -d <DEVICE_ID>

Vérification de l'Installation

Exécutez flutter doctor pour vérifier que votre environnement est correctement configuré :

PowerShell

flutter doctor

Notes de Développement

    Point d'entrée : lib/features/00_app/main.dart 

Le main initialise Hive, enregistre les adapters et ouvre les boxes avant d'instancier le repository

En mode debug, la base de données Hive n'est pas supprimée au démarrage, permettant de tester la persistance

Pour régénérer les fichiers .g.dart après modification des modèles :

PowerShell

    flutter pub run build_runner build --delete-conflicting-outputs

Boxes Hive Utilisées

L'application utilise six boxes Hive :

Box	Constante	Description
Portfolio	kPortfolioBoxName	

Données de portefeuille (institutions, comptes)

Settings	kSettingsBoxName	

Paramètres de l'application (couleur, mode en ligne, devise, etc.)

Transaction	kTransactionBoxName	

Historique complet des transactions

AssetMetadata	kAssetMetadataBoxName	

Prix et rendements des actifs (cache API)

PriceHistory	kPriceHistoryBoxName	

Historique des prix par jour — NOUVEAU

ExchangeRateHistory	kExchangeRateHistoryBoxName	

Historique des taux de change — NOUVEAU

📦 Compilation — Générer des Binaires

Android (APK / App Bundle)

Prérequis

    Android SDK et Android Studio installés

    Un device ou un émulateur configuré

    Vérifiez avec flutter doctor

Commandes de Compilation

APK Release (tous les ABIs) :
PowerShell

flutter build apk --release

APKs séparés par ABI (réduit la taille) :
PowerShell

flutter build apk --split-per-abi --release

Android App Bundle (AAB) pour le Play Store :
PowerShell

flutter build appbundle --release

Configuration de la Signature

Pour créer un APK signé pour la distribution :

    Créez un keystore :

PowerShell

keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

    Créez le fichier android/key.properties : 

Properties

storePassword=<mot_de_passe>
keyPassword=<mot_de_passe>
keyAlias=upload
storeFile=<chemin_vers_keystore>

    Configurez android/app/build.gradle (section signingConfigs) 

📍 Binaire généré : build/app/outputs/flutter-apk/app-release.apk

Windows (EXE)

Prérequis

    Machine Windows avec Visual Studio installé (Desktop development with C++)

    Support desktop activé :

PowerShell

flutter config --enable-windows-desktop
flutter doctor

Commande de Build

PowerShell

flutter build windows --release

📍 Exécutable généré : build\windows\x64\runner\Release\

Distribution

Pour distribuer l'exécutable :

    Incluez tous les fichiers du dossier Release\

    Les utilisateurs peuvent avoir besoin des VC++ Redistributables

Web (GitHub Pages)

🌐 Accès à l'Application Web

L'application est automatiquement déployée sur GitHub Pages à chaque push sur la branche master :

URL : https://kireg.github.io/portefeuille/

⚙️ Déploiement Automatique

Le workflow GitHub Actions (.github/workflows/deploy-web.yml) :

    Build automatique de l'application web

    Déploiement sur la branche gh-pages 

Publication sur GitHub Pages

Déclenchement : À chaque push sur master ou manuellement via l'onglet "Actions" sur GitHub

🔨 Build Web en Local

Pour compiler et tester localement :
PowerShell

# Build de production
flutter build web --release --base-href "/portefeuille/"

# Tester localement (serveur local sur http://localhost:8080)
cd build\web
python -m http.server 8080

📱 Utilisation sur iPhone

    Ouvrez Safari sur votre iPhone

    Accédez à l'URL : https://kireg.github.io/portefeuille/

    Pour ajouter à l'écran d'accueil :

        Appuyez sur le bouton Partager (icône ↑)

        Sélectionnez "Sur l'écran d'accueil"

        L'icône apparaîtra comme une application native

⚠️ Limitations Web

    Stockage local : Les données sont stockées dans IndexedDB (navigateur) 

Pas de synchronisation : Les données ne sont pas partagées entre appareils

Cache navigateur : Vider le cache supprime les données

flutter_secure_storage : Utilise le stockage navigateur standard (moins sécurisé que natif)

🔧 Configuration GitHub Pages

Si vous clonez ce projet, activez GitHub Pages :

    Allez dans Settings > Pages de votre dépôt

    Source : Deploy from a branch

    Branch : gh-pages / root

    Sauvegardez et attendez le déploiement

iOS / macOS

PowerShell

# iOS
flutter build ios --release

# macOS
flutter build macos --release

Linux

PowerShell

flutter build linux --release

⚠️ Recommandations

    Testez toujours en mode debug puis profile avant de compiler en release 

Vérifiez les permissions dans les manifestes (Android, iOS)

Sur Windows, testez l'exécutable sur une machine sans environnement de développement

🏗️ Architecture et Structure du Projet

Architecture Globale

Le projet suit une architecture feature-first modulaire avec séparation claire des responsabilités :

lib/
├── core/                    # Fondations partagées [cite: 2702]
│   ├── data/               # Couche données [cite: 2702]
│   ├── ui/               # Composants UI réutilisables [cite: 2702]
│   └── utils/              # Utilitaires globaux [cite: 2702]
│
└── features/               # Organisation par fonctionnalités [cite: 2702]
    ├── 00_app/            # Configuration de l'application [cite: 2702]
    ├── 01_launch/         # Écran d'accueil [cite: 2702]
    ├── 02_dashboard/      # Tableau de bord principal [cite: 2702]
    ├── 03_overview/       # Vue d'ensemble détaillée [cite: 2703]
    ├── 04_journal/        # Journal des transactions [cite: 2703]
    ├── 05_planner/        # Planificateur financier [cite: 2703]
    ├── 06_settings/       # Paramètres [cite: 2703]
    └── 07_management/     # Gestion des entités [cite: 2703]

Structure Détaillée

lib/
├── core/
│   ├── data/
│   │   ├── models/                            # 📦 Modèles Hive avec génération de code [cite: 2704]
│   │   │   ├── portfolio.dart               # Portefeuille principal [cite: 2704]
│   │   │   ├── institution.dart             # Institution financière [cite: 2704]
│   │   │   ├── account.dart                 # Compte d'investissement (getters calculés) [cite: 2705]
│   │   │   ├── account_type.dart            # Enum : PEA, CTO, Assurance Vie, etc. [cite: 2705]
│   │   │   ├── asset.dart                   # Actif/Position (getters calculés) [cite: 2705]
│   │   │   ├── asset_type.dart              # Enum : Stock, ETF, Crypto, etc. [cite: 2705]
│   │   │   ├── transaction.dart             # Transaction financière [cite: 2706]
│   │   │   ├── transaction_type.dart        # Enum : Buy, Sell, Deposit, etc. [cite: 2706]
│   │   │   ├── asset_metadata.dart          # Métadonnées (Prix, Rendement, Cache API) [cite: 2706]
│   │   │   ├── price_history_point.dart     # Historique des prix (par jour) [cite: 2706]
│   │   │   ├── exchange_rate_history.dart   # Historique des taux de change [cite: 2707]
│   │   │   ├── savings_plan.dart            # Plan d'épargne programmé [cite: 2707]
│   │   │   └── *.g.dart                     # Fichiers générés par build_runner [cite: 2707]
│   │   │
│   │   ├── repositories/
│   │   │   └── portfolio_repository.dart    # 🗄️ Repository principal (CRUD) [cite: 2707]
│   │   │
│   │   └── services/
│   │       └── api_service.dart             # 🌐 Service API (FMP + Yahoo Finance) [cite: 2708]
│   │
│   ├── ui/
│   │   ├── splash_screen.dart               # Écran de démarrage animé [cite: 2709]
│   │   └── theme/
│   │       └── app_theme.dart               # Thème Material personnalisé [cite: 2709]
│   │
│   └── utils/
│       ├── constants.dart                   # Constantes globales (noms des boxes) [cite: 2709]
│       └── currency_formatter.dart          # Formatage des montants en euros [cite: 2709]
│
├── features/
│   ├── 00_app/                              # 🚀 Configuration de l'application [cite: 2710]
│   │   ├── main.dart                        # Point d'entrée (init Hive, Providers) [cite: 2710]
│   │   └── providers/
│   │       ├── portfolio_provider.dart      # Gestion d'état du portefeuille [cite: 2710]
│   │       ├── portfolio_sync_logic.dart    # Logique de synchronisation API [cite: 2710]
│   │       ├── portfolio_migration_logic.dart # Migrations V1 & V2 (transactions & devises) [cite: 2711]
│   │       ├── portfolio_transaction_logic.dart # Logique CRUD des transactions [cite: 2711]
│   │       └── settings_provider.dart       # Gestion des paramètres [cite: 2711]
│   │
│   ├── 01_launch/                           # 🎬 Écran de lancement [cite: 2711]
│   │   └── ui/
│   │       └── launch_screen.dart           # Onboarding (démo ou nouveau portefeuille) [cite: 2712]
│   │
│   ├── 02_dashboard/                        # 📊 Tableau de bord principal [cite: 2712]
│   │   └── ui/
│   │       ├── dashboard_screen.dart        # Écran principal avec onglets [cite: 2712]
│   │       └── widgets/
│   │           └── dashboard_app_bar.dart   # AppBar personnalisée (statut en ligne) [cite: 2713]
│   │
│   ├── 03_overview/                         # 📈 Vue d'ensemble [cite: 2713]
│   │   └── ui/
│   │       ├── overview_tab.dart            # Onglet Vue d'ensemble [cite: 2713]
│   │       └── widgets/
│   │           ├── total_value_card.dart    # Carte valeur totale [cite: 2714]
│   │           ├── allocation_chart.dart    # Graphique répartition par compte [cite: 2714]
│   │           ├── asset_type_chart.dart    # Graphique répartition par type [cite: 2714]
│   │           └── ...                      # Autres widgets [cite: 2715]
│   │
│   ├── 04_journal/                          # 📖 Journal des transactions [cite: 2715]
│   │   └── ui/
│   │       ├── journal_tab.dart             # Onglet Journal (2 vues) [cite: 2715]
│   │       ├── views/
│   │       │   ├── synthese_view.dart       # Vue "Synthèse Actifs" (DataTable) [cite: 2716]
│   │       │   └── transactions_view.dart   # Vue "Transactions" (Liste) [cite: 2716]
│   │       └── widgets/
│   │           └── transaction_list_item.dart # Item de transaction [cite: 2716]
│   │
│   ├── 05_planner/                          # 📅 Planificateur financier [cite: 2717]
│   │   └── ui/
│   │       └── planner_tab.dart             # Simulateur d'investissements (BarChart) [cite: 2717]
│   │
│   ├── 06_settings/                         # ⚙️ Paramètres [cite: 2717]
│   │   └── ui/
│   │       ├── settings_screen.dart         # Écran principal des paramètres [cite: 2717]
│   │       └── widgets/
│   │           ├── appearance_settings.dart # Paramètres d'apparence [cite: 2718]
│   │           ├── app_settings.dart        # Paramètres de l'application (API) [cite: 2718]
│   │           ├── portfolio_management_settings.dart # Gestion portefeuilles [cite: 2718]
│   │           └── reset_app_section.dart   # Réinitialisation [cite: 2718]
│   │
│   └── 07_management/                       # 🛠️ Gestion des entités [cite: 2719]
│       └── ui/
│           ├── screens/
│           │   ├── add_institution_screen.dart
│           │   ├── add_account_screen.dart
│           │   ├── add_transaction_screen.dart  # ⭐ Avec recherche de tickers [cite: 2719]
│           │   ├── edit_transaction_screen.dart [cite: 2720]
│           │   └── add_savings_plan_screen.dart
│           └── widgets/
│               └── transaction_form_body.dart   # Formulaire partagé (add/edit)
│
└── main.dart                                # Export vers features/00_app/main.dart

🔑 Modèles de Données Clés

Transaction (typeId: 7)

Modèle central de l'architecture immuable :

    id, accountId, type, date 

amount, fees (montants dans la devise du compte)

assetTicker, assetName, assetType (pour Buy/Sell)

quantity, price (pour Buy/Sell - prix dans la devise de l'actif)

priceCurrency (devise du prix, ex: "USD") et exchangeRate (taux de conversion)

notes (notes personnalisées)

Getter totalAmount = amount - fees

Account (typeId: 2)

    Nouveau champ : currency (devise du compte : "EUR", "USD", etc.) 

Getters calculés : cashBalance, assets (basés sur transactions)

Champs dépréciés : stale_assets, stale_cashBalance (migration V1)

Asset (typeId: 3)

    Getters calculés : quantity, averagePrice (PRU) 

Champs en mémoire : currentPrice, estimatedAnnualYield (mis à jour par API)

AssetMetadata (typeId: 9)

    Cache des prix et rendements récupérés via API 

Nouveau champ : priceCurrency (devise du prix récupéré)

lastUpdated pour gérer l'expiration du cache

PriceHistoryPoint (typeId: 10) — NOUVEAU

    Historique des prix par jour 

Champs : ticker, date, price, currency

ExchangeRateHistory (typeId: 11) — NOUVEAU

    Historique des taux de change entre devises 

Champs : pair (ex: "USD-EUR"), date, rate

🔄 Flux de Données

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
PortfolioProvider → ApiService → FMP/Yahoo/Frankfurter [cite: 2723, 415, 371]
    ↓
AssetMetadata (cache) 

🧩 Providers

    SettingsProvider : Paramètres de l'application (couleur, mode en ligne, clé API, devise de base) 

PortfolioProvider : État du portefeuille, synchronisation, migrations V1 & V2

ApiService : Injection via Provider (non ChangeNotifier) - Gestion des prix et taux de change

📚 Documentation Complémentaire

📖 Migration V1 - Architecture par Transactions

L'application a migré vers une architecture immuable basée sur les transactions. Consultez le fichier MIGRATION_V1.md pour tous les détails :

    Nouveaux modèles : Transaction, TransactionType, AssetType 

Modifications des modèles : Account et Asset avec getters calculés

Logique de migration automatique : Conversion des anciennes données

Nouvelles fonctionnalités : Onglet Journal, Planificateur fonctionnel

Tests et bonnes pratiques

🌍 Migration V2 - Support Multi-Devises — NOUVEAU

La version 2 introduit la gestion complète des devises multiples :

    Comptes multi-devises : Chaque compte peut avoir sa propre devise (EUR, USD, GBP, etc.) 

Transactions internationales : Achat d'actifs en devise étrangère avec conversion automatique

Prix dans leur devise native : AAPL en USD, LVMH en EUR, etc.

Taux de change historiques : Conservation des taux utilisés lors des transactions

Migration automatique : Les données V1 sont converties en EUR par défaut

Exemple :

Dart

// Compte en EUR
Account { currency: "EUR" }

// Transaction : Achat AAPL (actif en USD)
Transaction {
  type: Buy,
  assetTicker: "AAPL",
  quantity: 10,
  price: 150.00,           // Prix en USD 
  priceCurrency: "USD",    // Devise du prix 
  exchangeRate: 0.92,      // Taux USD->EUR (1 USD = 0.92 EUR) 
  amount: -1380.00,        // Montant en EUR (10 × 150 × 0.92) 
  fees: 5.00               // Frais en EUR 
}

Résumé de la Migration

Avant (stockage direct) :

Dart

Account {
  cashBalance: 500€
  assets: [
    { ticker: "AAPL", quantity: 5, averagePrice: 100€ }
  ]
}

Après (calculé depuis les transactions) :

Dart

Account {
  transactions: [
    { type: Deposit, amount: 1000€, date: 2020-01-01 },
    { type: Buy, ticker: "AAPL", quantity: 5, price: 100€, amount: -500€ }
  ]
  
  // Getters calculés dynamiquement 
  cashBalance => 500€  (1000€ - 500€) [cite: 2727]
  assets[0].quantity => 5 [cite: 2727]
  assets[0].averagePrice => 100€  (PRU) [cite: 2727]
}

🔧 Suivi des Bugs et Corrections

    Corrections bug.md : Liste des bugs identifiés et corrigés 

CORRECTIONS_PR12.md : Dernières améliorations et corrections apportées

🧪 Tests et Qualité

Tests Unitaires

L'application dispose de tests unitaires pour les composants critiques :
PowerShell

# Lancer tous les tests
flutter test

# Lancer un fichier de test spécifique
flutter test test/core/data/services/api_service_test.dart

Tests Existants

    api_service_test.dart : Tests de récupération de prix (FMP/Yahoo), cache, recherche de tickers 

Tests des modèles : Calcul de cashBalance, quantity, averagePrice (PRU)

Tests de migration V1

Analyse Statique

Le projet utilise flutter_lints pour garantir la qualité du code :

PowerShell

flutter analyze

Configuration dans analysis_options.yaml.

🚦 Utilisation de l'Application

Premier Lancement

    Écran de lancement : Choisissez entre : 

    Mode Démo : Explore l'application avec des données fictives 

Nouveau Portefeuille : Créez votre portefeuille vierge

Créez une institution (ex: "Boursorama", "Binance")

Ajoutez un compte :

    Choisissez le type (PEA, CTO, Crypto, etc.) 

Sélectionnez la devise du compte (EUR, USD, GBP, etc.)

Nommez-le (ex: "PEA Principal")

Ajoutez votre première transaction :

    Cliquez sur le bouton + dans l'AppBar 

Type Dépôt pour ajouter des liquidités

Ou type Achat pour acheter un actif (avec recherche de ticker)

Navigation

🏠 Onglet "Vue d'ensemble"

    Valeur totale du portefeuille 

Graphiques : Répartition par compte et par type d'actif

Liste des comptes avec valeur et P/L

📅 Onglet "Planificateur"

    Créez des plans d'épargne (mensuels, trimestriels, annuels) 

Simulez la croissance de votre portefeuille (5 à 30 ans)

Graphique de projection avec capital investi et gains estimés

📖 Onglet "Journal"

    Vue "Synthèse Actifs" : Table complète de tous vos actifs avec PRU, P/L 

Vue "Transactions" : Historique complet des transactions

Actions : Modifier ou supprimer une transaction

⚙️ Paramètres (icône en haut à droite)

    Apparence : Changer la couleur principale 

Mode en ligne : Activer/désactiver la synchronisation des prix

Devise de base : Choisir votre devise principale (EUR, USD, etc.) — NOUVEAU

Clé API FMP : Configurer votre clé (optionnel)

Gestion des portefeuilles : Créer, changer, supprimer

Tableau de métadonnées : Suivi des prix/rendements (mode en ligne actif)

Mode En Ligne - Guide Rapide

    Activez le mode dans Paramètres > Mode en ligne 

L'indicateur "En ligne" s'affiche dans l'AppBar

Les prix se synchronisent automatiquement au démarrage avec leur devise native

Lors de l'ajout d'une transaction Achat :

    Tapez un ticker (ex: "AAPL") 

Sélectionnez dans les suggestions

Le prix actuel se pré-remplit automatiquement (en USD pour AAPL)

La conversion automatique s'applique selon la devise de votre compte

🤝 Contribution et Développement

Workflow de Développement

    Créer une branche pour votre fonctionnalité : 

PowerShell

git checkout -b feature/ma-fonctionnalite

    Modifier le code et tester localement 

Régénérer les fichiers Hive si modèles modifiés :

PowerShell

flutter pub run build_runner build --delete-conflicting-outputs

    Analyser le code : 

PowerShell

flutter analyze

    Lancer les tests : 

PowerShell

flutter test

    Commit et push : 

PowerShell

git add .
[cite_start]git commit -m "feat: description de la fonctionnalité" [cite: 2733]
[cite_start]git push origin feature/ma-fonctionnalite [cite: 2733]

Conventions de Code

    Langue : Code et commentaires en français 

Formatage : Utilisez le formateur Dart (dart format)

Nommage :

    Classes : PascalCase 

Variables/fonctions : camelCase

Constantes : kConstantName

Imports : Groupez les imports (Flutter > Package > Relatif)

Ajout de Nouvelles Fonctionnalités

Ajouter un nouveau type de transaction

    Modifiez transaction_type.dart 

Régénérez avec build_runner

Mettez à jour la logique de calcul dans account.dart et asset.dart

Ajoutez le type dans le formulaire transaction_form_body.dart

Ajouter un nouveau Provider

    Créez le fichier dans lib/features/00_app/providers/ 

Étendez ChangeNotifier

Ajoutez-le au MultiProvider dans main.dart

🐛 Dépannage

Problèmes Courants

"MissingPluginException"

Cause : Plugins natifs non synchronisés

Solution :

PowerShell

flutter clean
flutter pub get
flutter run

Erreur de génération Hive

Cause : Fichiers .g.dart obsolètes ou corrompus

Solution :

PowerShell

flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

Les prix ne se synchronisent pas

Vérifications :

    Mode en ligne activé ? (Paramètres) 

Connexion internet active ?

Vérifiez les logs dans la console (debugPrint)

Problèmes de conversion de devises

Cause : API de taux de change non disponible.

Note : ⚠️ L'application utilise l'API Frankfurter (BCE) pour les taux de change. Si l'API est indisponible, le taux de change de secours est 1.0.

Erreur "Box already open"

Cause : Tentative d'ouvrir une box déjà ouverte

Solution : Redémarrez l'application (Hot Restart, pas Hot Reload)

Logs et Debug

Activez les logs détaillés :

Dart

// Dans main.dart
debugPrint("🔍 Debug actif"); [cite: 2738]

Mode verbose :

PowerShell

flutter run -v

📄 Licence et Crédits

Dépendances Open Source

Ce projet utilise les packages suivants :

    provider - Gestion d'état 

hive & hive_flutter - Base de données locale

fl_chart - Graphiques interactifs

http - Requêtes HTTP

flutter_secure_storage - Stockage sécurisé

shimmer - Animations de chargement

animated_text_kit - Animations de texte

intl - Internationalisation et formatage

uuid - Génération d'identifiants uniques

APIs Utilisées

    Financial Modeling Prep (FMP) - Données financières et devises (optionnel, clé API requise) 

Yahoo Finance - Données financières et devises (gratuit, fallback automatique)

Taux de change : [Frankfurter (BCE)] - API réelle pour les taux de change.

Auteur

Portefeuille est développé et maintenu par [kireg].

📞 Support et Contact

Problèmes et Suggestions

    GitHub Issues : [Lien vers le repo] 

Consultez d'abord la section Dépannage

Incluez les logs et la version de Flutter dans votre rapport

Ressources

    Documentation Flutter : https://docs.flutter.dev 

Documentation Hive : https://docs.hivedb.dev

Guide Provider : https://pub.dev/packages/provider

🗺️ Roadmap et Améliorations Futures

Fonctionnalités Prévues

    [ ] Import/Export de transactions (CSV, JSON) 

[ ] Graphiques supplémentaires : Évolution historique, répartition sectorielle

[ ] Notifications : Alertes de prix, rappels de plans d'épargne

[x] Multi-devises : Support EUR, USD, GBP, etc. ✅ Implémenté en V2

[x] API taux de change réels : Remplacer les taux simulés par une API (FMP/ECB) ✅ Implémenté (Frankfurter)

[ ] Mode sombre : Thème clair/sombre

[ ] Synchronisation cloud : Backup automatique (Firebase/Supabase)

[ ] Analyse fiscale : Calcul automatique des déclarations (IFU, etc.)

[ ] Widget iOS/Android : Affichage de la valeur du portefeuille sur l'écran d'accueil

[ ] Graphiques historiques : Visualisation de l'évolution du prix des actifs

[ ] Conversion temps réel : Affichage des valeurs dans différentes devises

Optimisations Techniques

    [ ] Cache des getters : Mémorisation pour éviter les recalculs inutiles 

[ ] Pagination : Pour les grandes listes de transactions

[ ] Tests end-to-end : Tests d'intégration complets

[ ] CI/CD : Pipeline automatique de tests et déploiement

⚠️ Notes Importantes

Gestion Multi-Devises (V2)

La version 2 introduit le support multi-devises.

    Taux de change réels : L'application utilise l'API Frankfurter (BCE) pour les taux de change. Si l'API est indisponible, le taux de secours est 1.0. 

Migration automatique : Les données V1 (sans devise) sont automatiquement converties en EUR lors de la première utilisation de V2.

Compatibilité : Les portefeuilles créés en V2 ne sont pas rétro-compatibles avec V1.

Recommandations

    Backups réguliers : Bien que Hive soit fiable, des exports réguliers sont recommandés 

Version : 2.0.0+1 (Multi-Devises) Dernière mise à jour de la documentation : 16 novembre 2025

Made with ❤️ using Flutter