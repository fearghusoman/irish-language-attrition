# Step 5: Section B dependent-variable summaries, one row per participant.
#
# Takes the rescored trial tibbles from `rescore_task_trials()` (recall =
# Round 1, English->Irish; recognition = Round 2, Irish->English, already
# filtered to just the branched-to subset by `extract_task_trials()`).

library(dplyr)

#' Per-item retention level (Section B primary DV), one row per
#' participant x item.
#'
#' Joins the recall and recognition trial tibbles on `item_id` (a stable
#' key resolved by `rescore_task_trials()` from the actual displayed word,
#' NOT `trial_number` -- Round 2 renumbers its smaller item subset in its
#' own randomized order, unrelated to Round 1's numbering). Every item a
#' participant saw in Round 1 gets a row, since Round 1 always covers all
#' 60 items; `recognized` is `NA` for items already recalled in Round 1
#' (they never reach Round 2).
#'
#' Also carries the item-level attributes (`category`, `word_length`,
#' `freq_rank`, `familiarity_rating`) needed for the trial-level dataset's
#' item fixed effects (`build_trial_level_dataset()`).
compute_item_level_retention <- function(recall_trials_rescored, recognition_trials_rescored) {
  recall_trials_rescored %>%
    select(participant_id, item_id, category, word_length, freq_rank, familiarity_rating,
           recalled = correct_rescored) %>%
    left_join(
      recognition_trials_rescored %>% select(participant_id, item_id, recognized = correct_rescored),
      by = c("participant_id", "item_id")
    ) %>%
    mutate(
      retention_level = case_when(
        recalled %in% TRUE ~ 2L,                                             # recalled
        !(recalled %in% TRUE) & (recognized %in% TRUE) ~ 1L,                 # recognized-only
        !(recalled %in% TRUE) & !(recognized %in% TRUE) & !is.na(recalled) ~ 0L, # neither
        TRUE ~ NA_integer_
      )
    )
}

#' Summarise production (recall) accuracy, recognition accuracy, and
#' recalled/recognized-only/neither counts, per participant.
#'
#' Recognition accuracy is computed only over the subset of items that
#' reached the recognition phase (i.e. weren't already recalled in Round 1),
#' per the codebook's branching DV design (Section B).
#'
#' Rows where rescoring flagged a response `NA` (near-miss, needs manual
#' review -- see `score_lexical_response()`) are excluded from the
#' recalled/recognized-only/neither counts rather than forced into a
#' bucket; check `n_recall_flagged`/`n_recognition_flagged` before trusting
#' those counts as final.
compute_participant_dv_summary <- function(recall_trials_rescored, recognition_trials_rescored) {
  production <- recall_trials_rescored %>%
    group_by(participant_id) %>%
    summarise(
      n_recall_trials = n(),
      n_recalled = sum(correct_rescored, na.rm = TRUE),
      n_recall_flagged = sum(is.na(correct_rescored)),
      production_accuracy_pct = 100 * mean(as.numeric(correct_rescored), na.rm = TRUE),
      .groups = "drop"
    )

  recognition <- recognition_trials_rescored %>%
    group_by(participant_id) %>%
    summarise(
      n_recognition_trials = n(),
      n_recognized = sum(correct_rescored, na.rm = TRUE),
      n_recognition_flagged = sum(is.na(correct_rescored)),
      recognition_accuracy_pct = 100 * mean(as.numeric(correct_rescored), na.rm = TRUE),
      .groups = "drop"
    )

  retention <- compute_item_level_retention(recall_trials_rescored, recognition_trials_rescored) %>%
    group_by(participant_id) %>%
    summarise(
      n_recalled_full = sum(retention_level == 2, na.rm = TRUE),
      n_recognized_only = sum(retention_level == 1, na.rm = TRUE),
      n_neither = sum(retention_level == 0, na.rm = TRUE),
      .groups = "drop"
    )

  production %>%
    full_join(recognition, by = "participant_id") %>%
    full_join(retention, by = "participant_id")
}
