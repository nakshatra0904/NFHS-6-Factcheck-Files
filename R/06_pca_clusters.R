source("R/common.R")
# Exploratory state profiles. PCA/clustering are descriptive; no treatment,
# instrument, exogeneity claim, or individual-level interpretation is made.
features <- data.frame(
  unit = states,
  women_schooling = indicator(12, "v")$v_total6[match(states, indicator(12, "v")$unit)],
  women_internet = indicator(14, "v")$v_total6[match(states, indicator(14, "v")$unit)],
  child_marriage = indicator(16, "v")$v_total6[match(states, indicator(16, "v")$unit)],
  anc_four_visits = indicator(30, "v")$v_total6[match(states, indicator(30, "v")$unit)],
  adequate_child_diet = indicator(68, "v")$v_total6[match(states, indicator(68, "v")$unit)],
  child_stunting = indicator(69, "v")$v_total6[match(states, indicator(69, "v")$unit)],
  women_overweight = indicator(76, "v")$v_total6[match(states, indicator(76, "v")$unit)]
)
X <- as.matrix(features[-1])
stopifnot(nrow(X) == 27L, ncol(X) == 7L, all(is.finite(X)))
Z <- scale(X)
colnames(Z) <- colnames(X)
write.csv(features, "results/pca_input_state_profiles.csv", row.names = FALSE)
write.csv(data.frame(unit = states, Z), "results/pca_standardized.csv",
          row.names = FALSE)

pca <- prcomp(Z, center = FALSE, scale. = FALSE)
if (pca$rotation["women_schooling", 1] < 0) {
  pca$rotation[, 1] <- -pca$rotation[, 1]
  pca$x[, 1] <- -pca$x[, 1]
}
variance <- pca$sdev^2
explained <- variance / sum(variance)
loadings <- data.frame(variable = rownames(pca$rotation),
                       pca$rotation, row.names = NULL)
components <- data.frame(component = paste0("PC", seq_along(explained)),
                         eigenvalue = variance,
                         variance_share = explained,
                         cumulative_share = cumsum(explained))
write.csv(loadings, "results/pca_loadings.csv", row.names = FALSE)
write.csv(components, "results/pca_variance.csv", row.names = FALSE)

# Parallel analysis asks whether an observed component exceeds the 95th
# percentile from data with each feature independently permuted.
set.seed(20260930)
null_eigen <- replicate(500, {
  permuted <- apply(Z, 2, sample)
  prcomp(permuted, center = FALSE, scale. = FALSE)$sdev^2
})
null95 <- apply(null_eigen, 1, quantile, probs = .95)
components$parallel_null95 <- null95
components$above_parallel_null95 <- variance > null95
write.csv(components, "results/pca_variance.csv", row.names = FALSE)

# KMO checks whether correlations are concentrated in shared rather than
# partial associations. It is diagnostic, not a proof of latent structure.
R <- cor(Z)
P <- solve(R)
partial <- -P / sqrt(outer(diag(P), diag(P)))
diag(partial) <- 0
kmo <- sum(R[upper.tri(R)]^2) /
  (sum(R[upper.tri(R)]^2) + sum(partial[upper.tri(partial)]^2))

silhouette_mean <- function(z, group) {
  d <- as.matrix(dist(z))
  mean(vapply(seq_len(nrow(z)), function(i) {
    same <- which(group == group[i] & seq_along(group) != i)
    if (length(same) == 0) return(0)
    a <- mean(d[i, same])
    b <- min(vapply(setdiff(unique(group), group[i]),
                    function(g) mean(d[i, group == g]), numeric(1)))
    (b - a) / max(a, b)
  }, numeric(1)))
}
ari <- function(a, b) {
  tab <- table(a, b)
  pair <- function(n) sum(n * (n - 1) / 2)
  same <- pair(tab)
  row_pairs <- pair(rowSums(tab))
  col_pairs <- pair(colSums(tab))
  total <- nrow(X) * (nrow(X) - 1) / 2
  expected <- row_pairs * col_pairs / total
  denominator <- (row_pairs + col_pairs) / 2 - expected
  if (denominator == 0) return(NA_real_)
  (same - expected) / denominator
}

set.seed(20260930)
cluster_models <- lapply(2:4, function(k)
  kmeans(Z, centers = k, nstart = 100, iter.max = 100))
quality <- data.frame(
  k = 2:4,
  mean_silhouette = vapply(cluster_models, function(f)
    silhouette_mean(Z, f$cluster), numeric(1))
)
best_index <- which.max(quality$mean_silhouette)
best_k <- quality$k[best_index]
groups <- cluster_models[[best_index]]$cluster
stability <- vapply(seq_len(ncol(Z)), function(j) {
  z_minus <- scale(X[, -j, drop = FALSE])
  set.seed(20260930)
  altered <- kmeans(z_minus, centers = best_k, nstart = 100,
                    iter.max = 100)$cluster
  ari(groups, altered)
}, numeric(1))
quality$feature_deletion_mean_ari <- NA_real_
quality$feature_deletion_mean_ari[best_index] <- mean(stability)
write.csv(quality, "results/cluster_quality.csv", row.names = FALSE)
write.csv(data.frame(omitted_feature = colnames(X),
                     adjusted_rand_index = stability),
          "results/cluster_feature_stability.csv", row.names = FALSE)
membership <- data.frame(unit = states, cluster = groups,
                         pc1 = pca$x[, 1], pc2 = pca$x[, 2])
