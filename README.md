# Irish L2 Lexical Attrition Study — Participant Web App

A participant-facing web app for "Revisiting lexical attrition of instructed L2 Irish"
(University of Cologne): a single continuous session covering consent, a 60-item
lexical recall/recognition task, and a background questionnaire, all tagged with
one `participant_id`.

- **Frontend**: React + Vite SPA, deployed as a static site to GitHub Pages (`app/`)
- **Backend**: Supabase (Postgres + PostgREST), insert-only for the public anon key via
  Row Level Security — see `supabase/schema.sql`
- Full architecture rationale: see the design doc the app was built from (schema,
  security model, write-timing decisions).

## Repository layout

```
context/                            Source materials from the researcher (questionnaire, codebook,
                                     wordlist xlsx, task instructions, WIP R analysis script)
scripts/convert-wordlist.mjs        Converts context/*.xlsx -> app/src/data/wordlist.json + supabase/seed_word_items.sql
supabase/schema.sql                 Full Postgres schema + RLS policies
supabase/seed_word_items.sql        Generated: INSERT statements for the 60 word items
supabase/questionnaire_export_view.sql  Wide Q1..Q53 view for R-compatible questionnaire export
app/                                The React/Vite SPA
.github/workflows/deploy.yml        Builds & deploys app/ to GitHub Pages on push to main
```

## One-time setup

### 1. Create the Supabase project

1. Create a new Supabase project in an **EU region** (e.g. Frankfurt) — required for
   the GDPR commitment made in the study's consent form.
2. In the SQL editor, run `supabase/schema.sql` (creates all tables + RLS policies).
3. Run `supabase/seed_word_items.sql` (loads the 60 word items into `word_items`).
4. Run `supabase/questionnaire_export_view.sql` (creates the `questionnaire_export`
   view used when exporting data for R analysis — see "Exporting data for analysis"
   below).

   All three must be run as `service_role` / via the SQL editor — the anon role has
   no write access to `word_items`, and no read access to the export view.
5. From Project Settings → API, note the **Project URL** and the **anon public key**.
   These are safe to ship in the client bundle — every table they can touch is
   insert-only via RLS (see `supabase/schema.sql` for the full security model).

### 2. Configure the app's environment variables

Create `app/.env.local` (gitignored) with:

```
VITE_SUPABASE_URL=https://<your-project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<your-anon-public-key>
```

For GitHub Pages deployment, add the same two values as **repository secrets**
(`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`) under Settings → Secrets and
variables → Actions — the deploy workflow reads them from there.

### 3. Enable GitHub Pages

Under Settings → Pages, set the source to **GitHub Actions**. Pushing to `main`
(with changes under `app/`) will then build and deploy automatically via
`.github/workflows/deploy.yml`.

If the repository is renamed from `irish-attrition-project`, update the `base`
path in `app/vite.config.js` (or override at build time with `VITE_BASE_PATH`).

## Running the app locally

### 1. Install dependencies

```bash
cd app
npm install
```

### 2. Set up environment variables

The app needs a Supabase URL + anon key to start at all (it throws otherwise).
Create `app/.env.local` (gitignored):

```
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-public-key
```

You have two options here:

- **If you already have the real Supabase project set up** (see "One-time setup"
  above), use its real URL/anon key. This gives you a fully working app — real
  writes land in the tables.
- **If you just want to click through the UI without a real backend yet**, put
  in any placeholder values (e.g. `https://example.supabase.co` / `test-key`).
  The app will still render and behave correctly — every write attempt will
  just fail, retry a few times, and silently queue in `sessionStorage` (the app
  is built not to block the session on write failures). Good enough for
  checking screens/flow, not for checking that data actually lands.

### 3. Run it

```bash
npm run dev
```

Then open **http://localhost:5173**.

### Other useful commands

```bash
npm run test        # run the automated test suite
npm run test:watch  # same, in watch mode
npm run build        # production build to app/dist (same one GitHub Pages runs)
```

## Re-generating the word list

If the researcher sends an updated wordlist xlsx:

```bash
node scripts/convert-wordlist.mjs
```

