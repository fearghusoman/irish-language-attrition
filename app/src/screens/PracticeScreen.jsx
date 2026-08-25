import { useState } from "react";
import { LexicalTrial } from "../components/LexicalTrial";
import { PRACTICE_ITEMS } from "../data/practiceItems";

/**
 * 1-2 practice items, per task-instructions v6 Screen 2: "not scored, not part
 * of the 60." Deliberately never writes to Supabase and never touches the
 * recall/recognition matching logic.
 */
export function PracticeScreen({ onComplete }) {
  const [index, setIndex] = useState(0);
  const item = PRACTICE_ITEMS[index];

  function handleSubmit() {
    if (index + 1 >= PRACTICE_ITEMS.length) {
      onComplete();
    } else {
      setIndex((prev) => prev + 1);
    }
  }

  return (
    <div className="screen practice-screen">
      <p className="practice-label">Practice — not scored</p>
      <LexicalTrial
        key={`practice:${index}`}
        promptWord={item.english_gloss}
        instructionText="Type the Irish word or phrase"
        onSubmit={handleSubmit}
      />
    </div>
  );
}
