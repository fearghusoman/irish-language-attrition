# Approach to the regression analysis

Yes — this is a natural continuation of the pipeline we just built, and the `trial_level_dataset.csv` is already shaped for it. Here's how I'd approach it, following the codebook's own Section F plan rather than inventing a different one.

## 1. Resolve the blocking gap first

`proficiency_score` is `NA` for all 47 participants right now (no CAO table). Before running the *primary* model, we need a decision: either you supply a CAO-points-by-year table, or we run an interim model without proficiency (clearly labelled as incomplete relative to the pre-registered 4-predictor design) so you can see the other 3 predictors' effects while the table is sourced. I wouldn't silently drop it and call the result "the primary model."

## 2. EDA and pre-model checks (on `participant_dataset.csv`)

Before fitting anything on ~2,800 trial rows, sanity-check the participant-level composites first, since that's where problems are easiest to spot:
- Distribution/range of each of the 4 core predictors and the composites — look for floor/ceiling effects or a skewed `multilingualism_count`.
- **Collinearity check** (`car::vif()` on a simple linear model of the composites) — the codebook specifically flags that Geary (2022) found motivation and proficiency correlated, so this isn't optional.
- **Reliability check** (Cronbach's alpha) on each multi-item composite (exposure, integrative motivation, learning experience, etc.) before trusting the averages — the codebook calls this out explicitly.
- Look at `n_recall_flagged`/`n_recognition_flagged` per participant — decide whether flagged near-miss trials get excluded from the model or resolved by manual review first.

## 3. Model specification (on `trial_level_dataset.csv`)

`retention_level` is ordinal (0/1/2), so the right tool is a **cumulative link mixed model** — the `ordinal` package's `clmm()`, exactly as the codebook specifies, not `lme4::glmer()` (which assumes a binary or count outcome). Structure:

- **Fixed effects:** the 4 core predictors (participant-level) + `word_length`, `freq_rank`, `category` (item-level).
- **Random effects:** random intercepts for `participant_id` and `item_id`. With only 47 participants and 60 items, I'd start with intercepts-only — random slopes would likely be underpowered/non-convergent — and only add slopes if there's a specific theoretical reason and the model actually converges.
- Continuous predictors (composites, word length, freq rank) get centered/scaled first, both for interpretability of the intercept and to help the optimizer converge.

Then, following the codebook's own three-tier plan:
- **Primary (confirmatory):** the 4-predictor model above.
- **Secondary (exploratory):** same model + instrumental motivation as a 5th predictor, explicitly labelled underpowered (8 obs/predictor).
- **Tertiary (descriptive check):** a simple participant-level regression on `production_accuracy_pct` from `participant_dataset.csv`, as a supplementary sanity check against the trial-level result.
- Plus the codebook's named exploratory extras: a Mann-Whitney U comparison by `curriculum_cohort`, and (if you want it) a resident-only vs. mixed-residency split using the time-abroad variable.

## 4. Diagnostics, not just a p-value table

- Check `clmm` convergence warnings and whether the by-item/by-participant random-effect variances are meaningfully non-zero (if one collapses to ~0, the simpler model without it is more honest).
- Check the proportional-odds assumption (`ordinal::nominal_test()`) rather than assuming it holds.
- Report **effect sizes with confidence intervals**, not just significance — the codebook is explicit about this given n=40–47 sits at the 10-obs-per-predictor ceiling for the primary model.
- Run a sensitivity check excluding the near-miss-flagged trials, to see whether they're influencing results.

## 5. What I'd need from you before writing code

- A decision on the CAO table (supply it, or proceed proficiency-free for now).
- Confirmation that `ordinal` and `car` (and `lme4`/`psych` for the reliability/collinearity checks) can be installed in this R environment, same as the packages we just added.
- Whether you want all three tiers (primary/secondary/tertiary) in one script, or the primary model first as a standalone deliverable before building out the rest.
