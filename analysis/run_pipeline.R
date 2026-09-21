# Task-scoring smoke test: runs extract_task_trials() + rescore_task_trials()
# against the sample recall/recognition CSVs, as a regression check that
# the wordlist join and Section E scoring logic still work correctly.
#
# (The questionnaire side isn't exercised here -- the sample questionnaire
# CSV is a long-format export from an earlier pilot build that no longer
# matches the real wide-format export `extract_questionnaire_answers()` now
# reads; see analysis/run_real_data.R for the full pipeline against real
# data.)
#
# Run from the repo root:
#   Rscript analysis/run_pipeline.R
#
# Required packages: readxl, readr, dplyr, tidyr, jsonlite, tibble, stringr
# install.packages(c("readxl", "readr", "dplyr", "tidyr", "jsonlite", "tibble", "stringr"))

source("analysis/R/read_task.R")
source("analysis/R/scoring.R")

wordlist <- jsonlite::fromJSON("app/src/data/wordlist.json")

recall_trials <- extract_task_trials("results/data-task-3js1 (2).csv", word_col = "Spreadsheet: English") %>%
  rescore_task_trials(wordlist, direction = "recall")
recognition_trials <- extract_task_trials("results/data-task-vl4k (3).csv", word_col = "Spreadsheet: Irish") %>%
  rescore_task_trials(wordlist, direction = "recognition")

cat("--- recall trials rescored (first 10 rows) ---\n")
print(head(recall_trials, 10))

cat("\n--- sanity checks ---\n")
cat("n recall trials:", nrow(recall_trials), "(expect 60)\n")
cat("n recognition trials:", nrow(recognition_trials), "\n")

t19 <- recall_trials[recall_trials$trial_number == 19, ]
t45 <- recall_trials[recall_trials$trial_number == 45, ]
cat("\ntrial 19 (\"book\"): item_id =", t19$item_id, "(expect 4, not 19); ",
    "correct_gorilla =", t19$correct_gorilla, "; correct_rescored =", t19$correct_rescored, "(expect TRUE)\n")
cat("trial 45 (\"to walk\"): item_id =", t45$item_id, "(expect 44, not 45); ",
    "correct_gorilla =", t45$correct_gorilla, "; correct_rescored =", t45$correct_rescored, "(expect TRUE)\n")

cat("\nn recall items with no wordlist match (item_id NA -- should be 0):",
    sum(is.na(recall_trials$item_id)), "\n")
cat("n recognition items with no wordlist match (item_id NA -- should be 0):",
    sum(is.na(recognition_trials$item_id)), "\n")
