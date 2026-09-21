# Step 1: read the real Gorilla questionnaire export and reshape it to one
# row per participant, keeping only the columns that hold real answers.
#
# Requires gorilla_object_map.R to already be sourced (run_pipeline.R does
# this in order).
#
# The real export (results/21092026/data_exp_279099-vall_questionnaires.xlsx)
# is WIDE, not long: each participant contributes exactly 2 rows sharing a
# `Task Name` -- "Questionnaire - Consent" (just the consent checkbox) and
# "Questionnaire" (every other answer, one column per question). Every
# question's Object ID is embedded directly in its header text (e.g.
# "dd_gender object-6 Response"), rather than living in its own column, so
# reshaping means renaming columns via that embedded token, not pivoting.

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)

#' Read the raw wide questionnaire export as all-character columns.
read_gorilla_questionnaire_wide <- function(path) {
  df <- readxl::read_excel(path, col_types = "text")
  names(df) <- sub("^﻿", "", names(df))
  df
}

#' Reshape the wide questionnaire export into one row per participant.
#'
#' - Drops fully blank rows (trailing sheet artifacts).
#' - Takes `consent_given` from the "Questionnaire - Consent" row.
#' - Takes every other answer from the "Questionnaire" row, renaming each
#'   "<code> object-<N> <suffix>" column via `gorilla_object_map()`:
#'   - suffix "Response" -> `<variable_name>`
#'   - suffix "Quantised" -> `<variable_name>_quantised`
#'   - suffix "Value" -> `<variable_name>` (single-value widgets with no
#'     separate quantised form: free text, numeric entry, checkboxes)
#'   - anything else (multiselect: one column per option, suffix = the
#'     option's own label) -> `<variable_name>__<option_slug>` boolean,
#'     plus one `<variable_name>` summary column ("; "-joined checked
#'     option labels).
#'
#' Returns one row per `participant_id`, plus participant status/completion
#' metadata useful for filtering to complete sessions once there are many.
extract_questionnaire_answers <- function(path) {
  raw <- read_gorilla_questionnaire_wide(path) %>%
    filter(!is.na(`Participant Private ID`))

  participant_meta <- raw %>%
    distinct(`Participant Private ID`, `Participant Public ID`,
             `Participant Status`, `Participant Completion Code`) %>%
    rename(participant_id = `Participant Private ID`,
           participant_public_id = `Participant Public ID`,
           participant_status = `Participant Status`,
           participant_completion_code = `Participant Completion Code`)

  consent_col <- names(raw)[startsWith(names(raw), "Consent Form")][1]
  consent <- raw %>%
    filter(`Task Name` == "Questionnaire - Consent") %>%
    transmute(
      participant_id = `Participant Private ID`,
      consent_given = .data[[consent_col]] %in% "1"
    )

  answers_raw <- raw %>% filter(`Task Name` == "Questionnaire")

  obj_map <- questionnaire_object_map()
  question_cols <- names(answers_raw)[
    str_detect(names(answers_raw), "object-\\d+(-\\d+)?") & names(answers_raw) != consent_col
  ]

  parsed <- tibble(header = question_cols) %>%
    mutate(
      object_id = str_extract(header, "object-\\d+(-\\d+)?"),
      suffix = str_trim(str_remove(header, paste0("^.*", object_id))),
      kind = case_when(
        suffix == "Response" ~ "response",
        suffix == "Quantised" ~ "quantised",
        suffix == "Value" ~ "value",
        TRUE ~ "multiselect_option"
      )
    ) %>%
    left_join(obj_map, by = "object_id")

  unmapped <- parsed %>% filter(is.na(variable_name)) %>% pull(header)
  if (length(unmapped) > 0) {
    warning(
      "extract_questionnaire_answers(): ", length(unmapped),
      " question column(s) have no entry in questionnaire_object_map() and are being dropped: ",
      paste(unmapped, collapse = "; ")
    )
    parsed <- parsed %>% filter(!is.na(variable_name))
  }

  single <- parsed %>% filter(kind %in% c("response", "quantised", "value"))
  single_wide <- answers_raw %>%
    select(`Participant Private ID`, all_of(single$header)) %>%
    rename(participant_id = `Participant Private ID`)
  for (i in seq_len(nrow(single))) {
    col_name <- if (single$kind[i] == "quantised") {
      paste0(single$variable_name[i], "_quantised")
    } else {
      single$variable_name[i]
    }
    names(single_wide)[names(single_wide) == single$header[i]] <- col_name
  }

  multi <- parsed %>% filter(kind == "multiselect_option")
  if (nrow(multi) > 0) {
    multi$option_slug <- str_trim(str_replace_all(str_replace_all(tolower(multi$suffix), "[^a-z0-9]+", "_"), "^_|_$", ""))

    multi_long <- answers_raw %>%
      select(participant_id = `Participant Private ID`, all_of(multi$header)) %>%
      pivot_longer(-participant_id, names_to = "header", values_to = "checked_raw") %>%
      left_join(multi %>% select(header, variable_name, suffix, option_slug), by = "header") %>%
      mutate(checked = checked_raw %in% "1")

    multi_wide <- multi_long %>%
      mutate(col_name = paste0(variable_name, "__", option_slug)) %>%
      select(participant_id, col_name, checked) %>%
      pivot_wider(names_from = col_name, values_from = checked)

    multi_summary <- multi_long %>%
      filter(checked) %>%
      group_by(participant_id, variable_name) %>%
      summarise(labels = paste(suffix, collapse = "; "), .groups = "drop") %>%
      pivot_wider(names_from = variable_name, values_from = labels)
  }

  out <- single_wide
  if (nrow(multi) > 0) {
    out <- full_join(out, multi_wide, by = "participant_id")
    out <- full_join(out, multi_summary, by = "participant_id")
  }

  participant_meta %>%
    left_join(out, by = "participant_id") %>%
    left_join(consent, by = "participant_id")
}
