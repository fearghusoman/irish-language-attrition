import { useEffect, useState } from "react";
import { SchemaForm } from "../../components/SchemaForm";
import { writeRow } from "../../lib/dataWriter";
import { PART5_SUMMARY_FIELDS } from "./fieldSchemas";
import { AdditionalLanguagesForm } from "./AdditionalLanguagesForm";

/**
 * Part 5 (Q29) is two steps: a summary/gate question, then — only if the
 * participant reports additional languages — the repeatable per-language
 * sub-form. A participant with no additional languages skips straight
 * through to Part 6.
 */
export function Part5Screen({ participantId, onComplete }) {
  const [summary, setSummary] = useState(null);

  async function handleSummarySubmit(values) {
    await writeRow("questionnaire_part5_summary", { participant_id: participantId, ...values });
    setSummary(values);
  }

  useEffect(() => {
    if (summary && !summary.has_additional_languages) {
      onComplete();
    }
  }, [summary, onComplete]);

  if (summary === null) {
    return (
      <SchemaForm title="Multilingualism" fields={PART5_SUMMARY_FIELDS} onSubmit={handleSummarySubmit} />
    );
  }

  if (!summary.has_additional_languages) {
    return null; // onComplete fires via the effect above
  }

  return (
    <AdditionalLanguagesForm
      participantId={participantId}
      languageCount={summary.additional_languages_count_self_report}
      onComplete={onComplete}
    />
  );
}
