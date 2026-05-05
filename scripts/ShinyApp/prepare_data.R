# Run this locally once to generate county_lead.rds
setwd("/Users/clincoln/Desktop/vtpeh-6270/App-1")

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)

data_lead <- read.csv(
  "../Childhood_Blood_Lead_Testing_and_Elevated_Incidence_by_Zip_Code__Beginning_2000_20260205.csv")

data_lead$County.Code <- as.character(data_lead$County.Code)
data_lead$Zip <- as.character(data_lead$Zip)
data_lead$Tests <- as.numeric(data_lead$Tests)
data_lead$Less.than.5.mcg.dL <- as.numeric(data_lead$Less.than.5.mcg.dL)

data_lead_full <- data_lead %>%
  rename(
    "Total_Elevated_Blood_Levels" = "Total.Elevated.Blood.Levels.",
    "New_Case_Percentage"         = "Percent",
    "Rate_per_1000"               = "Rate.per.1.000",
    "ZIP_Location"                = "Zip.Code.Location",
    "County_Location"             = "County.Location",
    "County"                      = "County"
  )

county_lead <- data_lead_full %>%
  group_by(County, Year) %>%
  summarise(
    Total_Tests    = sum(Tests, na.rm = TRUE),
    Total_Elevated = sum(Total_Elevated_Blood_Levels, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(Rate_per_1000 = (Total_Elevated / Total_Tests) * 1000)

fips_crosswalk <- read.csv(
  "../New_York_State_ZIP_Codes-County_FIPS_Cross-Reference_20260421.csv",
  colClasses = "character"
)

county_fips_lookup <- fips_crosswalk %>%
  select(County.Name, County.FIPS) %>%
  distinct() %>%
  mutate(County.Name = trimws(County.Name))

county_lead <- county_lead %>%
  mutate(County = trimws(County)) %>%
  left_join(county_fips_lookup, by = c("County" = "County.Name"))

# Save into App-1 folder so app.R can find it
saveRDS(county_lead, "county_lead.rds")
cat("Done! county_lead.rds saved to App-1/\n")
