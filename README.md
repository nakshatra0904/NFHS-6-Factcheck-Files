# NFHS-6 state fact sheets

This project turns the [IIPS NFHS-6 India and State/UT fact sheets](https://www.nfhsiips.in/nfhsuser/assets/National%20Family%20Health%20Survey%20%28NFHS-6%29%202023-2024%20Fact%20Sheets.pdf) into an auditable CSV and answers four research questions with R. It also explores seven-dimensional state profiles with principal components and clustering. The source describes the NFHS-6 fact-sheet estimates as provisional. All regression conclusions concern **state-level associations**, not effects on individuals or causal effects.

The [compiled report PDF](report/report.pdf) gives the full interpretation, limitations, tables and figures; its [LaTeX source](report/report.tex) is included. The [data dictionary](data/README.md) defines every column and the indicators used. The [IV note](report/iv_validity_note.md) explains why the fact sheets do not support a credible instrumental-variable design.

## Questions and why they matter

| Question | Current relevance | Main result across 27 states |
| --- | --- | --- |
| Q1. Do wider urban–rural schooling gaps coexist with wider rural–urban child-stunting gaps? | India-level child stunting remains 29.3%; identifying geographic inequalities can guide the next microdata or policy study. | Linear slope **0.392** stunting-gap points per schooling-gap point; HC3 95% interval **0.170–0.614**. |
| Q2. Do rural–urban child-marriage gaps coexist with rural–urban teenage-motherhood gaps? | Child marriage remains 20.1% among women aged 20–24; the two gaps may signal places needing closer study. | Linear slope **0.373**; HC3 interval **0.181–0.566**. The two indicators use different age cohorts. |
| Q3. Are gender gaps in schooling linked to gender gaps in ever having used the internet? | The India-level internet ever-use gap is 16.2 percentage points between men and women aged 15–49. | Linear slope **0.653**; HC3 interval **0.192–1.114**. A quadratic predicts slightly better but its shape is uncertain. |
| Q4. Do states with faster stunting declines also have larger increases in women's overweight? | Stunting fell while women's overweight or obesity rose, indicating concurrent nutrition challenges. | All 27 states show both changes. Their magnitudes are weakly related: slope **0.105**, interval **−0.520–0.729**. A mean-only prediction wins. |

These are selected exploratory questions, so the intervals are not presented as confirmatory tests. The fact sheets lack the outcome-specific sampling variances needed to propagate survey uncertainty. Each state receives equal weight, and the India total and eight Union Territories are excluded from the 27-state regressions.

## Model choices

Each question compares an intercept-only baseline, linear ordinary least squares (OLS), quadratic OLS, and Huber robust linear regression using leave-one-state-out root mean squared prediction error (RMSE). The linear slope and HC3 robust interval are the main *explanatory summary* for Q1–Q3. Huber wins prediction by only 0.04 and 0.06 points for Q1 and Q2, respectively, without changing their conclusions. Q3's quadratic wins prediction by 0.33 points, but the linear and quadratic BIC values are nearly tied; its curvature is exploratory. For Q4, the intercept-only model wins prediction, consistent with little relationship between the two rates of change. Model comparison does not establish causality.

The multivariate section standardizes seven state indicators before PCA and k-means. Parallel analysis supports one strong component; k=2 has the highest tested silhouette, but cluster separation is modest. Stability checks and complete state membership are saved in `results/`. These are descriptive profiles, **not a welfare ranking**: women's overweight loads positively on the first component alongside schooling. No IV or 2SLS result is presented because the fact sheets contain no credible instrument with defensible independence and exclusion restrictions.

## Files

| Path | Contents |
| --- | --- |
| [`data/nfhs6_state_indicators.csv`](data/nfhs6_state_indicators.csv) | Consolidated 3,636-row CSV: 101 indicators for India and 35 States/UTs, raw suppression marks and physical PDF page. |
| [`scripts/extract_nfhs6.py`](scripts/extract_nfhs6.py) | Repeatable PDF extraction and structural checks. |
| [`scripts/check_project.py`](scripts/check_project.py) | Checks CSV completeness, figures, screenshots and LaTeX image references. |
| [`R/00_run_all.R`](R/00_run_all.R) | Runs all four questions, descriptive statistics, PCA and clustering. |
| `R/01_*.R` through `R/04_*.R` | One standalone entry point per regression question. |
| [`R/05_descriptives.R`](R/05_descriptives.R), [`R/06_pca_clusters.R`](R/06_pca_clusters.R) | Distribution summaries and exploratory multivariate analysis. |
| [`results/`](results/) | State-level observations, model comparisons, summary CSVs, diagnostics, text output, R session details. |
| [`figures/`](figures/) | 18 publication-oriented PNG charts; scatterplots, distribution plots, model comparisons, national changes and PCA/cluster displays. |
| [`screenshots/`](screenshots/) | Six readable PNG summaries of actual R output. |
| [`report/report.tex`](report/report.tex) | Complete LaTeX report with linked graphs and methods. |
| [`report/report.pdf`](report/report.pdf) | Compiled, ten-page version of the report by Nakshatra Ghosh. |
| [`report/iv_validity_note.md`](report/iv_validity_note.md) | Substantive audit of IV candidates and required assumptions. |
| [`prompts/extraction_prompt.md`](prompts/extraction_prompt.md) | A reusable extraction prompt and verification standard. |

## Reproduce

Use R 4.5.1 or a recent R release with its recommended `MASS` package. From the project root:

```sh
Rscript R/00_run_all.R
python scripts/check_project.py
```

Individual questions can be rerun with `Rscript R/01_schooling_stunting.R`, `Rscript R/02_marriage_motherhood.R`, `Rscript R/03_digital_gender.R`, or `Rscript R/04_nutrition_transition.R`. Each sources `R/common.R` and writes its own `results/`, `figures/` and `screenshots/` outputs. Run `R/05_descriptives.R` and `R/06_pca_clusters.R` similarly. The scripts assume the working directory is the project root.

To regenerate the consolidated CSV from the original PDF, install the Python dependency and pass the PDF path:

```sh
python -m pip install -r requirements.txt
python scripts/extract_nfhs6.py "path/to/National Family Health Survey (NFHS-6) 2023-2024 Fact Sheets.pdf"
```

The source PDF is not bundled. Its SHA-256 hash in this extraction is `59DEC561E837BEA060B6684A75CACA84E0C982ED9E2670848521755F2AB267F9`. The script expects the IIPS India and State/UT compendium layout, verifies 101 indicators per unit and checks structural and numeric invariants. Selected ambiguous cells were visually checked against the PDF; this is not a complete manual cell audit.

The compiled PDF is included. To rebuild it, run `pdflatex report.tex` twice from the `report/` directory with a standard LaTeX installation, or use Tectonic from the project root: `tectonic report/report.tex`.

## Boundaries and next study

Published aggregates cannot show whether the same people experience the measured conditions; the schooling and child-health populations differ. NFHS-5 and NFHS-6 totals are repeated cross-sections, not a tracked panel. Descriptive regressions may reflect household resources, public services, urbanization, demographics and other confounders. A stronger follow-up would obtain NFHS-6 microdata when available, use its survey design and relevant denominators, and specify hypotheses before seeing the model fits. The present repo is a coding and research-design sample, with data extraction, validation, diagnostics and restrained interpretation visible end to end.
