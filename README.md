# Portefeuille - Application de Suivi Financier

Ce projet vise à créer une application mobile pour le suivi de portefeuille financier, en se basant sur une architecture Flutter moderne et maintenable.

## Téléchargement pour Test

Vous pouvez télécharger les dernières versions de test de l'application ici :

- ⬇️ **[Télécharger pour Windows](https://github.com/kireg/portefeuille/releases/download/v0.1.0/portefeuille-windows-v0.1.0.zip)**
- ⬇️ **[Télécharger pour Android](https://github.com/kireg/portefeuille/releases/download/v0.1.0/app-release.apk)**

*Note pour Android : Vous devrez peut-être autoriser l'installation d'applications de sources inconnues dans les paramètres de votre téléphone.*

---

## État d'Avancement (au 28/05/2024)

La structure de base de l'application est en place, incluant les modèles de données, la gestion d'état et le squelette de l'interface utilisateur. Le projet est maintenant prêt pour l'implémentation des fonctionnalités dynamiques.

### Ce qui est terminé (Fondations Techniques) :

- **Squelette de l'Interface Utilisateur (UI) :** Les écrans principaux ont été implémentés de manière statique et affichent des données d'exemple.
- **Modèles de Données (`models`) :** La structure des données est définie, préparant l'application à gérer les informations du portefeuille.
- **Gestion d'État (`providers`) :** Le socle de gestion d'état est configuré avec `Provider` pour une architecture réactive.
- **Thème Visuel (`utils`) :** Le thème global de l'application (Dark Mode) est implémenté et centralisé.
- **Persistance des Données (stockage local) :** L'application sauvegarde les données de l'utilisateur et les conserve entre les sessions grâce à `Hive`.

### Problèmes Techniques Résolus :

- **Mise à Jour des Dépendances :** Correction d'un blocage critique causé par des versions de dépendances obsolètes (notamment `fl_chart`), assurant la compatibilité avec les dernières fonctionnalités des packages.
- **Correction de l'API des Graphiques :** Mise à jour du code des graphiques pour utiliser les API modernes suite à la mise à jour de la dépendance `fl_chart`.
- **Conventions de Nommage et API Obsolètes :** Harmonisation du code pour respecter les conventions `lowerCamelCase` et remplacement des API Flutter obsolètes (ex: `CardThemeData`, `WidgetStateProperty`).
- **Configuration de la Génération de Code :** Résolution des erreurs de synchronisation avec les fichiers générés par `Hive` (`.g.dart`) après modification des modèles de données.

## Prochaines Étapes (Implémentation des Fonctionnalités)

Voici la liste des tâches à accomplir pour rendre l'application fonctionnelle. Vous pouvez demander à démarrer une tâche en utilisant son numéro.

- **2. Implémentation de la Logique UI**
  - **Objectif :** Rendre l'interface utilisateur dynamique et interactive.
  - **Tâches :**
    - **2.1.** Activer l'onglet **"Correction"** pour permettre la modification des données du portefeuille.
    - **2.2.** Connecter les **graphiques** aux données réelles du `PortfolioProvider`.
    - **2.3.** Développer la logique de l'onglet **"Planificateur"** (création/gestion des plans).

- **3. Intégration des Services Externes**
  - **Objectif :** Connecter l'application à des API externes.
  - **Tâches :**
    - **3.1.** Implémenter l'appel à l'API Google Gemini pour la fonctionnalité d'**Analyse IA**.
    - **3.2.** (Optionnel) Intégrer une API financière pour la **mise à jour automatique des prix**.

- **4. Amélioration de l'Expérience Utilisateur (UX)**
  - **Objectif :** Finaliser le parcours utilisateur et ajouter des fonctionnalités de confort.
  - **Tâches :**
    - **4.1.** Implémenter le flux de **création d'un nouveau portefeuille**.
    - **4.2.** Implémenter la logique d'affichage des **bulles d'aide** (Tooltips) en fonction du niveau de l'utilisateur.
