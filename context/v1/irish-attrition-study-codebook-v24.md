# Codebook — L2 Irish Lexical Attrition Study (v24)

Participant ID (anonymous code) should appear on every row/section so the questionnaire and task data can be merged. All "scale" items should be built as fixed Likert items where noted, not free text, so they can go straight into the regression without recoding. Item numbers below refer to questionnaire v35. Note: the acquisition-context field in Q28 (per additional language) is multi-select ("check all that apply"), not single-select — a participant may report, e.g., both Formal classroom instruction and Self-study for the same language. Store as either a comma-separated list or one binary column per context option; this field remains descriptive-only, not part of the core predictor.

## A. Sample / screening

| Variable | Operationalisation | Type | Source / notes |
|---|---|---|---|
| Participant ID | Anonymous code assigned at consent | String | Same code used across questionnaire + task platform |
| N | ~40 participants | — | Adults in Ireland, 14–45 years since end of formal Irish instruction |
| Years since end of formal instruction | Later of Leaving Cert year (Q12) or third-level Irish end year (Q15), calculated to a number | Continuous (14–45) | Ask for year, not raw "years" |
| L1/L2 screening | Whether Irish was a first (home) language vs. second (school) language | Categorical | Q4 — exclude or flag separately any participant reporting Irish as a genuine first/home language; the study is designed around L2 attrition specifically |
| Current active use | Self-rated frequency of current Irish use | Ordinal, 5-pt (Never/Rarely/Occasionally/Often/Daily — frequency scale, distinct format from the agreement items but now matched to 5 points for visual consistency) | Q8 — screening + control variable |

## B. Dependent variables (from tasks)

