#' Plot Similarity Scores for Words in a Political Context
#' @import stats
#' @importFrom ggplot2 ggplot aes geom_point geom_linerange geom_hline facet_wrap theme_bw theme element_text position_dodge
#' @importFrom dplyr filter mutate %>%
#' @importFrom forcats fct_relevel fct_reorder

plot_libVillib_wordfacet <- function(country = "Italy", model = "model1") {
  # Define file path
  filepath <- paste0("./models_cosSim_ci/", country, "/", model, "/")
  files <- list.files(filepath, pattern = "\\.RData$", full.names = TRUE)

  # Load all .RData files as a list of word vectors
  all_lists <- lapply(files, load, .GlobalEnv)
  all_lists <- as.character(all_lists)

  # Load results data
  df_results <- get(all_lists[[1]])

  # Set column names
  colnames(df_results) <- c("Similarity", "sd", "lower", "upper", "dimension", "Policy", "Party", "Time", "word")

  # Generate the plot
  plot <- df_results %>%
    dplyr::filter(dimension == "LibIllib") %>%
    mutate(
      word = as.factor(word),
      word = fct_relevel(word, "AVERAGE"),
      word = fct_reorder(word, as.numeric(word == "AVERAGE"), .desc = TRUE)
    ) %>%
    ggplot(aes(x = reorder(Party, Similarity), y = Similarity, color = Party)) +
    geom_point(position = position_dodge(width = 0.4)) +
    geom_linerange(aes(ymin = lower, ymax = upper), position = position_dodge(width = 0.4)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey80") +
    facet_wrap(~word) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(plot)
}
