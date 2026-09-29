source("R/common.R")
# Q3: Both gaps compare men and women, ages 15-49 in the adult indicators.
# Internet is ever-use, not current use or digital skill.
a <- combine_indicators(indicator(12, "school_w"), indicator(13, "school_m"),
                        indicator(14, "internet_w"), indicator(15, "internet_m"))
a <- a[a$unit %in% states, ]
a$x <- a$school_m_total6 - a$school_w_total6
a$y <- a$internet_m_total6 - a$internet_w_total6
run_case(
  "q3_digital_gender",
  "Q3: Schooling and internet gender gaps",
  a,
  "Men minus women with 10+ years schooling (percentage points)",
  "Men minus women ever using internet (percentage points)",
  "Interpretation: education is one correlate of access, not its sole cause."
)
