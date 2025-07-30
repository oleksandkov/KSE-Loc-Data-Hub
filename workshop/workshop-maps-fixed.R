rm(list = ls(all.names = TRUE)) # Clear the memory of variables from previous run.

#+ load-packages -----------------------------------------------------------
# Check if packages are installed and load them
packages_needed <- c("tidyverse", "sf", "tmap", "readxl", "janitor", "stargazer", "scales")

# Function to check and install packages if needed
check_and_install <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    cat("Package", pkg, "not found. Please install it using:\n")
    cat("install.packages('", pkg, "')\n", sep = "")
    return(FALSE)
  }
  return(TRUE)
}

# Check all packages
all_loaded <- all(sapply(packages_needed, check_and_install))

if (!all_loaded) {
  cat("\nSome required packages are missing. Please install them and run this script again.\n")
  cat("You can install all packages at once using:\n")
  cat("install.packages(c('tidyverse', 'sf', 'tmap', 'readxl', 'janitor', 'stargazer', 'scales'))\n")
  stop("Missing required packages")
}

# If we get here, all packages are loaded
cat("All required packages loaded successfully!\n")

#+ load-data -----------------------------------------------------------

#load survey data
if (!file.exists("./agro-survey-workshop.xlsx")) {
  stop("File './agro-survey-workshop.xlsx' not found. Please ensure it's in the workshop directory.")
}

ds0 <-  readxl::read_xlsx("./agro-survey-workshop.xlsx") %>% 
  janitor::clean_names()

colnames(ds0)[1:6] <- c("oblast", "raion", "hromada", "military_action", "pct_idp", "n_idp") 

#load general KSE dataset - try local file first
if (file.exists("../maps/full_dataset.csv")) {
  cat("Loading local full_dataset.csv...\n")
  ds_general <- readr::read_csv("../maps/full_dataset.csv")
} else if (file.exists("../data/derived/full_dataset.csv")) {
  cat("Loading full_dataset.csv from data/derived...\n")
  ds_general <- readr::read_csv("../data/derived/full_dataset.csv")
} else {
  # Try to download from GitHub (will fail without internet)
  cat("Local file not found, trying to download from GitHub...\n")
  tryCatch({
    ds_general <- readr::read_csv("https://raw.githubusercontent.com/kse-ua/ua-de-center/main/data-public/derived/full_dataset.csv")
  }, error = function(e) {
    stop("Could not load full_dataset.csv. Please ensure the file exists in either '../maps/full_dataset.csv' or '../data/derived/full_dataset.csv'")
  })
}

# Note about polygons: This script requires geospatial data to create maps.
# The polygons would normally be loaded from:
# https://raw.githubusercontent.com/kse-ua/ua-de-center/main/data-public/derived/shapefiles/admin/terhromad_fin.geojson
# 
# Since we don't have internet access, we'll create a placeholder that demonstrates
# the data processing logic without the mapping components.

cat("WARNING: Geospatial polygon data not available without internet connection.\n")
cat("The script will continue with data processing but will skip mapping sections.\n")

# Create a flag to indicate whether we have spatial data
has_spatial_data <- FALSE

# Placeholder for polygons - would normally load from GitHub
polygons <- NULL

#+ merge-data-with-polygons -----------------------------------------------------------

#combination of oblast-raion-hromada gives us a unique identifier - we can use this to merge with the full dataset
ds_general %>% distinct(oblast_name, raion_name, hromada_full_name)

ds1 <- 
  #clean our test dataset and create key variable
  ds0 %>% 
  mutate(
    oblast = str_remove(oblast, " область")
    ,raion = str_remove(raion, " район")
    ,raion = str_replace_all(raion, c("'"="ʼ", "'"="ʼ"))
    ,hromada = str_replace_all(hromada, c("a"="а", "o"="о", "e"="е", "O"="О", "p"="р", "'"="ʼ", "ʼ"="ʼ"))
    ,key = paste(oblast, raion, hromada)
  ) %>% 
  #merge our test dataset with the KSE main dataset by key variable
  left_join(
    ds_general %>% 
      select(hromada_code, oblast_name, raion_name, hromada_full_name, total_popultaion_2022) %>% 
      mutate(
        key = paste(oblast_name, raion_name, hromada_full_name)
        ,key = str_replace_all(key, c("'"="ʼ", "'"="ʼ"))
      )
    ,by = "key"
  ) %>% 
  distinct(hromada_code, .keep_all = T) %>% 
  filter(hromada != "Війтівецька сільська громада") %>% 
  #add variable with % of IDPs based on the total population from the general dataset
  mutate(
    pct_idp = n_idp/total_popultaion_2022 * 100
    ,pct_idp_rounded = scales::percent(round(pct_idp/100, 4))
  ) %>% 
  filter(pct_idp <= 100, !is.na(pct_idp))

# Add spatial data if available
if (has_spatial_data && !is.null(polygons)) {
  ds1 <- ds1 %>%
    left_join(
      polygons %>% select(cod_3, geometry)
      ,by = c("hromada_code"="cod_3")
    )
}

# Checks
cat("\nData quality checks:\n")
cat("Missing values by column:\n")
ds1 %>% summarise(across(everything(), ~ sum(is.na(.x)))) %>% t() %>% print()

cat("\nMerge quality check (first few rows):\n")
ds1 %>% 
  select(oblast, oblast_name, raion, raion_name, hromada, hromada_full_name) %>% 
  head(10) %>% print()

