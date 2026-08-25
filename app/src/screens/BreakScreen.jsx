export function BreakScreen({ completed, total, onContinue }) {
  return (
    <div className="screen break-screen">
      <h2>Halfway there</h2>
      <p>
        You've completed {completed} of {total} items. Feel free to take a short break before
        continuing.
      </p>
      <button type="button" onClick={onContinue}>
        Continue
      </button>
    </div>
  );
}