This regenerates both `app/src/data/wordlist.json` (bundled into the app) and
`supabase/seed_word_items.sql` (re-run the relevant `INSERT`s via the SQL editor)
from the same parse, so they can't drift apart.

## Exporting data for analysis

Data is only readable via the Supabase **service_role** key (SQL editor or
dashboard) — the public anon key used by the app cannot read anything back, by
design. The export shape is aligned directly to `context/irish-attrition-analysis-script-v1.pdf`
(the WIP R script), which expects two CSVs plus the wordlist xlsx:

1. **`task_trial_data.csv`** — export the `trials` table as-is (`SELECT * FROM trials`).
   Its columns already match the script's expected shape
   (`participant_id | item_id | phase | irish_target | english_gloss | category |
   response_text | response_time_ms | live_match_result`, plus a few harmless extras
   the script ignores). `live_match_result` is a Postgres boolean, which a CSV export
   renders as `true`/`false` — `readr::read_csv` parses that straight into an R
   logical column, so `live_match_result == TRUE` in the script works without any
   conversion step.

   **Important**: the script's comment says it expects this column to already reflect
   *final* scoring (fada/edit-distance-tolerant, manual-review-resolved per codebook
   Section E) — what the app writes is the *live routing check* only. Whoever does the
   manual scoring pass needs to update `live_match_result` accordingly before this
   export is fed into the script; the app's boolean type just means that step no
   longer also has to do a string→boolean conversion at the same time.

2. **`questionnaire_data.csv`** — run `SELECT * FROM questionnaire_export`
   (defined in `supabase/questionnaire_export_view.sql`) rather than exporting the
   `questionnaire_part*` tables directly. The view reshapes our normalized,
   per-Part tables into the single wide, one-row-per-participant, `Q1`..`Q53`-named
   layout the script's column-selection code (`exposure_items <- c("Q16", ...)` etc.)
   expects. We kept the base tables normalized — that's what makes per-Part writes
   validate correctly under insert-only RLS — and did the reshaping only at this
   read/export boundary.

   Multilingualism is the one place the script's current shape (`lang1_freq`,
   `lang2_freq`, a semicolon-separated `lang_overflow` text field) is itself marked
   "ADAPT" / placeholder in the script, since it was written before any real export
   existed. The view produces exactly that shape from our `additional_languages`
   table so the script runs unmodified today, but flag to the analyst that this was
   a best-effort match to a placeholder, not a jointly agreed-on format.

3. **Wordlist** — the script reads `context/irish-attrition-wordlist-template-v12.xlsx`
   directly (not from Supabase) for item-level `word_length`/`freq_rank` covariates,
   so no export is needed there.

### Things worth flagging back to the researcher / analyst

A few discrepancies turned up while aligning the export to the script — none of
these were ours to silently resolve, since they're about the analysis itself:

- The script's header says it "implements the analysis plan in codebook v22,
  Section F," but the codebook we have is v20. Worth confirming nothing
  substantive changed between those versions.
- The codebook defines instrumental motivation as 3 items (Q25–Q27), but the
  script's `instrumental_items` vector and reliability check only reference
  Q25–Q26. We still export Q27 (see `supabase/questionnaire_export_view.sql`)
  rather than drop it, but the script itself will need Q27 added if that's an
  oversight rather than a deliberate change.
- The CAO-points proficiency predictor is explicitly left as a TODO in the
  script itself (`quest_raw$proficiency <- NA_real_`) pending a CAO lookup
  table the analyst still needs to build — no action needed from the app side,
  Q12–Q14 are exported as-is for whenever that lookup exists.

## Key design notes

- **No resume after a crash/reload.** Because the anon key can't read back what
  it wrote, an interrupted session can't be automatically resumed — the
  participant sees a message asking them to contact the researcher.
- **Live matching is a routing check only**, not final scoring. Fada-stripping
  (recall) and "to"-stripping + multi-alternative matching (recognition) decide
  whether an item moves to the recognition phase; final scoring (edit-distance
  tolerance, manual review of unlisted synonyms) is a post-hoc step in R, per
  codebook Section E.
- **`contact_optins` is fully decoupled** from study data (no `participant_id`,
  no foreign key) so the optional "email me the findings" step can never be
  joined back to a participant's responses.
