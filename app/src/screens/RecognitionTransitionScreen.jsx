export function RecognitionTransitionScreen({ onContinue }) {
  return (
    <div className="screen">
      <h2>Second task</h2>
      <p>
        Now for the second task. This time you'll see words in Irish, and your task is to type
        what each one means in English. As soon as you are ready, click "Submit". Same 20-second
        limit per word.
      </p>
      <button type="button" onClick={onContinue}>
        Continue
      </button>
    </div>
  );
}
