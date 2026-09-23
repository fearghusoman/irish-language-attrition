#!/usr/bin/env Rscript
#
# build_cao_lookup.R
#
# Builds `cao_lookup`, the grade-to-points conversion table used by
# `compute_predictors()` (analysis/R/composites.R), and writes it to
# analysis/resources/cao_lookup.csv.
#
# ---------------------------------------------------------------------------
# WHY THIS IS A FIXED GRADE SCALE, NOT A CAO-POINTS-BY-YEAR TABLE
# ---------------------------------------------------------------------------
# An earlier version of this script built a full historical CAO
# points-by-year table (1992-present, tracking the pre-2017 letter-grade
# scale and the post-2017 H/O/F scale, sub-grades and all). Per the
# researcher's decision (2026-09-23), the proficiency predictor instead
# uses a single fixed points scale keyed only on the plain letter grade
# (A-F) the questionnaire actually collects (Q14) and the paper level
# (Higher/Ordinary) -- no exam year, no sub-grades. This is simpler and
# matches what was actually asked for; it deliberately does not track the
# real CAO scale's historical changes.
# ---------------------------------------------------------------------------

cao_lookup <- data.frame(
  leaving_cert_paper = rep(c("Higher", "Ordinary"), each = 6),
  leaving_cert_grade  = rep(c("A", "B", "C", "D", "E", "F"), times = 2),
  points              = c(95, 80, 65, 50, 0, 0,   # Higher level
                           55, 40, 25, 10, 0, 0),  # Ordinary level
  stringsAsFactors = FALSE
)

## --- Sanity checks --------------------------------------------------------

stopifnot(
  all(c("leaving_cert_paper", "leaving_cert_grade", "points") %in% names(cao_lookup)),
  !anyNA(cao_lookup),
  nrow(unique(cao_lookup[c("leaving_cert_paper", "leaving_cert_grade")])) == nrow(cao_lookup),
  all(cao_lookup$points >= 0), all(cao_lookup$points <= 100)
)

## --- Write output ----------------------------------------------------------

write.csv(cao_lookup, file = "analysis/resources/cao_lookup.csv", row.names = FALSE)

cat(sprintf(
  "Built cao_lookup: %d rows, papers: %s\n",
  nrow(cao_lookup), paste(sort(unique(cao_lookup$leaving_cert_paper)), collapse = ", ")
))
