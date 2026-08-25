-- Irish L2 Lexical Attrition Study — Supabase schema
--
-- Security model (applies uniformly to every table below):
--   - RLS is enabled on every table, no exceptions.
--   - The ONLY policy type anywhere is "anon may INSERT" — never SELECT/UPDATE/DELETE.
--   - word_items has NO anon policy at all (seeded once via service_role, which bypasses RLS).
--   - Defense in depth: REVOKE ALL + explicit GRANT INSERT, independent of the RLS policies,
--     so a future RLS misconfiguration alone can't reopen read/write access.
--   - The researcher exports data via the service_role key (SQL editor / dashboard), never
--     through the public anon endpoint.
--
-- Run this once against a fresh Supabase project (EU region, e.g. Frankfurt, for GDPR).
-- Then run supabase/seed_word_items.sql (also via service_role) to load the 60 word items.

-- ============================================================================
-- participants
-- ============================================================================

create table participants (
  participant_id uuid primary key,
  consent_given boolean not null,
  age_18_plus_confirmed boolean not null,
  consent_version text not null default 'v28',
  app_version text,
  consented_at timestamptz not null default now(),

  constraint participants_consent_required check (consent_given and age_18_plus_confirmed)
);

alter table participants enable row level security;

revoke all on participants from anon;
grant insert on participants to anon;

create policy insert_only_anon on participants
  for insert to anon
  with check (true);

-- ============================================================================
-- word_items — static reference data, seeded once via service_role
-- ============================================================================

create table word_items (
  item_id smallint primary key,
  category text not null check (category in ('concrete_noun', 'abstract_noun', 'verb', 'adjective')),
  irish_target text not null,
  english_gloss text not null,
  english_gloss_alternatives text[] not null,
  word_length smallint not null,
  freq_rank smallint not null,
  familiarity_rating smallint check (familiarity_rating between 1 and 7)
);

alter table word_items enable row level security;

revoke all on word_items from anon;
-- Deliberately no policies at all for anon: not even SELECT. The running app loads
-- app/src/data/wordlist.json instead; this table exists purely as a DB-side FK
-- integrity anchor for trials.item_id and a convenience export target.

-- ============================================================================
-- trials — long format, one row per trial
-- ============================================================================

create table trials (
  trial_id bigint generated always as identity primary key,
  participant_id uuid not null references participants (participant_id),
  item_id smallint not null references word_items (item_id),
  phase text not null check (phase in ('recall', 'recognition')),
  irish_target text not null,
  english_gloss text not null,
  category text not null check (category in ('concrete_noun', 'abstract_noun', 'verb', 'adjective')),
  word_length smallint not null,
  freq_rank smallint not null,
  response_text text not null default '',
  response_time_ms integer not null check (response_time_ms between 0 and 20000),
  timed_out boolean not null default false,
  -- Boolean (not 'match'/'no_match' text) so it round-trips as R logical
  -- TRUE/FALSE via a plain CSV export — the analysis script does
  -- `live_match_result == TRUE` directly on this column.
  live_match_result boolean not null,
  trial_sequence smallint not null check (trial_sequence between 1 and 60),
  client_submitted_at timestamptz not null default now(),

  constraint trials_unique_participant_item_phase unique (participant_id, item_id, phase)
);

create index trials_participant_id_idx on trials (participant_id);

alter table trials enable row level security;

revoke all on trials from anon;
grant insert on trials to anon;
grant usage, select on sequence trials_trial_id_seq to anon;

create policy insert_only_anon on trials
  for insert to anon
  with check (true);

-- ============================================================================
-- questionnaire_part1 — Q1-11, general background
-- ============================================================================

create table questionnaire_part1 (
  participant_id uuid primary key references participants (participant_id),
  age smallint not null check (age between 18 and 120),
  gender text not null check (gender in ('female', 'male', 'non_binary', 'prefer_not_to_say')),
  region_residence text not null check (region_residence in ('leinster', 'munster', 'connacht', 'ulster')),
  irish_l1_status text not null check (
    irish_l1_status in ('first_language_home', 'second_language_school', 'mix_of_both')
  ),
  age_began_learning smallint not null check (age_began_learning between 0 and 120),
  informal_exposure_before boolean not null,
  informal_exposure_context text,
  gaeltacht_contact boolean not null,
  gaeltacht_contact_context text,
  current_use_frequency smallint not null check (current_use_frequency between 1 and 5),
  current_use_contexts text[] not null default '{}',
  irish_related_occupation boolean not null,
  is_parent boolean not null,
  parent_engagement text check (
    parent_engagement in ('yes_currently', 'yes_in_past', 'no', 'not_applicable')
  ),
  submitted_at timestamptz not null default now(),

  constraint part1_parent_engagement_requires_parent check (
    (is_parent and parent_engagement is not null) or (not is_parent and parent_engagement is null)
  )
);

