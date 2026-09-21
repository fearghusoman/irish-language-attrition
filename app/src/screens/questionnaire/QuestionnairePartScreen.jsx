import { useState } from "react";
import { SchemaForm } from "../../components/SchemaForm";
import { writeRow } from "../../lib/dataWriter";

/**
 * Generic wrapper for questionnaire Parts 1-4 and 6: render the Part's field
 * schema, and on submit write the row to Supabase immediately (per the
 * per-Part write-timing decision) before advancing to the next screen.
 */
export function QuestionnairePartScreen({ table, title, fields, participantId, onComplete }) {
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  async function handleSubmit(values) {
    if (submitting) return;
    setSubmitting(true);
    setError(null);
    try {
      await writeRow(table, { participant_id: participantId, ...values });
      onComplete();
    } catch (err) {
      console.error(`[QuestionnairePartScreen] submit for "${table}" failed:`, err);
      setError("Something went wrong saving your answers. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <SchemaForm
      title={title}
      fields={fields}
      submitLabel={submitting ? "Saving…" : "Continue"}
      disabled={submitting}
      externalError={error}
      onSubmit={handleSubmit}
    />
  );
}
