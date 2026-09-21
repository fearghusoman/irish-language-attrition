# Step 2: read a Gorilla task (word-recall/recognition) export and filter it
# down to one row per real scored trial.
#
# The real production export (results/21092026) is a single .xlsx file
# containing BOTH rounds, distinguished by `Task Name` ("Round 1: Recall" /
# "Round 2: Recognition"). The earlier sample CSVs are already split one
# round per file (with different Task Name strings entirely), so the
# `task_name` filter below is optional and only applied when supplied.

library(readxl)
library(readr)
library(dplyr)

#' Read a raw Gorilla task export (.csv or .xlsx) as all-character columns.
read_gorilla_task_long <- function(path) {
  df <- if (grepl("\\.xlsx?$", path, ignore.case = TRUE)) {
    readxl::read_excel(path, col_types = "text")
  } else {
    read_csv(path, col_types = cols(.default = "c"), na = character())
  }
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
#' @param task_name Optional `Task Name` value to filter to first -- needed
#'   when `path` is a single combined export holding both rounds (real
#'   data: `"Round 1: Recall"` / `"Round 2: Recognition"`). `NULL` (default)
#'   skips this filter, for exports that already contain only one round.
extract_task_trials <- function(path, word_col, task_name = NULL) {
  df <- read_gorilla_task_long(path)
  if (!is.null(task_name)) {
    df <- df %>% filter(`Task Name` == task_name)
  }
  df %>%
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
