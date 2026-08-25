import { useEffect, useRef, useState } from "react";
import { useCountdownTimer } from "../hooks/useCountdownTimer";

const TRIAL_DURATION_MS = 20000;

/**
 * A single recall or recognition trial: one prompt word, one text input,
 * a 20-second visible countdown that auto-submits (as a timeout) on expiry.
 *
 * The caller must render this with a `key` unique per trial (e.g.
 * `${phase}:${item_id}`) so React fully remounts it between trials — that's
 * what resets the timer and clears the input, rather than an internal effect.
 */
export function LexicalTrial({ promptWord, instructionText, onSubmit }) {
  const [responseText, setResponseText] = useState("");
  const submittedRef = useRef(false);
  const inputRef = useRef(null);

  const { remainingMs, getElapsedMs } = useCountdownTimer(TRIAL_DURATION_MS, () => finalize(true));

  function finalize(timedOut) {
    if (submittedRef.current) return;
    submittedRef.current = true;
    onSubmit({
      responseText: responseText.trim(),
      responseTimeMs: getElapsedMs(),
      timedOut,
    });
  }

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const secondsRemaining = Math.ceil(remainingMs / 1000);
  const percentRemaining = (remainingMs / TRIAL_DURATION_MS) * 100;
  const urgency = remainingMs <= 5000 ? "danger" : remainingMs <= 10000 ? "warning" : "normal";

  return (
    <div className="lexical-trial">
      <div className="trial-timer">
        <div className="trial-timer-track">
          <div
            className={`trial-timer-fill trial-timer-fill--${urgency}`}
            style={{ width: `${percentRemaining}%` }}
          />
        </div>
        <span className="trial-timer-label" aria-live="polite">
          {secondsRemaining}s
        </span>
      </div>
      <div className="trial-prompt">{promptWord}</div>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          finalize(false);
        }}
      >
        <label htmlFor="trial-response">{instructionText}</label>
        <input
          id="trial-response"
          ref={inputRef}
          type="text"
          autoComplete="off"
          autoCorrect="off"
          spellCheck="false"
          value={responseText}
          onChange={(event) => setResponseText(event.target.value)}
        />
        <button type="submit">Submit</button>
      </form>
    </div>
  );
}
