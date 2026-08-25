import { useState } from "react";
import { LexicalTrial } from "../components/LexicalTrial";
import { ProgressIndicator } from "../components/ProgressIndicator";
import { writeRow } from "../lib/dataWriter";
import { checkRecognitionMatch } from "../lib/matching";

/**
 * Runs recognition trials only for items that failed the live recall check —
 * same item_id, direction reversed (Irish shown, English typed). `items` may
 * be empty (a participant who recalled all 60) — the caller is responsible
 * for skipping this phase entirely in that case.
 */
export function RecognitionPhase({ items, participantId, onComplete }) {
  const [index, setIndex] = useState(0);
  const currentItem = items[index];

  async function handleSubmit({ responseText, responseTimeMs, timedOut }) {
    const isMatch = checkRecognitionMatch(responseText, currentItem.english_gloss_alternatives);

    await writeRow("trials", {
      participant_id: participantId,
      item_id: currentItem.item_id,
      phase: "recognition",
      irish_target: currentItem.irish_target,
      english_gloss: currentItem.english_gloss,
      category: currentItem.category,
      word_length: currentItem.word_length,
      freq_rank: currentItem.freq_rank,
      response_text: responseText,
      response_time_ms: responseTimeMs,
      timed_out: timedOut,
      live_match_result: isMatch,
      trial_sequence: index + 1,
    });

    const nextIndex = index + 1;
    if (nextIndex >= items.length) {
      onComplete();
    } else {
      setIndex(nextIndex);
    }
  }

  return (
    <div className="screen recognition-phase">
      <ProgressIndicator current={index + 1} total={items.length} label={`Item ${index + 1} of ${items.length}`} />
      <LexicalTrial
        key={`recognition:${currentItem.item_id}`}
        promptWord={currentItem.irish_target}
        instructionText="Type what this word means in English"
        onSubmit={handleSubmit}
      />
    </div>
  );
}
