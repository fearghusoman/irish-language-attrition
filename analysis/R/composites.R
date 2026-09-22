# Step 4: compute the codebook's composite scores from the wide
# questionnaire tibble produced by `extract_questionnaire_answers()`.
#
# All functions here take (and return, with new columns added) the same
# one-row-per-participant tibble, keyed by `participant_id`, so they can be
# chained with dplyr pipes.

library(dplyr)

.is_yes <- function(x) tolower(trimws(x)) == "yes"

#' Collapse a CAO lookup table keyed on official sub-grades (A1/A2, B1/B2/B3,
#' C1/C2/C3, D1/D2/D3, E, F, ...) down to the single letter grade (A/B/C/D/E/F)
#' the questionnaire actually collects (Q14 is a plain A-F dropdown, per
#' irish-attrition-questionnaire-v35.md -- it never asks for a sub-grade).
#'
#' Per project decision, each letter's score is the mean of its CAO points
#' across all of that letter's sub-grades within the same (year, paper)
#' group -- e.g. "B" in 1998 Higher level = mean(B1, B2, B3). This is a
#' deliberate approximation: sub-grade point values are not evenly spaced
#' within a letter (in the 1998 example, B1=88 but B2=B3=77), so this loses
#' some precision that a true sub-grade would have captured, but it's the
#' only property in the raw data that's actually knowable.
#'
#' Rows using the post-2017 H1-H8/O1-O8/NG grade codes are dropped here --
#' the questionnaire's fixed A-F dropdown can never produce those values,
#' so they can never match a real response regardless of exam year.
collapse_cao_subgrades <- function(cao_lookup) {
  cao_lookup %>%
    filter(grepl("^[A-F][0-9]?$", leaving_cert_grade)) %>%
    mutate(leaving_cert_grade = sub("^([A-F]).*$", "\\1", leaving_cert_grade)) %>%
    group_by(leaving_cert_year, leaving_cert_paper, leaving_cert_grade) %>%
    summarise(points = mean(points, na.rm = TRUE), .groups = "drop")
}

#' Section C: the 4 core predictor variables for the primary regression model.
#'
#' @param cao_lookup Optional data frame with columns `leaving_cert_year`,
#'   `leaving_cert_paper`, `leaving_cert_grade`, `points` -- a
#'   CAO-points-by-year conversion table. None exists in the repo yet; if
#'   omitted, `proficiency_score` is `NA` for every row (with a warning)
#'   rather than guessed.
compute_predictors <- function(questionnaire_wide, cao_lookup = NULL) {
  qw <- questionnaire_wide

  exposure_items <- c(
    "exposure_signage_media_quantised", "exposure_conversations_quantised",
    "exposure_media_consumption_quantised", "exposure_events_quantised",
    "exposure_family_social_quantised"
  )
  qw$exposure_composite <- rowMeans(
    do.call(cbind, lapply(exposure_items, function(v) suppressWarnings(as.numeric(qw[[v]])))),
    na.rm = FALSE
  )

  integrative_items <- c("integrative_q21", "integrative_q22", "integrative_q23", "integrative_q24")
  qw$integrative_motivation_composite <- rowMeans(
    do.call(cbind, lapply(integrative_items, function(v) suppressWarnings(as.numeric(qw[[v]])))),
    na.rm = FALSE
  )

  # Multilingualism count: additional languages currently used at least
  # "Occasionally" (quantised position >= 3 on the 5-point frequency scale),
  # across both the full-detail (lang1/lang2) and brief-overflow (lang3/lang4+) slots.
  use_freq_cols <- intersect(
    c("lang1_use_frequency_quantised", "lang2_use_frequency_quantised",
      "lang3_use_frequency_quantised", "lang4_use_frequency_quantised"),
    names(qw)
  )
  # NOTE: cbind() (not sapply()) deliberately -- sapply() only simplifies to
  # a matrix when each per-column result has length > 1, which silently
  # breaks on a single-row (single-participant) dataset like the sample data.
  if (length(use_freq_cols) == 0) {
    qw$multilingualism_count <- rep(0L, nrow(qw))
  } else {
    qw$multilingualism_count <- rowSums(
      do.call(cbind, lapply(use_freq_cols, function(v) {
        x <- suppressWarnings(as.numeric(qw[[v]]))
        !is.na(x) & x >= 3
      })),
      na.rm = TRUE
    )
  }

  # NOTE: the real deployed dropdown wording is "Did not take Leaving Cert
  # Irish" (not "sit", as v35's draft text has it) -- match both.
  qw$proficiency_used_fallback <- grepl("^Did not (sit|take)", qw$leaving_cert_paper, ignore.case = TRUE)
  qw$proficiency_fallback_self_rated <- qw$no_lc_self_rated_proficiency

  if (is.null(cao_lookup)) {
    warning(
      "compute_predictors(): no `cao_lookup` table supplied -- proficiency_score ",
      "is NA for all rows. Supply a CAO-points-by-year table (columns: ",
      "leaving_cert_year, leaving_cert_paper, leaving_cert_grade, points) once available."
    )
    qw$proficiency_score <- NA_real_
  } else {
    # NOTE: the questionnaire's `leaving_cert_paper` values are "Higher
    # level"/"Ordinary level"/"Foundation level"; some cao_lookup sources
    # (e.g. analysis/resources/cao_lookup.csv) use the bare "Higher"/
    # "Ordinary"/"Foundation". Normalize both sides so the join isn't
    # silently broken by that wording difference.
    strip_level_suffix <- function(x) trimws(sub("(?i)\\s*level\\s*$", "", x, perl = TRUE))
    cao_by_letter <- collapse_cao_subgrades(cao_lookup)

    # Per project decision: there's no national CAO points scale before 1992
    # (see analysis/build_cao_lookup.R), so participants who sat the Leaving
    # Cert earlier than the table's first year have that earliest year's
    # points system applied to their grade instead of being left NA.
    # `.join_year` is only used to find the matching cao_lookup row --
    # `leaving_cert_year` itself is left untouched everywhere else (cohort
    # calculation, output columns, etc.).
    earliest_cao_year <- min(cao_by_letter$leaving_cert_year, na.rm = TRUE)

    qw <- qw %>%
      mutate(
        leaving_cert_year = suppressWarnings(as.integer(leaving_cert_year)),
        .join_year = pmax(leaving_cert_year, earliest_cao_year),
        .join_paper = strip_level_suffix(leaving_cert_paper)
      ) %>%
      left_join(
        cao_by_letter %>%
          mutate(.join_paper = strip_level_suffix(leaving_cert_paper)) %>%
          select(-leaving_cert_paper) %>%
          rename(.join_year = leaving_cert_year),
        by = c(".join_year", ".join_paper", "leaving_cert_grade")
      ) %>%
      select(-.join_year, -.join_paper) %>%
      rename(proficiency_score = points)
    unmatched <- !qw$proficiency_used_fallback & is.na(qw$proficiency_score)
    if (any(unmatched, na.rm = TRUE)) {
      warning(
        sum(unmatched, na.rm = TRUE),
        " participant(s) sat the Leaving Cert but had no matching row in `cao_lookup` -- proficiency_score is NA for them."
      )
    }
  }

  qw
}

