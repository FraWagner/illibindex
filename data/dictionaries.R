# data-raw/dictionaries.R
# Load the raw data and save it in the package

# Load your data (adjust the format if necessary)
load("df_list.rda") # This loads 'dictionaries' into the environment

# Save the object properly within the package
usethis::use_data(df_list, overwrite = TRUE)
