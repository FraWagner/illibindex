
<!-- README.md is generated from README.Rmd. Please edit that file -->

# illibindex

<!-- badges: start -->

[![R-CMD-check](https://github.com/FraWagner/illibindex/workflows/R-CMD-check/badge.svg)](https://github.com/FraWagner/illibindex/actions)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

## Overview

**illibindex** measures liberal and illiberal rhetoric in political
discourse using word embeddings and cosine similarity. The package helps
researchers quantify how political actors position themselves on policy
issues by comparing their language to predefined liberal and illiberal
vocabularies.

### Key Features

- 📚 **Pre-built dictionaries** for immigration, gender, and other
  policy domains
- 🧠 **Word embedding training** using GloVe with bootstrap resampling
- 📊 **Cosine similarity analysis** to measure ideological positioning
- 🎯 **Flexible workflow** from text to validated measurements

## Installation

Install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("FraWagner/illibindex")
```

## Quick Example

``` r
library(illibindex)

# Load the demo cosine similarity results
data(demo_cossim_IT)
```

## Working with Dictionaries

The package includes pre-built dictionaries for analyzing political
rhetoric:

``` r
library(illibindex)

# Load built-in dictionaries
data(dictionaries)

# See available policy domains
names(dictionaries)
#> [1] "immigration"

# View immigration-related terms
dictionaries$immigration$term
#> [1] "immigra" "asylum"  "border"  "migrat"  "migrant" NA        NA

head(dictionaries$liberal$immigra)
#> NULL
```

## Visualizing Results

Using the demo data, we can visualize how political parties position
themselves:

``` r
library(illibindex)

# Load demo results
data(demo_cossim_IT)

# Use the built-in plotting function
plot_libVillib_wordfacet()
#> No results files found. Using demo_cossim_IT.
```

<img src="man/figures/README-visualization-1.png" width="100%" />

## Understanding the Scores

**Liberal-Illiberal (LibIllib) Score:** - Calculated as:
`liberal_similarity - illiberal_similarity` - **Positive values**:
Actor’s language closer to liberal vocabulary - **Negative values**:
Actor’s language closer to illiberal vocabulary - **Near zero**: Neutral
or ambiguous positioning

**Individual Dimensions:** - `liberal`: Mean cosine similarity to
liberal terms - `illiberal`: Mean cosine similarity to illiberal terms -
`LibIllib`: The difference score (main measure of interest)

## Full Workflow

### Step 1: Prepare Your Data

``` r
# Load your corpus (example using included data)
data(corpus_ITA)
head(corpus_ITA)
```

### Step 2: Train Word Embeddings

``` r
# Train embeddings with bootstrap resampling
train_word_embeddings(
  country = "Italy",
  model = "model1",
  output_dir = "output/embeddings",
  corpus = corpus_ITA,
  n_bootstrap = 100,
  window_size = 6,
  dim = 300
)
```

### Step 3: Calculate Cosine Similarity

``` r
# Calculate similarity scores
results <- calc_cosSim(
  country = "Italy",
  model = "model1",
  which = "immigration",
  embeddings_path = "output/embeddings/Italy/model1",
  save = TRUE,
  output_dir = "output/results"
)

# View results
head(results$immigration)
```

## Advanced Usage

### Custom Dictionaries

You can create your own dictionaries following the package format:

``` r
# Create a custom dictionary data frame
custom_dict <- data.frame(
  country = "all",
  term = NA,
  climate_liberal = c("renewable", "sustainable", "green", NA),
  climate_illiberal = c("hoax", "expensive", "unnecessary", NA),
  stringsAsFactors = FALSE
)

# Add to dictionaries list
data(dictionaries)
dictionaries$climate <- custom_dict

# Process it
climate_dict <- process_dictionary(dictionaries, "climate")
```

## Data Included

The package includes example datasets:

- **`dictionaries`**: Liberal and illiberal term lists for multiple
  policy domains
- **`corpus_ITA`**: Italian political party corpus for demonstration
- **`demo_cossim_IT`**: Pre-computed cosine similarity results

``` r
# See what data is available
data(package = "illibindex")
```

## Citation

If you use this package in your research, please cite:

    Wagner, F. (2024). illibindex: Measuring Liberal and Illiberal Rhetoric 
    in Political Discourse. R package version 0.1.0. 
    https://github.com/FraWagner/illibindex

## Related Work

This package implements methods for measuring ideological positioning
using word embeddings. For theoretical background and validation, see:

- [“Measuring Illiberalism: Mapping Illiberalism in Seven Countries,
  2000-2022.”](https://preprints.apsanet.org/engage/apsa/article-details/67840ffc6dde43c9083af8cb)
- [“Opposition to Government and Back: How Illiberal Parties Shape
  Immigration Discourse and Party
  Competition”](https://www.cogitatiopress.com/politicsandgovernance/article/view/9609)

## Contributing

Contributions are welcome! Please feel free to:

- Report bugs or request features via [GitHub
  Issues](https://github.com/FraWagner/illibindex/issues)
- Submit pull requests
- Suggest new dictionaries or policy domains

## License

GPL-3

------------------------------------------------------------------------
