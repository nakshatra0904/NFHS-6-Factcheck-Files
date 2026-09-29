source("R/common.R")
questions <- c("q1_schooling_stunting", "q2_marriage_motherhood",
               "q3_digital_gender", "q4_nutrition_transition")
stat_one <- function(values, question, variable) {
  data.frame(question = question, variable = variable, n = length(values),
             mean = mean(values), median = median(values), sd = sd(values),
             p25 = unname(quantile(values, .25)),
             p75 = unname(quantile(values, .75)),
             min = min(values), max = max(values),
             n_positive = sum(values > 0))
}
all_stats <- list()
for (q in questions) {
  d <- read.csv(paste0("results/", q, "_observations.csv"))
  all_stats[[length(all_stats) + 1]] <- stat_one(d$x, q, "predictor_x")
  all_stats[[length(all_stats) + 1]] <- stat_one(d$y, q, "outcome_y")
  png(paste0("figures/", q, "_distributions.png"),
      width = 1450, height = 700, res = 150)
  par(mfrow = c(1, 2), mar = c(5, 5, 4, 1), family = "sans")
  for (v in c("x", "y")) {
    hist(d[[v]], breaks = "FD", col = "#9AB6BC", border = "white",
         main = paste(ifelse(v == "x", "Predictor", "Outcome"), "distribution"),
         xlab = "Percentage points", ylab = "Number of states")
    abline(v = mean(d[[v]]), col = "#B45E3F", lwd = 2)
    mtext(sprintf("Mean %.2f | Median %.2f | SD %.2f",
                  mean(d[[v]]), median(d[[v]]), sd(d[[v]])),
          side = 3, line = .25, cex = .8)
  }
  dev.off()
}
desc <- do.call(rbind, all_stats)
write.csv(desc, "results/descriptive_statistics.csv", row.names = FALSE)

ids <- c(12, 13, 14, 15, 16, 19, 69, 76)
short <- c("Women 10+ years schooling", "Men 10+ years schooling",
           "Women ever used internet", "Men ever used internet",
           "Women married before 18", "Teen mothers or pregnant",
           "Under-five stunting", "Women overweight or obese")
national <- do.call(rbind, lapply(seq_along(ids), function(i) {
  r <- raw[raw$unit == "India" & raw$indicator_id == ids[i], ]
  old <- num(r$nfhs5_total)
  new <- num(r$nfhs6_total)
  data.frame(indicator_id = ids[i], indicator = short[i],
             nfhs5_total_pct = old, nfhs6_total_pct = new,
             change_pp = new - old)
}))
write.csv(national, "results/india_selected_indicators.csv", row.names = FALSE)
png("figures/india_selected_changes.png", width = 1550, height = 850, res = 150)
par(mar = c(5, 15, 4, 2), family = "sans")
at <- rev(seq_len(nrow(national)))
plot(NA, xlim = c(0, 100), ylim = c(.5, nrow(national) + .5),
     yaxt = "n", xlab = "India percentage (%)", ylab = "",
     main = "Selected India indicators: NFHS-5 and NFHS-6")
axis(2, at = at, labels = national$indicator, las = 2, cex.axis = .85)
segments(national$nfhs5_total_pct, at, national$nfhs6_total_pct, at,
         col = "#BBC5C5", lwd = 2)
points(national$nfhs5_total_pct, at, pch = 1, cex = 1.3,
       col = "#B45E3F", lwd = 2)
points(national$nfhs6_total_pct, at, pch = 19, cex = 1.2,
       col = "#1D5266")
legend("bottomright", c("NFHS-5 total (2019-21)", "NFHS-6 total (2023-24)"),
       pch = c(1, 19), col = c("#B45E3F", "#1D5266"), bty = "n")
dev.off()

# Both trends are positive in every state; show their size without implying
# that the populations or mechanisms are identical.
trans <- read.csv("results/q4_nutrition_transition_observations.csv")
trans <- trans[order(trans$x), ]
png("figures/state_nutrition_changes.png", width = 1500, height = 1350,
    res = 150)
par(mar = c(5, 13, 4, 2), family = "sans")
at <- seq_len(nrow(trans))
plot(NA, xlim = c(0, max(trans$x, trans$y) + 1), ylim = c(.5, 27.5),
     yaxt = "n", xlab = "Change from NFHS-5 to NFHS-6 (percentage points)",
     ylab = "", main = "Two nutrition trends across 27 states")
axis(2, at = at, labels = trans$unit, las = 2, cex.axis = .76)
segments(trans$x, at, trans$y, at, col = "#CCD3D3")
points(trans$x, at, pch = 19, col = "#1D5266")
points(trans$y, at, pch = 17, col = "#B45E3F")
legend("bottomright", c("Stunting decline", "Women's overweight rise"),
       pch = c(19, 17), col = c("#1D5266", "#B45E3F"), bty = "n")
dev.off()

print(desc, row.names = FALSE)
print(national, row.names = FALSE)
overview <- c(
  "State-level descriptive summary (n = 27)",
  "Means and medians are unweighted across states; units are percentage points.",
  sprintf("Q1 schooling gap mean %.2f, median %.2f; stunting gap mean %.2f, median %.2f",
          desc$mean[1], desc$median[1], desc$mean[2], desc$median[2]),
  sprintf("Q2 child-marriage gap mean %.2f; teenage motherhood gap mean %.2f",
          desc$mean[3], desc$mean[4]),
  sprintf("Q3 schooling gender gap mean %.2f; internet gender gap mean %.2f",
          desc$mean[5], desc$mean[6]),
  sprintf("Q4 stunting decline mean %.2f; women's overweight rise mean %.2f",
          desc$mean[7], desc$mean[8]),
  sprintf("Q4 states with both changes positive: %d of 27",
          sum(read.csv("results/q4_nutrition_transition_observations.csv")$x > 0 &
              read.csv("results/q4_nutrition_transition_observations.csv")$y > 0)),
  sprintf("India stunting: %.1f%% to %.1f%% (NFHS-5 to 6)",
          national$nfhs5_total_pct[national$indicator_id == 69],
          national$nfhs6_total_pct[national$indicator_id == 69]),
  sprintf("India women's overweight: %.1f%% to %.1f%%",
          national$nfhs5_total_pct[national$indicator_id == 76],
          national$nfhs6_total_pct[national$indicator_id == 76]),
  "Source: IIPS NFHS-6 India and State/UT fact sheets."
)
writeLines(overview, "results/descriptive_R_output.txt")
save_result_image("descriptives", "Descriptive statistics", overview)
