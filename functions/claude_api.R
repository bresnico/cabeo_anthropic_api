# Fonctions pour l'interaction avec l'API Claude d'Anthropic

# Prompt AMSTAR2 optimisé
get_amstar_prompt <- function() {
  return("Tu es un expert en méthodologie de recherche spécialisé dans l'évaluation de revues systématiques selon les critères AMSTAR2.

Évalue cette revue systématique selon les 16 critères AMSTAR2. Pour chaque item, attribue un score (Oui/Partiellement/Non/N/A) et fournis une justification CONCISE (maximum 20 mots).

CRITÈRES AMSTAR2 À ÉVALUER :

CRITÈRES CRITIQUES (impact majeur sur la validité) :
- Item 2 : Protocole enregistré avant le début (PROSPERO, etc.)
- Item 4 : Stratégie de recherche comprehensive (≥2 bases, termes appropriés)
- Item 7 : Liste des études exclues avec justifications
- Item 9 : Évaluation du risque de biais des études individuelles
- Item 11 : Méthodes statistiques appropriées pour la méta-analyse
- Item 13 : Prise en compte du risque de biais dans l'interprétation
- Item 15 : Investigation du biais de publication

CRITÈRES NON-CRITIQUES :
- Item 1 : Composantes PICO dans la question de recherche
- Item 3 : Justification des types d'études incluses
- Item 5 : Sélection des études en duplicate
- Item 6 : Extraction des données en duplicate
- Item 8 : Description adéquate des études incluses
- Item 10 : Sources de financement rapportées
- Item 12 : Impact du risque de biais sur les résultats
- Item 14 : Explication de l'hétérogénéité
- Item 16 : Déclaration des conflits d'intérêts

RÈGLES D'ÉVALUATION GLOBALE :
- Haute : Aucune faiblesse critique
- Modérée : 1 faiblesse critique
- Faible : 2+ faiblesses critiques  
- Très faible : 2+ faiblesses critiques avec faiblesses non-critiques multiples

Réponds UNIQUEMENT avec le JSON suivant (utilise l'ARTICLE_ID fourni ci-dessus) :
{
  \"article_id\": \"UTILISE_L_ARTICLE_ID_FOURNI\",
  \"amstar2_evaluation\": {
    \"item_1_pico_components\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_2_protocol_registration\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_3_study_design_explanation\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_4_comprehensive_search\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_5_duplicate_selection\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_6_duplicate_extraction\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_7_excluded_studies_list\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_8_study_characteristics\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_9_risk_of_bias_assessment\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_10_funding_sources\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_11_meta_analysis_methods\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_12_risk_of_bias_impact\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_13_risk_of_bias_discussion\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_14_heterogeneity_discussion\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_15_publication_bias\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"},
    \"item_16_conflicts_of_interest\": {\"score\": \"Oui|Partiellement|Non|N/A\", \"justification\": \"justification courte\"}
  },
  \"faiblesses_critiques\": [\"Item 2\", \"Item 4\"],
  \"evaluation_globale\": \"Haute|Modérée|Faible|Très faible\",
  \"recommandation\": \"Inclusion|Exclusion\"
}")
}

# Appel à l'API Claude avec gestion d'erreurs et retry
call_claude_api <- function(text_content, article_id, max_retries = 3) {
  
  prompt <- get_amstar_prompt()
  full_prompt <- paste(prompt, "\n\nARTICLE_ID: ", article_id, "\n\nTEXTE DE LA REVUE SYSTÉMATIQUE :\n", text_content)
  
  # Préparation de la requête
  request_body <- list(
    model = config$anthropic$model,
    max_tokens = config$anthropic$max_tokens,
    messages = list(
      list(role = "user", content = full_prompt)
    )
  )
  
  # Tentatives avec retry
  for(attempt in 1:max_retries) {
    
    tryCatch({
      
      # Appel API
      response <- request("https://api.anthropic.com/v1/messages") %>%
        req_headers(
          "x-api-key" = config$anthropic$api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ) %>%
        req_body_json(request_body) %>%
        req_timeout(config$anthropic$timeout) %>%
        req_perform()
      
      # Extraction du contenu
      response_data <- response %>% resp_body_json()
      content <- response_data$content[[1]]$text
      
      # Nettoyage pour extraire le JSON
      clean_json <- extract_json_from_response(content)
      
      # Validation JSON
      result <- fromJSON(clean_json, flatten = FALSE)
      
      return(result)
      
    }, error = function(e) {
      
      if(attempt == max_retries) {
        stop(sprintf("Échec après %d tentatives: %s", max_retries, e$message))
      }
      
      log_message(sprintf("Tentative %d échouée pour %s: %s", attempt, article_id, e$message), level = "WARNING")
      Sys.sleep(config$screening$retry_delay)
    })
  }
}

# Validation et nettoyage du JSON de réponse
validate_claude_response <- function(json_response) {
  
  required_fields <- c("article_id", "amstar2_evaluation", "faiblesses_critiques", 
                       "evaluation_globale", "recommandation")
  
  # Vérification des champs obligatoires
  missing_fields <- setdiff(required_fields, names(json_response))
  if(length(missing_fields) > 0) {
    stop(sprintf("Champs manquants dans la réponse: %s", paste(missing_fields, collapse = ", ")))
  }
  
  # Validation des items AMSTAR2
  amstar_items <- json_response$amstar2_evaluation
  expected_items <- paste0("item_", 1:16, c("_pico_components", "_protocol_registration", 
                                            "_study_design_explanation", "_comprehensive_search",
                                            "_duplicate_selection", "_duplicate_extraction",
                                            "_excluded_studies_list", "_study_characteristics",
                                            "_risk_of_bias_assessment", "_funding_sources",
                                            "_meta_analysis_methods", "_risk_of_bias_impact",
                                            "_risk_of_bias_discussion", "_heterogeneity_discussion",
                                            "_publication_bias", "_conflicts_of_interest"))
  
  # Validation des scores
  valid_scores <- c("Oui", "Partiellement", "Non", "N/A")
  
  for(item_name in names(amstar_items)) {
    item <- amstar_items[[item_name]]
    if(!item$score %in% valid_scores) {
      log_message(sprintf("Score invalide pour %s: %s", item_name, item$score), level = "WARNING")
    }
  }
  
  return(json_response)
}

# Fonction pour extraire le JSON d'une réponse de Claude
extract_json_from_response <- function(response_text) {
  
  # Chercher le premier '{' et le dernier '}'
  first_brace <- regexpr("\\{", response_text)
  last_brace <- max(gregexpr("\\}", response_text)[[1]])
  
  if(first_brace == -1 || last_brace == -1) {
    stop("Aucun JSON trouvé dans la réponse")
  }
  
  # Extraire le JSON
  json_text <- substr(response_text, first_brace, last_brace)
  
  return(json_text)
}