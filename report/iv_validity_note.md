# Why this project does not estimate an instrumental-variable effect

An instrumental variable (IV) for schooling in a stunting regression would need **relevance** (it changes schooling), **independence** (it is unrelated to unobserved causes of stunting), and an **exclusion restriction** (it affects stunting only through schooling). The NFHS fact sheets provide contemporaneous area averages, not an externally assigned policy shock or a defensible historical instrument. The proposed regression is also ecological: the women counted in schooling are not necessarily the mothers of the children counted in stunting.

The apparent candidates in this PDF fail the substantive audit:

- **Electricity coverage:** may be related to schooling, but can affect income, food storage, water treatment, health services and living conditions directly.
- **Women's internet use:** may be related to schooling, but can influence health information, service access, work and household resources directly.
- **Health insurance coverage:** can influence care and household finances directly, and reflects state policy and economic conditions.
- **Fieldwork phase or survey date:** reflects geography and timing, and may affect measured outcomes through seasonality and state-specific conditions. It is not randomly assigned schooling variation.
- **Women's schooling as an IV for child marriage in a teenage motherhood model:** schooling plausibly affects pregnancy through knowledge, aspirations and economic opportunities even apart from marriage.

These are not proven invalid by a statistical test; their exclusion and independence assumptions lack a credible argument. A high first-stage F statistic would test only relevance. An over-identification test would not prove that all instruments are exogenous. With only 27 states, weak-instrument and ecological bias concerns would be acute.

**Decision:** no 2SLS estimate is reported. If a future project adds an externally assigned, historically timed instrument, document the assignment process, timing, first-stage relationship, potential direct pathways, covariate balance and placebo outcomes. Use weak-IV-robust inference where needed. Exogeneity and exclusion still require substantive justification; they cannot be established from these fact sheets alone.

PCA and clustering do not require an exclusion restriction because they are descriptive methods. Their relevant checks are indicator comparability, standardization, missingness, stability and interpretability. The included multivariate script reports those checks and does not label clusters as causal or permanent state types.
