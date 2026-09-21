// Test mode lets a developer/researcher click through a session with a short,
// curated wordlist instead of all 60 items. Controlled entirely by env vars so
// it can never accidentally ship to real participants (production builds via
// GitHub Actions simply never set VITE_TEST_MODE).
//
// Sessions run in test mode are flagged via participants.is_test — every
// export view (questionnaire_export, trials_export) filters these out, so
// test click-throughs never pollute the real dataset even though they land
// in the same Supabase project.

// One item per category, plus a second verb — chosen to exercise the
// trickiest matching logic (multi-alternative glosses, the dual-"to" case),
// not just whichever items happen to sort first by item_id.
const DEFAULT_TEST_ITEM_IDS = [
  1, // teach (concrete noun) — simple single-gloss baseline
  25, // aire (abstract noun, "care/attention") — multi-alternative gloss
  39, // éirigh (verb, "to get up/to rise") — dual-"to" edge case
  33, // tabhair (verb, "to give/grant") — one alternative has no "to" prefix
  50, // ard (adjective, "tall/high") — multi-alternative gloss
];

export function isTestModeEnabled() {
  return import.meta.env.VITE_TEST_MODE === "true";
}

function getTestItemIds() {
  const raw = import.meta.env.VITE_TEST_ITEM_IDS;
  if (!raw) return DEFAULT_TEST_ITEM_IDS;
  return raw.split(",").map((id) => Number(id.trim()));
}

/**
 * Returns the full wordlist unchanged unless test mode is enabled, in which
 * case it's filtered down to the curated (or VITE_TEST_ITEM_IDS-overridden)
 * subset.
 */
export function selectWordlist(fullWordlist) {
  if (!isTestModeEnabled()) return fullWordlist;
  const testItemIds = getTestItemIds();
  return fullWordlist.filter((item) => testItemIds.includes(item.item_id));
}
