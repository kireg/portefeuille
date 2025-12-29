# Logique de Calculs - My-Invests

Ce document décrit les règles de gestion et les formules mathématiques appliquées dans l'application pour garantir la cohérence des données financières.

## 1. Gestion des Liquidités (Cash Balance)

La liquidité d'un compte est calculée dynamiquement en sommant toutes les transactions.

### Formule
$$ \text{Cash Balance} = \sum (\text{Montant Transaction}) $$

### Règles par Type de Transaction
| Type | Impact sur Liquidité | Signe du Montant | Exemple |
| :--- | :--- | :--- | :--- |
| **Dépôt** (`Deposit`) | Augmente | Positif (+) | Virement entrant de 1000€ |
| **Retrait** (`Withdrawal`) | Diminue | Négatif (-) | Virement sortant de 500€ |
| **Achat** (`Buy`) | Diminue | Négatif (-) | Achat d'actions pour 200€ |
| **Vente** (`Sell`) | Augmente | Positif (+) | Vente d'actions pour 250€ |
| **Dividende** (`Dividend`) | Augmente | Positif (+) | Réception de 10€ |
| **Intérêts** (`Interest`) | Augmente | Positif (+) | Intérêts reçus |
| **Frais** (`Fees`) | Diminue | Négatif (-) | Frais de courtage |

> **Note Importante :** Lors des imports (PDF, Excel), il est crucial de convertir les montants d'achat en négatif. Si un utilisateur importe un achat de 1000€ sans dépôt préalable, le solde sera de -1000€. L'application gère ce cas (solde négatif) sans erreur.

---

## 2. Valorisation du Portefeuille

La valeur totale est la somme de la valeur de tous les actifs + la liquidité disponible.

### Formule Globale
$$ \text{Valeur Totale} = \sum (\text{Valeur Actifs}) + \sum (\text{Cash Balance}) $$

### Valorisation d'un Actif
$$ \text{Valeur Actif} = \text{Quantité Détenue} \times \text{Prix Actuel} $$

*   **Quantité Détenue :** Somme des quantités achetées - Somme des quantités vendues.
*   **Prix Actuel :**
    *   *Actions/ETF :* Dernier prix de clôture (API ou manuel).
    *   *Crowdfunding :* Montant investi initial (le capital ne varie pas sauf défaut).
    *   *Immobilier Physique :* Prix estimé manuel.

---

## 3. Performance (Plus/Moins-Value)

### Plus-Value Latente (Unrealized P&L)
C'est la différence entre la valeur actuelle et le coût d'acquisition moyen pondéré (PRU).

$$ \text{P\&L Latent} = (\text{Prix Actuel} - \text{PRU}) \times \text{Quantité} $$

### PRU (Prix de Revient Unitaire)
Calculé comme la moyenne pondérée des prix d'achat.

$$ \text{PRU} = \frac{\sum (\text{Prix Achat} \times \text{Quantité Achat})}{\sum \text{Quantité Achat}} $$

> Les ventes ne modifient pas le PRU, elles réduisent seulement la quantité détenue.

> **Note :** Les transactions dont la date est future (postérieure à la date actuelle) sont exclues des calculs de quantité, PRU et valeur totale. Elles sont considérées comme "planifiées" mais non réalisées.

---

## 4. Rendement (Yield)

### Rendement Estimé Annuel
Moyenne pondérée des rendements de chaque actif.

$$ \text{Rendement Portefeuille} = \frac{\sum (\text{Valeur Actif} \times \text{Rendement Actif})}{\text{Valeur Totale Portefeuille}} $$

*   *Actions à dividendes :* Rendement du dividende (Dividend Yield).
*   *Crowdfunding :* Taux d'intérêt contractuel.
*   *Livrets :* Taux d'intérêt annuel.

---

## 5. Conversion de Devises

Toutes les valeurs sont converties dans la devise de référence de l'application (ex: EUR) au moment de l'affichage.

$$ \text{Valeur (EUR)} = \text{Valeur (Devise Origine)} \times \text{Taux de Change} $$

*   Si le taux de change échoue (API down), un taux de 1.0 est utilisé par défaut (fallback) pour ne pas bloquer l'application, avec une alerte visuelle.

---

## 6. Cas Spécifiques

### Import Crowdfunding
*   Chaque projet est importé comme une transaction d'**ACHAT**.
*   Le montant de la transaction est **NÉGATIF** (sortie de cash).
*   Le prix de l'actif est fixé à 1€ par unité.
*   La quantité est fixée au montant investi (ex: 1000€ = 1000 unités).
*   **Auto-Dépôt automatique :** Un DÉPÔT compensatoire est créé automatiquement pour chaque date d'investissement afin de neutraliser l'impact sur les liquidités. Cela reflète le fait que l'argent était déjà disponible sur la plateforme avant l'import.
*   **Notes du dépôt :** `"Apport auto - Crowdfunding (mode depuis source)"`

### Import Initial/Actualisation/Supplément de Positions et Achats
*   Lors d'un import de positions existantes (snapshot) ou d'achats via Trade Republic, BoursoBank, etc., les achats sont importés avec montants **NÉGATIFS**.
*   Pour éviter un solde de liquidité fortement négatif, un DÉPÔT compensatoire est créé automatiquement par date d'achat.
*   Cela s'applique à **TOUS les modes** (initial, actualisation, supplément) car l'argent a déjà été prélevé lors de l'investissement réel sur la plateforme d'investissement.
*   **Notes du dépôt :** `"Apport auto - Crowdfunding (Actualisation depuis source)"` ou `"Apport auto - Neutralisation import (Import initial depuis source)"`

### Import PDF/Excel (Banque)
*   Les achats sont convertis en montants **NÉGATIFS**.
*   Les ventes sont converties en montants **POSITIFS**.
*   Les dividendes et intérêts sont **POSITIFS**.
*   Les retraits sont **NÉGATIFS**.
