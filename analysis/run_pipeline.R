# Runs the full Gorilla-export -> participant-level dataset pipeline
# against the sample data in results/, as a smoke test.
#
# Run from the repo root:
#   Rscript analysis/run_pipeline.R
#
# Required packages: readr, dplyr, tidyr, jsonlite, tibble
# install.packages(c("readr", "dplyr", "tidyr", "jsonlite", "tibble"))

source("analysis/R/gorilla_object_map.R")
source("analysis/R/read_questionnaire.R")
source("analysis/R/read_task.R")
source("analysis/R/scoring.R")
source("analysis/R/composites.R")
source("analysis/R/dv_summary.R")
source("analysis/R/build_participant_dataset.R")

participant_data <- build_participant_dataset(
  questionnaire_path = "results/data-questionnaire-cimk (5).csv",
  recall_path        = "results/data-task-3js1 (2).csv",
  recognition_path   = "results/data-task-vl4k (3).csv",
  wordlist_path      = "app/src/data/wordlist.json",
  cao_lookup         = NULL, # no CAO-points-by-year table exists yet -- see compute_predictors()
  collection_year    = 2026
)

print(as.data.frame(t(participant_data)))

cat("\n--- sanity checks ---\n")
cat("production_accuracy_pct (expect ~53.3 pre-rescoring, likely a bit higher after rescoring):",
    participant_data$production_accuracy_pct, "\n")
cat("recognition_accuracy_pct (expect ~25.0 pre-rescoring):",
    participant_data$recognition_accuracy_pct, "\n")
cat("n_recall_flagged (near-miss, needs manual review):", participant_data$n_recall_flagged, "\n")
cat("n_recognition_flagged (near-miss, needs manual review):", participant_data$n_recognition_flagged, "\n")
