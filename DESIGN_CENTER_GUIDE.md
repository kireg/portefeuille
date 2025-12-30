# 📚 Guide Design Center - Utilisation & Corrections

## ✅ Avant toute correction, consulter ce guide

Vous avez trouvé un hardcoding d'UI ? Consultez ce guide pour la correction rapide.

---

## 🎨 **Correction des Couleurs**

### ❌ NE PAS FAIRE
```dart
Icon(Icons.check, color: Colors.red)
Container(color: Colors.white)
Text("Erreur", style: TextStyle(color: Colors.grey))
BoxDecoration(border: Border.all(color: Colors.black))
```

### ✅ À FAIRE
```dart
// Import requis (vérifier qu'il existe)
import 'package:portefeuille/core/ui/theme/app_colors.dart';

// Puis utiliser:
Icon(Icons.check, color: AppColors.error)
Container(color: AppColors.white)
Text("Erreur", style: TextStyle(color: AppColors.textSecondary))
BoxDecoration(border: Border.all(color: AppColors.textPrimary))
```

### 📖 Mapping des Couleurs Communes

| ❌ Hardcodé | ✅ AppColors |
|-----------|-----------|
| `Colors.red` | `AppColors.error` |
| `Colors.green` | `AppColors.success` |
| `Colors.blue` / `Colors.blueAccent` | `AppColors.primary` |
| `Colors.white` | `AppColors.white` |
| `Colors.black` | `AppColors.textPrimary` |
| `Colors.grey` | `AppColors.textSecondary` |
| `Colors.grey[300]` | `AppColors.border` |
| `Colors.grey[100]` | `AppColors.surfaceLight` |
| `Colors.redAccent` | `AppColors.error` |
| `Colors.greenAccent` | `AppColors.success` |
| `Colors.amber` | `AppColors.warning` |
| `Colors.cyan` | `AppColors.cyan` |
| `Colors.orange` | `AppColors.orange` |

### 🎭 Overlays Semi-Transparents

```dart
// ❌ NE PAS FAIRE
Container(color: Colors.white.withValues(alpha: 0.5))
Container(color: Colors.black.withValues(alpha: 0.3))

// ✅ À FAIRE (couleurs prédéfinies)
Container(color: AppColors.whiteOverlay50)
Container(color: AppColors.blackOverlay30)
```

**Variantes disponibles:**
- `AppColors.whiteOverlay05`, `whiteOverlay10`, `whiteOverlay20`, ..., `whiteOverlay60`
- `AppColors.blackOverlay10`, `blackOverlay20`, ..., `blackOverlay60`

---

## 📝 **Correction de la Typographie**

### ❌ NE PAS FAIRE
```dart
Text("Titre", style: TextStyle(fontSize: 24))
Text("Body", style: TextStyle(fontSize: 14))
Text("Caption", style: TextStyle(fontSize: 12, color: Colors.grey))
Theme.of(context).textTheme.bodyMedium
```

### ✅ À FAIRE
```dart
// Import requis
import 'package:portefeuille/core/ui/theme/app_typography.dart';

// Puis utiliser les styles prédéfinis:
Text("Titre", style: AppTypography.h1)
Text("Body", style: AppTypography.body)
Text("Caption", style: AppTypography.caption)
Text("Détail", style: AppTypography.micro)

// Ou avec couleur dynamique:
Text("Erreur", style: AppTypography.bodyWithColor(AppColors.error))
```

### 📖 Mapping des Tailles de Texte

| ❌ Hardcodé | ✅ AppTypography |
|-----------|-----------|
| `fontSize: 10` | `AppTypography.micro` |
| `fontSize: 11` | `AppTypography.small` |
| `fontSize: 12` | `AppTypography.caption` |
| `fontSize: 14` | `AppTypography.body` |
| `fontSize: 16` | `AppTypography.h3` |
| `fontSize: 18` | `AppTypography.h2` |
| `fontSize: 20` | `AppTypography.h1` |
| `fontSize: 24+` | `AppTypography.hero` |

### 🎨 Helpers Typographie

```dart
// Appliquer une couleur custom au style:
Text("Success", style: AppTypography.bodyWithColor(AppColors.success))
Text("Error", style: AppTypography.captionWithColor(AppColors.error))

// Copier et modifier un style:
Text("Bold", style: AppTypography.body.copyWith(fontWeight: FontWeight.bold))
```

---

## 📏 **Correction des Dimensions**

### ❌ NE PAS FAIRE
```dart
Padding(padding: EdgeInsets.all(8))
Padding(padding: EdgeInsets.all(16))
BorderRadius.circular(4)
BorderRadius.circular(12)
const SizedBox(height: 8)
```

### ✅ À FAIRE
```dart
// Import requis
import 'package:portefeuille/core/ui/theme/app_dimens.dart';

// Puis utiliser les constantes:
Padding(padding: EdgeInsets.all(AppDimens.paddingXS))  // 4px
Padding(padding: EdgeInsets.all(AppDimens.paddingM))   // 16px
BorderRadius.circular(AppDimens.radiusS)   // 4px
BorderRadius.circular(AppDimens.radiusM)   // 12px
SizedBox(height: AppDimens.paddingXS)
```

### 📖 Mapping des Espacements

| ❌ Hardcodé | ✅ AppDimens |
|-----------|-----------|
| `4` px | `AppDimens.paddingXS` |
| `8` px | `AppDimens.paddingS` |
| `12` px | (utiliser `paddingM` = 16) |
| `16` px | `AppDimens.paddingM` |
| `20` px | (utiliser `paddingL` = 24) |
| `24` px | `AppDimens.paddingL` |
| `32` px | `AppDimens.paddingXL` |

