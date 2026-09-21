# Step 3: re-score raw typed lexical responses per codebook Section E.
#
# Gorilla's own `Correct` column does NOT implement this protocol -- it
# looks like a stricter/simpler match. Confirmed concretely in the sample
# data: Round 1 trial 19 (target "leabhar", typed "leabhair") and trial 45
# (target "siúil", typed "siul") are both flagged `Correct = 0` by Gorilla,
# but both are within the fada-stripped Levenshtein-1 tolerance below, so
# should count as correct once rescored.
#
# NOTE ON THE LENGTH CUTOFF: the codebook specifies "Levenshtein distance
# <=1 for short words, <=2 for longer words" but does not define "short" vs
# "longer" numerically. This implementation uses <=4 characters (after
# fada-stripping) = "short", else "longer" -- confirm this cutoff with the
# collaborator before relying on it for real scoring decisions.

library(dplyr)
library(tidyr)

#' Lowercase, trim, and strip fadas (á/é/í/ó/ú) from a string.
strip_fada <- function(x) {
  x <- tolower(trimws(x))
  chartr("áéíóú", "aeiou", x)
}

#' Strip a leading "to " (recognition-phase verb responses only, Section E.5).
strip_to_prefix <- function(x) sub("^to\\s+", "", x)

#' Score one typed response against its target (and any accepted
#' alternatives), per codebook Section E.
#'
#' @param target Primary accepted answer (Irish word for recall direction,
#'   English gloss for recognition direction).
#' @param response The participant's raw typed answer.
#' @param direction "recall" (English shown -> Irish typed) or
#'   "recognition" (Irish shown -> English typed). Only affects whether a
#'   leading "to " is stripped (verb glosses in the recognition direction).
#' @param alternatives Optional character vector of additional accepted
#'   answers (e.g. multiple English glosses for one item) -- checked
#'   alongside `target`, any one matching is sufficient.
#' @return `TRUE` (correct), `FALSE` (incorrect / no response), or `NA`
#'   (edit distance close to but past the accept threshold -- flagged for
#'   manual review rather than auto-scored, per Section E.3/E.7).
score_lexical_response <- function(target, response,
                                    direction = c("recall", "recognition"),
                                    alternatives = NULL) {
  direction <- match.arg(direction)

  if (is.na(response) || trimws(response) == "") {
    return(FALSE) # timeout / no response typed
  }

  candidates <- if (!is.null(alternatives) && length(alternatives) > 0) {
    unique(c(target, alternatives))
  } else {
    target
  }
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]

  resp_norm <- strip_fada(response)
  if (direction == "recognition") resp_norm <- strip_to_prefix(resp_norm)

  verdicts <- vapply(candidates, function(cand) {
    cand_norm <- strip_fada(cand)
    if (direction == "recognition") cand_norm <- strip_to_prefix(cand_norm)

    if (identical(cand_norm, resp_norm)) return(1L)

    dist <- as.integer(utils::adist(cand_norm, resp_norm)[1, 1])
    threshold <- if (nchar(cand_norm) <= 4) 1L else 2L

    if (dist <= threshold) return(1L)
    if (dist <= threshold + 2L) return(-1L) # near-miss: flag for manual review
    return(0L)
  }, integer(1))

  if (any(verdicts == 1L)) return(TRUE)
  if (any(verdicts == -1L)) return(NA)
  return(FALSE)
}

#' Rescore a full trial-level tibble (from `extract_task_trials()`) against
#' `wordlist.json`, joining by `trial_number == item_id`.
#'
#' Adds `correct_rescored` (TRUE/FALSE/NA per `score_lexical_response()`)
#' alongside the original `correct_gorilla` flag for comparison.
#'
#' @param wordlist The parsed wordlist (e.g. via
#'   `jsonlite::fromJSON("app/src/data/wordlist.json")`).
#' @param direction "recall" (Round 1) or "recognition" (Round 2).
rescore_task_trials <- function(trials, wordlist, direction = c("recall", "recognition")) {
  direction <- match.arg(direction)

  wl <- wordlist %>%
    select(item_id, irish_target, english_gloss, english_gloss_alternatives)

  trials %>%
    left_join(wl, by = c("trial_number" = "item_id")) %>%
    rowwise() %>%
    mutate(
      correct_rescored = score_lexical_response(
        target = if (direction == "recall") irish_target else english_gloss,
        response = response_raw,
        direction = direction,
        alternatives = if (direction == "recognition") unlist(english_gloss_alternatives) else NULL
      )
    ) %>%
    ungroup() %>%
    select(-irish_target, -english_gloss, -english_gloss_alternatives)
}
