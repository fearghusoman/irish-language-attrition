# Irish L2 Lexical Attrition Study — Analysis Project

R analysis pipeline for *"Revisiting lexical attrition of instructed L2 Irish: an exploration of levels of retention and influencing factors among adults in Ireland after extended post-instruction periods"* (University of Cologne).

Data collection is handled entirely by **Gorilla Experiment Builder** — a single online session covering consent, a 60-item lexical recall/recognition task, and a background questionnaire, all tagged with one `Participant Private ID`. This repository is everything downstream of that: the source materials the study was built from, the raw exports Gorilla produces, and the R pipeline that turns them into analysis-ready datasets.

## Repository layout

```
context/                  Source materials from the researcher: questionnaire, codebook, task
                           instructions, wordlist. context/v1/ holds the current versions
                           (codebook v24, questionnaire v35, task instructions v12); the files
                           at the root of context/ are earlier superseded versions kept for
                           reference (codebook v20, questionnaire v28, task instructions v6).

handover/                 Plain-language guide (data-structure-overview.md) explaining what
                           each Gorilla export file is, which ones matter for analysis, and
                           which can be ignored.

results/<date>/           Raw Gorilla exports, one folder per data pull (named DDMMYYYY).
                           Each contains the questionnaire + task exports as delivered by
                           Gorilla; once analysis/run_real_data.R has been run against a
                           given date, a derived/ subfolder appears there with the two
                           analysis-ready output CSVs (see results/<date>/derived/README.md).

analysis/                 The R pipeline.
  R/                        Pipeline modules: read the raw exports, rescore lexical responses
                             per the codebook's scoring protocol, compute composite/predictor
                             scores, summarise DVs, and assemble the participant-level and
                             trial-level analysis datasets.
  resources/                cao_lookup.csv (Leaving Cert grade -> points, fixed scale by
                             paper level, per the researcher's decision -- see
                             build_cao_lookup.R) and wordlist.json (the 60 study items
                             with category/frequency/
                             familiarity/length metadata).
  build_cao_lookup.R        Regenerates resources/cao_lookup.csv from source.
  run_pipeline.R            Task-scoring regression smoke test against sample data.
  run_real_data.R           The real pipeline -- run this to produce the two output CSVs
                             for a given results/<date>/ folder.

regression-analysis/      Planning notes for the next stage: fitting the actual mixed-effects
                           model on the trial-level dataset.
```

## Running the analysis

From the repo root (open `irish-attrition-project.Rproj` in RStudio, or `Rscript` from a terminal):

```r
install.packages(c("readxl", "readr", "dplyr", "tidyr", "jsonlite", "tibble", "stringr"))
```

```bash
Rscript analysis/run_real_data.R
```

This reads the raw Gorilla exports (currently pointed at `results/22092026/`), rescores every lexical response per the codebook's Section E protocol, computes the questionnaire composites/predictors, and writes:

- `results/<date>/derived/participant_dataset.csv` — one row per participant.
- `results/<date>/derived/trial_level_dataset.csv` — one row per participant x item, ready for the primary mixed-effects model.

See `results/22092026/derived/README.md` for what each output column means, and `regression-analysis/approach.md` for how the actual regression modelling is planned to proceed.

`analysis/run_pipeline.R` is a smaller smoke test — it only exercises the task-scoring logic (`analysis/R/read_task.R` + `scoring.R`) against sample data, useful for checking that a change to the scoring/matching logic hasn't broken anything without needing a full real-data run.

## Known limitations

- `proficiency_score` uses a fixed grade-to-points scale (year-independent, per the researcher's decision — see `analysis/build_cao_lookup.R`) and is only `NA` for participants who didn't sit the Leaving Cert or couldn't recall their grade.
- The short/long-word Levenshtein tolerance used in rescoring (`analysis/R/scoring.R`) is an unconfirmed placeholder — worth confirming against the actual scoring protocol.
- No statistical model has been fit yet — the pipeline produces the trial-level dataset the primary model needs, but stops there (see `regression-analysis/approach.md`).
