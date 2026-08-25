// Field schemas for the SchemaForm renderer, one export per questionnaire Part.
// Field `key`s match the target Postgres column names exactly (see supabase/schema.sql)
// so a Part's submitted values object can be spread straight into an insert row.

const CURRENT_YEAR = new Date().getFullYear();

const FREQUENCY_LABELS = ["Never", "Rarely", "Occasionally", "Often", "Daily or almost daily"];
const CONFIDENCE_LABELS = ["Not at all confident", "Slightly confident", "Moderately confident", "Confident", "Very confident"];
const ATTRITION_LABELS = [
  "Stayed almost the same",
  "Lost a little",
  "Lost a moderate amount",
  "Lost a lot",
  "Almost completely disappeared",
];

const USE_CONTEXT_OPTIONS = [
  { value: "work", label: "Work" },
  { value: "social", label: "Social settings" },
  { value: "media", label: "Media or social media" },
  { value: "family", label: "Family" },
  { value: "other", label: "Other" },
  { value: "not_applicable", label: "Not applicable" },
];

const REGION_OPTIONS = [
  { value: "leinster", label: "Leinster" },
  { value: "munster", label: "Munster" },
  { value: "connacht", label: "Connacht" },
  { value: "ulster", label: "Ulster" },
];

const GRADE_OPTIONS = ["a", "b", "c", "d", "e", "f"].map((g) => ({ value: g, label: g.toUpperCase() }));

// ---------------------------------------------------------------------------
// Part 1 — General background (Q1-11)
// ---------------------------------------------------------------------------
export const PART1_FIELDS = [
  { key: "age", type: "number", label: "What is your age?", min: 18, max: 120 },
  {
    key: "gender",
    type: "select",
    label: "What is your gender?",
    options: [
      { value: "female", label: "Female" },
      { value: "male", label: "Male" },
      { value: "non_binary", label: "Non-binary" },
      { value: "prefer_not_to_say", label: "Prefer not to say" },
    ],
  },
  { key: "region_residence", type: "select", label: "What is your current region of residence?", options: REGION_OPTIONS },
  {
    key: "irish_l1_status",
    type: "select",
    label:
      "Did you grow up speaking Irish as a first language at home (e.g. in a Gaeltacht household), or did you learn it as a second language at school?",
    options: [
      { value: "first_language_home", label: "First language at home" },
      { value: "second_language_school", label: "Second language, learned at school" },
      { value: "mix_of_both", label: "A mix of both" },
    ],
  },
  { key: "age_began_learning", type: "number", label: "At what age did you begin learning Irish?", min: 0, max: 120 },
  {
    key: "informal_exposure_before",
    type: "boolean",
    label:
      "Beyond what you indicated above, did you have any additional informal exposure to Irish before you began learning it formally (e.g. occasional exposure from a relative, neighbours, or media)?",
  },
  {
    key: "informal_exposure_context",
    type: "text",
    label: "Approximate context/frequency (optional)",
    required: false,
    dependsOn: (v) => v.informal_exposure_before === true,
  },
  {
    key: "gaeltacht_contact",
    type: "boolean",
    label: "Did you ever attend a Gaeltacht summer course, or have regular contact with Gaeltacht speakers, during your school years?",
  },
  {
    key: "gaeltacht_contact_context",
    type: "text",
    label: "Approximate frequency/context (optional)",
    required: false,
    dependsOn: (v) => v.gaeltacht_contact === true,
  },
  {
    key: "current_use_frequency",
    type: "scale5",
    label: "How often do you use Irish now?",
    scaleLabels: FREQUENCY_LABELS,
  },
  {
    key: "current_use_contexts",
    type: "multiselect",
    label: "In which contexts do you use Irish?",
    options: USE_CONTEXT_OPTIONS,
    required: (v) => v.current_use_frequency > 1,
    dependsOn: (v) => v.current_use_frequency > 1,
  },
  {
    key: "irish_related_occupation",
    type: "boolean",
    label:
      "Do you currently work, or have you ever worked, in a field related to the Irish language specifically (e.g. Irish teaching, Irish translation or interpreting)?",
  },
  { key: "is_parent", type: "boolean", label: "Are you a parent?" },
  {
    key: "parent_engagement",
    type: "select",
    label:
      "Have you engaged with Irish through your children's education — for example helping with homework, or encouraging their use of Irish — either now or in the past?",
    dependsOn: (v) => v.is_parent === true,
    options: [
      { value: "yes_currently", label: "Yes, currently — children still at school" },
      { value: "yes_in_past", label: "Yes, in the past — children have since finished school" },
      { value: "no", label: "No" },
      { value: "not_applicable", label: "Not applicable — children not yet at school age" },
    ],
  },
];