#' Section D: descriptive-only composites/items (not in the primary model).
#'
#' Each composite is averaged strictly within its own construct -- per the
#' codebook, Q49-50 (factual Yes/No family proficiency) are deliberately
#' NOT averaged into the Q45-48 Likert parental-encouragement composite,
#' and are kept as separate logical columns instead.
compute_descriptive_composites <- function(questionnaire_wide) {
  qw <- questionnaire_wide

  # cbind() (not sapply()) deliberately -- see note in compute_predictors().
  mean_of <- function(...) {
    cols <- do.call(cbind, lapply(list(...), function(v) suppressWarnings(as.numeric(qw[[v]]))))
    rowMeans(cols, na.rm = FALSE)
  }

  qw$attitude_composite <- mean_of("attitude_q34", "attitude_q35", "attitude_q36")
  qw$learning_experience_composite <- mean_of("learning_exp_q37", "learning_exp_q38", "learning_exp_q39", "learning_exp_q40")
  qw$classroom_anxiety_composite <- mean_of("classroom_anxiety_q41", "classroom_anxiety_q42")
  qw$parental_encouragement_composite <- mean_of(
    "parental_encouragement_q43", "parental_encouragement_q44",
    "parental_encouragement_q45", "parental_encouragement_q46"
  )
  qw$linguistic_identity_now_composite <- mean_of("linguistic_identity_q49", "linguistic_identity_q50")

  # 2 items (Q25-26), matching both the v24 codebook and the real deployed
  # build (rs_exams/rs_practical) -- an earlier pilot build had a 3rd item
  # ("rs_personal_int"), but it isn't present in the final questionnaire
  # (v35) or in the real 47-participant export.
  qw$instrumental_motivation_composite <- mean_of("instrumental_q25", "instrumental_q26")

  qw$self_rated_attrition <- suppressWarnings(as.numeric(qw$self_rated_attrition_q51))
  qw$reconnection_motivation <- suppressWarnings(as.numeric(qw$reconnection_motivation_q52))
  qw$motivation_confidence <- suppressWarnings(as.numeric(qw$motivation_confidence_q28))

  qw$family_irish_proficiency_parent <- .is_yes(qw$family_irish_proficiency_parent)
  qw$family_irish_proficiency_helper <- .is_yes(qw$family_irish_proficiency_helper)
  qw$lived_abroad <- .is_yes(qw$lived_abroad)
  qw$is_parent <- .is_yes(qw$is_parent)
  qw$informal_exposure_before <- .is_yes(qw$informal_exposure_before)
  qw$gaeltacht_contact <- .is_yes(qw$gaeltacht_contact)
  qw$irish_related_occupation <- .is_yes(qw$irish_related_occupation)
  qw$current_use_frequency_num <- suppressWarnings(as.numeric(qw$current_use_frequency_quantised))

  qw
}

#' Section H: curriculum-era cohort (1999 primary-school reform).
#'
#' Computed, not asked directly: birth year, then primary-school start
#' year, then cohort. Transition cases (~1997-2001) are flagged as
#' uncertain rather than forced into a binary, per the codebook.
compute_cohort <- function(questionnaire_wide, collection_year) {
  qw <- questionnaire_wide
  age <- suppressWarnings(as.integer(qw$age))
  age_began <- suppressWarnings(as.integer(qw$age_began_learning))

  birth_year <- collection_year - age
  primary_start_year <- birth_year + age_began

  qw$birth_year <- birth_year
  qw$primary_school_start_year <- primary_start_year
  qw$curriculum_cohort <- dplyr::case_when(
    primary_start_year < 1997 ~ "pre_1999",
    primary_start_year > 2001 ~ "post_1999",
    !is.na(primary_start_year) ~ "transition_1997_2001",
    TRUE ~ NA_character_
  )
  qw
}
