# Fonctions pour le traitement des données et l'export

# Traitement des résultats principaux (format CSV existant)
process_main_results <- function(evaluation) {
  
  item_mapping <- get_item_mapping()
  
  # Création de la ligne de résultats
  main_row <- tibble(
    Revue = evaluation$article_id,
    `Item 1` = evaluation$amstar2_evaluation$item_1_pico_components$score,
    `Item 2` = evaluation$amstar2_evaluation$item_2_protocol_registration$score,
    `Item 3` = evaluation$amstar2_evaluation$item_3_study_design_explanation$score,
    `Item 4` = evaluation$amstar2_evaluation$item_4_comprehensive_search$score,
    `Item 5` = evaluation$amstar2_evaluation$item_5_duplicate_selection$score,
    `Item 6` = evaluation$amstar2_evaluation$item_6_duplicate_extraction$score,
    `Item 7` = evaluation$amstar2_evaluation$item_7_excluded_studies_list$score,
    `Item 8` = evaluation$amstar2_evaluation$item_8_study_characteristics$score,
    `Item 9` = evaluation$amstar2_evaluation$item_9_risk_of_bias_assessment$score,
    `Item 10` = evaluation$amstar2_evaluation$item_10_funding_sources$score,
    `Item 11` = evaluation$amstar2_evaluation$item_11_meta_analysis_methods$score,
    `Item 12` = evaluation$amstar2_evaluation$item_12_risk_of_bias_impact$score,
    `Item 13` = evaluation$amstar2_evaluation$item_13_risk_of_bias_discussion$score,
    `Item 14` = evaluation$amstar2_evaluation$item_14_heterogeneity_discussion$score,
    `Item 15` = evaluation$amstar2_evaluation$item_15_publication_bias$score,
    `Item 16` = evaluation$amstar2_evaluation$item_16_conflicts_of_interest$score,
    `Faiblesses critiques` = ifelse(length(evaluation$faiblesses_critiques) > 0, 
                                    paste(evaluation$faiblesses_critiques, collapse = ", "), 
                                    "Aucune"),
    `Évaluation globale` = evaluation$evaluation_globale,
    Recommandation = evaluation$recommandation
  )
  
  return(main_row)
}

# Traitement des justifications détaillées
process_justifications <- function(evaluation) {
  
  item_mapping <- get_item_mapping()
  justif_rows <- tibble()
  
  # Parcours de tous les items évalués
  for(item_key in names(evaluation$amstar2_evaluation)) {
    
    item_data <- evaluation$amstar2_evaluation[[item_key]]
    mapping_info <- item_mapping[[item_key]]
    
    if(!is.null(mapping_info)) {
      
      justif_row <- tibble(
        Revue = evaluation$article_id,
        Item = mapping_info$num,
        Item_Name = mapping_info$name,
        Score = item_data$score,
        Justification = ifelse(is.null(item_data$justification), "", item_data$justification),
        Type_Critere = ifelse(mapping_info$critical, "Critique", "Non-critique")
      )
      
      justif_rows <- bind_rows(justif_rows, justif_row)
    }
  }
  
  return(justif_rows)
}

# Export des résultats en Excel
export_results <- function(resultats_principaux, justifications) {
  
  # Création du dossier de sortie si nécessaire
  output_dir <- config$folders$results_output
  if(!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Export du fichier principal
  main_file <- file.path(output_dir, config$output$main_results)
  
  wb_main <- createWorkbook()
  addWorksheet(wb_main, "AMSTAR2_Results")
  writeData(wb_main, "AMSTAR2_Results", resultats_principaux)
  
  # Formatage du tableau principal
  addStyle(wb_main, "AMSTAR2_Results", 
           createStyle(textDecoration = "bold", fgFill = "#D9E1F2"), 
           rows = 1, cols = 1:ncol(resultats_principaux))
  
  saveWorkbook(wb_main, main_file, overwrite = TRUE)
  cat(sprintf("   Résultats principaux: %s ✅\n", main_file))
  
  # Export des justifications si activé
  if(config$screening$export_justifications && nrow(justifications) > 0) {
    
    justif_file <- file.path(output_dir, config$output$justifications)
    
    wb_justif <- createWorkbook()
    addWorksheet(wb_justif, "Justifications_Detaillees")
    writeData(wb_justif, "Justifications_Detaillees", justifications)
    
    # Formatage du tableau des justifications
    addStyle(wb_justif, "Justifications_Detaillees", 
             createStyle(textDecoration = "bold", fgFill = "#E2EFDA"), 
             rows = 1, cols = 1:ncol(justifications))
    
    # Auto-ajustement des colonnes
    setColWidths(wb_justif, "Justifications_Detaillees", cols = 1:ncol(justifications), widths = "auto")
    
    saveWorkbook(wb_justif, justif_file, overwrite = TRUE)
    cat(sprintf("   Justifications détaillées: %s ✅\n", justif_file))
  }
}

# Fonction pour calculer des statistiques de résumé
generate_summary_stats <- function(resultats_principaux) {
  
  if(nrow(resultats_principaux) == 0) return(NULL)
  
  stats <- list(
    total_articles = nrow(resultats_principaux),
    evaluations = table(resultats_principaux$`Évaluation globale`),
    recommendations = table(resultats_principaux$Recommandation),
    items_critiques_problematiques = resultats_principaux %>%
      filter(`Faiblesses critiques` != "Aucune") %>%
      pull(`Faiblesses critiques`) %>%
      str_split(", ") %>%
      unlist() %>%
      table()
  )
  
  return(stats)
}