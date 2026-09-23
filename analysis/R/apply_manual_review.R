# Step 9: merge the researcher's manual review of near-miss (retention_level
# == NA) trials back into the trial-level dataset.
#
# codebook Section E flags any rescored response that's close to but past
# the auto-accept edit-distance threshold for human review rather than
# guessing (unlisted synonyms, dialect variants, genuine near-misses). The
# researcher's review log records that judgment call per (participant_id,
# item_id); this just merges it in.

library(readxl)
library(dplyr)

#' Merge a manual review log's decisions into the trial-level dataset.
#'
#' Expects the log's "Manual review log" sheet to have columns
#' `participant_id`, `item_id`, `decision` (one of "accept as recalled" /
#' "accept as recognized" / "reject (neither)"), and
#' `corrected_retention_level` (2/1/0 respectively). Validates that the two
#' agree before trusting either, since a mismatch would mean something went
#' wrong upstream in the review process, not something to silently resolve
#' either way.
#'
#' Adds `retention_level_source` ("manual_review" / "automatic") to the
#' output for traceability -- so a reader of the final dataset can tell
#' which rows reflect the automatic scoring protocol vs. a human judgment
#' call, without having to diff against the review log separately.
#'
#' @param trial_dataset From `build_trial_level_dataset()`.
#' @param review_path Path to the manual review log .xlsx.
apply_manual_review <- function(trial_dataset, review_path) {
  review <- read_excel(review_path, sheet = "Manual review log", col_types = "text") %>%
    transmute(
      participant_id = as.character(participant_id),
      item_id = as.integer(item_id),
      decision = trimws(decision),
      corrected_retention_level = as.integer(corrected_retention_level)
    )

  expected_level <- c("accept as recalled" = 2L, "accept as recognized" = 1L, "reject (neither)" = 0L)
  mismatched <- review %>% filter(corrected_retention_level != expected_level[decision])
  if (nrow(mismatched) > 0) {
    stop(
      nrow(mismatched), " row(s) in the manual review log have a `decision` that doesn't ",
      "match their `corrected_retention_level` (e.g. \"accept as recalled\" should always be 2) -- ",
      "not merging until this is resolved. Affected participant_id/item_id: ",
      paste(sprintf("%s/%s", mismatched$participant_id, mismatched$item_id), collapse = ", ")
    )
  }

  unreviewed_na <- trial_dataset %>%
    filter(is.na(retention_level)) %>%
    anti_join(review, by = c("participant_id", "item_id"))
  if (nrow(unreviewed_na) > 0) {
    warning(
      nrow(unreviewed_na), " row(s) still have retention_level == NA with no matching ",
      "entry in the manual review log -- they remain unscored."
    )
  }

  trial_dataset %>%
    left_join(review %>% select(participant_id, item_id, corrected_retention_level),
              by = c("participant_id", "item_id")) %>%
    mutate(
      retention_level_source = if_else(!is.na(corrected_retention_level), "manual_review", "automatic"),
      retention_level = coalesce(corrected_retention_level, retention_level)
    ) %>%
    select(-corrected_retention_level)
}
