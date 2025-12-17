#' Load saved word embeddings
#'
#' Load word embeddings previously created with
#' \code{train_word_embeddings()}.
#'
#' @param country Country name used during training (e.g., "Italy").
#' @param model_name Model identifier used in training (e.g., "model1").
#' @param output_dir Directory where models are saved.
#'
#' @return A named list of word embedding matrices (or lists of matrices)
#'   loaded from \code{.rds} files.
#'
#' @export
load_word_embeddings <- function(
    country = "Italy",
    model_name = "model1",
    output_dir = NULL
) {
  
  # ---- No internal embeddings shipped ----
  if (is.null(output_dir)) {
    stop(
      "No word embeddings found.\n",
      "Please supply `output_dir` pointing to embeddings created with ",
      "`train_word_embeddings()`.",
      call. = FALSE
    )
  }
  
  dir_path <- file.path(output_dir, country, paste0(model_name, "_years"))
  
  if (!dir.exists(dir_path)) {
    stop(
      "Model directory does not exist:\n  ", dir_path, "\n",
      "Make sure you have run `train_word_embeddings()` first.",
      call. = FALSE
    )
  }
  
  files <- list.files(dir_path, pattern = "\\.rds$", full.names = TRUE)
  
  if (length(files) == 0) {
    stop(
      "No embedding files found in:\n  ", dir_path, "\n",
      "Check that `train_word_embeddings()` completed successfully.",
      call. = FALSE
    )
  }
  
  embeddings <- lapply(files, readRDS)
  names(embeddings) <- tools::file_path_sans_ext(basename(files))
  
  embeddings
}
