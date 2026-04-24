# VTPEH 6270 

This repository contains code and materials for VTPEH 6270 coursework. The 
project examines the relationship between geography and pediatric blood lead 
levels across New York State counties over time, culminating in an interactive 
Shiny application.

## Author

Cam Lincoln, MPH '26  
Contact: cal386@cornell.edu

---

## Project Description

This repository contains data processing scripts and datasets for the VTPEH 
6270 course. The project processes NYS Department of Health childhood blood 
lead testing data to examine trends in elevated pediatric blood lead levels 
across New York State counties from 2000 to 2024. Note: NYC is excluded from 
this dataset per the data source.

---

## Research Question

> Is there a decrease in reported positive cases of elevated pediatric blood 
> lead level over time in years, across counties in New York State?

Earlier coursework (HW4) examined this question at the ZIP code level within 
Nassau County specifically. A multiple linear regression controlling for ZIP 
code found a statistically significant downward trend in new case percentage 
over time (β = -1.90, SE = 0.48, p < 0.001), though this estimate was 
influenced by outlying values in the year 2000. A sensitivity analysis 
excluding 2000 confirmed a more modest but still significant decline 
(β = -0.56, SE = 0.20, p = 0.013). The Shiny app extends this exploration 
to all NYS counties interactively.

---

## Shiny App

An interactive Shiny app has been developed to visualize elevated blood lead 
incidence rates per 1,000 children tested, by county and year.

🔗 **Live App:** https://cal386.shinyapps.io/app-1/

### App Features

- **Interactive county map** — choropleth heatmap of NYS counties colored 
  by rate per 1,000 children tested (white = low, dark red = high)
- **Year slider** — scrub or animate through years to observe trends over time
- **County detail panel** — click any county to see total tests, elevated 
  cases, and rate for the selected year
- **About section** — background and public health context for the project
- **AI disclosure** — transparent accounting of AI assistance used in 
  development

---

## Running the App Locally

1. Clone this repository
2. Install the following R packages if needed:
```r
install.packages(c("shiny", "leaflet", "tigris", "sf", "dplyr", "stringr"))
```
3. Run `prepare_data.R` once to generate `county_lead.rds`
4. Open `App-1/app.R` in RStudio and click **Run App**

---

## Data Sources

- **Primary dataset:** New York State Department of Health — Childhood Blood 
  Lead Testing and Elevated Incidence by ZIP Code, Beginning 2000  
  https://health.data.ny.gov/Health/Childhood-Blood-Lead-Testing-and-Elevated-Incidenc/d54z-enu8/about_data

- **FIPS crosswalk:** New York State ZIP Codes — County FIPS Cross-Reference  
  https://data.ny.gov

---

## AI Tool Disclosure

Claude (Anthropic, claude.ai) was used to assist with Shiny app development, 
including UI layout, Leaflet map integration, CSS styling, and debugging of 
deployment errors on ShinyApps.io. Data cleaning, research question 
development, statistical analysis, and all written content are the author's 
own work.