// ---------------------------------------------------------------------------
// Part 2 — Proficiency at end of instruction (Q12-15)
// ---------------------------------------------------------------------------
export const PART2_FIELDS = [
  {
    key: "leaving_cert_year",
    type: "number",
    label: "In what year did you complete your Leaving Certificate Irish exam, if applicable?",
    min: 1950,
    max: CURRENT_YEAR,
    required: (v) => v.leaving_cert_paper !== "did_not_sit",
  },
  {
    key: "leaving_cert_paper",
    type: "select",
    label: "What Leaving Certificate Irish paper did you sit?",
    options: [
      { value: "higher", label: "Higher level" },
      { value: "ordinary", label: "Ordinary level" },
      { value: "foundation", label: "Foundation level" },
      { value: "did_not_sit", label: "Did not sit Leaving Cert Irish" },
    ],
  },
  {
    key: "no_lc_self_rated_proficiency",
    type: "select",
    label: "How would you describe your Irish proficiency at the end of your formal instruction?",
    dependsOn: (v) => v.leaving_cert_paper === "did_not_sit",
    options: [
      { value: "beginner", label: "Beginner" },
      { value: "intermediate", label: "Intermediate" },
      { value: "advanced", label: "Advanced" },
      { value: "fluent", label: "Fluent" },
    ],
  },
  {
    key: "no_lc_assessment_method",
    type: "text",
    label: "How was that proficiency assessed (e.g. a different exam, school report, self-assessment)?",
    dependsOn: (v) => v.leaving_cert_paper === "did_not_sit",
  },
  {
    key: "leaving_cert_grade",
    type: "select",
    label: "What grade did you receive in your Leaving Certificate Irish exam?",
    dependsOn: (v) => v.leaving_cert_paper !== "did_not_sit",
    options: GRADE_OPTIONS,
  },
  {
    key: "continued_study_after_lc",
    type: "boolean",
    label:
      "Did you continue studying Irish after the Leaving Certificate — at third level, or through any other Irish courses or classes?",
  },
  {
    key: "continued_study_until_year",
    type: "number",
    label: "Until what year?",
    min: 1950,
    max: CURRENT_YEAR,
    dependsOn: (v) => v.continued_study_after_lc === true,
  },
  {
    key: "continued_study_context",
    type: "text",
    label: "In what context (degree module/subject, evening class, etc.)?",
    dependsOn: (v) => v.continued_study_after_lc === true,
  },
  {
    key: "continued_study_result",
    type: "text",
    label: "If graded or assessed, what was the result? (optional)",
    required: false,
    dependsOn: (v) => v.continued_study_after_lc === true,
  },
];

// ---------------------------------------------------------------------------
// Part 3 — Exposure since instruction (Q16-20)
// ---------------------------------------------------------------------------
export const PART3_FIELDS = [
  { key: "exposure_signage_media", type: "scale5", label: "How often do you hear or see Irish in daily life (signage, media, announcements)?", scaleLabels: FREQUENCY_LABELS },
  { key: "exposure_conversations", type: "scale5", label: "How often have you had conversations in Irish over the years since finishing school?", scaleLabels: FREQUENCY_LABELS },
  { key: "exposure_media_consumption", type: "scale5", label: "How often do you engage with or consume Irish-language media (TV, radio, podcasts, social media)?", scaleLabels: FREQUENCY_LABELS },
  { key: "exposure_events", type: "scale5", label: "How often have you attended events, classes, or gatherings involving Irish since leaving school?", scaleLabels: FREQUENCY_LABELS },
  { key: "exposure_family_social", type: "scale5", label: "How often is Irish actively used by people in your family or social circle?", scaleLabels: FREQUENCY_LABELS },
];

