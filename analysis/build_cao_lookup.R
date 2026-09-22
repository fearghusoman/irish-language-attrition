#!/usr/bin/env Rscript
#
# build_cao_lookup.R
#
# Builds `cao_lookup`, the CAO-points-by-year conversion table referenced in
# the @param cao_lookup doc block, and writes it to data-raw/cao_lookup.csv
# and data/cao_lookup.rda (adjust paths to match this repo's layout).
#
# ---------------------------------------------------------------------------
# WHY THE TABLE STARTS IN 1992, NOT 1970
# ---------------------------------------------------------------------------
# There is no national CAO points table before 1992, so a table "back to
# 1970" isn't something that can be sourced -- it doesn't exist historically:
#   - The CAO itself was founded in 1976; its first student intake was 1978.
#     Before that, Irish third-level institutions ran independent admissions
#     with their own entry criteria -- there was no centralised points scale
#     of any kind.
#   - Even after CAO started (1978-1991), each institution/faculty scored
#     the Leaving Cert its own way. The single, common, national
#     "points scale" everyone associates with CAO points only came into
#     operation in 1992.
#   - The grading scale itself changed again in August 2017 (old letter
#     grades A1/A2/B1... -> today's H1-H8 / O1-O8 / F1-F8 scale), and a
#     25-point Higher Level Maths bonus was introduced in 2012.
#
# So this table covers 1992-present across the two grading eras that
# actually existed. Any row lookup for a year before 1992 will correctly
# fall through to the caller's existing "no cao_lookup row -> NA + warning"
# path, because there is nothing to look up, not because data is missing.
#
# IMPORTANT LIMITATION -- the Higher Level Maths bonus is NOT in this table.
# The bonus (25 points, from 2012, for a Higher grade of D3/H6 or better)
# applies only when the subject is Mathematics; it does not depend on
# leaving_cert_paper/leaving_cert_grade alone, so it cannot be represented
# as a row in a (year, paper, grade) -> points table. If proficiency_score
# needs to reflect the maths bonus, that has to be applied as a separate
# subject-aware adjustment on top of this lookup, not inside it.
#
# Sources (fetched 2026-09-22):
#   - CAO, "Irish Leaving Certificate Examination Points Calculation Grid"
#     https://www.cao.ie/index.php?page=scoring&s=lcepointsgrid
#   - CAO, "The Common Points Scale" https://www.cao.ie/index.php?page=newcps
#   - CAO, "New Common Points Scale for Entry to Higher Education from 2017"
#     https://www2.cao.ie/downloads/documents/CommonPointsScale2017.pdf
#   - CAO, "Bonus Points for Higher Level Leaving Certificate Mathematics"
#     https://www2.cao.ie/otherinfo/calc_points.pdf
#   - Wikipedia, "Central Applications Office"
#     https://en.wikipedia.org/wiki/Central_Applications_Office
#   - Wikipedia, "Academic grading in the Republic of Ireland"
#     https://en.wikipedia.org/wiki/Academic_grading_in_the_Republic_of_Ireland
#
# Cross-checked the pre-2017 and post-2017 point grids against two
# independent sources (the CAO PDF and a school careers-office PDF mirroring
# the same CAO table); both agreed on every value used below.
# ---------------------------------------------------------------------------

## --- Era 1: 1992-2016, old letter grades ------------------------------

old_grades <- data.frame(
  leaving_cert_grade = c("A1", "A2", "B1", "B2", "B3",
                          "C1", "C2", "C3", "D1", "D2", "D3",
                          "E", "F", "NG"),
  Higher   = c(100, 88, 88, 77, 77, 66, 66, 56, 56, 46, 46, 33, 0, 0),
  Ordinary = c( 56, 46, 46, 37, 37, 28, 28, 20, 20, 12, 12,  0, 0, 0),
  stringsAsFactors = FALSE
)

old_long <- do.call(rbind, lapply(c("Higher", "Ordinary"), function(paper) {
  data.frame(
    leaving_cert_paper = paper,
    leaving_cert_grade = old_grades$leaving_cert_grade,
    points = old_grades[[paper]],
    stringsAsFactors = FALSE
  )
}))