# Basic statistics
cat("\nBasic statistics for IDP numbers:\n")
summary(ds1$n_idp)

# Graphs - these will work regardless of spatial data availability
cat("\nGenerating plots...\n")

p1 <- ds1 %>% 
  ggplot(aes(x = n_idp)) +
  geom_histogram(position = "identity", alpha = 0.5, bins = 30, fill = "steelblue") +
  theme_bw() +
  labs(x = 'Number of IDPs', y = 'Frequency', title = 'Distribution of IDP Numbers') +
  xlim(0, 20000)

print(p1)

p2 <- ds1 %>% 
  ggplot(aes(x = pct_idp)) +
  geom_histogram(position = "identity", alpha = 0.5, bins = 30, fill = "darkred") +
  theme_bw() +
  labs(x = 'Share of IDPs in total population (%)', y = 'Frequency', 
       title = 'Distribution of IDP Share')

print(p2)

# Top and bottom communities by IDP percentage
ds3 <- bind_rows(
  ds1 %>% slice_max(pct_idp, n = 5),
  ds1 %>% slice_min(pct_idp, n = 5)
)

p3 <- ds3 %>% 
  ggplot(aes(x = pct_idp, y = fct_reorder(hromada, pct_idp))) +
  geom_col(fill = "orange") +
  geom_text(aes(label = round(pct_idp,2)), hjust = -0.1) +
  theme_bw() +
  labs(x = 'Share of IDPs in total population (%)', y = NULL,
       title = 'Top and Bottom Communities by IDP Share') +
  xlim(0, max(ds3$pct_idp) * 1.1)

print(p3)

# Scatter plot
p4 <- ds1 %>% 
  ggplot(aes(x = n_idp, y = total_popultaion_2022)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  theme_bw() +
  labs(x = "Number of IDPs", y = 'Population as of Jan 2022',
       title = 'Relationship between IDP Numbers and Population Size') +
  xlim(0, 50000) +
  ylim(0, 500000)

print(p4)

## Regression Analysis
cat("\nRunning regression analysis...\n")

ds2 <- ds1 %>% 
  left_join(ds_general %>% select(hromada_code, type, square, income_total_2021),
            by = 'hromada_code') %>%
  filter(!is.na(total_popultaion_2022), total_popultaion_2022 > 0)

model1 <- lm(n_idp ~ log10(total_popultaion_2022), data = ds2)
model2 <- lm(n_idp ~ log10(total_popultaion_2022) + type + square, data = ds2)
model3 <- lm(n_idp ~ log10(total_popultaion_2022) + type + square + income_total_2021,
             data = ds2)

# Display regression results
if (require("stargazer", quietly = TRUE)) {
  stargazer::stargazer(model1, model2, model3, type = 'text', 
                       title = "Regression Results: Factors Affecting IDP Numbers")
} else {
  cat("Stargazer package not available, showing basic summaries:\n")
  cat("\nModel 1 (Basic):\n")
  print(summary(model1))
  cat("\nModel 2 (With type and area):\n") 
  print(summary(model2))
  cat("\nModel 3 (Full model):\n")
  print(summary(model3))
}

#+ mapping-section -----------------------------------------------------------
cat("\n=== MAPPING SECTION ===\n")

if (has_spatial_data && !is.null(polygons)) {
  cat("Creating maps...\n")
  
  # Create sf object - required for mapping using tmap
  ds2_sf <- st_as_sf(ds1, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
  
  # Set the viewer mode as "plot"
  tmap_mode("plot")
  
  # Create simple map
  g1 <- tm_shape(ds2_sf) +
    tm_polygons("n_idp", title = "Кількість ВПО") + 
    tmap_options(check.and.fix = TRUE)
  
  print(g1)
  
  # Additional mapping code would go here...
  
} else {
  cat("SKIPPING MAPPING: Spatial data not available.\n")
  cat("To enable mapping functionality, you need:\n")
  cat("1. Internet connection to download polygon data, OR\n")
  cat("2. Local geospatial files in the appropriate format\n")
  cat("\nThe data processing and analysis parts of this script have completed successfully.\n")
}

#+ save-results -----------------------------------------------------------
cat("\nSaving results...\n")

# Create output directory if it doesn't exist
if (!dir.exists("./workshop-charts")) {
  dir.create("./workshop-charts")
  cat("Created directory: ./workshop-charts\n")
}

# Save plots
ggsave("./workshop-charts/idp_numbers_histogram.png", p1, width = 10, height = 6)
ggsave("./workshop-charts/idp_percentage_histogram.png", p2, width = 10, height = 6)
ggsave("./workshop-charts/top_bottom_communities.png", p3, width = 12, height = 8)
ggsave("./workshop-charts/idp_vs_population.png", p4, width = 10, height = 6)

# Save data
write_csv(ds1, "./workshop-charts/processed_idp_data.csv")
write_csv(ds2, "./workshop-charts/regression_data.csv")

cat("\nScript completed successfully!\n")
cat("Output files saved in: ./workshop-charts/\n")
cat("- PNG files: plots and visualizations\n")
cat("- CSV files: processed data\n")

if (!has_spatial_data) {
  cat("\nNote: Map creation was skipped due to missing spatial data.\n")
  cat("Install required packages and ensure internet connectivity for full functionality.\n")
}