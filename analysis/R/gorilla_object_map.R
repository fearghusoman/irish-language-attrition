# Maps Gorilla's per-question `Object ID` (stable across builder edits, but
# NOT stable across builder *revisions* -- see below) to a clean variable
# name, for the real wide-format questionnaire export
# (results/21092026/data_exp_279099-vall_questionnaires.xlsx).
#
# `Object Name` is not a safe key on its own: it's sometimes a custom label
# and sometimes just the generic widget-type prefix, and the same custom
# label can be reused for genuinely different questions (e.g. "dd_region"
# is used for both current region of residence and secondary-school
# region). Object ID is the only unique key, and in this export it's
# embedded directly in each column header (e.g. "dd_gender object-6
# Response") rather than living in its own column.
#
# IMPORTANT: this table was rebuilt from scratch against the real export's
# 207 headers. The object IDs here do NOT match an earlier version of this
# map that was hand-built from a pilot/sample export
# (results/data-questionnaire-cimk (5).csv) -- several questions were
# added, removed, or renumbered between that pilot build and the final one
# actually used to collect the real 47-participant data (e.g. object-45,
# a 3rd instrumental-motivation item, no longer exists; object-90, the
# motivation-confidence check, was renumbered to object-144). If the
# Gorilla task builder is edited again, re-derive this table the same way:
# read every distinct "<code> object-<N> <suffix>" header out of the
# current export and match it against the question wording in
# irish-attrition-questionnaire-v35.md.

library(tibble)

questionnaire_object_map <- function() {
  tribble(
    ~object_id, ~variable_name, ~section,

    # Part 1 -- General background (Q1-11)
    "object-5", "age", "part1",
    "object-6", "gender", "part1",
    "object-7", "region_residence", "part1",
    "object-8", "irish_l1_status", "part1",
    "object-9", "age_began_learning", "part1",
    "object-10", "informal_exposure_before", "part1",
    "object-18", "informal_exposure_context", "part1",
    "object-11", "gaeltacht_contact", "part1",
    "object-156", "gaeltacht_contact_context", "part1", # renumbered from the old map's object-19
    "object-13", "current_use_frequency", "part1",
    "object-14", "current_use_contexts", "part1", # multiselect (one column per option)
    "object-15", "irish_related_occupation", "part1",
    "object-159", "irish_related_occupation_context", "part1", # new free-text follow-up, not in v35
    "object-16", "is_parent", "part1",
    "object-17", "parent_engagement", "part1",

    # Part 2 -- Proficiency at end of instruction (Q12-15)
    "object-21", "leaving_cert_year", "part2",
    "object-23", "leaving_cert_paper", "part2",
    "object-157", "no_lc_self_rated_proficiency", "part2", # renumbered from the old map's object-24
    "object-158", "no_lc_context", "part2", # renumbered/renamed from the old map's object-25 (no_lc_assessment_method)
    "object-26", "leaving_cert_grade", "part2",
    "object-28", "continued_study_after_lc", "part2",
    "object-29", "continued_study_details", "part2",

    # Part 3 -- Exposure since instruction (Q16-20)
    "object-32", "exposure_signage_media", "part3",
    "object-34", "exposure_conversations", "part3",
    "object-35", "exposure_media_consumption", "part3",
    "object-36", "exposure_events", "part3",
    "object-37", "exposure_family_social", "part3",

    # Part 4 -- Motivation (Q21-27)
    # NOTE: object-45 (a 3rd instrumental item, "rs_personal_int") from the
    # pilot build does not exist in the real build -- only 2 instrumental
    # items were actually fielded, matching v35's Q25-26.
    "object-40", "integrative_q21", "part4",
    "object-41", "integrative_q22", "part4",
    "object-42", "integrative_q23", "part4",
    "object-43", "integrative_q24", "part4",
    "object-44", "instrumental_q25", "part4",
    "object-46", "instrumental_q26", "part4",
    "object-144", "motivation_confidence_q28", "part4", # renumbered from the old map's object-90 (Q27, "confident in your answers to the six statements above")

    # Part 5 -- Multilingualism (Q28)
    "object-49", "has_additional_languages", "part5",
    "object-50", "additional_languages_count_self_report", "part5",
    "object-122", "lang1_name", "part5",
    "object-52", "lang1_proficiency", "part5",
    "object-53", "lang1_acquisition_context", "part5", # multiselect
    "object-54", "lang1_acquisition_timing_duration", "part5",
    "object-55", "lang1_lc_status", "part5",
    "object-160", "lang1_lc_grade", "part5", # new field, not in the old map
    "object-56", "lang1_use_frequency", "part5",
    "object-57", "lang1_use_contexts", "part5", # multiselect
    "object-123", "lang2_name", "part5",
    "object-52-1", "lang2_proficiency", "part5",
    "object-53-1", "lang2_acquisition_context", "part5", # multiselect
    "object-54-1", "lang2_acquisition_timing_duration", "part5",
    "object-55-1", "lang2_lc_status", "part5",
    "object-161", "lang2_lc_grade", "part5", # new field, not in the old map
    "object-56-1", "lang2_use_frequency", "part5",
    "object-57-1", "lang2_use_contexts", "part5", # multiselect
    # Brief-overflow slots (3rd/4th+ languages, name + use-frequency only)
    "object-80", "lang3_name", "part5",
    "object-81", "lang3_use_frequency", "part5",
    "object-88", "lang4_name", "part5",
    "object-89", "lang4_use_frequency", "part5",

    # Part 6 -- Background-only variables
    "object-61", "primary_school_type", "part6",
    "object-62", "secondary_school_type", "part6",
    "object-63", "highest_education", "part6",
    "object-64", "secondary_school_region", "part6",
    "object-125", "lived_abroad", "part6",
    "object-126", "years_abroad", "part6",
    "object-127", "abroad_irish_access", "part6",
    "object-155", "abroad_irish_access_context", "part6", # new free-text follow-up, not in v35
    "object-94", "attitude_q34", "part6",
    "object-96", "attitude_q35", "part6", # Object Name "rs_identity" is misleading -- an attitude item, not linguistic identity
    "object-97", "attitude_q36", "part6",
    "object-137", "learning_exp_q37", "part6", # renumbered from the old map's object-99
    "object-138", "learning_exp_q38", "part6", # renumbered from the old map's object-100
    "object-139", "learning_exp_q39", "part6", # renumbered from the old map's object-101
    "object-140", "learning_exp_q40", "part6", # renumbered from the old map's object-102
    "object-142", "classroom_anxiety_q41", "part6", # renumbered from the old map's object-104
    "object-143", "classroom_anxiety_q42", "part6", # renumbered from the old map's object-105
    "object-148", "parental_encouragement_q43", "part6", # renumbered from the old map's object-107
    "object-149", "parental_encouragement_q44", "part6", # renumbered from the old map's object-108
    "object-150", "parental_encouragement_q45", "part6", # renumbered from the old map's object-109
    "object-151", "parental_encouragement_q46", "part6", # renumbered from the old map's object-110
    "object-153", "family_irish_proficiency_parent", "part6", # renumbered from the old map's object-112
    "object-154", "family_irish_proficiency_helper", "part6", # renumbered from the old map's object-113
    "object-115", "linguistic_identity_q49", "part6",
    "object-116", "linguistic_identity_q50", "part6",
    "object-118", "self_rated_attrition_q51", "part6",
    "object-120", "reconnection_motivation_q52", "part6",
    "object-121", "reconnection_channels", "part6" # multiselect
  )
}