write.csv(membership, "results/cluster_membership.csv", row.names = FALSE)
profiles <- aggregate(as.data.frame(Z), by = list(cluster = groups), FUN = mean)
write.csv(profiles, "results/cluster_profiles_z.csv", row.names = FALSE)

# PCA sensitivity to omitting one state; align arbitrary component signs.
pc1_loading_similarity <- vapply(seq_len(nrow(Z)), function(i) {
  reduced <- prcomp(Z[-i, , drop = FALSE], center = FALSE,
                    scale. = FALSE)$rotation[, 1]
  abs(cor(pca$rotation[, 1], reduced))
}, numeric(1))
diagnostics <- data.frame(
  metric = c("n_states", "n_features", "KMO", "PC1_variance_share",
             "PC2_variance_share", "parallel_components_above_null95",
             "pc1_leave_one_state_out_min_loading_correlation",
             "chosen_k_by_silhouette", "chosen_mean_silhouette",
             "mean_feature_deletion_ARI"),
  value = c(nrow(Z), ncol(Z), kmo, explained[1], explained[2],
            sum(components$above_parallel_null95),
            min(pc1_loading_similarity), best_k,
            quality$mean_silhouette[best_index], mean(stability))
)
write.csv(diagnostics, "results/multivariate_diagnostics.csv", row.names = FALSE)

png("figures/pca_scree_parallel.png", width = 1250, height = 820, res = 150)
par(mar = c(5, 5, 4, 2), family = "sans")
plot(seq_along(variance), variance, type = "b", pch = 19, lwd = 2,
     col = "#1D5266", xlab = "Principal component",
     ylab = "Eigenvalue", main = "State-profile PCA and permutation benchmark",
     ylim = range(c(variance, null95)))
lines(seq_along(null95), null95, type = "b", pch = 1, lty = 2,
      lwd = 2, col = "#B45E3F")
legend("topright", c("Observed", "95th percentile permuted"),
       lty = c(1, 2), pch = c(19, 1),
       col = c("#1D5266", "#B45E3F"), bty = "n")
dev.off()

png("figures/pca_loadings.png", width = 1300, height = 850, res = 150)
par(mar = c(5, 13, 4, 2), family = "sans")
vals <- loadings$PC1
at <- seq_along(vals)
plot(vals, at, pch = 19, cex = 1.3, col = "#1D5266",
     xlim = range(c(vals, 0)) + c(-.08, .08), yaxt = "n",
     xlab = "PC1 loading (sign oriented toward women's schooling)",
     ylab = "", main = "Which indicators define the first component?")
axis(2, at = at, labels = loadings$variable, las = 2)
segments(0, at, vals, at, col = "#9AB6BC", lwd = 2)
abline(v = 0, lty = 3, col = "gray65")
dev.off()

png("figures/state_pca_clusters.png", width = 1450, height = 1050, res = 150)
par(mar = c(5, 5, 4, 2), family = "sans")
palette <- c("#1D5266", "#B45E3F", "#637B66", "#615B78")
plot(membership$pc1, membership$pc2, pch = 19, cex = 1.3,
     col = palette[membership$cluster], xlab = "PC1 score",
     ylab = "PC2 score",
     main = paste("State profiles; exploratory k-means, k =", best_k))
labelled <- membership$unit %in% c(
  "Bihar", "Kerala", "Mizoram", "West Bengal", "Tripura",
  "Tamil Nadu", "Sikkim", "Meghalaya"
)
text(membership$pc1[labelled], membership$pc2[labelled],
     labels = membership$unit[labelled], pos = 3, cex = .72,
     col = "#303638")
abline(h = 0, v = 0, lty = 3, col = "gray70")
legend("bottomleft", paste("Cluster", sort(unique(groups))),
       pch = 19, col = palette[sort(unique(groups))], bty = "n")
dev.off()

png("figures/cluster_profiles.png", width = 1350, height = 900, res = 150)
par(mar = c(5, 13, 4, 2), family = "sans")
mat <- as.matrix(profiles[-1])
barplot(mat, beside = TRUE, horiz = TRUE, las = 2,
        col = palette[seq_len(best_k)], border = NA,
        names.arg = colnames(X), xlab = "Cluster mean, standardized z-score",
        main = "Cluster profiles across seven indicators")
abline(v = 0, col = "gray55")
mtext("Blue: Cluster 1    Orange: Cluster 2", side = 3,
      line = .25, cex = .85)
dev.off()

lines <- c(
  "Exploratory PCA and clustering of 27 state profiles",
  "Inputs: schooling, internet, child marriage, ANC4, child diet,",
  "        child stunting, women's overweight; standardized within states.",
  sprintf("KMO: %.3f", kmo),
  sprintf("PC1/PC2 variance shares: %.1f%% / %.1f%%",
          100 * explained[1], 100 * explained[2]),
  sprintf("Components above permutation 95th percentile: %d",
          sum(components$above_parallel_null95)),
  sprintf("Minimum leave-one-state-out PC1 loading similarity: %.3f",
          min(pc1_loading_similarity)),
  paste("Mean silhouette by k:",
        paste(sprintf("%d %.3f", quality$k, quality$mean_silhouette),
              collapse = " | ")),
  sprintf("Chosen k: %d; feature-deletion mean ARI: %.3f",
          best_k, mean(stability)),
  "Interpret clusters as exploratory profiles, not fixed state types.",
  "Source: IIPS NFHS-6 India and State/UT fact sheets."
)
writeLines(lines, "results/pca_cluster_R_output.txt")
save_result_image("q5_pca_clusters", "Q5: Exploratory state profiles", lines)
print(diagnostics, row.names = FALSE)
print(quality, row.names = FALSE)
