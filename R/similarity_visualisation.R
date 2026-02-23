#' Plot Similarity Scores for Words in a Political Context
#' 
#' @param country Character string specifying the country.
#' @param model Character string specifying the model identifier.
#' @param results Optional. A results object from calc_cosSim(). If NULL, 
#'   will attempt to load from file or use demo_results as fallback.
#' @param use_demo Logical. If TRUE and no results file found, use demo_cossim_IT. 
#'   Default is TRUE.
#' 
#' @export
#' @importFrom ggplot2 ggplot aes geom_point geom_linerange geom_hline facet_wrap theme_bw theme element_text position_dodge
#' @importFrom dplyr mutate %>% group_by summarise
#' @importFrom stats sd
#' @importFrom forcats fct_relevel fct_reorder
plot_libVillib_wordfacet <- function(
    country = "Italy", 
    model = "model1",
    results = NULL,
    use_demo = TRUE
) {
  
  # If results not provided, try to load from file or use demo
  if (is.null(results)) {
    # Define file path
    filepath <- paste0("./models_cosSim_ci/", country, "/", model, "/")
    
    # Check if directory exists
    if (dir.exists(filepath)) {
      files <- list.files(filepath, pattern = "\\.RData$", full.names = TRUE)
      
      if (length(files) > 0) {
        # Load from file
        all_lists <- lapply(files, function(f) {
          env <- new.env()
          load(f, envir = env)
          objs <- ls(envir = env)
          return(get(objs[1], envir = env))
        })
        df_results <- all_lists[[1]]
      } else if (use_demo) {
        # Use demo data if no files found
        message("No results files found. Using demo_cossim_IT.")
        df_results <- demo_cossim_IT[[1]]
      } else {
        stop("No results files found and use_demo = FALSE.")
      }
    } else if (use_demo) {
      message("No results files found. Using demo_cossim_IT.")
      df_results <- demo_cossim_IT[[1]]
    } else {
      stop("Directory not found and use_demo = FALSE.")
    }
  } else {
    # Use provided results
    if (is.list(results) && !is.data.frame(results)) {
      df_results <- results[[1]]
    } else {
      df_results <- results
    }
  }
  
  # Ensure consistent column names
  if (!all(c("Similarity", "dimension", "Policy", "Party", "Time", "word") %in% names(df_results))) {
    # Try to rename if columns exist but have different names
    if (all(c("mean", "sd", "lowerci", "upperci", "dimension", "Policy", "Party", "Time", "word") %in% names(df_results))) {
      colnames(df_results)[colnames(df_results) == "mean"] <- "Similarity"
      colnames(df_results)[colnames(df_results) == "lowerci"] <- "lower"
      colnames(df_results)[colnames(df_results) == "upperci"] <- "upper"
    } else {
      stop("Results data frame does not have expected column names.")
    }
  }
  
  # Filter and aggregate data
  plot_data <- df_results %>%
    dplyr::filter(dimension == "LibIllib") %>%
    dplyr::group_by(Party, word) %>%
    dplyr::summarise(
      Similarity = mean(Similarity, na.rm = TRUE),
      lower = mean(lower, na.rm = TRUE),
      upper = mean(upper, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      word = as.factor(word),
      word = fct_relevel(word, "AVERAGE"),
      word = fct_reorder(word, as.numeric(word == "AVERAGE"), .desc = TRUE)
    )
  
  # Generate the plot
  plot <- plot_data %>%
    ggplot(aes(x = reorder(Party, Similarity), y = Similarity, color = Party)) +
    geom_point(position = position_dodge(width = 0.4)) +
    geom_linerange(aes(ymin = lower, ymax = upper), position = position_dodge(width = 0.4)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey80") +
    facet_wrap(~word) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(plot)
}