alter table questionnaire_part1 enable row level security;
revoke all on questionnaire_part1 from anon;
grant insert on questionnaire_part1 to anon;
create policy insert_only_anon on questionnaire_part1 for insert to anon with check (true);

-- ============================================================================
-- questionnaire_part2 — Q12-15, proficiency at end of instruction
-- ============================================================================

create table questionnaire_part2 (
  participant_id uuid primary key references participants (participant_id),
  leaving_cert_year smallint,
  leaving_cert_paper text not null check (
    leaving_cert_paper in ('higher', 'ordinary', 'foundation', 'did_not_sit')
  ),
  no_lc_self_rated_proficiency text check (
    no_lc_self_rated_proficiency in ('beginner', 'intermediate', 'advanced', 'fluent')
  ),
  no_lc_assessment_method text,
  leaving_cert_grade text check (leaving_cert_grade in ('a', 'b', 'c', 'd', 'e', 'f')),
  continued_study_after_lc boolean not null,
  continued_study_until_year smallint,
  continued_study_context text,
  continued_study_result text,
  submitted_at timestamptz not null default now(),

  constraint part2_did_not_sit_requires_fallback check (
    (leaving_cert_paper = 'did_not_sit' and no_lc_self_rated_proficiency is not null)
    or (leaving_cert_paper <> 'did_not_sit')
  )
);

alter table questionnaire_part2 enable row level security;
revoke all on questionnaire_part2 from anon;
grant insert on questionnaire_part2 to anon;
create policy insert_only_anon on questionnaire_part2 for insert to anon with check (true);

-- ============================================================================
-- questionnaire_part3 — Q16-20, exposure since instruction (frequency composite)
-- ============================================================================

create table questionnaire_part3 (
  participant_id uuid primary key references participants (participant_id),
  exposure_signage_media smallint not null check (exposure_signage_media between 1 and 5),
  exposure_conversations smallint not null check (exposure_conversations between 1 and 5),
  exposure_media_consumption smallint not null check (exposure_media_consumption between 1 and 5),
  exposure_events smallint not null check (exposure_events between 1 and 5),
  exposure_family_social smallint not null check (exposure_family_social between 1 and 5),
  submitted_at timestamptz not null default now()
);

alter table questionnaire_part3 enable row level security;
revoke all on questionnaire_part3 from anon;
grant insert on questionnaire_part3 to anon;
create policy insert_only_anon on questionnaire_part3 for insert to anon with check (true);

-- ============================================================================
-- questionnaire_part4 — Q21-28, motivation
-- ============================================================================

create table questionnaire_part4 (
  participant_id uuid primary key references participants (participant_id),
  integrative_q21 smallint not null check (integrative_q21 between 1 and 5),
  integrative_q22 smallint not null check (integrative_q22 between 1 and 5),
  integrative_q23 smallint not null check (integrative_q23 between 1 and 5),
  integrative_q24 smallint not null check (integrative_q24 between 1 and 5),
  instrumental_q25 smallint not null check (instrumental_q25 between 1 and 5),
  instrumental_q26 smallint not null check (instrumental_q26 between 1 and 5),
  instrumental_q27 smallint not null check (instrumental_q27 between 1 and 5),
  motivation_confidence_q28 smallint not null check (motivation_confidence_q28 between 1 and 5),
  submitted_at timestamptz not null default now()
);

alter table questionnaire_part4 enable row level security;
revoke all on questionnaire_part4 from anon;
grant insert on questionnaire_part4 to anon;
create policy insert_only_anon on questionnaire_part4 for insert to anon with check (true);

-- ============================================================================
-- questionnaire_part5_summary — Q29 gate
-- ============================================================================

create table questionnaire_part5_summary (
  participant_id uuid primary key references participants (participant_id),
  has_additional_languages boolean not null,
  additional_languages_count_self_report smallint,
  submitted_at timestamptz not null default now()
);

alter table questionnaire_part5_summary enable row level security;
revoke all on questionnaire_part5_summary from anon;
grant insert on questionnaire_part5_summary to anon;
create policy insert_only_anon on questionnaire_part5_summary for insert to anon with check (true);

-- ============================================================================
-- additional_languages — repeatable Part 5 sub-form, 0..N rows per participant
-- ============================================================================

create table additional_languages (
  id bigint generated always as identity primary key,
  participant_id uuid not null references participants (participant_id),
  language_order smallint not null check (language_order >= 1),
  language_name text not null,
  detail_level text not null check (detail_level in ('full', 'brief')),
  proficiency text check (proficiency in ('beginner', 'intermediate', 'advanced', 'fluent')),
  acquisition_context text[],
  acquisition_timing_duration text,
  lc_status text check (lc_status in ('did_not_sit', 'ordinary', 'higher')),
  lc_grade text check (lc_grade in ('a', 'b', 'c', 'd', 'e', 'f')),
  use_frequency smallint not null check (use_frequency between 1 and 5),
  use_contexts text[],
  submitted_at timestamptz not null default now(),

  constraint additional_languages_unique_order unique (participant_id, language_order),
  constraint additional_languages_full_detail_requires_proficiency check (
    (detail_level = 'full' and proficiency is not null) or (detail_level = 'brief')
  )
);

