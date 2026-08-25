import { useState } from "react";
import { LexicalTrial } from "../components/LexicalTrial";
import { ProgressIndicator } from "../components/ProgressIndicator";
import { BreakScreen } from "./BreakScreen";
import { writeRow } from "../lib/dataWriter";
import { checkRecallMatch } from "../lib/matching";

/**
 * Runs all 60 recall trials in the (already shuffled, per-participant) order
 * given by `items`. Items that fail the live fada-stripped match are handed
 * to `onComplete` as the recognition queue for the next phase. Derives the
 * total and break-point from `items.length` rather than hardcoding 60/30, so
 * this doesn't silently break if the wordlist size ever changes.
 */
export function RecallPhase({ items, participantId, onComplete }) {
  const totalItems = items.length;
  const breakAfterItem = Math.floor(totalItems / 2);

  const [index, setIndex] = useState(0);
  const [showBreak, setShowBreak] = useState(false);
  const [recognitionQueue, setRecognitionQueue] = useState([]);

  const currentItem = items[index];

  async function handleSubmit({ responseText, responseTimeMs, timedOut }) {
    const isMatch = checkRecallMatch(responseText, currentItem.irish_target);

    await writeRow("trials", {
      participant_id: participantId,
      item_id: currentItem.item_id,
      phase: "recall",
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

    const updatedQueue = isMatch ? recognitionQueue : [...recognitionQueue, currentItem];
    setRecognitionQueue(updatedQueue);

    const nextIndex = index + 1;
    if (nextIndex >= totalItems) {
      onComplete(updatedQueue);
      return;
    }
    if (nextIndex === breakAfterItem) {
      setShowBreak(true);
      return;
    }
    setIndex(nextIndex);
  }

  if (showBreak) {
    return (
      <BreakScreen
        completed={breakAfterItem}
        total={totalItems}
        onContinue={() => {
          setShowBreak(false);
          setIndex(breakAfterItem);
        }}
      />
    );
  }

  return (
    <div className="screen recall-phase">
      <ProgressIndicator current={index + 1} total={totalItems} />
      <LexicalTrial
        key={`recall:${currentItem.item_id}`}
        promptWord={currentItem.english_gloss}
        instructionText="Type the Irish word or phrase"
        onSubmit={handleSubmit}
      />
    </div>
  );
}
