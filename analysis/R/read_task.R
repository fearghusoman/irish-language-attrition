# Step 2: read a Gorilla task (word-recall/recognition) export and filter it
# down to one row per real scored trial.

library(readr)
library(dplyr)

#' Read a raw Gorilla task long-format export as all-character columns.
read_gorilla_task_long <- function(path) {
  df <- read_csv(path, col_types = cols(.default = "c"), na = character())
  names(df) <- sub("^﻿", "", names(df))
  df
}

#' Reduce a task export to one row per real scored trial.
#'
#' Every trial logs several housekeeping rows (Instructions/Practice/Wait,
#' and for each real trial a `Screen == "Trial"`/`Response Type == "continue"`
#' page-load placeholder with a blank response and a default `Correct = 0`).
#' Round 2 additionally logs a `Screen == "Check"` row per item
#' (`Response = "checked"`, `Correct` always `1`) that is an unrelated
#' exposure/acknowledgment step for every one of the 60 items, not a scored
#' answer -- only a subset of items (the ones NOT recalled correctly in
#' Round 1) go on to get an actual `Screen == "Trial"` test in Round 2.
#'
#' The only row that holds the real scored answer is
#' `Screen == "Trial" & Response Type == "response"`.
#'
#' @param word_col Name of the stimulus column to keep: `"Spreadsheet: English"`
#'   for Round 1 (English shown, Irish typed) or `"Spreadsheet: Irish"` for
#'   Round 2 (Irish shown, English typed).
extract_task_trials <- function(path, word_col) {
  read_gorilla_task_long(path) %>%
    filter(Screen == "Trial", `Response Type` == "response") %>%
    transmute(
      participant_id = `Participant Private ID`,
      trial_number = as.integer(`Trial Number`),
      item_word = .data[[word_col]],
      response_raw = Response,
      correct_gorilla = as.integer(Correct),
      reaction_time_ms = suppressWarnings(as.numeric(`Reaction Time`))
    ) %>%
    arrange(trial_number)
}
