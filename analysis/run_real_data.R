# Runs the full Gorilla-export -> analysis-ready-dataset pipeline against
# the real results in results/22092026/, and writes both output datasets
# to CSV.
#
# Run from the repo root:
#   Rscript analysis/run_real_data.R
#
# Required packages: readxl, readr, dplyr, tidyr, jsonlite, tibble, stringr
# install.packages(c("readxl", "readr", "dplyr", "tidyr", "jsonlite", "tibble", "stringr"))

source("analysis/R/gorilla_object_map.R")
source("analysis/R/read_questionnaire.R")
source("analysis/R/read_task.R")
source("analysis/R/scoring.R")
source("analysis/R/composites.R")
source("analysis/R/dv_summary.R")
source("analysis/R/build_trial_dataset.R")
source("analysis/R/build_participant_dataset.R")

cao_lookup <- readr::read_csv("analysis/resources/cao_lookup.csv", show_col_types = FALSE)

result <- build_participant_dataset(
  questionnaire_path = "results/22092026/data_exp_279099-vall_questionnaires.xlsx",
  tasks_path         = "results/22092026/data_exp_279099-vall_tasks.xlsx",
  wordlist_path      = "analysis/resources/wordlist.json",
  cao_lookup         = cao_lookup,
  collection_year    = 2026
)

participant_dataset <- result$participant_dataset
trial_dataset <- result$trial_dataset

n_participants <- nrow(participant_dataset)
n_items <- length(unique(trial_dataset$item_id))

cat("--- participant-level dataset ---\n")
cat("n participants:", n_participants, "\n")
cat("n columns:", ncol(participant_dataset), "\n")

cat("\n--- trial-level dataset ---\n")
cat("n rows:", nrow(trial_dataset),
    "(max possible:", n_participants * n_items,
    "= n_participants x n_items -- fewer rows means some participant(s) have incomplete Round 1 sessions)\n")

cat("\n--- sanity checks ---\n")
cat("production_accuracy_pct summary:\n")
print(summary(participant_dataset$production_accuracy_pct))
cat("\nrecognition_accuracy_pct summary:\n")
print(summary(participant_dataset$recognition_accuracy_pct))
cat("\nn_recall_flagged (near-miss, needs manual review) summary:\n")
print(summary(participant_dataset$n_recall_flagged))
cat("\nproficiency_score -- n missing (some expected: cao_lookup.csv doesn't cover pre-1992 exam years, and \"Do not remember grade\" responses can't be scored):\n")
print(table(is.na(participant_dataset$proficiency_score)))
cat("\nexposure_composite / integrative_motivation_composite / multilingualism_count -- n missing:\n")
print(colSums(is.na(participant_dataset[c("exposure_composite", "integrative_motivation_composite", "multilingualism_count")])))
cat("\nretention_level distribution (trial-level):\n")
print(table(trial_dataset$retention_level, useNA = "always"))

dir.create("results/22092026/derived", showWarnings = FALSE, recursive = TRUE)
readr::write_csv(participant_dataset, "results/22092026/derived/participant_dataset.csv")
readr::write_csv(trial_dataset, "results/22092026/derived/trial_level_dataset.csv")
cat("\nWrote results/22092026/derived/participant_dataset.csv and trial_level_dataset.csv\n")
