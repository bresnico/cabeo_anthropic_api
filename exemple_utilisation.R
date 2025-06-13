# 🚀 Exemple d'utilisation AMSTAR2 + Files API
# 
# Étapes simples :
# 1. Placez vos fichiers PDF dans le dossier data/
#    Exemple: data/ma_revue_systematique.pdf
# 
# 2. Vérifiez votre configuration Files API dans config.yml
#    files_api:
#      enabled: true  # Files API activée (recommandé)
# 
# 3. Démarrez le screening:
source('amstar_screening.R')

# ✨ Le système utilisera automatiquement Files API :
# - Upload 1x chaque PDF vers Anthropic
# - Réutilisation instantanée pour futures évaluations
# - Fallback automatique vers ancienne méthode si nécessaire
# 
# 📊 Consultez les logs détaillés dans logs/screening_log.txt

