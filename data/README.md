# Data dictionary and provenance

The consolidated file, nfhs6_state_indicators.csv, contains 3,636 rows: 101 indicator IDs for India and each of 35 States/UTs. The source is IIPS, *National Family Health Survey (NFHS-6), 2023–24: India and State/UT Fact Sheets* (2026). The original PDF is available from [IIPS](https://www.nfhsiips.in/nfhsuser/assets/National%20Family%20Health%20Survey%20%28NFHS-6%29%202023-2024%20Fact%20Sheets.pdf). The SHA-256 hash of the copy used here is 59DEC561E837BEA060B6684A75CACA84E0C982ED9E2670848521755F2AB267F9.

The CSV columns are unit, physical pdf_page (starting at 1), indicator_id, indicator_label, nfhs6_urban, nfhs6_rural, nfhs6_total and nfhs5_total. Indicator labels are compact first-line text excerpts where the printed row wraps; the indicator number and page provide the authoritative full wording and footnotes. NFHS-5 urban and rural columns are not present in this PDF.

The raw CSV preserves asterisks for cells suppressed because they are based on fewer than 25 unweighted cases and parentheses around estimates based on 25–49 unweighted cases. Analysis scripts turn asterisks into missing values. They convert parentheses to numeric values only after retaining the raw file; none of the four primary 27-state regressions needs a parenthesized focal cell. Indicator 18 is total fertility rate in children per woman; all other numeric indicators in these tables are percentages.

Focal IDs and denominators:

- 12 and 13: Women and men aged 15–49 with at least ten years of schooling.
- 14 and 15: Women and men aged 15–49 who have ever used the internet.
- 16: Women aged 20–24 married before age 18.
- 19: Women aged 15–19 already mothers or pregnant at interview.
- 30: Mothers with at least four antenatal visits for the last birth in the preceding five years.
- 68: Total children aged 6–23 months receiving an adequate diet; consult the PDF footnote for the feeding definition.
- 69: Children under five with height-for-age below two WHO standard deviations.
- 76: Women aged 15–49 who are overweight or obese, BMI at least 25; excludes pregnant women and women with a birth in the preceding two months.

The extraction script validates area/indicator completeness, percentage ranges, the position of NFHS-6 totals between urban and rural values, and two India anchor rows. Selected ambiguous rows were visually checked against rendered PDF pages. It is not a full manual cell-by-cell audit. The fact-sheet estimates are provisional and do not supply indicator-specific standard errors for the regressions.
