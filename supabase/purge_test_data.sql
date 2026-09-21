-- Purge test-mode data from Supabase.
--
-- Scope: only rows belonging to participants where participants.is_test = true
-- (i.e. sessions run with VITE_TEST_MODE=true — see app/src/lib/testMode.js and
-- schema.sql's comment on participants.is_test). Real participant submissions
-- (is_test = false) are left untouched.
--
-- Not touched by this script:
--   - word_items: static vocabulary reference data, not participant data.
--   - contact_optins: fully decoupled from participants (no participant_id/FK,
--     see schema.sql), so there is no reliable way to tell a test opt-in from
--     a real one. Purge manually by email if needed.
--
-- Every table has RLS with only an "anon may INSERT" policy (see schema.sql) —
-- there is no anon DELETE policy. Run this in the Supabase SQL editor (or via
-- the service_role key), which runs as postgres and bypasses RLS.
--
-- Child tables are deleted before `participants` because none of the
-- participant_id foreign keys are declared ON DELETE CASCADE.

begin;

delete from trials
  where participant_id in (select participant_id from participants where is_test);

delete from questionnaire_part1
  where participant_id in (select participant_id from participants where is_test);

delete from questionnaire_part2
  where participant_id in (select participant_id from participants where is_test);

delete from questionnaire_part3
  where participant_id in (select participant_id from participants where is_test);

delete from questionnaire_part4
  where participant_id in (select participant_id from participants where is_test);

delete from questionnaire_part5_summary
  where participant_id in (select participant_id from participants where is_test);

delete from additional_languages
  where participant_id in (select participant_id from participants where is_test);

delete from questionnaire_part6
  where participant_id in (select participant_id from participants where is_test);

delete from session_events
  where participant_id in (select participant_id from participants where is_test);

delete from participants
  where is_test;

commit;
