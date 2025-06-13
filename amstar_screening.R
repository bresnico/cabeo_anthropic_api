# AMSTAR2 Screening avec Claude API
# Script principal pour l'évaluation automatisée de revues systématiques

# Packages requis
library(pdftools)
library(httr2)
library(openxlsx)
library(dplyr)
library(yaml)
library(jsonlite)
library(stringr)

# Chargement de la configuration
config <- yaml::read_yaml("config.yml")

# Source des fonctions utilitaires
source("functions/claude_api.R")
source("functions/files_api.R")
source("functions/amstar_evaluation.R")
source("functions/data_processing.R")
source("functions/utils.R")

# Fonction principale
amstar_screening <- function() {
  
  cat("🔬 Démarrage du screening AMSTAR2 avec Claude\n")
  cat("=" %>% rep(50) %>% paste(collapse = ""), "\n")
  
  # Vérification de la configuration
  if(!check_setup()) {
    stop("❌ Problème de configuration. Vérifiez config.yml et les dossiers.")
  }
  
  # Initialisation des logs
  setup_logging()
  log_message("Démarrage du screening AMSTAR2")
  
  # Récupération des PDFs
  pdf_files <- get_pdf_files()
  if(length(pdf_files) == 0) {
    stop("❌ Aucun fichier PDF trouvé dans le dossier data/")
  }
  
  cat(sprintf("📁 %d fichiers PDF trouvés\n", length(pdf_files)))
  log_message(sprintf("%d fichiers PDF à traiter", length(pdf_files)))
  
  # Préparation des tibbles de résultats
  resultats_principaux <- init_main_tibble()
  justifications <- init_justifications_tibble()
  
  # Boucle de traitement article par article
  for(i in seq_along(pdf_files)) {
    
    pdf_file <- pdf_files[i]
    article_id <- tools::file_path_sans_ext(basename(pdf_file))
    
    cat(sprintf("\n📖 Traitement [%d/%d]: %s\n", i, length(pdf_files), article_id))
    
    tryCatch({
      
      # Évaluation AMSTAR2 avec Claude (Files API + fallback automatique)
      cat("   Évaluation AMSTAR2 avec Claude...")
      evaluation <- evaluate_with_claude(pdf_file, article_id, batch_index = i, total_files = length(pdf_files))
      cat(" ✅\n")
      
      # Traitement des résultats
      cat("   Traitement des résultats...")
      main_row <- process_main_results(evaluation)
      justif_rows <- process_justifications(evaluation)
      
      # Ajout aux tibbles
      resultats_principaux <- bind_rows(resultats_principaux, main_row)
      justifications <- bind_rows(justifications, justif_rows)
      cat(" ✅\n")
      
      log_message(sprintf("Succès: %s - Évaluation: %s", article_id, evaluation$evaluation_globale))
      
    }, error = function(e) {
      cat(" ❌\n")
      error_msg <- sprintf("Erreur pour %s: %s", article_id, e$message)
      cat(sprintf("   %s\n", error_msg))
      log_message(error_msg, level = "ERROR")
    })
  }
  
  # Export des résultats
  cat("\n💾 Export des résultats...\n")
  export_results(resultats_principaux, justifications)
  
  # Rapport final
  cat("\n🎉 Screening terminé!\n")
  cat(sprintf("📊 %d articles traités avec succès\n", nrow(resultats_principaux)))
  cat(sprintf("📁 Résultats dans: %s/\n", config$folders$results_output))
  
  log_message("Screening terminé avec succès")
  
  return(list(
    resultats = resultats_principaux,
    justifications = justifications
  ))
}

# Exécution du script principal
if(!interactive()) {
  amstar_screening()
}