# Workshop Materials - Cartographic Analysis of IDP Data

This directory contains workshop materials for creating maps and analyzing data about Internally Displaced Persons (IDPs) in Ukrainian communities.

## Files

- **workshop-maps.R** - Original workshop script for creating maps and analyzing IDP data
- **workshop-maps-fixed.R** - Improved version with better error handling and offline capability
- **agro-survey-workshop.xlsx** - Survey data from agricultural communities
- **ІНСТРУКЦІЯ_WORKSHOP_MAPS.md** - Detailed instructions in Ukrainian

## Quick Start

### Prerequisites

1. **R Installation**: Ensure R is installed on your system
2. **System Dependencies** (Linux/Ubuntu):
   ```bash
   sudo apt install -y libcurl4-openssl-dev libssl-dev libxml2-dev libgdal-dev libudunits2-dev libproj-dev
   ```

3. **R Packages**:
   ```r
   install.packages(c("tidyverse", "sf", "tmap", "readxl", "janitor", "stargazer", "scales"))
   ```

### Running the Analysis

```bash
cd workshop
Rscript workshop-maps-fixed.R
```

### What the Script Does

1. **Data Loading & Cleaning**
   - Loads survey data from agro-survey-workshop.xlsx
   - Merges with the main KSE dataset (full_dataset.csv)
   - Cleans and standardizes location names

2. **Statistical Analysis**
   - Calculates IDP statistics by community
   - Runs regression models to identify factors affecting IDP numbers
   - Generates summary statistics

3. **Visualizations**
   - Histograms of IDP distribution
   - Community comparisons
   - Scatter plots showing relationships
   - Maps (when geospatial data is available)

4. **Output Generation**
   - Saves plots as PNG files in workshop-charts/
   - Exports processed data as CSV files
   - Creates regression summaries

### Output Files

The script creates a `workshop-charts/` directory with:

- **idp_numbers_histogram.png** - Distribution of IDP numbers
- **idp_percentage_histogram.png** - Distribution of IDP percentages  
- **top_bottom_communities.png** - Communities with highest/lowest IDP shares
- **idp_vs_population.png** - Relationship between IDPs and population
- **processed_idp_data.csv** - Cleaned and merged data
- **regression_data.csv** - Data used for statistical modeling

### Differences Between Original and Fixed Versions

| Feature | Original (workshop-maps.R) | Fixed (workshop-maps-fixed.R) |
|---------|---------------------------|-------------------------------|
| Package Checking | None | Comprehensive check with helpful error messages |
| Data Loading | GitHub URLs only | Local files first, GitHub fallback |
| Error Handling | Basic | Robust with informative messages |
| Offline Capability | None | Works without internet (limited functionality) |
| Output Management | Assumes directories exist | Creates directories as needed |
| Progress Feedback | Minimal | Detailed progress messages |

### Troubleshooting

**"Package not found" error:**
- Install missing packages: `install.packages("package_name")`

**"File not found" error:**
- Ensure you're in the workshop directory
- Check that agro-survey-workshop.xlsx exists
- Verify ../maps/full_dataset.csv is accessible

**Geospatial package errors:**
- Install system libraries (see prerequisites above)
- Some mapping features require internet connectivity

**Character encoding issues:**
- Set locale in R: `Sys.setlocale("LC_ALL", "en_US.UTF-8")`

### Technical Notes

- The script uses Ukrainian administrative division data
- Geographic analysis requires polygon shapefiles (downloaded from GitHub)
- Statistical models examine factors like population size, community type, and area
- Maps are created using the tmap package with both static and interactive options

For detailed instructions in Ukrainian, see ІНСТРУКЦІЯ_WORKSHOP_MAPS.md