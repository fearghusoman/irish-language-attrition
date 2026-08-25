export function ThankYouScreen({ onOfferContact, onFinish }) {
  return (
    <div className="screen thank-you-screen">
      <h2>Thank you</h2>
      <p>
        That's the study complete — thank you very much for your time and for sharing your
        experience of learning and using Irish.
      </p>
      <p>
        Would you like the researcher to email you a summary of the overall study findings once
        the research is complete? (This is entirely separate from your anonymous study data — if
        you say yes, you'll be asked for an email address on its own, unconnected page.)
      </p>
      <div className="thank-you-actions">
        <button type="button" onClick={onOfferContact}>
          Yes, email me the findings
        </button>
        <button type="button" onClick={onFinish}>
          No thanks
        </button>
      </div>
    </div>
  );
}
