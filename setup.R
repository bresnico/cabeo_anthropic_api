# Script de configuration initiale pour AMSTAR2 Screening

cat("🔧 Configuration initiale du projet AMSTAR2 Screening\n")
cat("=" %>% rep(50) %>% paste(collapse = ""), "\n")

# Vérification et installation des packages requis (ajout curl et tools pour Files API)
required_packages <- c("pdftools", "httr2", "openxlsx", "dplyr", "yaml", "jsonlite", "stringr", "curl", "tools")

cat("📦 Vérification des packages requis...\n")

for(pkg in required_packages) {
  if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("   Installation de %s...\n", pkg))
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  } else {
    cat(sprintf("   ✅ %s déjà installé\n", pkg))
  }
}

# Création de la structure des dossiers
required_dirs <- c("data", "results", "logs", "functions")

cat("\n📁 Création de la structure des dossiers...\n")

for(dir_name in required_dirs) {
  if(!dir.exists(dir_name)) {
    dir.create(dir_name, recursive = TRUE)
    cat(sprintf("   ✅ Dossier créé: %s/\n", dir_name))
  } else {
    cat(sprintf("   ✅ Dossier existant: %s/\n", dir_name))
  }
}

# Vérification de la configuration
if(file.exists("config.yml")) {
  config <- yaml::read_yaml("config.yml")
  
  if(config$anthropic$api_key == "your-anthropic-api-key-here") {
    cat("\n⚠️  ATTENTION: Vous devez configurer votre clé API Anthropic dans config.yml\n")
    cat("   1. Obtenez votre clé API sur: https://console.anthropic.com/\n")
    cat("   2. Remplacez 'your-anthropic-api-key-here' dans config.yml\n")
  } else {
    cat("\n✅ Clé API configurée dans config.yml\n")
  }
} else {
  cat("\n❌ Fichier config.yml manquant!\n")
}

# Test des fonctions utilitaires si elles existent
if(file.exists("functions/utils.R")) {
  source("functions/utils.R")
  
  cat("\n🧪 Test de la structure du projet...\n")
  if(exists("validate_project_structure")) {
    validate_project_structure()
  }
}

# Création d'un fichier d'exemple pour tester
example_content <- "# Exemple de test
# Placez vos fichiers PDF dans le dossier data/
# Exemple: data/ma_revue_systematique.pdf

# Pour démarrer le screening:
source('amstar_screening.R')
"

writeLines(example_content, "exemple_utilisation.R")

cat("\n🎉 Configuration terminée!\n")
cat("=" %>% rep(30) %>% paste(collapse = ""), "\n")
cat("Prochaines étapes:\n")
cat("1. ✏️  Configurez votre clé API dans config.yml\n")
cat("2. 📄 Placez vos PDFs dans le dossier data/\n")
cat("3. ▶️  Exécutez: source('amstar_screening.R')\n")
cat("\nBon screening! 🔬\n")