// ---------------------------------------------------------------------------
// Part 4 — Motivation (Q21-28)
// ---------------------------------------------------------------------------
export const PART4_FIELDS = [
  { key: "integrative_q21", type: "likert", prompt: "Learning Irish helped me feel connected to Ireland's culture, heritage, and history." },
  { key: "integrative_q22", type: "likert", prompt: "Learning Irish felt like an important part of who I was as a person at the time." },
  { key: "integrative_q23", type: "likert", prompt: "I was interested in Irish beyond what was required for exams." },
  { key: "integrative_q24", type: "likert", prompt: "I wanted to be able to take part in Irish-speaking community life or cultural activities." },
  { key: "instrumental_q25", type: "likert", prompt: "My main motivation for learning Irish was to pass my exams." },
  { key: "instrumental_q26", type: "likert", prompt: "I learned Irish mainly because it was compulsory, not out of personal interest." },
  { key: "instrumental_q27", type: "likert", prompt: "I was motivated by practical benefits (e.g. university entry requirements, job prospects) rather than the language itself." },
  {
    key: "motivation_confidence_q28",
    type: "scale5",
    label: "How confident are you in your answers to the seven statements above?",
    scaleLabels: CONFIDENCE_LABELS,
  },
];

// ---------------------------------------------------------------------------
// Part 5 summary — Q29 gate
// ---------------------------------------------------------------------------
export const PART5_SUMMARY_FIELDS = [
  {
    key: "has_additional_languages",
    type: "boolean",
    label:
      "Are you proficient in any languages other than English and Irish (at least basic conversational or functional ability)?",
  },
  {
    key: "additional_languages_count_self_report",
    type: "number",
    label: "How many additional languages?",
    min: 1,
    max: 20,
    dependsOn: (v) => v.has_additional_languages === true,
  },
];

// Part 5 per-language sub-form (full detail: first 2 languages by proficiency)
export const ADDITIONAL_LANGUAGE_FULL_FIELDS = [
  { key: "language_name", type: "text", label: "Language" },
  {
    key: "proficiency",
    type: "select",
    label: "Approximate proficiency",
    options: [
      { value: "beginner", label: "Beginner" },
      { value: "intermediate", label: "Intermediate" },
      { value: "advanced", label: "Advanced" },
      { value: "fluent", label: "Fluent" },
    ],
  },
  {
    key: "acquisition_context",
    type: "multiselect",
    label: "In what context(s) did you learn this language?",
    options: [
      { value: "formal_classroom", label: "Formal classroom instruction" },
      { value: "living_abroad", label: "Living or studying abroad" },
      { value: "immersion_program", label: "Immersion program" },
      { value: "family_heritage", label: "Family or heritage — learned at home" },
      { value: "self_study", label: "Self-study" },
      { value: "other", label: "Other" },
    ],
  },
  {
    key: "acquisition_timing_duration",
    type: "text",
    label: 'Approximately when, and for how long, did you learn or acquire this language? (e.g. "secondary school, 5 years")',
  },
  {
    key: "lc_status",
    type: "select",
    label: "Did you sit this language for the Leaving Certificate?",
    options: [
      { value: "did_not_sit", label: "Did not sit" },
      { value: "ordinary", label: "Ordinary level" },
      { value: "higher", label: "Higher level" },
    ],
  },
  {
    key: "lc_grade",
    type: "select",
    label: "Grade received",
    required: false,
    dependsOn: (v) => v.lc_status === "ordinary" || v.lc_status === "higher",
    options: GRADE_OPTIONS,
  },
  { key: "use_frequency", type: "scale5", label: "How often do you currently use this language?", scaleLabels: FREQUENCY_LABELS },
  { key: "use_contexts", type: "multiselect", label: "In what contexts do you use this language?", options: USE_CONTEXT_OPTIONS },
];

// Part 5 per-language sub-form (brief overflow: 3rd+ languages)
export const ADDITIONAL_LANGUAGE_BRIEF_FIELDS = [
  { key: "language_name", type: "text", label: "Language" },
  { key: "use_frequency", type: "scale5", label: "How often do you use this language?", scaleLabels: FREQUENCY_LABELS },
];

// ---------------------------------------------------------------------------
// Part 6 — Background-only variables (Q30-53)
// ---------------------------------------------------------------------------
const SCHOOL_TYPE_OPTIONS = [
  { value: "gaelscoil", label: "Gaelscoil" },
  { value: "english_medium", label: "English-medium school" },
  { value: "other", label: "Other" },
];

