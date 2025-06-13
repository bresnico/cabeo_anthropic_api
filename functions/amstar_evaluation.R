# Fonctions pour l'évaluation AMSTAR2

# Fonction principale d'évaluation avec Claude (Files API + fallback)
evaluate_with_claude <- function(pdf_path, article_id, batch_index = 1, total_files = 1) {
  
  # Tenter d'abord avec Files API si activée
  if(config$files_api$enabled) {
    
    log_message(sprintf("🚀 Tentative Files API pour %s", article_id), level = "INFO")
    
    tryCatch({
      # Calcul du délai pour batch processing (rate limiting protection)
      batch_delay <- 0
      if(total_files > 5) {
        # Pour plus de 5 fichiers, introduire des délais progressifs
        batch_delay <- min(batch_index * 2, 10)  # Max 10 secondes entre fichiers
        log_message(sprintf("📊 Batch %d/%d - Délai anti-rate-limit: %ds", 
                           batch_index, total_files, batch_delay), level = "INFO")
      }
      
      # Étape 1: Obtenir ou uploader le fichier
      file_info <- get_or_upload_file(pdf_path, batch_delay)
      
      if(!is.null(file_info)) {
        # Étape 2: Déterminer le type de contenu
        content_type <- get_content_type(pdf_path)
        
        # Étape 3: Appel à Claude avec file_id
        result <- call_claude_api_with_file(file_info$id, article_id, content_type, 
                                          max_retries = config$screening$retry_attempts)
        
        # Validation de la réponse
        validated_result <- validate_claude_response(result)
        
        log_message(sprintf("✅ Évaluation Files API réussie pour %s", article_id), level = "INFO")
        return(validated_result)
      }
    }, error = function(e) {
      log_message(sprintf("⚠️ Échec Files API pour %s: %s", article_id, e$message), level = "WARNING")
    })
  }
  
  # Fallback vers méthode classique
  log_message(sprintf("🔄 Fallback méthode classique pour %s", article_id), level = "INFO")
  
  # Extraction du texte PDF
  pdf_text <- extract_pdf_text(pdf_path)
  
  # Limitation de la longueur du texte pour éviter les timeouts
  max_chars <- 50000
  if(nchar(pdf_text) > max_chars) {
    pdf_text <- substr(pdf_text, 1, max_chars)
    log_message(sprintf("Texte tronqué pour %s (%d caractères)", article_id, max_chars), level = "WARNING")
  }
  
  # Appel à Claude avec méthode classique
  result <- call_claude_api(pdf_text, article_id, max_retries = config$screening$retry_attempts)
  
  # Validation de la réponse
  validated_result <- validate_claude_response(result)
  
  log_message(sprintf("✅ Évaluation classique réussie pour %s", article_id), level = "INFO")
  return(validated_result)
}

# Extraction du texte PDF avec nettoyage
extract_pdf_text <- function(pdf_path) {
  
  # Lecture du PDF
  text_pages <- pdf_text(pdf_path)
  
  # Concaténation et nettoyage
  full_text <- paste(text_pages, collapse = "\n")
  
  # Nettoyage basique
  full_text <- str_replace_all(full_text, "\\s+", " ")  # Normalisation des espaces
  full_text <- str_replace_all(full_text, "[\r\n]+", "\n")  # Normalisation des retours à la ligne
  full_text <- str_trim(full_text)
  
  if(nchar(full_text) < 100) {
    stop("Texte extrait trop court (possiblement un PDF protégé ou corrompu)")
  }
  
  return(full_text)
}

# Initialisation du tibble principal (format CSV existant)
init_main_tibble <- function() {
  return(tibble(
    Revue = character(),
    `Item 1` = character(),
    `Item 2` = character(),
    `Item 3` = character(),
    `Item 4` = character(),
    `Item 5` = character(),
    `Item 6` = character(),
    `Item 7` = character(),
    `Item 8` = character(),
    `Item 9` = character(),
    `Item 10` = character(),
    `Item 11` = character(),
    `Item 12` = character(),
    `Item 13` = character(),
    `Item 14` = character(),
    `Item 15` = character(),
    `Item 16` = character(),
    `Faiblesses critiques` = character(),
    `Évaluation globale` = character(),
    Recommandation = character()
  ))
}

# Initialisation du tibble des justifications
init_justifications_tibble <- function() {
  return(tibble(
    Revue = character(),
    Item = character(),
    Item_Name = character(),
    Score = character(),
    Justification = character(),
    Type_Critere = character()
  ))
}

# Mapping des noms d'items vers les numéros
get_item_mapping <- function() {
  return(list(
    "item_1_pico_components" = list(num = "Item 1", name = "PICO components", critical = FALSE),
    "item_2_protocol_registration" = list(num = "Item 2", name = "Protocol registration", critical = TRUE),
    "item_3_study_design_explanation" = list(num = "Item 3", name = "Study design explanation", critical = FALSE),
    "item_4_comprehensive_search" = list(num = "Item 4", name = "Comprehensive search", critical = TRUE),
    "item_5_duplicate_selection" = list(num = "Item 5", name = "Duplicate selection", critical = FALSE),
    "item_6_duplicate_extraction" = list(num = "Item 6", name = "Duplicate extraction", critical = FALSE),
    "item_7_excluded_studies_list" = list(num = "Item 7", name = "Excluded studies list", critical = TRUE),
    "item_8_study_characteristics" = list(num = "Item 8", name = "Study characteristics", critical = FALSE),
    "item_9_risk_of_bias_assessment" = list(num = "Item 9", name = "Risk of bias assessment", critical = TRUE),
    "item_10_funding_sources" = list(num = "Item 10", name = "Funding sources", critical = FALSE),
    "item_11_meta_analysis_methods" = list(num = "Item 11", name = "Meta-analysis methods", critical = TRUE),
    "item_12_risk_of_bias_impact" = list(num = "Item 12", name = "Risk of bias impact", critical = FALSE),
    "item_13_risk_of_bias_discussion" = list(num = "Item 13", name = "Risk of bias discussion", critical = TRUE),
    "item_14_heterogeneity_discussion" = list(num = "Item 14", name = "Heterogeneity discussion", critical = FALSE),
    "item_15_publication_bias" = list(num = "Item 15", name = "Publication bias", critical = TRUE),
    "item_16_conflicts_of_interest" = list(num = "Item 16", name = "Conflicts of interest", critical = FALSE)
  ))
}