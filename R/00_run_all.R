# Run from the project root: Rscript R/00_run_all.R
scripts <- c("R/01_schooling_stunting.R", "R/02_marriage_motherhood.R",
             "R/03_digital_gender.R", "R/04_nutrition_transition.R")
for (file in scripts) {
  cat("\nRunning", file, "\n")
  source(file, local = new.env(parent = globalenv()))
}
files <- c("q1_schooling_stunting", "q2_marriage_motherhood",
           "q3_digital_gender", "q4_nutrition_transition")
summaries <- do.call(rbind, lapply(files, function(name)
  read.csv(paste0("results/", name, "_summary.csv"))))
comparisons <- do.call(rbind, lapply(files, function(name)
  read.csv(paste0("results/", name, "_model_comparison.csv"))))
write.csv(summaries, "results/all_questions_summary.csv", row.names = FALSE)
write.csv(comparisons, "results/all_model_comparisons.csv", row.names = FALSE)
source("R/05_descriptives.R", local = new.env(parent = globalenv()))
source("R/06_pca_clusters.R", local = new.env(parent = globalenv()))
writeLines(capture.output(sessionInfo()), "results/R_session_info.txt")
cat("\nAll analyses completed. Combined outputs are in results/.\n")
