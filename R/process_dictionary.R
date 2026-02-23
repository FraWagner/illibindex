#' Process a dictionary into liberal and illiberal term lists
#'
#' @param dataset A named list of dictionary data frames.
#' @param which Name of the dictionary to extract.
#'
#' @return A named list with elements:
#' \describe{
#'   \item{terms}{Character vector of dictionary terms}
#'   \item{liberal}{Named list of liberal term vectors}
#'   \item{illiberal}{Named list of illiberal term vectors}
#' }
#'
#' @examples
#' data(dictionaries)
#' process_dictionary(dictionaries, "immigration")
#'
#' @importFrom dplyr filter pull
#' @importFrom stats na.omit setNames
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#'
#' @export
process_dictionary <- function(dataset = dictionaries, which) {
  
  if (!is.list(dataset)) {
    stop("`dataset` must be a named list of dictionaries.", call. = FALSE)
  }
  
  if (missing(which) || !which %in% names(dataset)) {
    stop(
      sprintf(
        "Dictionary '%s' not found. Available: %s",
        which,
        paste(names(dataset), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  
  dict <- dataset[[which]]
  
  # ---- derive terms from column names ONLY ----
  terms <- unique(
    sub("_(liberal|illiberal)$", "",
        grep("^[a-zA-Z].*_(liberal|illiberal)$",
             names(dict),
             value = TRUE))
  )
  
  if (length(terms) == 0) {
    stop("No *_liberal / *_illiberal columns found.", call. = FALSE)
  }
  
  liberal   <- stats::setNames(vector("list", length(terms)), terms)
  illiberal <- stats::setNames(vector("list", length(terms)), terms)
  
  for (term in terms) {
    cat("\n\nProcessing term:", term, "\n")
    
    # Create column names OUTSIDE the pipe
    lib_col <- paste0(term, "_liberal")
    illib_col <- paste0(term, "_illiberal")
    
    liberal[[term]] <- dict %>%
      dplyr::filter(.data$country == "all") %>%
      dplyr::pull(!!lib_col) %>%  
      stats::na.omit() %>%
      as.character()
    
    illiberal[[term]] <- dict %>%
      dplyr::filter(.data$country == "all") %>%
      dplyr::pull(!!illib_col) %>%
      stats::na.omit() %>%
      as.character()
    
    cat("Success!\n")
  }

  return(list(terms = terms, liberal = liberal, illiberal = illiberal))
}

