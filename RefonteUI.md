C'est une excellente décision stratégique. Pour atteindre un rendu "Premium" (type Finary, Revolut, Coinbase) et une maintenabilité parfaite, nous devons transformer `core/ui` en un **Design System** interne strict.

L'objectif est que les `features` ne contiennent **plus aucune logique de style**. Elles ne doivent faire qu'assembler des briques fournies par le `core`.

Voici la feuille de route ultra-détaillée pour cette transformation.

-----

## 🏗️ Phase 1 : Fondations du Design System (L'ADN)

Avant de toucher aux écrans, nous devons définir les règles physiques de l'interface dans `lib/core/ui/theme/`.

### 1.1. Palette de Couleurs Sémantique (`app_colors.dart`)

Ne plus utiliser `Colors.blue` ou `Colors.grey[800]`. Tout doit être sémantique.

* **Action** : Créer une palette sombre profonde ("Midnight") avec des accents néons.
* **Structure** :
    * `surfacePrimary` (Noir absolu ou très sombre)
    * `surfaceSecondary` (Gris bleuté sombre pour les cartes)
    * `surfaceGlass` (Pour l'effet de transparence/flou)
    * `accentPrimary` (Le "Brand Color", ex: Bleu électrique)
    * `textPrimary`, `textSecondary`, `textDisabled`
    * `semanticSuccess`, `semanticError`, `semanticWarning` (version pastel/néon, pas de rouge pur agressif)

### 1.2. Typographie Centralisée (`app_typography.dart`)

* **Action** : Définir des styles de texte fixes pour empêcher l'utilisation de tailles arbitraires.
* **Structure** :
    * `hero` (Pour le montant total du portefeuille)
    * `h1`, `h2`, `h3` (Titres de sections)
    * `bodyBold`, `body`, `caption`
    * **Note** : Intégrer une police moderne comme **Inter** ou **Manrope**.

### 1.3. Espacements et Rayons (`app_dimens.dart`)

* **Action** : Finis les `SizedBox(height: 13)`.
* **Structure** :
    * `paddingS`, `paddingM`, `paddingL`, `paddingXL`
    * `radiusS` (boutons), `radiusM` (cartes), `radiusL` (bottom sheets)

-----

## 🧱 Phase 2 : Création des "Primitifs" (Atoms)

Nous allons créer des widgets dans `lib/core/ui/widgets/primitives/` qui remplaceront les widgets Flutter de base.

### 2.1. `AppCard` (Le conteneur principal)

C'est la clé du design Premium. Elle ne doit pas être un simple rectangle gris.

* **Specs** :
    * Gradient subtil (haut-gauche plus clair, bas-droite plus sombre) pour simuler une lumière.
    * Bordure très fine (`0.5`) semi-transparente (effet verre).
    * Ombre diffuse colorée (glow) très légère.

### 2.2. `AppButton` (Boutons d'action)

* **Specs** :
    * Variante `Primary` : Dégradé linéaire de la couleur de marque, ombre portée, effet de presse (scale down).
    * Variante `Secondary` : Fond transparent, bordure fine.
    * Variante `Ghost` : Juste le texte, mais avec le style typographique correct.

### 2.3. `AppIcon`

* **Specs** : Wrapper autour de `Icon` pour forcer les couleurs du thème et gérer des fonds circulaires automatiques (ex: icône "Dépôt" avec cercle vert autour).

### 2.4. `AppTag` / `AppBadge`

* **Specs** : Pour afficher "PEA", "CTO", "SYNCHRONISÉ". Fond coloré à 10% d'opacité + texte de la même couleur.

-----

## 🧬 Phase 3 : Composants Moléculaires (Molecules)

Assemblage des atomes pour créer des composants fonctionnels réutilisables dans `lib/core/ui/widgets/components/`.

### 3.1. `AppScreen` (Wrapper de Scaffold)

* **Objectif** : Centraliser la gestion de la SafeArea, du Background (gradient global), et des loadings.
* **Action** : Toutes les pages (`*_screen.dart`) devront utiliser `AppScreen` au lieu de `Scaffold`.

### 3.2. `AppHeader` (SliverAppBar moderne)

* **Objectif** : Gérer les titres qui rétrécissent au scroll, avec effet de flou (blur) sur l'arrière-plan quand le contenu passe dessous.

### 3.3. `AppTile` (ListTile Premium)

* **Specs** :
    * Remplacer `ListTile`.
    * Mise en page Flex pour gérer le titre, le sous-titre, le montant (droite haut) et le détail (droite bas).
    * Support natif des squelettes de chargement (Shimmer).

### 3.4. `AppTextField`

* **Specs** : Input avec fond sombre unifié, bordure qui s'illumine au focus, label flottant propre.

-----

## 📊 Phase 4 : Visualisation de Données (Organisms)

Le cœur d'une app de finance. À placer dans `lib/core/ui/widgets/charts/`.

### 4.1. `AppLineChart` (Wrapper fl\_chart)

* **Action** : Créer une abstraction qui prend juste une liste de points `List<PortfolioValueHistoryPoint>`.
* **Style** : Courbe de Bézier (smooth), dégradé sous la courbe (fill), effet "Neon" sur la ligne, suppression des grilles moches.

### 4.2. `AppPieChart` (Camembert)

* **Action** : Abstraction prenant `Map<String, double>`.
* **Style** : Donut chart (trou au milieu), sections espacées, légendes externes propres.

-----

## 🛠️ Phase 5 : Le Grand Refactoring (Exécution)

Une fois le `core/ui` prêt, nous migrons feature par feature.

### 5.1. Nettoyage de `lib/core/ui/theme/app_theme.dart`

* Supprimer les méthodes statiques `buildStyledCard`, `buildSectionHeader`.
* Elles sont remplacées par les classes `AppCard`, `AppSectionHeader`.

### 5.2. Migration de `03_overview` (Le plus visible)

* Remplacer `PortfolioHeader` par une composition de `AppCard` + `AppText`.
* Remplacer les graphiques par `AppLineChart` et `AppPieChart`.
* Remplacer `InstitutionTile` par `AppCard` + `AppTile`.

### 5.3. Migration de `04_journal` (Les listes)

* Remplacer `TransactionListItem` par `AppTile`.
* Remplacer les tableaux de `SyntheseView` par des widgets personnalisés (les DataTables Flutter par défaut sont très laides sur mobile).

### 5.4. Migration de `07_management` (Les formulaires)

* Remplacer tous les `TextFormField` par `AppTextField`.
* Remplacer les `ElevatedButton` par `AppButton`.

-----

## 💎 Phase 6 : La "Premium Touch" (Polissage)

Une fois la structure en place, on ajoute les détails qui font la différence.

### 6.1. Animations d'entrée

* Généraliser `FadeInSlide` (que nous avons créé) sur **toutes** les listes et cartes.
* Utiliser `flutter_staggered_animations` pour que les listes s'affichent en cascade.

### 6.2. Micro-interactions

* Ajouter des retours haptiques (`HapticFeedback.lightImpact()`) sur les clics de boutons et les sélections de graphiques.

### 6.3. Skeleton Loaders

* Remplacer les `CircularProgressIndicator` par des effets Shimmer qui miment la forme exacte des composants (via `AppTile.loading()`, `AppCard.loading()`).

-----

## 📂 Structure de fichiers cible pour `lib/core/ui`

Voici à quoi devra ressembler le dossier `core/ui` à la fin :

```
lib/core/ui/
├── theme/
│   ├── app_colors.dart       # Palette sémantique
│   ├── app_typography.dart   # Styles de texte
│   ├── app_dimens.dart       # Espacements et rayons
│   └── app_theme.dart        # Configuration ThemeData
├── widgets/
│   ├── primitives/           # Atomes (Briques de base)
│   │   ├── app_card.dart
│   │   ├── app_button.dart
│   │   ├── app_icon.dart
│   │   ├── app_badge.dart
│   │   └── app_text.dart     # Raccourci pour Text avec style auto
│   ├── components/           # Molécules (Assemblages)
│   │   ├── app_screen.dart   # Wrapper de page
│   │   ├── app_header.dart   # Titres de section
│   │   ├── app_tile.dart     # Lignes de listes
│   │   └── app_loader.dart   # Shimmer
│   ├── inputs/               # Formulaires
│   │   ├── app_text_field.dart
│   │   └── app_dropdown.dart
│   └── charts/               # Graphiques
│       ├── app_line_chart.dart
│       └── app_pie_chart.dart
└── app_ui.dart               # Barrel file (exporte tout)
```

## 🚀 Première étape concrète

Je vous propose de commencer par **Phase 1 et Phase 2** (Couleurs, Typo et Primitifs `AppCard` et `AppButton`).

**Voulez-vous que je génère le code pour ces fondations (Palette, Typo, AppCard, AppButton) maintenant ?** Cela nous donnera la base pour migrer le reste.