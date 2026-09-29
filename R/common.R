# Shared functions for the four NFHS-6 portfolio analyses.
# Run scripts from the project root. Requires only base R and recommended MASS.
options(stringsAsFactors = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)
dir.create("screenshots", showWarnings = FALSE)

raw <- read.csv("data/nfhs6_state_indicators.csv", check.names = FALSE)
stopifnot(nrow(raw) == 3636L, length(unique(raw$unit)) == 36L,
          all(table(raw$unit) == 101L))
uts <- c("Andaman and Nicobar Islands", "Chandigarh",
         "Dadra and Nagar Haveli and Daman and Diu", "Jammu and Kashmir",
         "Ladakh", "Lakshadweep", "NCT of Delhi", "Puducherry")
states <- setdiff(unique(raw$unit), c("India", uts))
stopifnot(length(states) == 27L)

num <- function(x) {
  x <- trimws(as.character(x))
  x[x == "*"] <- NA_character_
  suppressWarnings(as.numeric(gsub("[()]", "", x)))
}

indicator <- function(id, prefix) {
  a <- raw[raw$indicator_id == id,
           c("unit", "nfhs6_urban", "nfhs6_rural", "nfhs6_total",
             "nfhs5_total")]
  names(a)[-1] <- paste0(prefix, c("_urban6", "_rural6",
                                    "_total6", "_total5"))
  for (j in 2:5) a[[j]] <- num(a[[j]])
  a
}

combine_indicators <- function(...) {
  parts <- list(...)
  Reduce(function(a, b) merge(a, b, by = "unit", all = FALSE), parts)
}

hc3 <- function(fit) {
  X <- model.matrix(fit)
  e <- residuals(fit)
  h <- hatvalues(fit)
  bread <- solve(crossprod(X))
  bread %*% crossprod(X, X * as.vector((e / (1 - h))^2)) %*% bread
}

linear_stats <- function(fit) {
  b <- unname(coef(fit)["x"])
  se <- unname(sqrt(diag(hc3(fit)))["x"])
  cutoff <- qt(.975, df.residual(fit))
  c(beta = b, hc3_se = se, ci_low = b - cutoff * se,
    ci_high = b + cutoff * se, p_hc3 = 2 * pt(-abs(b / se), df.residual(fit)),
    r_squared = summary(fit)$r.squared)
}

fit_one <- function(kind, dat) {
  if (kind == "No predictor") return(lm(y ~ 1, data = dat))
  if (kind == "Linear OLS") return(lm(y ~ x, data = dat))
  if (kind == "Quadratic OLS") return(lm(y ~ x + I(x^2), data = dat))
  if (kind == "Huber linear") return(MASS::rlm(y ~ x, data = dat, maxit = 100))
  stop("Unknown model")
}

loo_errors <- function(kind, dat) {
  vapply(seq_len(nrow(dat)), function(i) {
    fit <- fit_one(kind, dat[-i, , drop = FALSE])
    as.numeric(dat$y[i] - predict(fit, newdata = dat[i, , drop = FALSE]))
  }, numeric(1))
}

comparison <- function(dat, question) {
  kinds <- c("No predictor", "Linear OLS", "Quadratic OLS", "Huber linear")
  scores <- lapply(kinds, function(kind) {
    fit <- fit_one(kind, dat)
    e <- loo_errors(kind, dat)
    data.frame(question = question, model = kind, n = nrow(dat),
               loo_rmse = sqrt(mean(e^2)), loo_mae = mean(abs(e)),
               bic = if (kind != "Huber linear") BIC(fit) else NA_real_,
               in_sample_r2 = if (kind != "Huber linear")
                 summary(fit)$r.squared else NA_real_)
  })
  out <- do.call(rbind, scores)
  out$rank_rmse <- rank(out$loo_rmse, ties.method = "first")
  out
}

save_scatter <- function(dat, code, title, xlab, ylab, note) {
  png(paste0("figures/", code, "_scatter.png"), width = 1350,
      height = 950, res = 160)
  par(mar = c(6.5, 6, 4.5, 2), family = "sans")
  plot(dat$x, dat$y, pch = 19, cex = 1.15, col = "#1D5266",
       xlab = xlab, ylab = ylab, main = title)
  abline(h = 0, v = 0, lty = 3, col = "gray65")
  xs <- seq(min(dat$x), max(dat$x), length.out = 200)
  ols <- fit_one("Linear OLS", dat)
  quad <- fit_one("Quadratic OLS", dat)
  huber <- fit_one("Huber linear", dat)
  lines(xs, predict(ols, newdata = data.frame(x = xs)), lwd = 2,
        col = "#B45E3F")
  lines(xs, predict(quad, newdata = data.frame(x = xs)), lwd = 2,
        lty = 2, col = "#637B66")
  lines(xs, predict(huber, newdata = data.frame(x = xs)), lwd = 2,
        lty = 3, col = "#615B78")
  legend("topleft", c("States", "Linear OLS", "Quadratic OLS",
                      "Huber linear"),
         pch = c(19, NA, NA, NA), lty = c(NA, 1, 2, 3),
         lwd = c(NA, 2, 2, 2),
         col = c("#1D5266", "#B45E3F", "#637B66", "#615B78"),
         bty = "n")
  mtext(note, side = 1, line = 5.1, cex = .75)
  dev.off()
}

