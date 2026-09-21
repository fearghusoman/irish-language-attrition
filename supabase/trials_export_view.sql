-- Filtered view of `trials` excluding test-mode sessions (participants.is_test)
-- — e.g. developer/researcher click-throughs run with a shortened wordlist
-- (VITE_TEST_MODE). Export from this view rather than the raw `trials` table
-- directly so those sessions never end up in task_trial_data.csv.
--
-- Not readable by anon: no GRANT is issued on this view to anon, same as the
-- base tables.
--
-- Excludes test-mode sessions (participants.is_test) — see
-- supabase/migration_add_is_test_flag.sql if your project predates that column.
--
-- Usage: run this once (as service_role), then for each export:
--   SELECT * FROM trials_export;  -- and save as task_trial_data.csv
--
-- Run alongside schema.sql; re-run (CREATE OR REPLACE) after any future
-- trials schema changes.

create or replace view trials_export as
select t.*
from trials t
join participants p on p.participant_id = t.participant_id
where not p.is_test;