export const PART6_FIELDS = [
  { key: "primary_school_type", type: "select", label: "What type of primary school did you attend?", options: SCHOOL_TYPE_OPTIONS },
  { key: "secondary_school_type", type: "select", label: "What type of secondary school did you attend?", options: SCHOOL_TYPE_OPTIONS },
  {
    key: "highest_education",
    type: "select",
    label: "What is your highest level of education completed?",
    options: [
      { value: "primary_education_only", label: "Primary education only" },
      { value: "junior_certificate", label: "Intermediate or Junior Certificate" },
      { value: "leaving_certificate", label: "Leaving Certificate" },
      { value: "plc_qualification", label: "Post-Leaving Certificate (PLC) qualification" },
      { value: "third_level_certificate_or_diploma", label: "Third-level Certificate or Diploma" },
      { value: "bachelors_degree", label: "Bachelor's degree" },
      { value: "postgraduate_diploma_or_masters", label: "Postgraduate Diploma or Master's degree" },
      { value: "doctoral_degree", label: "Doctoral degree" },
      { value: "other", label: "Other" },
    ],
  },
  { key: "secondary_school_region", type: "select", label: "In what region did you attend secondary school?", options: REGION_OPTIONS },

  { key: "attitude_q34", type: "likert", prompt: "I have a positive attitude toward the Irish language." },
  { key: "attitude_q35", type: "likert", prompt: "Irish is an important part of Irish culture and identity." },
  { key: "attitude_q36", type: "likert", prompt: "I wish I had more opportunities to use Irish in daily life." },

  { key: "learning_exp_q37", type: "likert", prompt: "I enjoyed learning Irish in school." },
  { key: "learning_exp_q38", type: "likert", prompt: "I found Irish classes effective in helping me learn the language." },
  { key: "learning_exp_q39", type: "likert", prompt: "I felt confident in my overall Irish ability by the end of school." },
  { key: "learning_exp_q40", type: "likert", prompt: "I enjoyed the content of the Irish course in secondary school." },

  { key: "classroom_anxiety_q41", type: "likert", prompt: "I often felt nervous or uncomfortable speaking Irish in class." },
  { key: "classroom_anxiety_q42", type: "likert", prompt: "I felt embarrassed to answer or volunteer in Irish class." },

  { key: "parental_encouragement_q43", type: "likert", prompt: "My parents/family encouraged me to learn Irish." },
  { key: "parental_encouragement_q44", type: "likert", prompt: "My parents/family showed interest in how I was doing in Irish class." },
  { key: "parental_encouragement_q45", type: "likert", prompt: "My parents/family felt it was culturally important for me to learn Irish." },
  { key: "parental_encouragement_q46", type: "likert", prompt: "My parents/family mainly wanted me to do well in Irish for my overall school performance." },

  { key: "family_irish_proficiency_parent", type: "boolean", label: "At least one of my parents was proficient in Irish." },
  { key: "family_irish_proficiency_helper", type: "boolean", label: "At least one family member was able to help me with my Irish homework." },

  { key: "linguistic_identity_q49", type: "likert", prompt: "Being able to speak Irish is part of who I am." },
  { key: "linguistic_identity_q50", type: "likert", prompt: "I feel a personal connection to the Irish language, even if I don't use it often." },

  {
    key: "self_rated_attrition_q51",
    type: "scale5",
    label: "Compared to when I finished school, I feel the level of my Irish proficiency has:",
    scaleLabels: ATTRITION_LABELS,
  },

  { key: "reconnection_motivation_q52", type: "likert", prompt: "I feel motivated to reconnect with or relearn Irish now, as an adult." },
  {
    key: "reconnection_channels",
    type: "multiselect",
    label: "Through which channels, if any, have you engaged or would you consider engaging?",
    required: false,
    dependsOn: (v) => v.reconnection_motivation_q52 > 1,
    options: [
      { value: "social_media", label: "Social media or online communities (e.g. Facebook groups)" },
      { value: "language_apps", label: "Language apps (e.g. Duolingo)" },
      { value: "evening_classes", label: "Evening classes or courses" },
      { value: "conversation_groups", label: "Conversation groups or meet-ups (e.g. pub nights)" },
      { value: "gaeltacht_trips", label: "Trips to the Gaeltacht" },
      { value: "other", label: "Other" },
      { value: "none_so_far", label: "None so far" },
    ],
  },
];
