source("R/common.R")
# Diagnostics of the linear summaries. Marginal x/y distributions are not
# assumed to match; residual behavior and sensitivity matter instead.
codes <- c("q1_schooling_stunting", "q2_marriage_motherhood",
           "q3_digital_gender", "q4_nutrition_transition")
short <- c("Q1 Schooling and stunting gaps", "Q2 Marriage and motherhood gaps",
           "Q3 Schooling and internet gaps", "Q4 Nutrition changes")
datasets <- lapply(codes, function(code)
  read.csv(paste0("results/", code, "_observations.csv")))
fits <- lapply(datasets, function(dat) lm(y ~ x, data = dat))

rows <- lapply(seq_along(codes), function(j) {
  dat <- datasets[[j]]
  fit <- fits[[j]]
  e <- residuals(fit)
  aux <- lm(I(e^2) ~ dat$x)
  # A one-predictor Breusch-Pagan screening statistic; low power at n=27.
  bp_p <- pchisq(nrow(dat) * summary(aux)$r.squared,
                df = 1, lower.tail = FALSE)
  loo <- vapply(seq_len(nrow(dat)), function(i)
    unname(coef(lm(y ~ x, data = dat[-i, , drop = FALSE]))["x"]),
    numeric(1))
  student <- rstudent(fit)
  cook <- cooks.distance(fit)
  stat <- linear_stats(fit)
  data.frame(question = codes[j], n = nrow(dat),
             conventional_slope_se = unname(summary(fit)$coefficients["x", "Std. Error"]),
             hc3_slope_se = unname(stat["hc3_se"]),
             shapiro_residual_p = shapiro.test(e)$p.value,
             bp_spread_p = bp_p,
             max_abs_studentized_residual = max(abs(student)),
             largest_residual_state = dat$unit[which.max(abs(student))],
             max_cooks_distance = max(cook),
             most_influential_state = dat$unit[which.max(cook)],
             loo_slope_min = min(loo), loo_slope_max = max(loo))
})
diagnostics <- do.call(rbind, rows)
write.csv(diagnostics, "results/model_diagnostics.csv", row.names = FALSE)

png("figures/regression_residuals.png", width = 1600, height = 1150,
    res = 160)
par(mfrow = c(2, 2), mar = c(4.7, 5.3, 3.4, 1.4), oma = c(2.0, 0, 0, 0),
    family = "sans")
for (j in seq_along(codes)) {
  fit <- fits[[j]]
  z <- rstudent(fit)
  plot(fitted(fit), z, pch = 19, col = "#1D5266", cex = .95,
       ylim = range(c(z, -2.2, 2.2)),
       xlab = "Fitted outcome (percentage points)",
       ylab = "Studentized residual (unitless)",
       main = short[j], cex.main = 1.02)
  abline(h = 0, col = "#637B66", lwd = 1.3)
  abline(h = c(-2, 2), col = "#B45E3F", lty = 2)
}
mtext("Source: IIPS NFHS-6 fact sheets | 27 states per question | dashed lines: residual = +/-2",
      side = 1, outer = TRUE, line = .5, cex = .77)
dev.off()

png("figures/regression_residual_qq.png", width = 1600, height = 1150,
    res = 160)
par(mfrow = c(2, 2), mar = c(4.7, 5.3, 3.4, 1.4), oma = c(2.0, 0, 0, 0),
    family = "sans")
for (j in seq_along(codes)) {
  qqnorm(rstudent(fits[[j]]), pch = 19, col = "#1D5266", cex = .95,
         xlab = "Theoretical normal quantile (SD units)",
         ylab = "Studentized residual (unitless)",
         main = short[j], cex.main = 1.02)
  qqline(rstudent(fits[[j]]), col = "#B45E3F", lwd = 1.6)
}
mtext("Source: IIPS NFHS-6 fact sheets | 27 states per question | departure from the line suggests non-normal residuals",
      side = 1, outer = TRUE, line = .5, cex = .77)
dev.off()

print(diagnostics, row.names = FALSE)
