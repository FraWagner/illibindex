#' @import dplyr
#' @importFrom utils data
#' @importFrom stats na.omit filter
#' @importFrom dplyr filter pull
#' @importFrom magrittr %>%
#' @importFrom rlang .data

process_dictionary <- function(dataset = df_list, which) {
  # Check if dataset exists
  if (!exists("df_list")) {
    stop("The dictionary object is not loaded.")
  }

  # Check if the requested dictionary exists
  if (!which %in% names(df_list)) {
    stop(paste("The specified dictionary", which, "does not exist in your dictionary list."))
  }

  dict <- dataset[[which]]

  # Get the main terms
  terms <- dict %>%
    dplyr::filter(.data$country == "all") %>%
    dplyr::filter(!is.na(.data$term)) %>%
    dplyr::pull("term")

  assign("terms", terms, envir = .GlobalEnv)

  # Loop through each term to create separate environment variables
  for (i in terms) {
    # Extract liberal terms
    dict_lib <- dict %>%
      dplyr::filter(.data$country == "all") %>%
      dplyr::pull(paste0(i, "_liberal")) %>%
      stats::na.omit() %>%
      as.vector()

    # Extract illiberal terms
    dict_illib <- dict %>%
      dplyr::filter(.data$country == "all") %>%
      dplyr::pull(paste0(i, "_illiberal")) %>%
      stats::na.omit() %>%
      as.vector()

    # Assign to the global environment with dynamically generated names
    assign(paste0(i, "_liberal"), dict_lib, envir = .GlobalEnv)
    assign(paste0(i, "_illiberal"), dict_illib, envir = .GlobalEnv)
  }

  # Return extracted terms (not necessary but useful)
  return(terms)
}
