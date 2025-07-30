#!/usr/bin/env Rscript

# Simple test script to validate workshop-maps.R data requirements
# This script checks if files exist and can be loaded

cat("=== Workshop Maps Data Validation Test ===\n\n")

# Check working directory
cat("Current working directory:", getwd(), "\n")

# Check if required files exist
files_to_check <- c(
  "./agro-survey-workshop.xlsx",
  "../maps/full_dataset.csv"
)

for (file in files_to_check) {
  if (file.exists(file)) {
    cat("✓ Found:", file, "\n")
  } else {
    cat("✗ Missing:", file, "\n")
  }
}

# Try to load basic data (without heavy dependencies)
cat("\n=== Testing Data Loading ===\n")

# Test 1: Check if we can read Excel file (if readxl is available)
if (require("readxl", quietly = TRUE)) {
  tryCatch({
    cat("Loading agro-survey-workshop.xlsx...\n")
    survey_data <- readxl::read_xlsx("./agro-survey-workshop.xlsx")
    cat("✓ Successfully loaded survey data\n")
    cat("  - Dimensions:", nrow(survey_data), "rows x", ncol(survey_data), "columns\n")
    cat("  - Column names:", paste(names(survey_data)[1:min(6, ncol(survey_data))], collapse = ", "), "\n")
  }, error = function(e) {
    cat("✗ Error loading survey data:", e$message, "\n")
  })
} else {
  cat("⚠ readxl package not available - cannot test Excel file loading\n")
}

# Test 2: Check CSV file
if (file.exists("../maps/full_dataset.csv")) {
  tryCatch({
    cat("\nLoading full_dataset.csv...\n")
    # Read just the header to check structure
    header <- read.csv("../maps/full_dataset.csv", nrows = 1)
    full_data <- read.csv("../maps/full_dataset.csv")
    cat("✓ Successfully loaded full dataset\n")
    cat("  - Dimensions:", nrow(full_data), "rows x", ncol(full_data), "columns\n")
    cat("  - First few columns:", paste(names(full_data)[1:min(5, ncol(full_data))], collapse = ", "), "\n")
    
    # Check for key columns needed by workshop script
    required_cols <- c("hromada_code", "oblast_name", "raion_name", "hromada_full_name", "total_popultaion_2022")
    missing_cols <- required_cols[!required_cols %in% names(full_data)]
    
    if (length(missing_cols) == 0) {
      cat("✓ All required columns present\n")
    } else {
      cat("⚠ Missing required columns:", paste(missing_cols, collapse = ", "), "\n")
    }
    
  }, error = function(e) {
    cat("✗ Error loading CSV data:", e$message, "\n")
  })
} else {
  cat("⚠ full_dataset.csv not found - cannot test CSV loading\n")
}

# Test 3: Basic package availability
cat("\n=== Testing Package Availability ===\n")
required_packages <- c("tidyverse", "sf", "tmap", "readxl", "janitor", "stargazer", "scales")

for (pkg in required_packages) {
  if (require(pkg, quietly = TRUE, character.only = TRUE)) {
    cat("✓", pkg, "- available\n")
  } else {
    cat("✗", pkg, "- not installed\n")
  }
}

cat("\n=== Summary ===\n")
cat("This test checks the basic requirements for workshop-maps.R\n")
cat("If you see mostly ✓ marks above, the workshop script should work.\n")
cat("If you see ✗ marks, install missing packages or check file paths.\n")
cat("\nTo install all required packages, run:\n")
cat("install.packages(c('tidyverse', 'sf', 'tmap', 'readxl', 'janitor', 'stargazer', 'scales'))\n")