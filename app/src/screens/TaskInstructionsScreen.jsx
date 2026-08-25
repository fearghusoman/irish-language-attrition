export function TaskInstructionsScreen({ onContinue }) {
  return (
    <div className="screen">
      <h2>Task instructions</h2>
      <p>
        You'll now complete two short word tasks. In the first task, you'll be shown English
        words one at a time. Type the Irish word or phrase that comes to mind — don't worry about
        accents (fadas) if you can't easily type them. As soon as you are ready, click "Submit".
        You'll have a 20-second limit per word; after 20 seconds, the next word will appear
        automatically. If you're not sure, take your best guess or leave it blank and move on. For
        verbs, just give the basic form (e.g. "eat" not "eating" or "ate"). Please don't use a
        dictionary or translator — we're interested in what you remember, not what you can look
        up. There are 60 words in total, with a short break offered halfway through.
      </p>
      <button type="button" onClick={onContinue}>
        Continue
      </button>
    </div>
  );
}
