#' Calculate Cosine Similarity for Text Analysis
#'
#' @importFrom crayon make_style
#' @importFrom progress progress_bar
#' @importFrom quanteda dfm dfm_lookup dictionary tokens
#' @importFrom text2vec sim2
#' @importFrom stats sd
#' @importFrom dplyr bind_rows bind_cols
#' @importFrom tibble rownames_to_column
#' @importFrom stats reorder
#'
#' @param country Character string specifying the country name.
#' @param model Character string specifying model identifier.
#' @param which Character string specifying which dictionary to use
#'   (e.g. "immigration", "gender").
#' @param output_dir Character string specifying output directory.
#'@param embeddings_path Character. Path to a directory containing
#' pre-trained word embeddings.
#' @param save Logical. Whether to save results to disk.
#' @param output_dir Character string. Output directory if \code{save = TRUE}.
#' @return A data frame with cosine similarity results.
#' @export




calc_cosSim <- function(
    country = "Italy",
    model = "model1",
    which = "immigration",
    output_dir = NULL,
    save = FALSE,
    embeddings_path = NULL
) {
  
  styles <- initialize_styles()
  
  # ---- Check embeddings ----
  if (is.null(embeddings_path)) {
    stop(
      paste(
        "No word embeddings supplied.\n\n",
        "Please either:\n",
        "1) Provide a path via `embeddings_path`, or\n",
        "2) Run `train_word_embeddings(country = \"", country,
        "\", model = \"", model, "\")` first.",
        sep = ""
      ),
      call. = FALSE
    )
  }
  
  if (!file.exists(embeddings_path)) {
    stop(
      "The supplied embeddings file does not exist:\n",
      embeddings_path,
      call. = FALSE
    )
  }
  
  # ---- Load embeddings ----
  wordvecs_list <- load_word_embeddings(
    country    = country,
    model_name = model,
    output_dir = embeddings_path
  )
  
  terms <- process_dictionary(which = which)
  
  word_lists <- list(terms)
  names(word_lists) <- which
  
  list_names <- names(word_lists)
  
  df_results <- data.frame()

  # Process each word embedding vector
  for (model_idx in 1:length(wordvecs_list)) {
    current_model <- wordvecs_list[[model_idx]]
    model_name <- sub("wordvecs_", "", names(wordvecs_list)[model_idx])
    model_parts <- unlist(strsplit(names(wordvecs_list)[model_idx], "_"))
    actor_name <- model_parts[2]
    time <- model_parts[3]

    # Process each word list
    for (word_list_idx in 1:length(word_lists)) {
      current_word_list <- word_lists[[word_list_idx]]
      word_list_name <- list_names[word_list_idx]

      # Print a message indicating the current vector being processed
      cat(crayon::yellow$underline(paste0(
        "\n\n Getting vector for --",
        crayon::bold(model_name), "-- for --",
        crayon::bold(word_list_name), "-- word list "
      )))
      collect_LibIllib <- c()

      # Loop over each word in the word list
      for (word_idx in 1:length(current_word_list)) {
        current_word <- current_word_list[word_idx]
        cat(crayon::blue(paste0("\n", current_word, "... ")))
        # liberal
        liberal <- get(paste0(current_word, "_liberal"))
        # illiberal
        illiberal <- get(paste0(current_word, "_illiberal"))
        # Making the custom dictionary
        liberal_dict <- dictionary(list(liberal_dict = liberal))
        illiberal_dict <- dictionary(list(illiberal_dict = illiberal))
        # empty object to hold scores
        lib_scores <- c()
        illib_scores <- c()
        LibIllibscores <- c()
        #
        cat("\n")

        # Create a progress bar object
        pb <- progress::progress_bar$new(
          format = "  Progress [:bar] :percent Elapsed: :elapsed",
          total = length(current_model),
          clear = TRUE,
          width = 60
        )

        # THIS LOOP SHOULD BE INSIDE THE WORD LOOP
        for (i in 1:length(current_model)) {
          # update the progress bar
          pb$tick()
          
          # Extract the word vectors for the current bootstrapped sample
          word_vectors <- current_model[[i]]
          # Moving the trycatch here becomes SOME of the embeddings might be missing the term
          tryCatch(
            {
              # Extract the vec_currentword value for the current word
              # add check for current word:
              if (!(current_word %in% rownames(word_vectors))) {
                warning(paste("Word", current_word, "not found in word vectors. Skipping."))
                next
              }
            vec_currentword <- word_vectors[current_word, , drop = FALSE]
            # Compute the cosine similarity matrix for the current model
            cos_sim <- sim2(x = word_vectors, y = vec_currentword, method = "cosine", norm = "l2")
            # convert rownames to a column
            cos_sim <- tibble::rownames_to_column(data.frame(cos_sim), var = "terms")
            # Now looking up words in dictionary
            worddfm_lib <- dfm_lookup(dfm(tokens(cos_sim$terms)), dictionary = liberal_dict)
            worddf_lib <- convert(worddfm_lib, to = "data.frame")
            # and illiberal
            worddfm_illib <- dfm_lookup(dfm(tokens(cos_sim$terms)), dictionary = illiberal_dict)
            worddf_illib <- convert(worddfm_illib, to = "data.frame")
            # Combining
            cos_sim_combined <- cbind(cos_sim, worddf_lib, worddf_illib)
            # Check if any liberal or illiberal words matched
            if (all(cos_sim_combined$liberal_dict == 0) & all(cos_sim_combined$illiberal_dict == 0)) {
              warning(paste("No liberal or illiberal words matched in similarity matrix for", current_word))
              next
            }
            # getting scores by word so can report
            lib_words <- cos_sim_combined %>% subset.data.frame(cos_sim_combined$liberal_dict > 0)
            illib_words <- cos_sim_combined %>% subset.data.frame(cos_sim_combined$illiberal_dict > 0)
            ## Calculating mean similarity
            # using base R
            lib_score <- mean(lib_words[[current_word]])
            illib_score <- mean(illib_words[[current_word]])
            # seems to work
            # Taking the difference between the liberal and illiberal cosine distance
            LibIllib_score <- lib_score - illib_score
            #
            # collecting the scores
            lib_scores <- c(lib_scores, lib_score)
            illib_scores <- c(illib_scores, illib_score)
            LibIllibscores <- c(LibIllibscores, LibIllib_score)
          },
          error = function(e) {
            cat(crayon::red(" ...error calculating", crayon::red$bold(current_word), "... "))
          }
          )
        } 
      # removing missing values
      lib_scores <- na.omit(lib_scores)
      illib_scores <- na.omit(illib_scores)
      LibIllibscores <- na.omit(LibIllibscores)

      # Move the cursor up after the progress bar
      # cat("\033[F") # ANSI escape code to move cursor up after progress bar clears
      # cat(crayon::green("... "))
      # get the mean, upper ci, lower ci, and sd for each
      df_lib <- data.frame(
        mean = mean(lib_scores),
        sd = sd(lib_scores),
        lowerci = mean(lib_scores) - 1.96 * sd(lib_scores) / sqrt(length(lib_scores)),
        upperci = mean(lib_scores) + 1.96 * sd(lib_scores) / sqrt(length(lib_scores)),
        dimension = "liberal"
      )
      #
      df_illib <- data.frame(
        mean = mean(illib_scores),
        sd = sd(illib_scores),
        lowerci = mean(illib_scores) - 1.96 * sd(illib_scores) / sqrt(length(illib_scores)),
        upperci = mean(illib_scores) + 1.96 * sd(illib_scores) / sqrt(length(illib_scores)),
        dimension = "illiberal"
      )
      #
      df_LibIllib <- data.frame(
        mean = mean(LibIllibscores),
        sd = sd(LibIllibscores),
        lowerci = mean(LibIllibscores) - 1.96 * sd(LibIllibscores) / sqrt(length(LibIllibscores)),
        upperci = mean(LibIllibscores) + 1.96 * sd(LibIllibscores) / sqrt(length(LibIllibscores)),
        dimension = "LibIllib"
      )

      # combining in DF
      wordall <- dplyr::bind_rows(df_lib, df_illib, df_LibIllib)

      # Modify the "Policy" column to reflect the current word list
      wordall$Policy <- word_list_name # Assign the word list name to the "Policy" column
      wordall$Party <- actor_name # Add the actor name
      wordall$Time <- time # time period covered
      wordall$word <- current_word # adding the word (because we need to know the word we're measuring, no?)
      # Store the results in the result_list_word_list

      # store in the df
      df_results <- bind_rows(df_results, wordall)
      # collecting LibIllib scores
      collect_LibIllib <- c(collect_LibIllib, LibIllibscores)
      # clearing wordall
      wordall <- NA
      cat("\U0001F44D", crayon::green("... ")) # thumps up! It worked
      }

      # clearing up any missing values
      collect_LibIllib <- as.vector(na.omit(collect_LibIllib))
      
      # Check if we have any valid data before creating the summary
      if (length(collect_LibIllib) > 0) {
        # Calculate statistics
        mean_val <- mean(collect_LibIllib)
        sd_val <- sd(collect_LibIllib)
        n_val <- length(collect_LibIllib)
        
        # Handle case where sd is NA (happens with n=1)
        if (is.na(sd_val)) {
          sd_val <- 0
        }
        
        # adding average of the LibIllib scores for policy dictionary
        ave_Libillib <- data.frame(
          mean = mean_val,
          sd = sd_val,
          lowerci = mean_val - 1.96 * sd_val / sqrt(n_val),
          upperci = mean_val + 1.96 * sd_val / sqrt(n_val),
          dimension = "LibIllib",
          Policy = word_list_name,
          Party = actor_name,
          Time = time,
          word = "AVERAGE",
          stringsAsFactors = FALSE
        )
        # store in the df
        df_results <- bind_rows(df_results, ave_Libillib)
      } else {
        warning(paste("No valid LibIllib scores collected for", word_list_name))
      }
    }
  }

  # collect results in a named list
  results <- list()
  results[[word_list_name]] <- df_results
  
  # optionally save results to disk
  if (isTRUE(save)) {
    
    if (is.null(output_dir)) {
      stop("If save = TRUE, you must provide output_dir.", call. = FALSE)
    }
    
    dir <- file.path(output_dir, country, model)
    
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
    }
    
    saveRDS(
      results,
      file = file.path(dir, paste0("results_", word_list_name, ".rds"))
    )
  }
  
  return(results)
}



# Helper Functions --------------------------------------------------------

#' Initialize Style Colors
#' @keywords internal
initialize_styles <- function() {
  list(
    light_green = make_style("#a1d76a"),
    pink = make_style("#e9a3c9"),
    light_brown = make_style("burlywood"),
    forest_green = make_style("forestgreen"),
    gold = make_style("gold"),
    fire_red = make_style("firebrick")
  )
}
