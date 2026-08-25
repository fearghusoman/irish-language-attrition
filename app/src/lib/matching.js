// Live routing-check matching, per codebook v20 Section E.
// This governs recall -> recognition branching only. It is NOT final scoring —
// final scoring (edit-distance tolerance, manual review of unlisted synonyms)
// happens post-hoc in R, outside this app.

const FADA_MAP = { á: "a", é: "e", í: "i", ó: "o", ú: "u" };

export function stripFadas(text) {
  return text.replace(/[áéíóú]/g, (char) => FADA_MAP[char]);
}

function normalize(text) {
  return stripFadas(text.trim().toLowerCase());
}

/**
 * Recall phase (English shown, participant types Irish).
 * Fada-stripped exact match against the single Irish target.
 */
export function checkRecallMatch(responseText, irishTarget) {
  const normResponse = normalize(responseText);
  if (normResponse.length === 0) return false;
  return normResponse === normalize(irishTarget);
}

function stripLeadingTo(text) {
  const normalized = text.trim().toLowerCase();
  return normalized.startsWith("to ") ? normalized.slice(3).trim() : normalized;
}

/**
 * Recognition phase (Irish shown, participant types English).
 * "To" is optional for verbs — stripped independently from both the
 * participant's response and EACH listed alternative (some items, e.g.
 * "to get up/to rise", carry "to " on more than one alternative).
 * Any one matching alternative counts as correct.
 */
export function checkRecognitionMatch(responseText, englishGlossAlternatives) {
  const normResponse = stripLeadingTo(responseText);
  if (normResponse.length === 0) return false;
  return englishGlossAlternatives.some((alt) => stripLeadingTo(alt) === normResponse);
}
