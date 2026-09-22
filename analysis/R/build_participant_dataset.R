# Step 8: orchestrate steps 1-7 into the final analysis-ready datasets --
# one row per participant (Section F "tertiary/descriptive" analysis) and,
# via `build_trial_level_dataset()`, one row per participant x item
# (Section F primary analysis).

library(dplyr)
library(jsonlite)

#' Build the full participant-level and trial-level analysis datasets from
#' raw Gorilla exports.
#'
#' @param questionnaire_path Path to the wide questionnaire export (e.g.
#'   `results/21092026/data_exp_279099-vall_questionnaires.xlsx`).
#' @param tasks_path Path to the task export. The real export contains
#'   both rounds in a single file (`Task Name` = "Round 1: Recall" /
#'   "Round 2: Recognition"); for the older split sample CSVs, pass each
#'   round's file as a length-2 vector `c(recall_path, recognition_path)`
#'   (the corresponding `Task Name` filter is skipped for those, since
#'   each file already contains only one round).
#' @param wordlist_path Path to `analysis/resources/wordlist.json`.
#' @param cao_lookup Optional CAO-points-by-year lookup data frame -- see
#'   `compute_predictors()`. `NULL` (the default) leaves `proficiency_score`
#'   as `NA` with a warning.
#' @param collection_year Calendar year data collection took place, used
#'   for the Section H cohort calculation.
#' @return A list with `participant_dataset` (one row per participant) and
#'   `trial_dataset` (one row per participant x item).
build_participant_dataset <- function(questionnaire_path, tasks_path,
                                       wordlist_path, cao_lookup = NULL,
                                       collection_year = as.integer(format(Sys.Date(), "%Y"))) {
  wordlist <- fromJSON(wordlist_path)

  questionnaire <- extract_questionnaire_answers(questionnaire_path)

  recall_path <- tasks_path[1]
  recognition_path <- if (length(tasks_path) > 1) tasks_path[2] else tasks_path[1]
  recall_task_name <- if (length(tasks_path) > 1) NULL else "Round 1: Recall"
  recognition_task_name <- if (length(tasks_path) > 1) NULL else "Round 2: Recognition"

  recall_trials <- extract_task_trials(recall_path, word_col = "Spreadsheet: English",
                                        task_name = recall_task_name) %>%
    rescore_task_trials(wordlist, direction = "recall")
  recognition_trials <- extract_task_trials(recognition_path, word_col = "Spreadsheet: Irish",
                                             task_name = recognition_task_name) %>%
    rescore_task_trials(wordlist, direction = "recognition")

  dv_summary <- compute_participant_dv_summary(recall_trials, recognition_trials)

  participant_dataset <- questionnaire %>%
    compute_predictors(cao_lookup = cao_lookup) %>%
    compute_descriptive_composites() %>%
    compute_cohort(collection_year = collection_year) %>%
    left_join(dv_summary, by = "participant_id")

  trial_dataset <- build_trial_level_dataset(recall_trials, recognition_trials, participant_dataset)

  list(participant_dataset = participant_dataset, trial_dataset = trial_dataset)
}
