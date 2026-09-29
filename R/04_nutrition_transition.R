source("R/common.R")
# Q4: Compare change in child stunting (a decline is positive) with change
# in women overweight/obesity (an increase is positive) across survey rounds.
# These refer to different populations; the test is geographic coexistence.
a <- combine_indicators(indicator(69, "stunt"), indicator(76, "obesity"))
a <- a[a$unit %in% states, ]
a$x <- a$stunt_total5 - a$stunt_total6
a$y <- a$obesity_total6 - a$obesity_total5
run_case(
  "q4_nutrition_transition",
  "Q4: Child stunting decline and women's overweight rise",
  a,
  "Decline in under-five stunting, NFHS-5 to 6 (percentage points)",
  "Rise in women's overweight/obesity, NFHS-5 to 6 (percentage points)",
  "Interpretation: two different populations and survey rounds."
)
