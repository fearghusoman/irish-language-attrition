# Maps Gorilla's per-question `Object ID` (stable across builder edits) to a
# clean variable name.
#
# `Object Name` is NOT a safe key on its own: it's sometimes a custom label
# (e.g. "rs_culture") and sometimes just the generic widget type ("Dropdown",
# "Multiple Choice"), and the same custom label is reused for genuinely
# different questions elsewhere in the form (e.g. "dd_proficiency" is used
# both for the no-Leaving-Cert fallback proficiency question AND for
# Language 1's proficiency question; "rs_confidence" is used both for the
# motivation-confidence item and for the "confident in my overall Irish
# ability" learning-experience item). Object ID is the only unique key.
#
# This table was built by hand this session, reading every distinct
# (Object ID, Question, Context) triple out of
# results/data-questionnaire-cimk (5).csv. If the Gorilla task builder is
# ever edited (questions added/removed), re-derive it the same way.

library(tibble)

gorilla_object_map <- function() {
  tribble(
    ~object_id, ~variable_name, ~section, ~multiselect,

    # Part 1 -- General background (Q1-11)
    "object-5", "age", "part1", FALSE,
    "object-6", "gender", "part1", FALSE,
    "object-7", "region_residence", "part1", FALSE,
    "object-8", "irish_l1_status", "part1", FALSE,
    "object-9", "age_began_learning", "part1", FALSE,
    "object-10", "informal_exposure_before", "part1", FALSE,
    "object-18", "informal_exposure_context", "part1", FALSE,
    "object-11", "gaeltacht_contact", "part1", FALSE,
    "object-19", "gaeltacht_contact_context", "part1", FALSE,
    "object-13", "current_use_frequency", "part1", FALSE,
    "object-14", "current_use_contexts", "part1", TRUE,
    "object-15", "irish_related_occupation", "part1", FALSE,
    "object-16", "is_parent", "part1", FALSE,
    "object-17", "parent_engagement", "part1", FALSE,

    # Part 2 -- Proficiency at end of instruction (Q12-15)
    "object-21", "leaving_cert_year", "part2", FALSE,
    "object-23", "leaving_cert_paper", "part2", FALSE,
    "object-24", "no_lc_self_rated_proficiency", "part2", FALSE,
    "object-25", "no_lc_assessment_method", "part2", FALSE,
    "object-26", "leaving_cert_grade", "part2", FALSE,
    "object-28", "continued_study_after_lc", "part2", FALSE,
    # NOTE: as deployed in Gorilla this is a single combined free-text field
    # ("until what year, in what context, what result") rather than the 3
    # separate fields (continued_study_until_year/context/result) used in the
    # app/src build -- a build-vs-build inconsistency, not a bug in this map.
    "object-29", "continued_study_details", "part2", FALSE,

    # Part 3 -- Exposure since instruction (Q16-20)
    "object-32", "exposure_signage_media", "part3", FALSE,
    "object-34", "exposure_conversations", "part3", FALSE,
    "object-35", "exposure_media_consumption", "part3", FALSE,
    "object-36", "exposure_events", "part3", FALSE,
    "object-37", "exposure_family_social", "part3", FALSE,

    # Part 4 -- Motivation (Q21-28 as deployed; see codebook deviation note)
    "object-40", "integrative_q21", "part4", FALSE,
    "object-41", "integrative_q22", "part4", FALSE,
    "object-42", "integrative_q23", "part4", FALSE,
    "object-43", "integrative_q24", "part4", FALSE,
    "object-44", "instrumental_q25", "part4", FALSE,
    "object-45", "instrumental_q26", "part4", FALSE,
    "object-46", "instrumental_q27", "part4", FALSE,
    "object-90", "motivation_confidence_q28", "part4", FALSE,

    # Part 5 -- Multilingualism (Q29 gate onward)
    "object-49", "has_additional_languages", "part5", FALSE,
    "object-50", "additional_languages_count_self_report", "part5", FALSE,
    "object-122", "lang1_name", "part5", FALSE,
    "object-52", "lang1_proficiency", "part5", FALSE,
    "object-53", "lang1_acquisition_context", "part5", TRUE,
    "object-54", "lang1_acquisition_timing_duration", "part5", FALSE,
    "object-55", "lang1_lc_status", "part5", FALSE,
    "object-56", "lang1_use_frequency", "part5", FALSE,
    "object-57", "lang1_use_contexts", "part5", TRUE,
    "object-123", "lang2_name", "part5", FALSE,
    "object-52-1", "lang2_proficiency", "part5", FALSE,
    "object-53-1", "lang2_acquisition_context", "part5", TRUE,
    "object-54-1", "lang2_acquisition_timing_duration", "part5", FALSE,
    "object-55-1", "lang2_lc_status", "part5", FALSE,
    "object-56-1", "lang2_use_frequency", "part5", FALSE,
    "object-57-1", "lang2_use_contexts", "part5", TRUE,
    # Brief-overflow slots (3rd/4th+ languages, name + use-frequency only)
    "object-80", "lang3_name", "part5", FALSE,
    "object-81", "lang3_use_frequency", "part5", FALSE,
    "object-88", "lang4_name", "part5", FALSE,
    "object-89", "lang4_use_frequency", "part5", FALSE,

    # Part 6 -- Background-only variables
    "object-61", "primary_school_type", "part6", FALSE,
    "object-62", "secondary_school_type", "part6", FALSE,
    "object-63", "highest_education", "part6", FALSE,
    "object-64", "secondary_school_region", "part6", FALSE,
    "object-125", "lived_abroad", "part6", FALSE,
    "object-126", "years_abroad", "part6", FALSE,
    "object-127", "abroad_irish_access", "part6", FALSE,
    "object-94", "attitude_q34", "part6", FALSE,
    "object-96", "attitude_q35", "part6", FALSE, # Object Name "rs_identity" is misleading -- this is an attitude item, not linguistic identity
    "object-97", "attitude_q36", "part6", FALSE,
    "object-99", "learning_exp_q37", "part6", FALSE,
    "object-100", "learning_exp_q38", "part6", FALSE,
    "object-101", "learning_exp_q39", "part6", FALSE, # Object Name "rs_confidence" reused; NOT the same question as object-90
    "object-102", "learning_exp_q40", "part6", FALSE,
    "object-104", "classroom_anxiety_q41", "part6", FALSE,
    "object-105", "classroom_anxiety_q42", "part6", FALSE,
    "object-107", "parental_encouragement_q43", "part6", FALSE,
    "object-108", "parental_encouragement_q44", "part6", FALSE, # Object Name "rs_interest" is misleading -- parental interest, not integrative interest (that's object-42)
    "object-109", "parental_encouragement_q45", "part6", FALSE,
    "object-110", "parental_encouragement_q46", "part6", FALSE,
    "object-112", "family_irish_proficiency_parent", "part6", FALSE,
    "object-113", "family_irish_proficiency_helper", "part6", FALSE,
    "object-115", "linguistic_identity_q49", "part6", FALSE,
    "object-116", "linguistic_identity_q50", "part6", FALSE,
    "object-118", "self_rated_attrition_q51", "part6", FALSE,
    "object-120", "reconnection_motivation_q52", "part6", FALSE,
    "object-121", "reconnection_channels", "part6", TRUE
  )
}
