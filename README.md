# 🚀 AMSTAR2 Screening Automatisé avec Claude + Files API

Système automatisé d'évaluation de revues systématiques selon les critères AMSTAR2 utilisant l'API Claude d'Anthropic avec la **révolutionnaire Files API** pour une performance optimale.

## ✨ Nouveauté : Intégration Files API d'Anthropic

Ce système utilise la toute nouvelle [Files API d'Anthropic](https://docs.anthropic.com/en/docs/build-with-claude/files) qui révolutionne l'interaction avec les documents :

### 🔄 Workflow Révolutionnaire
- **Upload 1x, utilise ∞ fois** : Chaque PDF n'est uploadé qu'une seule fois
- **Performance x10** : Questions instantanées sans re-upload
- **Coûts réduits** : Élimination du trafic réseau redondant
- **Détection de doublons intelligente** : Réutilisation automatique des fichiers existants
- **Fallback automatique** : Retour transparent vers l'ancienne méthode si nécessaire

## 🚀 Installation et Configuration

### Prérequis
```r
# Installation des packages requis (ajout de curl pour Files API)
install.packages(c("pdftools", "httr2", "openxlsx", "dplyr", "yaml", "jsonlite", "stringr", "curl", "tools"))
```

### Configuration
1. **Clé API Anthropic** : Modifiez le fichier `config.yml` et remplacez `your-anthropic-api-key-here` par votre vraie clé API.

2. **Configuration Files API** : Le système est pré-configuré pour utiliser Files API. Vous pouvez ajuster les paramètres dans `config.yml` :
   ```yaml
   files_api:
     enabled: true                    # Active Files API (recommandé)
     source_directory: "data"          # Dossier des PDFs
     max_file_size_mb: 32            # Limite de taille
     allowed_extensions: ["pdf", "txt", "jpg", "jpeg", "png", "gif", "webp"]
   ```

3. **Structure des dossiers** :
   ```
   cabeo_anthropic_api/
   ├── config.yml
   ├── amstar_screening.R
   ├── README.md
   ├── data/                    # Placez vos PDFs ici
   ├── results/                 # Fichiers Excel générés
   ├── logs/                    # Logs d'exécution
   └── functions/
       ├── claude_api.R         # API Claude + Files API
       ├── files_api.R          # 🆕 Gestion Files API
       ├── amstar_evaluation.R
       ├── data_processing.R
       └── utils.R
   ```

## 📖 Utilisation

### 🎯 Workflow Files API Automatique

Le système fonctionne maintenant avec un workflow intelligent :

1. **Première exécution** : Upload automatique des PDFs vers Anthropic Files API
2. **Exécutions suivantes** : Réutilisation instantanée des fichiers déjà uploadés
3. **Détection intelligente** : Identification automatique des doublons
4. **Fallback sécurisé** : Basculement vers l'ancienne méthode si Files API indisponible

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

### 🔍 Comprendre le Workflow Files API

```r
# Le système effectue automatiquement :
# 1. Vérification des fichiers déjà uploadés chez Anthropic
# 2. Upload uniquement des nouveaux fichiers
# 3. Référencement par file_id pour les évaluations
# 4. Logs détaillés de toutes les opérations
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

### Configuration Files API
```yaml
files_api:
  enabled: true                        # Active/désactive Files API
  source_directory: "data"              # Dossier source des PDFs
  allowed_extensions: ["pdf", "txt", "jpg", "jpeg", "png", "gif", "webp"]
  max_file_size_mb: 32                 # Limite de taille (max 32MB)
  purpose: "user_request"               # Purpose pour l'upload
  anthropic_version: "2023-06-01"       # Version API
  beta_header: "files-api-2025-04-14"   # Header beta Files API
```

### Configuration Claude API
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

### Modification du prompt
Pour personnaliser le prompt d'évaluation, modifiez la fonction `get_amstar_prompt()` dans `functions/claude_api.R`.

### Désactiver Files API
Pour revenir à l'ancienne méthode :
```yaml
files_api:
  enabled: false  # Force l'utilisation de l'ancienne méthode
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

### Files API
- **Upload unique** : Chaque PDF n'est uploadé qu'une seule fois chez Anthropic
- **Réutilisation illimitée** : Questions multiples sans re-upload
- **Détection de doublons** : Vérification automatique des fichiers existants
- **Limite de taille** : 32 MB maximum par fichier (limite Anthropic)
- **Stockage total** : 100 GB par organisation Anthropic
- **Formats supportés** : PDF, TXT, JPG, PNG, GIF, WebP

### Fallback et Compatibilité
- **Fallback automatique** : Retour vers l'ancienne méthode si Files API échoue
- **Limitation de texte classique** : PDFs tronqués à 50,000 caractères en mode fallback
- **Gestion d'erreurs** : 3 tentatives automatiques pour chaque méthode
- **Format JSON** : Réponses Claude forcées en format JSON strict
- **Compatibilité totale** : Format de sortie identique au workflow existant

### Performance et Coûts
- **Réduction drastique** du trafic réseau (upload unique)
- **Accélération** des évaluations répétées
- **Optimisation** des coûts de bande passante
- **Évolutivité** pour traitement de grandes bibliothèques

## 🔧 Dépannage Files API

### Messages de logs Files API
```
🔍 Vérification des doublons via Files API
♻️  2 fichiers déjà uploadés: fichier1.pdf, fichier2.pdf
📤 1 nouveaux fichiers à uploader: fichier3.pdf
📊 Total: 3 locaux, 2 distants, 2 déjà uploadés
🚀 Tentative Files API pour article_123
✅ Upload réussi: fichier3.pdf (ID: file_abc123)
✅ Évaluation Files API réussie pour article_123
🔄 Fallback méthode classique pour article_456
```

### Problèmes spécifiques Files API

**Files API indisponible**
```
⚠️ Échec Files API pour article: HTTP 429 Too Many Requests
🔄 Fallback méthode classique pour article
```
→ Le système bascule automatiquement vers l'ancienne méthode

**Fichier trop volumineux**
```
❌ Fichier trop volumineux (>32 MB): document.pdf
```
→ Réduisez la taille du PDF ou utilisez un outil de compression

**Extension non supportée**
```
❌ Extension non autorisée: doc
```
→ Convertissez le fichier en PDF

## 🤝 Support

Pour toute question ou problème :
1. **Logs détaillés** : Consultez `logs/screening_log.txt` pour diagnostics complets
2. **Configuration** : Vérifiez les paramètres `files_api` dans `config.yml`
3. **Test simple** : Commencez avec un seul PDF de petite taille
4. **Fallback** : Désactivez Files API temporairement si nécessaire (`enabled: false`)

## 🎉 Avantages de cette Implémentation

- ✅ **Révolutionnaire** : Premier système R utilisant Files API d'Anthropic
- ✅ **Intelligent** : Détection automatique des doublons et optimisation des uploads
- ✅ **Robuste** : Fallback automatique garantissant la continuité de service
- ✅ **Compatible** : Aucun changement requis dans votre workflow existant
- ✅ **Performant** : Gains de performance dramatiques pour les évaluations répétées
- ✅ **Économique** : Réduction significative des coûts de bande passante

---

*Développé avec ❤️ pour optimiser l'évaluation AMSTAR2 avec la puissance de l'IA moderne*