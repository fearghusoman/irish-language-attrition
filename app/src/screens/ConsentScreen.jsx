import { useState } from "react";
import { writeRow } from "../lib/dataWriter";
import { logSessionEvent } from "../lib/sessionEvents";
import { isTestModeEnabled } from "../lib/testMode";

const APP_VERSION = "v1";
const CONSENT_VERSION = "v28";

// Text below is copied verbatim from questionnaire v28, Part 0, with
// [Your Name] / [Institute/Department] filled in — do not paraphrase this;
// it's the actual consent/GDPR copy, not app UI copy.
export function ConsentScreen({ onConsented }) {
  const [agreed, setAgreed] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    if (!agreed || submitting) return;

    setSubmitting(true);
    const participantId = crypto.randomUUID();

    // Clicking "I agree" is itself the participant's confirmation of both
    // consent and age (per the single combined statement below), so both
    // fields are recorded true together.
    await writeRow("participants", {
      participant_id: participantId,
      consent_given: true,
      age_18_plus_confirmed: true,
      consent_version: CONSENT_VERSION,
      app_version: APP_VERSION,
      is_test: isTestModeEnabled(),
    });
    logSessionEvent(participantId, "consent_given");

    onConsented(participantId);
  }

  return (
    <div className="screen consent-screen">
      <p className="consent-title">
        <strong>Study title:</strong> Revisiting lexical attrition of instructed L2 Irish: an
        exploration of levels of retention and influencing factors among adults in Ireland after
        extended post-instruction periods
      </p>
      <p>
        You are invited to take part in a study exploring long-term retention of Irish vocabulary
        among adults who learned Irish in school. The study involves a short background
        questionnaire and a set of word-recall/recognition tasks, taking approximately 20–25
        minutes in total.
      </p>
      <p>
        <strong>Participation is voluntary</strong> and you may withdraw at any time without
        giving a reason, up until data analysis begins.
      </p>
      <p>
        <strong>Your responses will be anonymised.</strong> You will not be asked for your name.
        Data will be stored securely and used only for the purposes of this research and any
        resulting academic publications or conference presentations. No individual will be
        identifiable in any report or publication.
      </p>
      <p>
        This study is conducted by <strong>Dr. Eimear Geary</strong>,{" "}
        <strong>Department of Linguistics</strong>, University of Cologne, in accordance with the
        University of Cologne's Research Code of Conduct and Guidelines for Good Scientific
        Practice, and applicable data protection regulations (GDPR).
      </p>
      <p>
        By clicking "I agree" below, you confirm that you are 18 or older, that you have read and
        understood the above, and that you consent to take part.
      </p>
      <form onSubmit={handleSubmit}>
        <label>
          <input type="checkbox" checked={agreed} onChange={(e) => setAgreed(e.target.checked)} />
          I agree to take part in this study
        </label>
        <button type="submit" disabled={!agreed || submitting}>
          {submitting ? "Starting…" : "I agree"}
        </button>
      </form>
    </div>
  );
}
