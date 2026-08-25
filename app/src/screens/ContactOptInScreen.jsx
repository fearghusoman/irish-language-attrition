import { useState } from "react";
import { writeRow } from "../lib/dataWriter";

/**
 * Deliberately holds no reference to participant_id anywhere in this
 * component or its closure — contact_optins has no FK/shared key with the
 * study data by design (see supabase/schema.sql), so this must stay
 * structurally impossible to join back to a participant's responses.
 */
export function ContactOptInScreen({ onFinish }) {
  const [email, setEmail] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [done, setDone] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    if (submitting || !email.trim()) return;
    setSubmitting(true);
    await writeRow("contact_optins", { email: email.trim() });
    setDone(true);
  }

  if (done) {
    return (
      <div className="screen">
        <p>Thanks — we'll be in touch once the study findings are ready.</p>
        <button type="button" onClick={onFinish}>
          Done
        </button>
      </div>
    );
  }

  return (
    <div className="screen contact-optin-screen">
      <h2>Stay informed</h2>
      <p>Enter an email address where we can send the overall study findings.</p>
      <form onSubmit={handleSubmit}>
        <label htmlFor="contact-email">Email address</label>
        <input
          id="contact-email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <button type="submit" disabled={submitting}>
          {submitting ? "Saving…" : "Submit"}
        </button>
      </form>
    </div>
  );
}
