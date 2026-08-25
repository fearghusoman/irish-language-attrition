import { useState } from "react";
import { SchemaForm } from "../../components/SchemaForm";
import { writeRow } from "../../lib/dataWriter";
import { ADDITIONAL_LANGUAGE_FULL_FIELDS, ADDITIONAL_LANGUAGE_BRIEF_FIELDS } from "./fieldSchemas";

const FULL_DETAIL_LANGUAGE_COUNT = 2;

/**
 * Steps through the participant's self-reported additional languages one at a
 * time — full detail for the first 2 (by proficiency, strongest first), brief
 * (name + use-frequency only) for the 3rd+. Each language is written to
 * `additional_languages` as its own row as soon as it's completed.
 */
export function AdditionalLanguagesForm({ participantId, languageCount, onComplete }) {
  const [currentOrder, setCurrentOrder] = useState(1);

  async function handleSubmit(values) {
    const detailLevel = currentOrder <= FULL_DETAIL_LANGUAGE_COUNT ? "full" : "brief";
    await writeRow("additional_languages", {
      participant_id: participantId,
      language_order: currentOrder,
      detail_level: detailLevel,
      ...values,
    });

    if (currentOrder >= languageCount) {
      onComplete();
    } else {
      setCurrentOrder((prev) => prev + 1);
    }
  }

  const isFull = currentOrder <= FULL_DETAIL_LANGUAGE_COUNT;
  const fields = isFull ? ADDITIONAL_LANGUAGE_FULL_FIELDS : ADDITIONAL_LANGUAGE_BRIEF_FIELDS;

  return (
    <SchemaForm
      key={currentOrder}
      title={`Additional language ${currentOrder} of ${languageCount}${
        isFull ? " (in order of proficiency, strongest first)" : ""
      }`}
      fields={fields}
      submitLabel={currentOrder >= languageCount ? "Continue" : "Next language"}
      onSubmit={handleSubmit}
    />
  );
}
