# Step 7: assemble the long-format, participant x item dataset that
# codebook Section F's primary confirmatory model needs (glmer/clmm,
# by-participant and by-item random effects, item-level fixed effects for
# word length/frequency/category). This only builds the dataset -- no
# model is fit here.

library(dplyr)

#' Build the trial-level (participant x item) analysis dataset.
#'
#' One row per participant x item (all 60 items each participant saw in
#' Round 1), with:
#' - the ordinal DV `retention_level` (0 = neither, 1 = recognized-only,
#'   2 = recalled) from `compute_item_level_retention()`
#' - item-level fixed effects: `category`, `word_length`, `freq_rank`
#' - the 4 core participant-level predictors (`proficiency_score`,
#'   `exposure_composite`, `integrative_motivation_composite`,
#'   `multilingualism_count`), repeated across that participant's rows
#' - each phase's raw typed response, expected answer, and Gorilla's own
#'   correctness flag (`recall_response`/`recall_expected_answer`/
#'   `recall_correct_gorilla` and the `recognition_*` equivalents, `NA`
#'   for items that were never reached in that phase) -- kept for the
#'   manual review of near-miss (`retention_level == NA`) rows that
#'   codebook Section E requires; not itself a modelling input
#'
#' @param recall_trials_rescored,recognition_trials_rescored From
#'   `rescore_task_trials()`.
#' @param participant_predictors One row per participant, e.g. the output
#'   of `compute_predictors()` (already carries `participant_id`).
build_trial_level_dataset <- function(recall_trials_rescored, recognition_trials_rescored,
                                       participant_predictors) {
  item_retention <- compute_item_level_retention(recall_trials_rescored, recognition_trials_rescored)

  predictors <- participant_predictors %>%
    select(participant_id, proficiency_score, exposure_composite,
           integrative_motivation_composite, multilingualism_count)

  item_retention %>%
    select(participant_id, item_id, category, word_length, freq_rank, retention_level,
           recall_expected_answer, recall_response, recall_correct_gorilla,
           recognition_expected_answer, recognition_response, recognition_correct_gorilla) %>%
    left_join(predictors, by = "participant_id") %>%
    arrange(participant_id, item_id)
}
