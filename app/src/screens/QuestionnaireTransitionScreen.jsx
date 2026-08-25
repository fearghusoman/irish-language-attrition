export function QuestionnaireTransitionScreen({ onContinue }) {
  return (
    <div className="screen">
      <p>Thanks — that's the word tasks done. Now a background questionnaire to finish up.</p>
      <button type="button" onClick={onContinue}>
        Continue
      </button>
    </div>
  );
}
