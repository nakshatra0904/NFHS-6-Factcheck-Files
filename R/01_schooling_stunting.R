source("R/common.R")
# Q1: A positive y means rural children have more stunting than urban children.
# A positive x means urban women have more schooling than rural women.
# The paired gaps remove shared state-level conditions, but remain ecological.
a <- combine_indicators(indicator(12, "school"), indicator(69, "stunt"))
a <- a[a$unit %in% states, ]
a$x <- a$school_urban6 - a$school_rural6
a$y <- a$stunt_rural6 - a$stunt_urban6
run_case(
  "q1_schooling_stunting",
  "Q1: Schooling gap and child stunting gap",
  a,
  "Urban minus rural women with 10+ years schooling (percentage points)",
  "Rural minus urban under-five stunting (percentage points)",
  "Interpretation: geographic association, not a mother-child effect."
)
