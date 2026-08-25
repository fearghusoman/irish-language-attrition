import { writeRow } from "./dataWriter";

export const SESSION_EVENT_TYPES = [
  "consent_given",
  "task_started",
  "recall_completed",
  "recognition_completed",
  "questionnaire_started",
  "questionnaire_completed",
];

export function logSessionEvent(participantId, eventType) {
  if (!SESSION_EVENT_TYPES.includes(eventType)) {
    throw new Error(`Unknown session event type: ${eventType}`);
  }
  // Fire-and-forget: a missed diagnostics event must never block the session flow.
  writeRow("session_events", { participant_id: participantId, event_type: eventType });
}
