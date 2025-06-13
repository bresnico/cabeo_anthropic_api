# Fonctions pour l'API Files d'Anthropic
# Gestion des uploads et références de fichiers pour AMSTAR2

library(httr2)
library(tools)

# URLs et constantes
BASE_URL <- "https://api.anthropic.com/v1"

# Fonction pour lister les fichiers existants chez Anthropic
list_remote_files <- function() {
  
  if(!config$files_api$enabled) {
    return(NULL)
  }
  
  log_message("🔍 Récupération liste des fichiers distants", level = "INFO")
  
  tryCatch({
    response <- request(paste0(BASE_URL, "/files")) %>%
      req_headers(
        "x-api-key" = config$anthropic$api_key,
        "anthropic-version" = config$files_api$anthropic_version,
        "anthropic-beta" = config$files_api$beta_header
      ) %>%
      req_timeout(config$anthropic$timeout) %>%
      req_perform()
    
    if (resp_status(response) == 200) {
      result <- response %>% resp_body_json()
      files_list <- result$data
      
      log_message(sprintf("✅ %d fichiers trouvés chez Anthropic", length(files_list)), level = "INFO")
      
      if (length(files_list) > 0) {
        for (f in files_list) {
          log_message(sprintf("  - %s (ID: %s)", f$filename, f$id), level = "DEBUG")
        }
      }
      
      return(files_list)
    } else {
      log_message(sprintf("❌ Erreur liste fichiers: %d", resp_status(response)), level = "ERROR")
      return(NULL)
    }
  }, error = function(e) {
    log_message(sprintf("❌ Erreur réseau liste fichiers: %s", e$message), level = "ERROR")
    return(NULL)
  })
}

# Fonction pour vérifier si un fichier existe déjà chez Anthropic
file_exists_remote <- function(filename, files_list = NULL) {
  
  if(!config$files_api$enabled) {
    return(FALSE)
  }
  
  if (is.null(files_list)) {
    files_list <- list_remote_files()
  }
  
  if (is.null(files_list) || length(files_list) == 0) {
    return(FALSE)
  }
  
  # Vérifier si un fichier avec le même nom existe
  existing_names <- sapply(files_list, function(f) f$filename)
  return(filename %in% existing_names)
}

# Fonction pour obtenir les infos d'un fichier existant
get_file_info <- function(filename, files_list = NULL) {
  
  if(!config$files_api$enabled) {
    return(NULL)
  }
  
  if (is.null(files_list)) {
    files_list <- list_remote_files()
  }
  
  if (is.null(files_list) || length(files_list) == 0) {
    return(NULL)
  }
  
  # Trouver le fichier par nom
  for (f in files_list) {
    if (f$filename == filename) {
      return(f)
    }
  }
  
  return(NULL)
}

# Fonction pour déterminer le type MIME
get_mime_type <- function(filepath) {
  ext <- tolower(tools::file_ext(filepath))
  mime_types <- list(
    "pdf" = "application/pdf",
    "txt" = "text/plain",
    "jpg" = "image/jpeg",
    "jpeg" = "image/jpeg",
    "png" = "image/png",
    "gif" = "image/gif",
    "webp" = "image/webp"
  )
  
  return(mime_types[[ext]] %||% "application/octet-stream")
}