save_comparison_plot <- function(comp, code, title) {
  png(paste0("figures/", code, "_model_comparison.png"),
      width = 1200, height = 850, res = 150)
  par(mar = c(8, 5, 4, 2), family = "sans")
  colors <- ifelse(comp$rank_rmse == 1, "#1D5266", "#AAB6B7")
  b <- barplot(comp$loo_rmse, names.arg = comp$model, las = 2, col = colors,
               border = NA, ylab = "Leave-one-state-out RMSE (percentage points)",
               main = title, ylim = c(0, max(comp$loo_rmse) * 1.22))
  text(b, comp$loo_rmse, labels = sprintf("%.2f", comp$loo_rmse),
       pos = 3, cex = .9)
  mtext("Lower is better for prediction; this does not establish causality.",
        side = 1, line = 6.5, cex = .75)
  dev.off()
}

save_result_image <- function(code, title, lines) {
  png(paste0("screenshots/", code, "_R_results.png"),
      width = 1400, height = 1000, res = 160)
  par(mar = c(0, 0, 0, 0), family = "mono")
  plot.new()
  text(.05, .94, title, adj = c(0, .5), font = 2, cex = 1.18,
       col = "#1D5266")
  ys <- seq(.84, .08, length.out = length(lines))
  text(.05, ys, lines, adj = c(0, .5), cex = .86, col = "#20292D")
  dev.off()
}

run_case <- function(code, title, data, xlab, ylab, interpretation) {
  dat <- data[is.finite(data$x) & is.finite(data$y),
              c("unit", "x", "y"), drop = FALSE]
  dat <- dat[order(dat$unit), , drop = FALSE]
  stopifnot(nrow(dat) == 27L, !anyDuplicated(dat$unit))
  lin <- fit_one("Linear OLS", dat)
  robust <- fit_one("Huber linear", dat)
  stat <- linear_stats(lin)
  comp <- comparison(dat, code)
  best <- comp$model[which.min(comp$loo_rmse)]
  loo_betas <- vapply(seq_len(nrow(dat)), function(i)
    unname(coef(lm(y ~ x, data = dat[-i, , drop = FALSE]))["x"]),
    numeric(1))
  result <- data.frame(
    question = code, n = nrow(dat), x_mean = mean(dat$x), y_mean = mean(dat$y),
    ols_beta = unname(stat["beta"]), hc3_se = unname(stat["hc3_se"]),
    ci_low = unname(stat["ci_low"]), ci_high = unname(stat["ci_high"]),
    p_hc3 = unname(stat["p_hc3"]),
    r_squared = unname(stat["r_squared"]),
    huber_beta = unname(coef(robust)["x"]),
    loo_beta_min = min(loo_betas), loo_beta_max = max(loo_betas),
    best_loo_rmse_model = best,
    best_loo_rmse = min(comp$loo_rmse))
  write.csv(dat, paste0("results/", code, "_observations.csv"),
            row.names = FALSE)
  write.csv(result, paste0("results/", code, "_summary.csv"),
            row.names = FALSE)
  write.csv(comp, paste0("results/", code, "_model_comparison.csv"),
            row.names = FALSE)
  lines <- c(
    paste("QUESTION:", title),
    paste("State observations:", nrow(dat)),
    sprintf("Linear OLS beta: %.3f percentage points per point of x", stat["beta"]),
    sprintf("HC3 robust SE: %.3f", stat["hc3_se"]),
    sprintf("HC3 95%% interval: [%.3f, %.3f]", stat["ci_low"], stat["ci_high"]),
    sprintf("HC3 p-value (descriptive): %.4f", stat["p_hc3"]),
    sprintf("Linear OLS R-squared: %.3f", stat["r_squared"]),
    sprintf("Huber linear beta: %.3f", coef(robust)["x"]),
    sprintf("Leave-one-state-out beta range: [%.3f, %.3f]",
            min(loo_betas), max(loo_betas)),
    paste("Lowest prediction RMSE:", best),
    paste("LOO RMSE:", paste(sprintf("%s %.2f", comp$model, comp$loo_rmse),
                           collapse = " | ")),
    interpretation,
    "Source: IIPS NFHS-6 India and State/UT fact sheets."
  )
  writeLines(lines, paste0("results/", code, "_R_output.txt"))
  save_scatter(dat, code, title, xlab, ylab,
               "Source: IIPS NFHS-6 fact sheets | 27 states | area-level estimates")
  save_comparison_plot(comp, code,
                       paste0(toupper(substr(code, 1, 2)),
                              ": Leave-one-state-out model comparison"))
  save_result_image(code, title, lines)
  print(result, row.names = FALSE)
  invisible(result)
}
