-- One-time migration for a Supabase project created BEFORE the is_test flag
-- existed (i.e. you already ran the original schema.sql + seed_word_items.sql).
-- Run once via the SQL editor as service_role. Safe to re-run — IF NOT EXISTS
-- avoids an error on a second run.
--
-- New projects don't need this file — schema.sql already includes is_test.

alter table participants
  add column if not exists is_test boolean not null default false;