### 📐 Rayon des Coins

| ❌ Hardcodé | ✅ AppDimens |
|-----------|-----------|
| `4` | `AppDimens.radiusS` |
| `8` | `AppDimens.radiusM` |
| `12` | `AppDimens.radiusL` |
| `16` | (utiliser `radiusL` = 12) |
| `20` | (utiliser `radiusL` = 12) |

### 📊 Hauteurs des Tab Bars

Pour les écrans avec barres flottantes (supérieure ou inférieure), utilisez les constantes prédéfinies:

| ❌ Hardcodé | ✅ AppDimens | Usage |
|-----------|-----------|-------|
| `90` | `floatingAppBarPaddingTopFixed` | Padding TOP pour écrans avec AppBar flottante (Dashboard, Synthèse, Transactions) |
| `100` ou `80` | `floatingNavBarPaddingBottomFixed` | Padding BOTTOM pour écrans avec BottomNavBar flottante (Planification, Crowdfunding, Settings) |
| `60` | `floatingAppBarHeight` | Hauteur réelle de la barre supérieure |
| `80` | `floatingNavBarHeight` | Hauteur réelle de la barre de navigation inférieure |
| `56` | `tabBarHeight` | Hauteur standard d'une TabBar Material |

#### Exemple : Top Padding (AppBar flottante supérieure)
```dart
// ❌ NE PAS FAIRE
final double topPadding = MediaQuery.of(context).padding.top + 90;

// ✅ À FAIRE
final double topPadding = MediaQuery.of(context).padding.top + AppDimens.floatingAppBarPaddingTopFixed;

// Dans CustomScrollView avec SliverPadding
SliverPadding(
  padding: EdgeInsets.only(top: topPadding),
  sliver: ...,
)
```

#### Exemple : Bottom Padding (BottomNavBar flottante)
```dart
// ❌ NE PAS FAIRE
Padding(padding: EdgeInsets.only(bottom: 100))
SizedBox(height: 80)

// ✅ À FAIRE
Padding(
  padding: EdgeInsets.only(bottom: AppDimens.floatingNavBarPaddingBottomFixed),
  child: ...,
)

// Dans ListView
ListView.builder(
  padding: const EdgeInsets.fromLTRB(
    AppDimens.paddingM, 
    0, 
    AppDimens.paddingM, 
    AppDimens.floatingNavBarPaddingBottomFixed
  ),
  itemBuilder: ...,
)
```

#### Exemple : TabBar avec contenu
```dart
// ✅ PATTERN POUR SETTINGS SCREEN
Expanded(
  child: TabBarView(
    children: [
      Padding(
        padding: const EdgeInsets.only(
          bottom: AppDimens.floatingNavBarPaddingBottomFixed,
        ),
        child: const GeneralSettingsTab(),
      ),
      // ... autres tabs
    ],
  ),
)
```

---

## 🔧 **Processus de Correction Pas à Pas**

### 1. Identifier la violation
```bash
dart scripts/lint_design_center.dart
```
Regardez la ligne signalée et le type de violation.

### 2. Ajouter l'import (le cas échéant)
```dart
import 'package:portefeuille/core/ui/theme/app_colors.dart';
import 'package:portefeuille/core/ui/theme/app_typography.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
```

### 3. Remplacer le code hardcodé
Utiliser le mapping fourni ci-dessus.

### 4. Valider
```bash
dart scripts/lint_design_center.dart
```
Le nombre de violations doit diminuer.

---

## 🎯 **Cas Spéciaux**

### Couleur non-disponible?
Si votre couleur n'existe pas dans `AppColors`, **ajoutez-la** à `lib/core/ui/theme/app_colors.dart`:

```dart
// Avant
Container(color: Color(0xFF123456))

// Après - dans app_colors.dart
static const Color myCustomColor = Color(0xFF123456);

// Puis dans votre fichier
Container(color: AppColors.myCustomColor)
```

### Taille non-standard?
Si vous avez besoin d'une taille de police intermédiaire:

```dart
// Avant
Text("Special", style: TextStyle(fontSize: 13))

// Après
Text("Special", style: AppTypography.body.copyWith(fontSize: 13))
```

### Espacement non-standard?
```dart
// Avant
Padding(padding: EdgeInsets.all(5))

// Après
Padding(padding: EdgeInsets.all(AppDimens.paddingXS).copyWith(top: 5))
// Ou simplement arrondir à AppDimens.paddingXS (4) ou paddingS (8)
```

---

## ✨ **Bénéfices de cette Approche**

✅ **Maintenabilité**: Changer le thème en 1 endroit seulement  
✅ **Cohérence**: UI uniforme partout  
✅ **Dark Mode**: Support automatique (futur)  
✅ **Performance**: Pas de recalculs à l'exécution  
✅ **Accessibilité**: Espacements et tailles respectent les standards  

---

## 📞 **Questions?**

- Consultez [DESIGN_CENTER_MIGRATION.md](../../../DESIGN_CENTER_MIGRATION.md)
- Vérifiez `lib/core/ui/theme/app_colors.dart`
- Lancez le linter: `dart scripts/lint_design_center.dart`

---

**Statut:** ✅ Design Center 147/152 violations corrigées (~97% conformité)  
**Dernier update:** 30 Décembre 2025
