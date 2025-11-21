📍 Le nouveau Flux (Workflow)

    Point d'entrée : Un bouton dédié (ex: "Import via IA") distinct de l'ajout manuel classique.

    Étape 1 : Configuration & Sécurité (Nouvel Écran)

        Sélection obligatoire du Compte cible (PEA, CTO, etc.).

        Avertissement légal (Disclaimer) : Message clair sur l'envoi de données à Gemini et recommandation de masquer les PII (noms, IBAN). Bouton "J'accepte et continuer".

    Étape 2 : Capture & Crop (Modifié)

        On réutilise votre ImportTransactionScreen actuel, mais il ne fera que le travail technique (scan/API) et renverra les résultats bruts.

    Étape 3 : Révision en masse (Nouvel Écran AiTransactionReviewScreen)

        Affichage d'une liste déroulante des transactions détectées.

        Chaque ligne/carte est éditable (Date, Ticker, Prix, Quantité, Frais).

        Pré-remplissage avec les données de l'IA (TransactionExtractionResult).

        Bouton "Valider tout" qui effectue les vérifications métiers (ISIN, cohérence) à la fin.