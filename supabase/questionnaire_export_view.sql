-- Reshapes the normalized questionnaire_part1..part6 + additional_languages
-- tables into the single wide, one-row-per-participant shape the researcher's
-- R analysis script (irish-attrition-analysis-script-v1) expects: one column
-- per item, named "Q1".."Q53" (quoted/mixed-case so the exact column names
-- survive into the CSV header, matching the script's `c("Q16", "Q17", ...)`
-- style column selection).
--
-- We deliberately did NOT flatten the base tables themselves into this wide
-- shape — the normalized tables are what make per-Part writes validate
-- correctly under insert-only RLS from an untrusted client. This view is the
-- read-side adapter that produces the analysis-ready export without giving
-- up that write-side safety.
--
-- Not readable by anon: no GRANT is issued on this view to anon, so (like the
-- base tables) it's only queryable via the service_role key / SQL editor.
--
-- Usage: run this once (as service_role), then for each export:
--   SELECT * FROM questionnaire_export;  -- and save as questionnaire_data.csv
--
-- Run alongside schema.sql; re-run (CREATE OR REPLACE) after any future
-- questionnaire schema changes.

create or replace function freq_label(code smallint)
returns text
language sql
immutable
as $$
  select case code
    when 1 then 'Never'
    when 2 then 'Rarely'
    when 3 then 'Occasionally'
    when 4 then 'Often'
    when 5 then 'Daily or almost daily'
  end
$$;

create or replace view questionnaire_export as
select
  p.participant_id,

  -- Part 1 — general background (Q1-11)
  p1.age                                     as "Q1",
  p1.gender                                  as "Q2",
  p1.region_residence                        as "Q3",
  p1.irish_l1_status                         as "Q4",
  p1.age_began_learning                      as "Q5",
  p1.informal_exposure_before                as "Q6",
  p1.informal_exposure_context               as q6_context,
  p1.gaeltacht_contact                       as "Q7",
  p1.gaeltacht_contact_context               as q7_context,
  p1.current_use_frequency                   as "Q8",
  p1.current_use_contexts                    as "Q9",
  p1.irish_related_occupation                as "Q10",
  p1.is_parent                               as "Q11",
  p1.parent_engagement                       as q11_engagement,

  -- Part 2 — proficiency at end of instruction (Q12-15). Q12-14 are exactly
  -- the columns the script's commented-out CAO lookup join expects
  -- (`left_join(cao_lookup, by = c("Q12" = "exam_year", "Q13" = "level",
  -- "Q14" = "grade"))`) — note our stored vocabulary for Q13/Q14 is lowercase
  -- ('higher'/'ordinary'/'foundation'/'did_not_sit', 'a'..'f'); the CAO
  -- lookup table will need to use the same casing or the join needs a
  -- case-normalizing step.
  p2.leaving_cert_year                       as "Q12",
  p2.leaving_cert_paper                      as "Q13",
  p2.leaving_cert_grade                      as "Q14",
  p2.continued_study_after_lc                as "Q15",
  p2.no_lc_self_rated_proficiency            as no_lc_self_rated_proficiency,
  p2.no_lc_assessment_method                 as no_lc_assessment_method,
  p2.continued_study_until_year              as continued_study_until_year,
  p2.continued_study_context                 as continued_study_context,
  p2.continued_study_result                  as continued_study_result,

  -- Part 3 — exposure since instruction (Q16-20). Numeric 1-5, matching the
  -- script's rowMeans(quest_raw[, exposure_items]) expectation directly.
  p3.exposure_signage_media                  as "Q16",
  p3.exposure_conversations                  as "Q17",
  p3.exposure_media_consumption              as "Q18",
  p3.exposure_events                         as "Q19",
  p3.exposure_family_social                  as "Q20",

  -- Part 4 — motivation (Q21-28)
  p4.integrative_q21                         as "Q21",
  p4.integrative_q22                         as "Q22",
  p4.integrative_q23                         as "Q23",
  p4.integrative_q24                         as "Q24",
  p4.instrumental_q25                        as "Q25",
  p4.instrumental_q26                        as "Q26",
  -- NOTE: the codebook defines instrumental motivation as 3 items (Q25-27),
  -- but the WIP script's `instrumental_items` vector currently only lists
  -- Q25-Q26. We still export Q27 here rather than silently drop it — flag
  -- this back to the analyst so they can confirm whether Q27 was
  -- deliberately left out or just not wired up yet.
  p4.instrumental_q27                        as "Q27",
  p4.motivation_confidence_q28               as "Q28",

  -- Part 5 — multilingualism. Q29 is the gate; lang1_freq/lang2_freq/
  -- lang_overflow match the exact placeholder shape the WIP script's
  -- Section 4 currently parses (frequency LABEL strings, not our numeric
  -- 1-5 codes, since `is_active()` does a string %in% check).
  p5.has_additional_languages                as "Q29",
  p5.additional_languages_count_self_report  as q29_count_self_report,
  lang.lang1_freq,
  lang.lang2_freq,
  lang.lang_overflow,

  -- Part 6 — background-only (Q30-53)
  p6.primary_school_type                     as "Q30",
  p6.secondary_school_type                   as "Q31",
  p6.highest_education                       as "Q32",
  p6.secondary_school_region                 as "Q33",
  p6.attitude_q34                            as "Q34",
  p6.attitude_q35                            as "Q35",
  p6.attitude_q36                            as "Q36",
  p6.learning_exp_q37                        as "Q37",
  p6.learning_exp_q38                        as "Q38",
  p6.learning_exp_q39                        as "Q39",
  p6.learning_exp_q40                        as "Q40",
  p6.classroom_anxiety_q41                   as "Q41",
  p6.classroom_anxiety_q42                   as "Q42",
  p6.parental_encouragement_q43              as "Q43",
  p6.parental_encouragement_q44              as "Q44",
  p6.parental_encouragement_q45              as "Q45",
  p6.parental_encouragement_q46              as "Q46",
  p6.family_irish_proficiency_parent         as "Q47",
  p6.family_irish_proficiency_helper         as "Q48",
  p6.linguistic_identity_q49                 as "Q49",
  p6.linguistic_identity_q50                 as "Q50",
  p6.self_rated_attrition_q51                as "Q51",
  p6.reconnection_motivation_q52             as "Q52",
  p6.reconnection_channels                   as "Q53"

from participants p
left join questionnaire_part1 p1 on p1.participant_id = p.participant_id
left join questionnaire_part2 p2 on p2.participant_id = p.participant_id
left join questionnaire_part3 p3 on p3.participant_id = p.participant_id
left join questionnaire_part4 p4 on p4.participant_id = p.participant_id
left join questionnaire_part5_summary p5 on p5.participant_id = p.participant_id
left join questionnaire_part6 p6 on p6.participant_id = p.participant_id
left join lateral (
  select
    freq_label(max(case when al.language_order = 1 then al.use_frequency end)) as lang1_freq,
    freq_label(max(case when al.language_order = 2 then al.use_frequency end)) as lang2_freq,
    string_agg(
      case when al.language_order >= 3
        then al.language_name || ': ' || freq_label(al.use_frequency)
      end,
      '; ' order by al.language_order
    ) as lang_overflow
  from additional_languages al
  where al.participant_id = p.participant_id
) lang on true;
