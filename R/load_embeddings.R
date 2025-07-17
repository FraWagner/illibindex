#' Load saved word embeddings
#'
#' @param country Country name used during training (e.g., "Italy")
#' @param model_name Model identifier used in training (e.g., "model1")
#' @param output_dir Directory where models are saved
#'
#' @return A character vector of loaded word embeddings
load_word_embeddings <- function(country = "Italy",
                                 model_name = "model1",
                                 output_dir = "./models_wordembeddings/") {
  dir_path <- file.path(output_dir, country, paste0(model_name, "_years"))

  if (!dir.exists(dir_path)) {
    stop("Model directory does not exist: ", dir_path)
  }

  files <- list.files(dir_path, pattern = "\\.rds$", full.names = TRUE)

  embeddings <- lapply(files, readRDS)
  names(embeddings) <- tools::file_path_sans_ext(basename(files))

  return(embeddings)
}
