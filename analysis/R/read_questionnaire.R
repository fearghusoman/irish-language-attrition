# Step 1: read a Gorilla questionnaire "long" export (one row per
# page/question event) and reshape it to one row per participant, keeping
# only the columns that hold real answers.
#
# Requires gorilla_object_map.R to already be sourced (run_pipeline.R does
# this in order).

library(readr)
library(dplyr)
library(tidyr)

#' Read a raw Gorilla long-format export as all-character columns.
#'
#' Read everything as character deliberately: this is an event log with
#' mixed row shapes (metadata rows have blank Trial/Response columns, answer
#' rows are text/number/boolean depending on the question), so type
#' coercion happens later, per-variable, once we know what each column
#' actually represents.
read_gorilla_questionnaire_long <- function(path) {
  df <- read_csv(path, col_types = cols(.default = "c"), na = character())
  names(df) <- sub("^﻿", "", names(df)) # strip a stray BOM from the first header if present
  df
}

#' Reshape a Gorilla questionnaire long export into one row per participant.
#'
#' - Keeps only `Response Type == "response"` rows (the final submitted
#'   value; Gorilla also logs a duplicate `"action"` row per answer).
#' - Single-value questions (Key %in% c("value", "quantised")) become two
#'   columns each: `<variable_name>` (the raw label/number Gorilla stored)
#'   and `<variable_name>_quantised` (Gorilla's numeric-coded version,
#'   ready to use for scale items without re-deriving a label->number map).
#' - Multiselect/checkbox questions (one row per option, Key = option
#'   label, Response = "0"/"1") become one boolean column per option
#'   (`<variable_name>__<option_slug>`) plus one human-readable summary
#'   column (`<variable_name>`, a "; "-joined list of the checked labels).
#'
#' Returns one row per `participant_id`, plus participant status/completion
#' metadata useful for filtering to complete sessions once there are many.
extract_questionnaire_answers <- function(path) {
  raw <- read_gorilla_questionnaire_long(path) %>%
    filter(`Response Type` == "response", !is.na(`Object ID`), `Object ID` != "")

  obj_map <- gorilla_object_map()

  participant_meta <- raw %>%
    distinct(`Participant Private ID`, `Participant Public ID`,
             `Participant Status`, `Participant Completion Code`) %>%
    rename(participant_id = `Participant Private ID`,
           participant_public_id = `Participant Public ID`,
           participant_status = `Participant Status`,
           participant_completion_code = `Participant Completion Code`)

  single_ids <- obj_map$object_id[!obj_map$multiselect]
  single_wide <- raw %>%
    filter(`Object ID` %in% single_ids, Key %in% c("value", "quantised")) %>%
    left_join(obj_map, by = c("Object ID" = "object_id")) %>%
    mutate(col_name = if_else(Key == "quantised",
                               paste0(variable_name, "_quantised"),
                               variable_name)) %>%
    distinct(`Participant Private ID`, col_name, .keep_all = TRUE) %>%
    select(`Participant Private ID`, col_name, Response) %>%
    pivot_wider(names_from = col_name, values_from = Response)

  multi_ids <- obj_map$object_id[obj_map$multiselect]
  multi_long <- raw %>%
    filter(`Object ID` %in% multi_ids) %>%
    left_join(obj_map, by = c("Object ID" = "object_id")) %>%
    mutate(
      option_slug = gsub("[^a-z0-9]+", "_", tolower(Key)),
      option_slug = gsub("^_|_$", "", option_slug),
      col_name = paste0(variable_name, "__", option_slug),
      checked = Response == "1"
    )

  multi_wide <- multi_long %>%
    distinct(`Participant Private ID`, col_name, .keep_all = TRUE) %>%
    select(`Participant Private ID`, col_name, checked) %>%
    pivot_wider(names_from = col_name, values_from = checked)

  multi_summary <- multi_long %>%
    filter(checked) %>%
    group_by(`Participant Private ID`, variable_name) %>%
    summarise(labels = paste(Key, collapse = "; "), .groups = "drop") %>%
    pivot_wider(names_from = variable_name, values_from = labels)

  out <- single_wide %>%
    rename(participant_id = `Participant Private ID`)
  if (nrow(multi_wide) > 0) {
    out <- full_join(out, rename(multi_wide, participant_id = `Participant Private ID`),
                      by = "participant_id")
  }
  if (nrow(multi_summary) > 0) {
    out <- full_join(out, rename(multi_summary, participant_id = `Participant Private ID`),
                      by = "participant_id")
  }

  left_join(participant_meta, out, by = "participant_id")
}