old_years <- 1992:2016
old_table <- do.call(rbind, lapply(old_years, function(yr) {
  cbind(leaving_cert_year = yr, old_long)
}))

## --- Era 2: 2017-present, H/O/F grades ---------------------------------

new_grades <- data.frame(
  leaving_cert_grade = c("H1", "H2", "H3", "H4", "H5", "H6", "H7", "H8"),
  Higher = c(100, 88, 77, 66, 56, 46, 37, 0),
  stringsAsFactors = FALSE
)
new_grades_o <- data.frame(
  leaving_cert_grade = c("O1", "O2", "O3", "O4", "O5", "O6", "O7", "O8"),
  Ordinary = c(56, 46, 37, 28, 20, 12, 0, 0),
  stringsAsFactors = FALSE
)
# Foundation level is 0 points for standard CAO purposes for every grade
# (F1-F8); a small number of HEIs additionally award Foundation-level MATHS
# specifically 20/12 points for F1/F2, but that is an institution-specific,
# subject-specific exception documented separately by CAO, not part of the
# common points scale, so it is deliberately left out of this general
# paper-level table (same reasoning as the maths bonus, above).
new_grades_f <- data.frame(
  leaving_cert_grade = c("F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8"),
  Foundation = 0,
  stringsAsFactors = FALSE
)

new_long <- rbind(
  data.frame(leaving_cert_paper = "Higher",
             leaving_cert_grade = new_grades$leaving_cert_grade,
             points = new_grades$Higher, stringsAsFactors = FALSE),
  data.frame(leaving_cert_paper = "Ordinary",
             leaving_cert_grade = new_grades_o$leaving_cert_grade,
             points = new_grades_o$Ordinary, stringsAsFactors = FALSE),
  data.frame(leaving_cert_paper = "Foundation",
             leaving_cert_grade = new_grades_f$leaving_cert_grade,
             points = new_grades_f$Foundation, stringsAsFactors = FALSE)
)

# Extend to the current calendar year at build time; re-run this script (or
# just bump this bound) each year the grid doesn't change -- it hasn't
# changed since August 2017.
current_year <- as.integer(format(Sys.Date(), "%Y"))
new_years <- 2017:current_year
new_table <- do.call(rbind, lapply(new_years, function(yr) {
  cbind(leaving_cert_year = yr, new_long)
}))

## --- Combine -------------------------------------------------------------

cao_lookup <- rbind(old_table, new_table)
cao_lookup$leaving_cert_year  <- as.integer(cao_lookup$leaving_cert_year)
cao_lookup$leaving_cert_paper <- as.character(cao_lookup$leaving_cert_paper)
cao_lookup$leaving_cert_grade <- as.character(cao_lookup$leaving_cert_grade)
cao_lookup$points             <- as.numeric(cao_lookup$points)
rownames(cao_lookup) <- NULL
cao_lookup <- cao_lookup[order(cao_lookup$leaving_cert_year,
                                cao_lookup$leaving_cert_paper,
                                cao_lookup$leaving_cert_grade), ]

## --- Sanity checks --------------------------------------------------------

stopifnot(
  all(c("leaving_cert_year", "leaving_cert_paper", "leaving_cert_grade",
        "points") %in% names(cao_lookup)),
  !anyNA(cao_lookup),
  nrow(unique(cao_lookup[c("leaving_cert_year", "leaving_cert_paper",
                            "leaving_cert_grade")])) == nrow(cao_lookup),
  min(cao_lookup$leaving_cert_year) == 1992,
  max(cao_lookup$leaving_cert_year) == current_year,
  all(cao_lookup$points >= 0), all(cao_lookup$points <= 100)
)

## --- Write outputs ---------------------------------------------------------

out_dir <- "."
write.csv(cao_lookup,
          file = file.path(out_dir, "cao_lookup.csv"),
          row.names = FALSE)
saveRDS(cao_lookup, file.path(out_dir, "cao_lookup.rds"))

cat(sprintf(
  "Built cao_lookup: %d rows, years %d-%d, papers: %s\n",
  nrow(cao_lookup), min(cao_lookup$leaving_cert_year),
  max(cao_lookup$leaving_cert_year),
  paste(sort(unique(cao_lookup$leaving_cert_paper)), collapse = ", ")
))
