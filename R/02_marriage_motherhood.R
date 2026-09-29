source("R/common.R")
# Q2: Child marriage refers to women age 20-24 married before age 18.
# Teenage motherhood/pregnancy refers to women age 15-19. They are distinct
# cohorts, so this measures coexistence of area-level gaps, not a pathway.
a <- combine_indicators(indicator(16, "marriage"), indicator(19, "teen"))
a <- a[a$unit %in% states, ]
a$x <- a$marriage_rural6 - a$marriage_urban6
a$y <- a$teen_rural6 - a$teen_urban6
run_case(
  "q2_marriage_motherhood",
  "Q2: Child marriage gap and teenage motherhood gap",
  a,
  "Rural minus urban child marriage (percentage points)",
  "Rural minus urban teenage motherhood/pregnancy (percentage points)",
  "Interpretation: the indicators cover different age cohorts."
)