create index additional_languages_participant_id_idx on additional_languages (participant_id);

alter table additional_languages enable row level security;
revoke all on additional_languages from anon;
grant insert on additional_languages to anon;
grant usage, select on sequence additional_languages_id_seq to anon;
create policy insert_only_anon on additional_languages for insert to anon with check (true);

-- ============================================================================
-- questionnaire_part6 — Q30-53, background-only variables
-- ============================================================================

create table questionnaire_part6 (
  participant_id uuid primary key references participants (participant_id),
  primary_school_type text not null check (primary_school_type in ('gaelscoil', 'english_medium', 'other')),
  secondary_school_type text not null check (secondary_school_type in ('gaelscoil', 'english_medium', 'other')),
  highest_education text not null check (
    highest_education in (
      'primary_education_only', 'junior_certificate', 'leaving_certificate',
      'plc_qualification', 'third_level_certificate_or_diploma', 'bachelors_degree',
      'postgraduate_diploma_or_masters', 'doctoral_degree', 'other'
    )
  ),
  secondary_school_region text not null check (
    secondary_school_region in ('leinster', 'munster', 'connacht', 'ulster')
  ),

  attitude_q34 smallint not null check (attitude_q34 between 1 and 5),
  attitude_q35 smallint not null check (attitude_q35 between 1 and 5),
  attitude_q36 smallint not null check (attitude_q36 between 1 and 5),

  learning_exp_q37 smallint not null check (learning_exp_q37 between 1 and 5),
  learning_exp_q38 smallint not null check (learning_exp_q38 between 1 and 5),
  learning_exp_q39 smallint not null check (learning_exp_q39 between 1 and 5),
  learning_exp_q40 smallint not null check (learning_exp_q40 between 1 and 5),

  classroom_anxiety_q41 smallint not null check (classroom_anxiety_q41 between 1 and 5),
  classroom_anxiety_q42 smallint not null check (classroom_anxiety_q42 between 1 and 5),

  parental_encouragement_q43 smallint not null check (parental_encouragement_q43 between 1 and 5),
  parental_encouragement_q44 smallint not null check (parental_encouragement_q44 between 1 and 5),
  parental_encouragement_q45 smallint not null check (parental_encouragement_q45 between 1 and 5),
  parental_encouragement_q46 smallint not null check (parental_encouragement_q46 between 1 and 5),

  family_irish_proficiency_parent boolean not null,
  family_irish_proficiency_helper boolean not null,

  linguistic_identity_q49 smallint not null check (linguistic_identity_q49 between 1 and 5),
  linguistic_identity_q50 smallint not null check (linguistic_identity_q50 between 1 and 5),

  self_rated_attrition_q51 smallint not null check (self_rated_attrition_q51 between 1 and 5),

  reconnection_motivation_q52 smallint not null check (reconnection_motivation_q52 between 1 and 5),
  reconnection_channels text[] not null default '{}',

  submitted_at timestamptz not null default now()
);

alter table questionnaire_part6 enable row level security;
revoke all on questionnaire_part6 from anon;
grant insert on questionnaire_part6 to anon;
create policy insert_only_anon on questionnaire_part6 for insert to anon with check (true);

-- ============================================================================
-- session_events — append-only funnel/diagnostics log
-- ============================================================================

create table session_events (
  id bigint generated always as identity primary key,
  participant_id uuid not null references participants (participant_id),
  event_type text not null check (
    event_type in (
      'consent_given', 'task_started', 'recall_completed',
      'recognition_completed', 'questionnaire_started', 'questionnaire_completed'
    )
  ),
  event_at timestamptz not null default now()
);

create index session_events_participant_id_idx on session_events (participant_id);

alter table session_events enable row level security;
revoke all on session_events from anon;
grant insert on session_events to anon;
grant usage, select on sequence session_events_id_seq to anon;
create policy insert_only_anon on session_events for insert to anon with check (true);

-- ============================================================================
-- contact_optins — fully decoupled from study data, no participant_id/FK
-- ============================================================================

create table contact_optins (
  id bigint generated always as identity primary key,
  email text not null,
  opted_in_at timestamptz not null default now()
);

alter table contact_optins enable row level security;
revoke all on contact_optins from anon;
grant insert on contact_optins to anon;
grant usage, select on sequence contact_optins_id_seq to anon;
create policy insert_only_anon on contact_optins for insert to anon with check (true);