# Fonction pour uploader un fichier vers Anthropic Files API
upload_file_to_anthropic <- function(filepath, purpose = NULL) {
  
  if(!config$files_api$enabled) {
    return(NULL)
  }
  
  if (is.null(purpose)) {
    purpose <- config$files_api$purpose
  }
  
  # Vérifications préliminaires
  if (!file.exists(filepath)) {
    log_message(sprintf("❌ Fichier non trouvé: %s", filepath), level = "ERROR")
    return(NULL)
  }
  
  filename <- basename(filepath)
  file_size <- file.info(filepath)$size
  
  # Vérifier la taille du fichier
  max_size <- config$files_api$max_file_size_mb * 1024 * 1024
  if (file_size > max_size) {
    log_message(sprintf("❌ Fichier trop volumineux (>%d MB): %s", config$files_api$max_file_size_mb, filename), level = "ERROR")
    return(NULL)
  }
  
  # Vérifier l'extension
  ext <- tolower(tools::file_ext(filepath))
  if (!ext %in% config$files_api$allowed_extensions) {
    log_message(sprintf("❌ Extension non autorisée: %s", ext), level = "ERROR")
    return(NULL)
  }
  
  log_message(sprintf("📤 Upload de %s (%.1f KB)", filename, file_size/1024), level = "INFO")
  
  tryCatch({
    # Préparer les données du fichier
    file_data <- readBin(filepath, "raw", file.info(filepath)$size)
    
    # Créer le body multipart
    body_data <- list(
      file = curl::form_file(filepath),
      purpose = purpose
    )
    
    # Appel API avec httr2
    response <- request(paste0(BASE_URL, "/files")) %>%
      req_headers(
        "x-api-key" = config$anthropic$api_key,
        "anthropic-version" = config$files_api$anthropic_version,
        "anthropic-beta" = config$files_api$beta_header
      ) %>%
      req_body_multipart(!!!body_data) %>%
      req_timeout(config$anthropic$timeout) %>%
      req_perform()
    
    if (resp_status(response) == 200) {
      file_info <- response %>% resp_body_json()
      log_message(sprintf("✅ Upload réussi: %s (ID: %s)", filename, file_info$id), level = "INFO")
      return(file_info)
    } else {
      error_msg <- sprintf("❌ Erreur upload: %d", resp_status(response))
      log_message(error_msg, level = "ERROR")
      
      # Log détails de l'erreur
      tryCatch({
        error_details <- response %>% resp_body_json()
        log_message(sprintf("Détails erreur: %s", error_details$error$message), level = "ERROR")
      }, error = function(e) {
        log_message(sprintf("Réponse erreur: %s", response %>% resp_body_string()), level = "ERROR")
      })
      
      return(NULL)
    }
  }, error = function(e) {
    log_message(sprintf("❌ Erreur lors de l'upload: %s", e$message), level = "ERROR")
    return(NULL)
  })
}

# Fonction principale pour obtenir un file_id (upload ou réutilisation)
get_or_upload_file <- function(filepath, batch_delay = 0) {
  
  if(!config$files_api$enabled) {
    log_message("Files API désactivée, utilisation de l'ancienne méthode", level = "INFO")
    return(NULL)
  }
  
  # Délai entre fichiers pour éviter rate limiting en batch
  if(batch_delay > 0) {
    log_message(sprintf("⏳ Délai batch: %d secondes", batch_delay), level = "DEBUG")
    Sys.sleep(batch_delay)
  }
  
  filename <- basename(filepath)
  
  # Étape 1: Vérifier si le fichier existe déjà
  log_message(sprintf("🔍 Vérification existence de %s", filename), level = "INFO")
  files_list <- list_remote_files()
  
  if (file_exists_remote(filename, files_list)) {
    # Fichier existe déjà, récupérer ses infos
    file_info <- get_file_info(filename, files_list)
    log_message(sprintf("✨ Fichier existant réutilisé: %s (ID: %s)", filename, file_info$id), level = "INFO")
    return(file_info)
  } else {
    # Fichier n'existe pas, l'uploader
    log_message(sprintf("📁 Fichier non trouvé, upload nécessaire: %s", filename), level = "INFO")
    file_info <- upload_file_to_anthropic(filepath)
    return(file_info)
  }
}

# Fonction pour résoudre le chemin d'un fichier dans le dossier source
resolve_pdf_path <- function(filename) {
  
  # Si c'est déjà un chemin absolu qui existe
  if (file.exists(filename)) {
    return(filename)
  }
  
  # Sinon, chercher dans le dossier source
  source_path <- file.path(config$files_api$source_directory, filename)
  if (file.exists(source_path)) {
    return(source_path)
  }
  
  # Fichier non trouvé
  log_message(sprintf("❌ Fichier non trouvé: %s", filename), level = "ERROR")
  return(NULL)
}

# Fonction pour déterminer le type de contenu selon l'extension
get_content_type <- function(filepath) {
  mime_type <- get_mime_type(filepath)
  
  if (mime_type %in% c("image/jpeg", "image/png", "image/gif", "image/webp")) {
    return("image")
  } else {
    return("document")
  }
}

# Log de chargement (sera exécuté après chargement de utils.R)
# log_message("📚 Fonctions Files API chargées", level = "INFO")