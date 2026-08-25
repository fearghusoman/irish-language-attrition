import { useEffect, useState } from "react";
import wordlist from "./data/wordlist.json";
import { shuffle } from "./lib/shuffle";
import { logSessionEvent } from "./lib/sessionEvents";
import { flushPendingWrites } from "./lib/dataWriter";

import { ConsentScreen } from "./screens/ConsentScreen";
import { TaskInstructionsScreen } from "./screens/TaskInstructionsScreen";
import { PracticeScreen } from "./screens/PracticeScreen";
import { RecallPhase } from "./screens/RecallPhase";
import { RecognitionTransitionScreen } from "./screens/RecognitionTransitionScreen";
import { RecognitionPhase } from "./screens/RecognitionPhase";
import { QuestionnaireTransitionScreen } from "./screens/QuestionnaireTransitionScreen";
import { ThankYouScreen } from "./screens/ThankYouScreen";
import { ContactOptInScreen } from "./screens/ContactOptInScreen";
import { QuestionnairePartScreen } from "./screens/questionnaire/QuestionnairePartScreen";
import { Part5Screen } from "./screens/questionnaire/Part5Screen";
import {
  PART1_FIELDS,
  PART2_FIELDS,
  PART3_FIELDS,
  PART4_FIELDS,
  PART6_FIELDS,
} from "./screens/questionnaire/fieldSchemas";

import "./App.css";

// This app is a linear, forward-only session: no router, no back-navigation
// (timed trials shouldn't be revisitable). SCREEN enumerates every step; App
// holds only the state needed to get from one screen to the next.
const SCREEN = {
  CONSENT: "consent",
  TASK_INSTRUCTIONS: "task_instructions",
  PRACTICE: "practice",
  RECALL: "recall",
  RECOGNITION_TRANSITION: "recognition_transition",
  RECOGNITION: "recognition",
  QUESTIONNAIRE_TRANSITION: "questionnaire_transition",
  QUESTIONNAIRE_PART1: "questionnaire_part1",
  QUESTIONNAIRE_PART2: "questionnaire_part2",
  QUESTIONNAIRE_PART3: "questionnaire_part3",
  QUESTIONNAIRE_PART4: "questionnaire_part4",
  QUESTIONNAIRE_PART5: "questionnaire_part5",
  QUESTIONNAIRE_PART6: "questionnaire_part6",
  THANK_YOU: "thank_you",
  CONTACT_OPTIN: "contact_optin",
  DONE: "done",
};

function App() {
  const [screen, setScreen] = useState(SCREEN.CONSENT);
  const [participantId, setParticipantId] = useState(null);
  const [recallOrder, setRecallOrder] = useState(null);
  const [recognitionQueue, setRecognitionQueue] = useState([]);

  useEffect(() => {
    flushPendingWrites();
    window.addEventListener("online", flushPendingWrites);
    return () => window.removeEventListener("online", flushPendingWrites);
  }, []);

  switch (screen) {
    case SCREEN.CONSENT:
      return (
        <ConsentScreen
          onConsented={(id) => {
            setParticipantId(id);
            setScreen(SCREEN.TASK_INSTRUCTIONS);
          }}
        />
      );

    case SCREEN.TASK_INSTRUCTIONS:
      return <TaskInstructionsScreen onContinue={() => setScreen(SCREEN.PRACTICE)} />;

    case SCREEN.PRACTICE:
      return (
        <PracticeScreen
          onComplete={() => {
            setRecallOrder(shuffle(wordlist));
            logSessionEvent(participantId, "task_started");
            setScreen(SCREEN.RECALL);
          }}
        />
      );

    case SCREEN.RECALL:
      return (
        <RecallPhase
          items={recallOrder}
          participantId={participantId}
          onComplete={(queue) => {
            logSessionEvent(participantId, "recall_completed");
            setRecognitionQueue(queue);
            // Skip the recognition phase entirely if every item was recalled.
            setScreen(queue.length > 0 ? SCREEN.RECOGNITION_TRANSITION : SCREEN.QUESTIONNAIRE_TRANSITION);
          }}
        />
      );

    case SCREEN.RECOGNITION_TRANSITION:
      return <RecognitionTransitionScreen onContinue={() => setScreen(SCREEN.RECOGNITION)} />;

    case SCREEN.RECOGNITION:
      return (
        <RecognitionPhase
          items={recognitionQueue}
          participantId={participantId}
          onComplete={() => {
            logSessionEvent(participantId, "recognition_completed");
            setScreen(SCREEN.QUESTIONNAIRE_TRANSITION);
          }}
        />
      );

    case SCREEN.QUESTIONNAIRE_TRANSITION:
      return (
        <QuestionnaireTransitionScreen
          onContinue={() => {
            logSessionEvent(participantId, "questionnaire_started");
            setScreen(SCREEN.QUESTIONNAIRE_PART1);
          }}
        />
      );

    case SCREEN.QUESTIONNAIRE_PART1:
      return (
        <QuestionnairePartScreen
          table="questionnaire_part1"
          title="Part 1 — General background"
          fields={PART1_FIELDS}
          participantId={participantId}
          onComplete={() => setScreen(SCREEN.QUESTIONNAIRE_PART2)}
        />
      );

    case SCREEN.QUESTIONNAIRE_PART2:
      return (
        <QuestionnairePartScreen
          table="questionnaire_part2"
          title="Part 2 — Proficiency at end of instruction"
          fields={PART2_FIELDS}
          participantId={participantId}
          onComplete={() => setScreen(SCREEN.QUESTIONNAIRE_PART3)}
        />
      );

    case SCREEN.QUESTIONNAIRE_PART3:
      return (
        <QuestionnairePartScreen
          table="questionnaire_part3"
          title="Part 3 — Exposure to Irish since the end of formal instruction"
          fields={PART3_FIELDS}
          participantId={participantId}
          onComplete={() => setScreen(SCREEN.QUESTIONNAIRE_PART4)}
        />
      );

    case SCREEN.QUESTIONNAIRE_PART4:
      return (
        <QuestionnairePartScreen
          table="questionnaire_part4"
          title="Part 4 — Motivation"
          fields={PART4_FIELDS}
          participantId={participantId}
          onComplete={() => setScreen(SCREEN.QUESTIONNAIRE_PART5)}
        />
      );

    case SCREEN.QUESTIONNAIRE_PART5:
      return (
        <Part5Screen participantId={participantId} onComplete={() => setScreen(SCREEN.QUESTIONNAIRE_PART6)} />
      );

    case SCREEN.QUESTIONNAIRE_PART6:
      return (
        <QuestionnairePartScreen
          table="questionnaire_part6"
          title="Part 6 — Background"
          fields={PART6_FIELDS}
          participantId={participantId}
          onComplete={() => {
            logSessionEvent(participantId, "questionnaire_completed");
            setScreen(SCREEN.THANK_YOU);
          }}
        />
      );

    case SCREEN.THANK_YOU:
      return (
        <ThankYouScreen
          onOfferContact={() => setScreen(SCREEN.CONTACT_OPTIN)}
          onFinish={() => setScreen(SCREEN.DONE)}
        />
      );

    case SCREEN.CONTACT_OPTIN:
      return <ContactOptInScreen onFinish={() => setScreen(SCREEN.DONE)} />;

    case SCREEN.DONE:
      return (
        <div className="screen">
          <p>You may now close this window. Thank you again for taking part.</p>
        </div>
      );

    default:
      return null;
  }
}

export default App;
