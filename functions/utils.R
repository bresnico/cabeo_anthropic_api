# Fonctions utilitaires

# Vérification de la configuration et des dossiers
check_setup <- function() {
  
  # Vérification de la clé API
  if(is.null(config$anthropic$api_key) || config$anthropic$api_key == "your-anthropic-api-key-here") {
    cat("❌ Clé API Anthropic manquante dans config.yml\n")
    return(FALSE)
  }
  
  # Vérification des dossiers requis
  required_dirs <- c(config$folders$pdf_input, config$folders$logs)
  
  for(dir_path in required_dirs) {
    if(!dir.exists(dir_path)) {
      cat(sprintf("📁 Création du dossier: %s\n", dir_path))
      dir.create(dir_path, recursive = TRUE)
    }
  }
  
  # Création du dossier de résultats s'il n'existe pas
  if(!dir.exists(config$folders$results_output)) {
    dir.create(config$folders$results_output, recursive = TRUE)
  }
  
  return(TRUE)
}

# Récupération des fichiers PDF
get_pdf_files <- function() {
  
  pdf_pattern <- "\\.(pdf|PDF)$"
  pdf_files <- list.files(config$folders$pdf_input, 
                          pattern = pdf_pattern, 
                          full.names = TRUE)
  
  return(pdf_files)
}

# Configuration du système de logs
setup_logging <- function() {
  
  log_dir <- config$folders$logs
  if(!dir.exists(log_dir)) {
    dir.create(log_dir, recursive = TRUE)
  }
  
  # Initialisation du fichier de log avec timestamp
  log_file <- file.path(log_dir, config$output$log_file)
  
  # En-tête du log
  header <- paste(
    "=== AMSTAR2 Screening Log ===",
    paste("Démarrage:", Sys.time()),
    paste("Nombre de PDFs:", length(get_pdf_files())),
    "================================",
    sep = "\n"
  )
  
  writeLines(header, log_file)
}

# Fonction de logging
log_message <- function(message, level = "INFO") {
  
  log_file <- file.path(config$folders$logs, config$output$log_file)
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] %s: %s", timestamp, level, message)
  
  # Écriture dans le fichier (en mode append)
  write(log_entry, file = log_file, append = TRUE)
  
  # Affichage dans la console pour les erreurs et warnings
  if(level %in% c("ERROR", "WARNING")) {
    cat(sprintf("⚠️  %s\n", message))
  }
}

# Fonction pour nettoyer les anciens logs (optionnel)
cleanup_old_logs <- function(days_to_keep = 30) {
  
  log_dir <- config$folders$logs
  if(!dir.exists(log_dir)) return()
  
  log_files <- list.files(log_dir, pattern = "\\.txt$", full.names = TRUE)
  cutoff_date <- Sys.Date() - days_to_keep
  
  for(log_file in log_files) {
    file_date <- as.Date(file.info(log_file)$mtime)
    if(file_date < cutoff_date) {
      file.remove(log_file)
      cat(sprintf("🗑️  Ancien log supprimé: %s\n", basename(log_file)))
    }
  }
}

# Fonction pour valider la structure des dossiers du projet
validate_project_structure <- function() {
  
  required_structure <- list(
    "config.yml" = "file",
    "amstar_screening.R" = "file", 
    "data/" = "directory",
    "logs/" = "directory",
    "functions/" = "directory",
    "functions/claude_api.R" = "file",
    "functions/amstar_evaluation.R" = "file",
    "functions/data_processing.R" = "file",
    "functions/utils.R" = "file"
  )
  
  missing_items <- c()
  
  for(item_name in names(required_structure)) {
    item_type <- required_structure[[item_name]]
    
    if(item_type == "file" && !file.exists(item_name)) {
      missing_items <- c(missing_items, paste("Fichier:", item_name))
    } else if(item_type == "directory" && !dir.exists(item_name)) {
      missing_items <- c(missing_items, paste("Dossier:", item_name))
    }
  }
  
  if(length(missing_items) > 0) {
    cat("❌ Éléments manquants:\n")
    for(item in missing_items) {
      cat(sprintf("   - %s\n", item))
    }
    return(FALSE)
  }
  
  cat("✅ Structure du projet validée\n")
  return(TRUE)
}

# Fonction pour afficher un résumé des résultats
print_summary <- function(resultats_principaux) {
  
  if(nrow(resultats_principaux) == 0) {
    cat("Aucun résultat à afficher.\n")
    return()
  }
  
  cat("\n📊 RÉSUMÉ DES RÉSULTATS\n")
  cat("=" %>% rep(30) %>% paste(collapse = ""), "\n")
  
  # Statistiques par évaluation globale
  eval_stats <- table(resultats_principaux$`Évaluation globale`)
  cat("Évaluations globales:\n")
  for(eval in names(eval_stats)) {
    cat(sprintf("  - %s: %d articles\n", eval, eval_stats[eval]))
  }
  
  # Statistiques par recommandation
  rec_stats <- table(resultats_principaux$Recommandation)
  cat("\nRecommandations:\n")
  for(rec in names(rec_stats)) {
    cat(sprintf("  - %s: %d articles\n", rec, rec_stats[rec]))
  }
  
  # Items critiques les plus problématiques
  faiblesses <- resultats_principaux %>%
    filter(`Faiblesses critiques` != "Aucune") %>%
    pull(`Faiblesses critiques`) %>%
    str_split(", ") %>%
    unlist() %>%
    table() %>%
    sort(decreasing = TRUE)
  
  if(length(faiblesses) > 0) {
    cat("\nItems critiques les plus problématiques:\n")
    for(i in 1:min(5, length(faiblesses))) {
      item <- names(faiblesses)[i]
      count <- faiblesses[i]
      cat(sprintf("  - %s: %d fois\n", item, count))
    }
  }
  
  cat("\n")
}