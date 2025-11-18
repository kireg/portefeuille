# Guide d'utilisation de Specify

Ce dossier contient la configuration **Specify** (Spec-Driven Development) pour le projet Portefeuille.

## 📚 Qu'est-ce que Specify ?

Specify est un toolkit qui permet de développer de manière structurée en se concentrant sur **QUOI construire** avant **COMMENT le construire**. Il aide les agents IA à respecter vos règles architecturales et à produire du code cohérent.

## 🎯 Objectif pour ce projet

Garantir que l'architecture feature-first de l'application Portefeuille soit **toujours respectée** par les agents IA, en évitant :
- ❌ Des features qui s'importent mutuellement
- ❌ Des accès directs à Hive depuis les UI
- ❌ Des fichiers surchargés de 500+ lignes
- ❌ De la duplication de code entre features

## 📂 Structure de ce dossier

```
.specify/
├── memory/
│   └── constitution.md          # 🏛️ Principes architecturaux du projet (LOI SUPRÊME)
├── templates/
│   ├── spec-template.md         # Template pour définir une nouvelle feature
│   ├── plan-template.md         # Template pour planifier l'implémentation
│   ├── tasks-template.md        # Template pour décomposer en tâches
│   └── agent-file-template.md   # Template pour les guidelines des agents
├── scripts/
│   └── powershell/              # Scripts d'automatisation (Windows)
└── README.md                    # Ce fichier
```

## 🚀 Commandes Specify disponibles

Les commandes Specify sont utilisées **dans le chat de votre agent IA** (GitHub Copilot, Claude, etc.).

### Commandes essentielles

| Commande | Description | Quand l'utiliser |
|----------|-------------|------------------|
| `/speckit.constitution` | Créer/modifier les principes architecturaux | ✅ Déjà fait - voir `memory/constitution.md` |
| `/speckit.specify` | Définir une nouvelle feature (QUOI) | Quand vous voulez ajouter une fonctionnalité |
| `/speckit.plan` | Créer le plan technique (COMMENT) | Après avoir défini le QUOI |
| `/speckit.tasks` | Générer la liste de tâches | Avant l'implémentation |
| `/speckit.implement` | Implémenter les tâches | Pour coder selon le plan validé |

### Commandes optionnelles

| Commande | Description | Utilité |
|----------|-------------|---------|
| `/speckit.clarify` | Clarifier les zones floues | Avant de planifier si des détails manquent |
| `/speckit.analyze` | Vérifier la cohérence des artefacts | Après `/speckit.tasks`, avant `/speckit.implement` |
| `/speckit.checklist` | Générer des checklists de qualité | Pour valider la complétude |

## 📖 Workflow recommandé pour ajouter une feature

### Option 1 : Développement rapide (sans Specify)

Si vous voulez juste coder rapidement, l'agent IA **respectera automatiquement** la constitution :

```
Vous : "Ajoute un filtre de transactions par date"
IA : *Lit constitution.md automatiquement*
    → Crée un nouveau fichier dans 04_journal/ui/widgets/
    → Utilise PortfolioProvider au lieu d'accéder à Hive
    → Respecte les conventions de nommage
```

### Option 2 : Développement structuré (avec Specify)

Pour des features complexes, utilisez le workflow complet :

#### 1️⃣ Définir QUOI construire

```
/speckit.specify Ajouter un système de filtrage des transactions avec les critères suivants :
- Filtrer par date (plage de dates personnalisée)
- Filtrer par type de transaction (achat, vente, dividende)
- Filtrer par compte
- Sauvegarder les filtres favoris
```

**Résultat** : Création de `specs/XXX-transaction-filters/spec.md` avec :
- User stories détaillées
- Scénarios d'acceptance
- Requirements fonctionnels

#### 2️⃣ Planifier COMMENT l'implémenter

```
/speckit.plan Cette feature utilisera :
- Un nouveau widget TransactionFilterPanel dans 04_journal/ui/widgets/
- Un provider local TransactionFilterState pour gérer l'état des filtres
- Sauvegarde des filtres favoris dans SettingsProvider
- UI Material Design avec chips pour les filtres actifs
```

**Résultat** : Création de `specs/XXX-transaction-filters/plan.md` avec :
- Structure des fichiers
- Architecture technique
- Dépendances

#### 3️⃣ Générer les tâches

```
/speckit.tasks
```

**Résultat** : Création de `specs/XXX-transaction-filters/tasks.md` avec :
- Liste de tâches ordonnées
- Dépendances entre tâches
- Estimation de complexité

