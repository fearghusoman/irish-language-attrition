# Task Instructions & Screen Design (v6)
For platform build — lexical task portion

## Package summary — what's being sent to the collaborator

1. **Questionnaire** (v28, .md + .docx) — full instrument, consent, predictors, background variables
2. **Word list** (v12, .xlsx, "FINAL 60 – Selected" sheet) — the 60 test items
3. **Codebook** (v20) — variable definitions, scoring protocol, analysis plan
4. **This document** — screen design and data export spec for the lexical task portion

## Session identity — single continuous session, one participant ID

The lexical task and the questionnaire must be built as **one continuous platform session**, not two separate tools/links. A single participant ID must be attached automatically to every row of data — both the trial-level task data and the questionnaire responses — for that entire session.

## Session order (REVISED in v4)

1. **Consent screen** (questionnaire v28, Part 0)
2. **Lexical task** — recall phase, then recognition phase (this document) — placed immediately after consent, before any background questions, so the task is administered while participants are freshest
3. **Full questionnaire** (all Parts 1–6, predictors + background) — administered after the task

*Rationale for order: the lexical task is the most cognitively demanding part of the session. Placing it immediately after consent, with no intervening questions, avoids any risk of fatigue effects being confounded with genuine attrition.*

## Screen 1 — Task instructions (before practice trial)

> You'll now complete two short word tasks. In the first task, you'll be shown English words one at a time. Type the Irish word or phrase that comes to mind — don't worry about accents (fadas) if you can't easily type them. As soon as you are ready, click "Submit". You'll have a 20-second limit per word; after 20 seconds, the next word will appear automatically. If you're not sure, take your best guess or leave it blank and move on. For verbs, just give the basic form (e.g. "eat" not "eating" or "ate"). Please don't use a dictionary or translator — we're interested in what you remember, not what you can look up. There are 60 words in total, with a short break offered halfway through.

## Screen 2 — Practice trial (1–2 items, not scored, not part of the 60)

Use 1–2 very easy, unambiguous words (e.g. "yes"/"tá", "no"/"níl"). Clearly labeled "Practice — not scored."

## Screen 3 — Recall trial (repeated per item, randomized order across all 60)

- Display: English gloss only, no category label, no hint
- Input: single text field
- Timer: 20 seconds, visible countdown; auto-advances on timeout
- **Live routing check** (not final scoring): fada-stripped exact match against target
  - Match → item marked "recalled," move to next recall trial
  - No match / timeout / blank → item added to the recognition queue

## Screen 4 — Transition instructions (before recognition phase begins)

Shown once, after all 60 recall trials are complete, before the recognition phase starts:

> Now for the second task. This time you'll see words in Irish, and your task is to type what each one means in English. As soon as you are ready, click "Submit". Same 20-second limit per word.

*Note: wording deliberately avoids stating or implying that the recognition items are the same words seen in the recall phase — participants should not be cued to expect repetition.*

## Screen 5 — Recognition trial (only for items that didn't pass the live recall check)

**These are NOT new or different words** — the recognition set is the same items from the recall phase that the participant did not produce, now shown in the opposite direction: the Irish form is displayed, and the participant types the English meaning. Same `item_id`, direction reversed.

- Display: Irish word only
- Input: single text field, participant types the English meaning
- Timer: 20 seconds
- Same live/final scoring separation as recall

**Items that fail recognition too complete the branching path as "neither recalled nor recognized"** — a real, reportable third outcome category (see Outcome Categories below), not a data gap.

## Recognition-phase English answer matching (live routing check)

- **"To" is optional for verbs.** Both "put" and "to put" must be accepted as correct for a verb target like "to put" — do not require the infinitive "to" prefix, and do not penalize its absence either. Strip any leading "to " from both the target and the participant's response before comparing.
- **Any listed alternative is accepted.** Where the word list gives more than one English gloss for an item (e.g. "way/path", "care/attention"), the participant's answer should be checked against every alternative, not just the first — any one of them counts as correct.
- **Unlisted synonyms are not caught by the live check, by design.** A participant may give a correct English translation that isn't one of the specific alternatives listed (e.g. "route" for "way/path"). The live check does not need to anticipate every possible correct synonym — this is exactly what the post-hoc manual review step (codebook Section E) is for. Live matching only needs to be a reasonable first pass, not the final scoring authority.

## Outcome categories per item

Every one of the 60 items ends up in exactly one of three categories per participant: **Recalled**, **Recognized only**, or **Neither recalled nor recognized**. All three are meaningful and should be preserved in the data — codebook Section B defines the DV as this three-level ordinal outcome (0/1/2). The proportion of items in "neither" per participant is itself a valuable summary figure (genuinely lost vocabulary, distinct from "recognized only," which reflects partial/weaker retention).

## Screen 6 — Progress / break

- Simple progress indicator throughout ("Item 23 of 60")
- One optional break screen offered at the halfway point of the recall block

## Screen 7 — Transition to questionnaire

After both task phases are complete: "Thanks — that's the word tasks done. Now a background questionnaire to finish up." (No separate time estimate given here — the single overall estimate of 20–25 minutes is stated once, at consent, per questionnaire Part 0. Avoid a second, separately-worded time claim partway through the session.)

## Data export requirements

Long format, one row per trial:
`participant_id | item_id | phase (recall/recognition) | irish_target | english_gloss | category | response_text | response_time_ms | live_match_result`

Keep `response_text` as raw typed input — final scoring (fada/edit-distance tolerance, manual review) is applied afterward per the codebook (Section E).

**The same `participant_id` must appear on the questionnaire response export too** — this is what lets the trial-level task data and participant-level questionnaire data be merged into one dataset for the mixed-effects model.

## Notes

- Category is never shown or hinted at any point.
- No dictionary/translation tool use — stated explicitly in instructions.
- Verb responses: root/imperative form is the target — instructions should say this explicitly.

## Session end — decision needed

**Do not show participants their own recalled/recognized/neither breakdown.** Showing raw individual performance risks distress or self-consciousness, particularly given this is a personally and emotionally meaningful topic for many participants (see questionnaire Part 6, reconnection-motivation items). Use a plain, warm thank-you screen instead. Optionally offer to email a summary of the *overall study findings* once the research is complete (not the individual's own result) — if offered, this needs its own brief consent/contact-collection step, kept separate from the anonymous study data.

