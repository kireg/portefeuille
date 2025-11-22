Voici le fichier CSV transformé et prêt à être importé. J'ai identifié qu'il s'agissait de données "La Première Brique", j'ai donc rempli la colonne Plateforme en conséquence.

Pour répondre à votre demande de "prompt" (le script logique) qui explique comment cette transformation a été réalisée, voici le code Python complet que j'ai utilisé.

Logique appliquée :

    Calcul de la durée : Différence en mois entre la Date de signature et la Date de remboursement maximale.

    Type de remboursement : Déduit en croisant le fichier "Mes prêts" avec "Mes échéances" :

        Amortizing : Si du capital est remboursé sur plusieurs échéances.

        MonthlyInterest : Si des intérêts sont versés régulièrement mais le capital à la fin.

        InFine : Si tout (capital + intérêts) est payé à la fin (défaut).

Python

import pandas as pd
import numpy as np
from datetime import datetime

# 1. Chargement des fichiers (Attention aux lignes d'en-tête)
# "Mes prêts" a l'en-tête à la ligne 2 (index 1)
df_prets = pd.read_csv("Donnees tests.xlsx - Mes prêts.csv", header=1)
# "Mes échéances" a l'en-tête à la ligne 1 (index 0)
df_echeances = pd.read_csv("Donnees tests.xlsx - Mes échéances.csv", header=0)

# 2. Initialisation de la structure de sortie
output_columns = [
    "Nom du Projet", "Plateforme", "Date Investissement", "Montant Investi", 
    "Taux Rendement", "Durée (Mois)", "Type Remboursement", 
    "Ville", "Pays", "Note Risque"
]
data = []

# 3. Traitement ligne par ligne
for index, row in df_prets.iterrows():
    project_name = row['Nom du projet']
    if pd.isna(project_name): continue
        
    # Gestion des dates
    start_date = pd.to_datetime(row['Date de signature (JJ/MM/AAAA)'], dayfirst=True)
    end_date_max = pd.to_datetime(row['Date de remboursement maximale (JJ/MM/AAAA)'], dayfirst=True)
    
    # Calcul Durée (Mois)
    months = 0
    if pd.notna(start_date) and pd.notna(end_date_max):
        months = round((end_date_max - start_date).days / 30.437)
        
    # Déduction du Type de Remboursement via le fichier Echéances
    proj_sched = df_echeances[df_echeances['Projet'] == project_name]
    reimbursement_type = "InFine" # Valeur par défaut
    
    if not proj_sched.empty:
        rows_with_interest = (proj_sched['Part des intérêts'] > 0).sum()
        rows_with_capital = (proj_sched['Part du capital'] > 0).sum()
        
        if rows_with_capital > 1: 
            reimbursement_type = "Amortizing"
        elif rows_with_interest > 1:
            reimbursement_type = "MonthlyInterest"
            
    # Ajout à la liste
    data.append({
        "Nom du Projet": project_name,
        "Plateforme": "La Première Brique",
        "Date Investissement": start_date.strftime('%d/%m/%Y') if pd.notna(start_date) else "",
        "Montant Investi": row['Montant investi (€)'],
        "Taux Rendement": row['Taux annuel total (%)'],
        "Durée (Mois)": int(months),
        "Type Remboursement": reimbursement_type,
        "Ville": "", # Non disponible dans la source
        "Pays": "France",
        "Note Risque": "" # Non disponible dans la source
    })

# 4. Création du CSV final
df_final = pd.DataFrame(data, columns=output_columns)
df_final.to_csv("import_immocrowd.csv", index=False)