#### 4️⃣ (Optionnel) Analyser la cohérence

```
/speckit.analyze
```

**Résultat** : Vérification que :
- Les tâches couvrent tous les requirements
- Pas de contradiction entre spec et plan
- Architecture conforme à la constitution

#### 5️⃣ Implémenter

```
/speckit.implement
```

**Résultat** : L'agent IA code toutes les tâches en respectant :
- La constitution (règles architecturales)
- Le plan technique validé
- Les conventions du projet

## 🏛️ Constitution : La loi suprême

Le fichier `memory/constitution.md` contient les **8 principes fondamentaux** du projet :

1. **Architecture Feature-First** - Isolation des features
2. **Hiérarchie des dépendances** - Features → 00_app → core
3. **Responsabilité unique** - Un fichier = une classe
4. **Ressources partagées dans Core** - Widget 2+ features → core/
5. **State Management Provider** - Providers globaux dans 00_app/
6. **Accès aux données** - Pas d'accès direct à Hive
7. **Conventions de nommage** - *_screen.dart, *_provider.dart, etc.
8. **Test-First** - Tests pour logique critique

**Important** : Les agents IA consultent **automatiquement** ce fichier avant de générer du code.

## ✅ Ce qui est déjà configuré

- ✅ Constitution créée avec les 8 principes architecturaux
- ✅ Documentation complète dans `docs/ARCHITECTURE.md`
- ✅ Templates Specify prêts à l'emploi
- ✅ Scripts PowerShell pour automatisation

## 🎓 Exemples concrets

### Exemple 1 : Ajouter un simple widget

**Sans Specify** (rapide) :
```
Vous : "Crée un widget AccountBalanceCard pour afficher le solde d'un compte"
IA : *Consulte constitution.md*
    → Crée lib/features/XX_feature/ui/widgets/account_balance_card.dart
    → Widget utilisé dans 1 feature seulement
```

**Avec Specify** (structuré) :
```
1. /speckit.specify Widget AccountBalanceCard avec affichage solde, devise, variation 24h
2. /speckit.plan Widget Material avec Card, ListTile, données depuis PortfolioProvider
3. /speckit.tasks
4. /speckit.implement
```

### Exemple 2 : Feature complexe multi-fichiers

**Sans Specify** :
```
Vous : "Ajoute un système de notifications pour les alertes de prix"
IA : Risque de mal organiser les fichiers
```

**Avec Specify** (recommandé) :
```
1. /speckit.specify [description détaillée avec user stories]
2. /speckit.clarify [si zones floues]
3. /speckit.plan [architecture technique]
4. /speckit.tasks [décomposition]
5. /speckit.analyze [vérification]
6. /speckit.implement [codage]
```

## 🔍 Vérifier que Specify fonctionne

Pour tester que la constitution est bien prise en compte :

```
Vous : "Crée un widget qui accède directement à Hive.box<Portfolio>()"
IA : ❌ Devrait refuser et proposer d'utiliser PortfolioProvider à la place
```

Si l'IA ne respecte pas la constitution, vérifiez :
1. Le fichier `memory/constitution.md` existe
2. Votre agent IA supporte Specify (voir liste ci-dessous)

## 🤖 Agents IA compatibles

| Agent | Support Specify | Notes |
|-------|----------------|-------|
| GitHub Copilot | ✅ | Intégration native |
| Claude Code | ✅ | Supporte les commandes slash |
| Cursor | ✅ | Compatible |
| Windsurf | ✅ | Compatible |
| Gemini CLI | ✅ | Compatible |

## 📚 Ressources

- [Documentation officielle Specify](https://github.com/github/spec-kit)
- [Architecture du projet](../docs/ARCHITECTURE.md)
- [Spec-Driven Development Methodology](https://github.com/github/spec-kit/blob/main/spec-driven.md)

## 🆘 Besoin d'aide ?

1. **Constitution pas respectée ?** 
   - Vérifiez que `memory/constitution.md` est à jour
   - Relancez l'agent IA avec un nouveau chat

2. **Commande Specify ne fonctionne pas ?**
   - Vérifiez que votre agent supporte Specify
   - Utilisez `/` (slash) avant la commande

3. **Feature mal organisée ?**
   - Utilisez le workflow Specify complet
   - Validez le plan AVANT d'implémenter

---

**Dernière mise à jour** : 18 novembre 2025  
**Version de la constitution** : 1.0.0