| Variable | Operationalisation | Type | Source / notes |
|---|---|---|---|
| Retention level per item | Branching design: recalled / recognized-only / neither | Ordinal (0/1/2) per word | Primary DV — captures degree of retention per Geary (2022) design logic, not just flat accuracy |
| Production (recall) accuracy | % of items correctly recalled (English→Irish, typed) | Continuous (0–100%) | Participant-level composite, computed from trial-level export |
| Recognition accuracy | % of non-recalled items correctly recognized (Irish→English, typed) | Continuous (0–100%) | Only computed on the subset that reached the recognition phase |
| Self-rated degree of Irish language loss since the end of formal instruction (self-rated attrition) | Learner's own estimate of how much Irish they've lost | Ordinal/Likert, 5-pt with labelled anchors | Q53 — own DV/comparison variable, not a predictor. Questionnaire heading deliberately avoids "attrition" (field jargon a general participant wouldn't recognise); retained here in parentheses for consistency with standard terminology in the attrition literature |

## C. Core predictor variables (4 total — primary regression model, n=40)

| Variable | Operationalisation | Type | Source / notes |
|---|---|---|---|
| 1. Proficiency at end of instruction | Leaving Cert Irish grade (A–F, Q14) × level (Higher/Ordinary, Q13), converted via CAO-points-by-year table matching each participant's exam year (Q12). Fallback self-rating (Q13 sub-item) for participants who didn't sit the exam | Continuous (points) | NOT self-rated by default. Different curriculum eras need different points tables |
| 2. Exposure to Irish since the end of formal instruction | Composite of 5 items (Q16–Q20: signage/media, conversation, media engagement/consumption, events, family/social circle) — a FREQUENCY scale (Never/Rarely/Occasionally/Often/Daily, coded 1–5), not an agreement scale | Continuous composite | Converted from agreement to frequency format, since these items ask about factual frequency of experience, not subjective opinion. Average into one score; check internal reliability |
| 3. Integrative/cultural motivation | Composite of 4 Likert items (Q21–Q24: cultural/heritage connection, personal identity during learning, interest beyond exams, desire to take part in Irish-speaking community/cultural life) | Continuous composite | Expanded from 3 to 4 items to match Gardner's AMTB Integrative Orientation subscale length (4 items) and improve reliability — the 4th item covers a facet (community/cultural participation) the original 3 didn't. Item deliberately avoids "communicate with Irish speakers" wording, since Irish speakers are universally also fluent English speakers — no functional communication necessity exists, unlike Gardner's original French-Canadian context. Core predictor — NOT the instrumental-motivation composite (Q25–Q26), which is descriptive-only. Confidence-check item (Q27) covers both composites, analyzed separately from either |

**Instrumental motivation composite reduced from 3 to 2 items**: the original third item ("I learned Irish mainly because it was compulsory, not out of personal interest") was removed on two grounds. First, "mainly...not out of personal interest" imposed forced exclusivity inconsistent with the composite's design elsewhere, where items are not mutually exclusive. Second, and more decisively: since Irish was a compulsory school subject for virtually the entire sample, this item was unlikely to discriminate meaningfully between participants regardless of wording. The remaining two items (Q25, Q26) were also reworded to remove similar forced-exclusivity language ("main," "rather than the language itself").
| 4. Multilingualism | Count of additional languages the participant currently uses at least "Occasionally" — i.e. rated Occasionally, Often, or Daily/almost daily (Q28 per-language use-frequency field, collected for all reported languages regardless of whether full detail or brief-overflow format was used) — NOT a count of all languages ever learned | Continuous (count) | Grounded in the Activation Threshold Hypothesis (Herdina & Jessner 2013): a dormant language poses little retrieval competition, while an actively "online" language plausibly competes with Irish for lexical access. Directly supported by Pot, Keijzer & de Bot (2018), who found that "usage-based" operationalisations of multilingualism (frequency/intensity of use) predicted cognitive outcomes while "knowledge-based" measures (raw language count, proficiency) did not — using the closely related Adaptive Control Hypothesis (Green & Abutalebi 2013) as their framework. NOTE: full descriptive detail (language identity, proficiency, acquisition context, duration, LC result) is only collected for the participant's first 2 additional languages (by proficiency); 3rd+ languages are captured via a brief overflow list (name + use-frequency only) — precedented by LEAP-Q, which similarly profiles only the first 3 languages in depth. This does NOT affect the core predictor, which only needs use-frequency, collected for every reported language either way |

**n=40 supports ~4 predictors at the loosest rule of thumb (10 obs/predictor) — the primary model is at that ceiling.** Report effect sizes/CIs, not just significance thresholds.

## D. Descriptive-only variables (not in the primary regression model)

Region of current residence (Q3, provinces), education type (Gaelscoil/mainstream, Q29–30), highest education (Q31), region of secondary school (Q32), time lived abroad since instruction (Q33–35), attitudes toward Irish (Q36–38), language-learning experience incl. course content (Q39–42), classroom anxiety (Q43–44), parental/family encouragement (Q45–48), family Irish proficiency — factual Yes/No, kept separate from the encouragement Likert composite (Q49–50), linguistic identity now (Q51–52), instrumental motivation (Q25–26), current motivation to reconnect with Irish (Q54–55), age of acquisition (Q5), pre-school exposure (Q6), Gaeltacht contact (Q7), Irish-language occupation (Q10), parenthood (Q11). Collected for description, discussion, and correlation checks. Each is its own Likert composite/item where applicable; don't merge across constructs — this specifically includes NOT averaging Q49–50 (factual Yes/No) into the Q45–48 Likert composite. (Note: the "reconnect" item, Q54, should NOT be framed in write-up as indicating "new speaker" status — that category requires sustained active use, not expressed interest.)

**Time lived abroad since instruction (Q33–35)**: added because the study's framing explicitly contrasts an Ireland-resident sample against Geary (2022)'s all-emigrant sample — participants who spent substantial time abroad during the post-instruction period blur this distinction and represent a genuine potential confound for the exposure predictor (Q16–20), since ambient Irish exposure differs mechanically between residing in Ireland versus abroad. Deliberately does NOT ask for country (would require coding 190+ countries and handling multi-country cases for little analytical gain) — instead asks directly about the theoretically relevant construct, access to Irish-language resources while abroad, which is what country would only have been a proxy for. Q34 (years abroad) is a single combined total across all periods abroad, not per-country or per-stay, avoiding the need to track exact date ranges. Descriptive-only; not part of any core predictor. Usable for two things: (a) contextualising individual exposure scores in discussion, and (b) an optional exploratory comparison (resident-only vs. mixed-residency participants), following the same pattern as the curriculum-era cohort variable (Section H).

**Additional-language proficiency (Q28 sub-item)**: rated on a four-level categorical scale (Beginner/Intermediate/Advanced/Fluent) rather than a finer-grained numeric scale (e.g. LEAP-Q's 0–10 format). Justification for write-up: *"Proficiency in additional languages was self-rated using a four-level categorical scale (Beginner/Intermediate/Advanced/Fluent) rather than a finer-grained numeric scale, since this variable served a purely descriptive function rather than entering the regression model, and categorical self-assessment offers comparable interpretability without implying a precision of self-insight that fine-grained numeric self-ratings do not, in practice, provide (cf. Carter & Dunning 2008 on the general difficulty of accurate self-assessment; Pot, Keijzer & de Bot 2018 raise the same concern specifically for multilingualism proficiency self-ratings)."*

**Self-selection bias (limitation for write-up)**: as in Pot, Keijzer & de Bot (2018), voluntary participation in a study specifically about Irish language retention likely attracts people who already identify positively with the language and/or with being multilingual, potentially skewing the sample toward more positive attitudes, higher motivation, or better retention than the broader population of Irish-educated adults. State this explicitly as a limitation rather than leaving it implicit.

## E. Scoring protocol for typed lexical responses

Decided in advance of seeing any data, to avoid post-hoc rule-tuning.

1. **Fadas (á, é, í, ó, ú) — never penalize a missing fada.** Strip fadas from both the target answer and the participant's response before comparing.
2. **Minor typos — allow small edit-distance tolerance.** Levenshtein distance ≤1 for short words, ≤2 for longer words, accepted as correct.
3. **Anything beyond the threshold — flag for manual review**, don't auto-score.
4. **Verb responses (recall phase, English→Irish)**: accept the verb root/imperative form only (e.g. *ith*).
5. **Verb responses (recognition phase, Irish→English)**: "to" is optional — both "put" and "to put" must be accepted for a target like "to put." Strip any leading "to " from both the target and the participant's response before comparing.
6. **Multiple listed English alternatives (recognition phase)**: where an item has more than one English gloss (e.g. "way/path", "care/attention"), accept any of them — check the participant's answer against every alternative, not just the first.
7. **Unlisted synonyms are handled by manual review, not automatic matching.** A correct-but-unlisted English translation (e.g. "route" for "way/path") won't be caught by an automatic check — this is expected, and exactly what manual review is for. Don't try to enumerate every possible correct synonym in advance.
8. **Platform doesn't need to judge correctness live** — record raw typed responses; scoring (steps 1–3, 5–7) is a post-processing step, not real-time.

*Note: the final 60-item list has no dual-form items (see Section I) — the two that existed in earlier versions of the list (child, family) were each replaced by a single-translation alternative, so dual-acceptance scoring no longer applies.*

## F. Modelling notes for your collaborator

- **Primary analysis (confirmatory)**: trial-level mixed-effects model (`glmer`/`clmm` in R), using the full participant × item dataset (~40 × 60 = 2,400 rows), by-participant and by-item random effects, the 4 core predictors (Section C), plus item-level word length and category as fixed effects (see Section I).
- **Secondary analysis (exploratory) — 5-predictor model**: the same 4 core predictors plus instrumental motivation (Q25–26 composite) added as a 5th predictor, to directly test whether it predicts retention once the others are accounted for. Explicitly label this as exploratory and underpowered relative to the primary model (n=40 with 5 predictors = 8 obs/predictor, below the 10/predictor guideline) — report with wider confidence intervals and appropriately cautious interpretation, not as a confirmatory result.
- **Tertiary/descriptive analysis**: simple participant-level regression (one row per participant, composite scores) as an easier-to-report supplementary check on the primary 4-predictor model.
- Check collinearity between motivation and proficiency (`car::vif()`) — Geary (2022) found these correlated in her sample.
- Composite scales should each be checked for internal reliability (Cronbach's alpha) before averaging into a single predictor. Note: classroom anxiety (Q43–44) is only 2 items — report as a correlation rather than full Cronbach's alpha given the small item count. Integrative/cultural motivation (Q21–24) was expanded from 3 to 4 items specifically to bring it in line with established scale-length practice (see Section C) — still worth reporting its alpha explicitly given n=40, rather than assuming reliability from item count alone.
- Categorical predictors (education type, region) need dummy/effect coding.
- Keep trial-level data in long format — needed for the primary mixed-effects analysis.

## G. Retrospective self-report — memory reliability

Motivation and attitude items ask participants to characterize how they felt 14–45 years ago. Per Geary (2022), citing Mehotcheva (2010) and Mehotcheva & Mytara (2019): self-report is "the most viable research option" for this kind of data, and a retained "lasting impression," while not precise reconstruction, is still meaningful.

1. **Items framed as recalled impression, not claimed precision** — reflected in current wording (e.g. Q22, Q53 ask how things felt/feel, not to reconstruct exact past states).
2. **Confidence-check item (Q27)** — gives an empirical handle on reliability; covers all six motivation items (Q21–26). Check post-hoc whether confidence correlates with years-since-instruction, and whether low-confidence responses behave differently in the model.
3. **Years-since-instruction as a robustness check** — the sample spans 14–45 years (much wider than Geary's ~25–30 year window); check whether the motivation→retention relationship holds similarly across the range, or weakens over a longer post-instruction period.

Expect the motivation predictors to carry more measurement noise than proficiency (objective exam record) or multilingualism (simple count) — state this proactively in the limitations section, citing Jordan (2004), Cherciov (2013), and Mehotcheva (2010).

## H. Curriculum-era cohort variable (1999 primary reform)

The Curaclam na Bunscoile (1971) primary Irish curriculum was revised in 1999 to a communicative, task-based approach (primary-level only). Since the sample spans 1981–2012, this reform genuinely divides the sample into two curriculum cohorts, unlike Geary (2022)'s narrower window.

**Computed, not asked directly**: approx. birth year = data collection year − age (Q1); approx. primary school start year = birth year + age of acquisition (Q5); cohort = "pre-1999" if start year < 1999, "post-1999" if ≥ 1999. **Transition cases** (~1997–2001) flagged as uncertain rather than forced into a binary.

**Use**: descriptive reporting plus one exploratory group comparison (e.g. Mann-Whitney U on retention scores by cohort) — NOT a core regression predictor.

## I. Item selection: word length, frequency, AND familiarity — verified

**Final item count: 60 (15 per category)**, matching standard practice in the online vocabulary-testing literature (e.g. LexTALE uses 60 items). Reduced from an original 80 because the recall+recognition task format (typed responses, 20-second cap per item) runs meaningfully longer per item than the simple yes/no recognition format most benchmark tests use — so matching those tests' item count alone wasn't the right comparison; total task time was the real constraint.

**How the final 60 were chosen.** Each of the original 80 candidate items had two independent pieces of evidence: a corpus frequency rank (from the New Corpus for Ireland, ~992 ranked lemmas) and a subjective familiarity rating (1–7 scale, from a native-speaker consultant familiar with the Irish curriculum, rating how familiar each word would be to an average adult in Ireland today). These two measures were combined into one composite score per item, calculated separately within each grammatical category:

**composite = 0.8 × (standardized, reversed, log-transformed frequency rank) + 0.2 × (standardized familiarity rating)**

Frequency was weighted four times as heavily as familiarity because it's an objective, checkable, corpus-derived number, while the familiarity rating comes from a single expert judgement — more useful for breaking ties between similarly-frequent words than for driving the selection on its own. The log transform on rank reflects that a jump from rank 10 to rank 20 is a much bigger real difference than a jump from rank 400 to rank 410. The 15 highest-composite items in each category were kept.

**This weighting was checked for robustness**, not just chosen and left alone: re-running the selection at 2:1 and 3:1 (frequency:familiarity) returns the identical 60 items. Selection on frequency alone, by contrast, changes 4 items — dropping sean ("old"), múinteoir ("teacher"), clann ("family"), and tosaigh ("to start"), all rated 4+ on familiarity, in favour of less-familiar alternatives. So the chosen weighting isn't doing nothing, and it isn't fragile to the exact number picked either.

**Verified stats for the final 60**, independently recomputed and cross-checked against the source data:

| Category | Mean word length | Length range | Mean frequency rank | Frequency range | Mean familiarity | Familiarity range |
|---|---|---|---|---|---|---|
| Concrete noun | 5.20 | 3–9 | 200 | 79–384 | 4.67 | 4–7 |
| Abstract noun | 4.93 | 2–9 | 151 | 39–456 | 4.07 | 2–6 |
| Verb | 4.93 | 3–7 | 89 | 17–203 | 3.40 | 2–5 |
| Adjective | 4.20 | 2–7 | 300 | 80–706 | 4.07 | 2–6 |

**Both word length and frequency rank should still be entered as item-level fixed effects in the mixed-effects model** (alongside category) — cheap to compute, both already in the word list file.

**How well do frequency and familiarity actually agree?** Not very well, and this is worth stating plainly rather than glossing over: across all 80 rated candidates, the two measures correlate only weakly (Spearman ρ = +0.15). For verbs specifically, they're essentially unrelated (ρ = +0.005) — concrete nouns show the strongest agreement (ρ = +0.44). This means corpus frequency alone tells you almost nothing about whether a verb will actually be recognizable to a participant, which is exactly why the familiarity ratings were collected in the first place — and it also means the verb category is the weakest part of the instrument: three high-frequency verbs made the final list despite low familiarity ratings (tabhair, féad, iarr, all rated 2) because nothing more familiar scored high enough on frequency to replace them. Floor effects on these three items should be expected and aren't a design flaw so much as an honest reflection of the corpus/familiarity mismatch for this category.

**Single-rater limitation**: the familiarity ratings come from one consultant. No inter-rater agreement statistic is possible, so these ratings should be treated as one expert's informed judgement, not a normed measure — a further reason familiarity was weighted below frequency rather than given equal say.

**Dual-form scoring dropped entirely.** Two items in the original 80 had two equally acceptable Irish translations (leanbh/páiste for "child"; clann/teaghlach for "family"). Both were replaced with single-translation candidates from the same 200-item pool — food/bia (rank 384, familiarity 4) and colour/dath (rank 456, familiarity 3) respectively — so no new vocabulary was introduced, just a different selection from material already vetted. **The final 60-item set has zero dual-answer items; the scoring protocol (Section E) should be updated to remove dual-acceptance handling entirely**, since it no longer applies.

**One manual override, and it's the only one in the set.** For the "family" replacement, the composite actually ranked fómhar ("autumn") marginally above dath ("colour") — a very small gap (−0.98 vs. −1.07 on a scale spanning about 2.1 across the retained items). Dath was chosen instead for two reasons the composite doesn't capture: it has the higher familiarity rating (3 vs. 2), and it has one clear meaning, whereas fómhar also means "harvest" — the same kind of ambiguity that got luath dropped earlier in this project. This is worth reporting explicitly as a deliberate, principled override, not something to quietly absorb into the numbers.
