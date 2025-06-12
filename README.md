# AMSTAR2 Screening Automatisé avec Claude

Système automatisé d'évaluation de revues systématiques selon les critères AMSTAR2 utilisant l'API Claude d'Anthropic.

## 🚀 Installation et Configuration

### Prérequis
```r
# Installation des packages requis
install.packages(c("pdftools", "httr2", "openxlsx", "dplyr", "yaml", "jsonlite", "stringr"))
```

### Configuration
1. **Clé API Anthropic** : Modifiez le fichier `config.yml` et remplacez `your-anthropic-api-key-here` par votre vraie clé API.

2. **Structure des dossiers** :
   ```
   /Users/bresnico/Projets/cabeo_anthropic_api/
   ├── config.yml
   ├── amstar_screening.R
   ├── README.md
   ├── data/                    # Placez vos PDFs ici
   ├── results/                 # Fichiers Excel générés
   ├── logs/                    # Logs d'exécution
   └── functions/
       ├── claude_api.R
       ├── amstar_evaluation.R
       ├── data_processing.R
       └── utils.R
   ```

## 📖 Utilisation

### Méthode simple
1. Placez vos fichiers PDF de revues systématiques dans le dossier `data/`
2. Exécutez le script principal :
   ```r
   source("amstar_screening.R")
   ```

### Exécution depuis R
```r
# Chargement et exécution
source("amstar_screening.R")
resultats <- amstar_screening()

# Accès aux résultats
print(resultats$resultats)        # Tableau principal
print(resultats$justifications)   # Justifications détaillées
```

## 📊 Outputs

### Fichiers générés
- **`resultats_amstar2.xlsx`** : Tableau principal compatible avec votre format CSV existant
- **`justifications_detaillees.xlsx`** : Justifications détaillées pour chaque critère
- **`screening_log.txt`** : Journal des opérations et erreurs

### Format du tableau principal
| Colonne | Description |
|---------|-------------|
| Revue | Nom du fichier PDF |
| Item 1-16 | Scores AMSTAR2 (Oui/Partiellement/Non/N/A) |
| Faiblesses critiques | Liste des items critiques défaillants |
| Évaluation globale | Haute/Modérée/Faible/Très faible |
| Recommandation | Inclusion 1/Exclusion |

## ⚙️ Configuration Avancée

### Modification du prompt
Pour personnaliser le prompt d'évaluation, modifiez la fonction `get_amstar_prompt()` dans `functions/claude_api.R`.

### Paramètres dans config.yml
```yaml
anthropic:
  model: "claude-3-5-sonnet-20241022"  # Modèle Claude à utiliser
  max_tokens: 4000                     # Limite de tokens
  timeout: 60                          # Timeout en secondes

screening:
  retry_attempts: 3                    # Nombre de tentatives en cas d'erreur
  retry_delay: 2                       # Délai entre tentatives
  export_justifications: true          # Export du fichier de justifications
```

## 🔬 Critères AMSTAR2 Évalués

### Critères Critiques (7 items)
- **Item 2** : Protocole enregistré avant le début
- **Item 4** : Stratégie de recherche comprehensive
- **Item 7** : Liste des études exclues avec justifications
- **Item 9** : Évaluation du risque de biais
- **Item 11** : Méthodes statistiques appropriées
- **Item 13** : Prise en compte du risque de biais
- **Item 15** : Investigation du biais de publication

### Critères Non-Critiques (9 items)
- **Item 1** : Composantes PICO
- **Item 3** : Justification des types d'études
- **Item 5** : Sélection en duplicate
- **Item 6** : Extraction en duplicate
- **Item 8** : Description des études
- **Item 10** : Sources de financement
- **Item 12** : Impact du risque de biais
- **Item 14** : Explication de l'hétérogénéité
- **Item 16** : Conflits d'intérêts

## 🛠️ Dépannage

### Problèmes courants

**Erreur de clé API**
```
❌ Clé API Anthropic manquante dans config.yml
```
→ Vérifiez que votre clé API est correctement définie dans `config.yml`

**Aucun PDF trouvé**
```
❌ Aucun fichier PDF trouvé dans le dossier data/
```
→ Placez vos fichiers PDF dans le dossier `data/`

**Timeout API**
→ Augmentez la valeur `timeout` dans `config.yml` ou réduisez la taille des PDFs

### Logs
Consultez le fichier `logs/screening_log.txt` pour diagnostiquer les problèmes.

## 📝 Notes Importantes

- **Limitation de texte** : Les PDFs très longs sont automatiquement tronqués à 50,000 caractères
- **Gestion d'erreurs** : Le système fait 3 tentatives automatiques en cas d'échec
- **Format JSON** : Les réponses de Claude sont forcées en format JSON strict
- **Compatibilité** : Le format de sortie est compatible avec votre workflow existant

## 🤝 Support

Pour toute question ou problème :
1. Consultez les logs dans `logs/screening_log.txt`
2. Vérifiez la configuration dans `config.yml`
3. Testez avec un seul PDF simple d'abord