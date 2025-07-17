#' @importFrom quanteda docvars "docvars<-" tokens_subset featnames tokens_keep fcm
#' @importFrom text2vec GlobalVectors

train_word_embeddings <- function(corpus = NULL,
                                  model_name = "model1",
                                  country = "Italy",
                                  speaker_party = "Speaker_party",
                                  num_bootstraps = 100,
                                  window_size = 10,
                                  drop_parties = c("RE"),
                                  min_docs = 50,
                                  output_dir = "./models_wordembeddings/") {
  if (is.null(corpus)) {
    data("corpus_ITA", package = "illibIndex")
    corpus <- corpus_ITA
  }

  corpus_all <- corpus
  docvars(corpus_all, "actor_name") <- docvars(corpus_all, speaker_party)

  # Filter actors
  actors <- na.omit(unique(docvars(corpus_all, "actor_name")))
  actors <- actors[!(actors %in% drop_parties)]

  # Get unique years
  docvars(corpus_all, "year") <- as.integer(substr(docvars(corpus_all, "year_month"), 1, 4))
  years <- sort(unique(docvars(corpus_all, "year")))

  # Create output directory
  dir_path <- file.path(output_dir, country, paste0(model_name, "_years"))
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)

  set.seed(1999)

  for (name in actors) {
    cat(crayon::yellow("\nTraining word embeddings for", name, "... "))
    corpus <- tokens_subset(corpus_all, Speaker_party == name)

    for (y in years) {
      cat(crayon::red("for year", y, "... "))
      corpusY <- tokens_subset(corpus, year == y)

      if (length(corpusY) < min_docs) {
        cat(crayon::red("Skipping year", y, "due to insufficient documents.\n"))
        next
      }

      # Minimal pruning
      dfm <- quanteda::dfm(corpusY)
      keep <- featnames(dfm)[quanteda::featfreq(dfm) >= 5]
      corpusY <- tokens_keep(corpusY, keep)

      # Train bootstrapped word embedding models
      bootstrapped_samples <- vector("list", num_bootstraps)
      for (i in 1:num_bootstraps) {
        cat(crayon::blue("bootstrap", i, "... "))
        bootstrapped_corpus <- sample(corpusY, replace = TRUE)
        fcm <- fcm(bootstrapped_corpus, context = "window", count = "weighted",
                   weights = 1 / (1:window_size), tri = TRUE, window = window_size)

        glove <- GlobalVectors$new(rank = 50, x_max = 10)
        wv_main <- glove$fit_transform(fcm, n_iter = 10, convergence_tol = 0.01, n_threads = 16)
        wv_context <- glove$components
        word_vectors <- wv_main + t(wv_context)

        bootstrapped_samples[[i]] <- word_vectors
      }

      # Save model
      file_name <- paste0("wordvecs_", name, "_", y, ".rds")
      saveRDS(bootstrapped_samples, file = file.path(dir_path, file_name))
    }
  }
}
