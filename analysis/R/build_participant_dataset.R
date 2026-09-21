# Step 6: orchestrate steps 1-5 into one final one-row-per-participant
# tibble, ready for the "tertiary/descriptive" analysis in codebook
# Section F (one row per participant, composite scores).

library(dplyr)
library(jsonlite)

#' Build the full participant-level analysis dataset from raw Gorilla
#' exports.
#'
#' @param questionnaire_path Path to the main questionnaire long-format
#'   export (e.g. `results/data-questionnaire-cimk (5).csv`).
#' @param recall_path Path to the Round 1 (recall, English->Irish) task
#'   export (e.g. `results/data-task-3js1 (2).csv`).
#' @param recognition_path Path to the Round 2 (recognition, Irish->English)
#'   task export (e.g. `results/data-task-vl4k (3).csv`).
#' @param wordlist_path Path to `app/src/data/wordlist.json`.
#' @param cao_lookup Optional CAO-points-by-year lookup data frame -- see
#'   `compute_predictors()`. `NULL` (the default) leaves `proficiency_score`
#'   as `NA` with a warning.
#' @param collection_year Calendar year data collection took place, used
#'   for the Section H cohort calculation.
build_participant_dataset <- function(questionnaire_path, recall_path, recognition_path,
                                       wordlist_path, cao_lookup = NULL,
                                       collection_year = as.integer(format(Sys.Date(), "%Y"))) {
  wordlist <- fromJSON(wordlist_path)

  questionnaire <- extract_questionnaire_answers(questionnaire_path)

  recall_trials <- extract_task_trials(recall_path, word_col = "Spreadsheet: English") %>%
    rescore_task_trials(wordlist, direction = "recall")
  recognition_trials <- extract_task_trials(recognition_path, word_col = "Spreadsheet: Irish") %>%
    rescore_task_trials(wordlist, direction = "recognition")

  dv_summary <- compute_participant_dv_summary(recall_trials, recognition_trials)

  questionnaire %>%
    compute_predictors(cao_lookup = cao_lookup) %>%
    compute_descriptive_composites() %>%
    compute_cohort(collection_year = collection_year) %>%
    left_join(dv_summary, by = "participant_id")
}
