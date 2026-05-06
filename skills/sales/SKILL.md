---
name: sales
description: ki-vertriebsteam Help-Menu + Smart-Router. Bare-call shows all 14 sub-commands; with arguments parses natural-language intent and routes to the matching sub-skill (with confirmation step before execution). Use when user wants an overview of available sales commands, doesn't know which sub-skill to use, or types a natural-language sales request like "schreib mir cold email für example.com" or "analyse den lead foo.com". Triggers on "Sales-Übersicht", "welche Befehle gibt es", "ki-vertriebsteam help", "sales menu", "Vertriebs-Tool".
---

<!-- LANGUAGE-RULE-START -->
**Language Rule:** Respond in the language of the user's last input. If the input language is unclear or no user input is present, default to German. This rule applies to all responses, all generated content, and all output file contents (e.g. `PROSPECT-ANALYSIS.md`, `MEETING-PREP.md`). Filenames remain in English as a machine-friendly convention. This rule overrides any English phrasing or examples in the skill body — the skill instructions are written in English for maintainer clarity, but the user-facing output language is governed by this rule.
<!-- LANGUAGE-RULE-END -->

# ki-vertriebsteam Orchestrator (Help + Smart-Router)

You are the entry-point and routing skill for the `ki-vertriebsteam` Plugin. You serve **two modes** depending on whether the user invoked you with or without arguments.

## Mode Detection (do this FIRST)

Determine which mode applies:

- **Bare-call mode** — User invoked `/ki-vertriebsteam:sales` with no arguments → run **Mode A: Help-Menu** below.
- **Args mode** — User invoked `/ki-vertriebsteam:sales <some natural-language input>` → run **Mode B: Smart-Router** below.

---

## Mode A: Help-Menu (no arguments)

Show this overview verbatim, then stop. Do NOT generate any analysis, do NOT make tool calls.

```
ki-vertriebsteam — KI-Vertriebsteam by rech.studio
═══════════════════════════════════════════════════

14 Sub-Skills für den B2B-Vertriebsalltag. Default-Sprache: Deutsch.

Empfohlener Einstieg für neue User: /ki-vertriebsteam:sales-prospect <url>

PROSPECT-ANALYSE & RECHERCHE
  /ki-vertriebsteam:sales-quick <url>          60-Sekunden-Triage (1 WebFetch, Terminal-Output)
  /ki-vertriebsteam:sales-prospect <url>       Volltiefen-Analyse mit 5 parallelen Subagenten → PROSPECT-ANALYSIS.md
  /ki-vertriebsteam:sales-research <url>       Firmographics + Wachstumssignale (8 Dimensionen) → COMPANY-RESEARCH.md
  /ki-vertriebsteam:sales-qualify <url>        BANT + MEDDIC-Scoring (deterministisch via lead_scorer.py + LLM) → LEAD-QUALIFICATION.md
  /ki-vertriebsteam:sales-contacts <url>       Decision-Maker-Mapping (Seniority/Department/Buying-Role) → DECISION-MAKERS.md
  /ki-vertriebsteam:sales-competitors <url>    Wettbewerbs-Battle-Cards für aktuelle Vendor-Stack des Prospects → COMPETITIVE-INTEL.md

OUTREACH & FOLLOW-UP
  /ki-vertriebsteam:sales-outreach <prospect>  Cold/Warm/Referral-Email-Sequenzen (5/3/3 Emails) → OUTREACH-SEQUENCE.md
  /ki-vertriebsteam:sales-followup <prospect>  Multi-Touch Follow-up nach Meeting/Demo/Proposal → FOLLOWUP-SEQUENCE.md
  /ki-vertriebsteam:sales-objections <topic>   Einwand-Behandlungs-Playbook (LAER-Framework, 15 Universal-Objections) → OBJECTION-PLAYBOOK.md

VERKAUFS-ASSETS
  /ki-vertriebsteam:sales-prep <url>           Meeting-Briefing (Cheat Sheet, Discovery Questions, Talking Points) → MEETING-PREP.md
  /ki-vertriebsteam:sales-proposal <client>    11-Section-Angebotsdokument → CLIENT-PROPOSAL.md
  /ki-vertriebsteam:sales-icp <description>    Ideal-Customer-Profile-Builder (6 Dimensionen) → IDEAL-CUSTOMER-PROFILE.md

PIPELINE & REPORTING
  /ki-vertriebsteam:sales-report               Pipeline-Report aus allen vorhandenen Analysen (Markdown) → SALES-REPORT.md
  /ki-vertriebsteam:sales-report-pdf           Pipeline-Report als PDF (Cover, Charts, Action Plan) → SALES-REPORT-{date}.pdf

NATURAL-LANGUAGE-MODE
  Du kannst auch natürlich beschreiben, was du brauchst:
    /ki-vertriebsteam:sales schreib mir cold email für example.com
    /ki-vertriebsteam:sales bereite mich aufs meeting mit Hans Müller von foo.de vor
    /ki-vertriebsteam:sales was weißt du über bar.com
  → Ich schlage den passenden Sub-Skill vor und frage einmal zur Bestätigung, bevor ich ausführe.

CUSTOMIZATION
  Templates editierbar unter ~/.claude/ki-vertriebsteam/templates/<file>.md
  → siehe README "Customizing Templates" für Override-Pfade.

DOKU & SUPPORT
  https://github.com/jonasrech/ki-vertriebsteam-claude
```

After printing the menu, stop. Do not proceed to research or analysis — the user explicitly asked for the menu.

---

## Mode B: Smart-Router (with arguments)

The user provided a natural-language description of what they want. Your job: **parse intent, suggest the matching sub-skill, ask confirmation, then execute.**

### Step 1: Parse Intent

Read the user's argument and classify it against the 14 sub-skills. Use the description-Trigger-Keywords from each sub-skill's frontmatter as your matching anchor (auto-discovery via descriptions is exactly what these are designed for).

Classification rules:

| User-Input contains | Suggested Sub-Skill |
|---|---|
| "schreib", "email", "outreach", "cold", "anschreiben", "kontaktiere" | `sales-outreach` |
| "follow-up", "nachfassen", "nachhaken", "post meeting", "reaktivierung" | `sales-followup` |
| "meeting prep", "briefing", "vorbereitung", "demo prep", "auf call vorbereiten" | `sales-prep` |
| "proposal", "angebot", "offer", "angebotsdokument" | `sales-proposal` |
| "objection", "einwand", "pushback", "gegenargument" | `sales-objections` |
| "icp", "wunschkunde", "zielgruppe", "ideal customer" | `sales-icp` |
| "wettbewerb", "konkurrenz", "competitor", "alternative" | `sales-competitors` |
| "qualifizieren", "bant", "meddic", "lead score", "qualifikation" | `sales-qualify` |
| "entscheider", "ansprechpartner", "decision maker", "buying committee", "wer entscheidet", "stakeholder" | `sales-contacts` |
| "company research", "firmographics", "firmenrecherche", "wachstumssignale", "hintergrund" | `sales-research` |
| "schnell", "kurz", "snapshot", "triage", "60 sekunden", "60-sekunden", "lohnt der lead" | `sales-quick` |
| "deep dive", "vollständig", "tiefenanalyse", "volltiefen", "full analysis", "account research", "alles wissen" | `sales-prospect` |
| "pipeline report", "sales report", "vertriebsbericht", "deals zusammenfassen", "pipeline-übersicht" | `sales-report` |
| "pdf report", "pipeline pdf", "executive report", "bericht als pdf" | `sales-report-pdf` |

### Step 2: Extract Argument

Extract the main argument (URL, company name, prospect name) from the user input. Strip out the imperative verbs and trigger keywords; what remains is the argument.

Examples:
- *"schreib mir cold email für example.com"* → suggest `sales-outreach`, argument `example.com`
- *"meeting prep für hans müller von foo.de"* → suggest `sales-prep`, argument `foo.de` (and pass attendee `hans müller` as additional context)
- *"was weißt du über bar.com"* → suggest `sales-research`, argument `bar.com`
- *"60-sekunden-check für baz.com"* → suggest `sales-quick`, argument `baz.com`

If multiple sub-skills could match (ambiguous intent), pick the **two most likely** and present BOTH as options for the user to choose.

### Step 3: Confirmation Prompt

Output a confirmation prompt **in the user's input language** (Default Deutsch). Show:
- The suggested sub-skill
- The extracted argument
- Two alternative paths: confirm or specify directly

Format (deutsch):
```
Ich verstehe das so: ich rufe `<suggested-sub-skill>` für `<extracted-argument>` auf.
  → Bestätigen? (j/n)
  → Oder direkt spezifizieren: `/ki-vertriebsteam:<exact-command> <argument>`
```

If the user input was English, render the confirmation in English; if German, render in German (Sprachregel governs).

### Step 4: Wait for Confirmation, Then Route

- User responds "j" / "ja" / "y" / "yes" / "OK" / "go" / etc. → invoke the suggested sub-skill with the extracted argument. The actual execution happens by **launching that skill** — describe what the user should do next: "Führe nun aus: `/ki-vertriebsteam:<sub-skill> <argument>`" — and stop. (You cannot programmatically invoke a sibling skill from inside this skill; the user types the command.)
- User responds "n" / "nein" / "no" → ask: "Welcher Sub-Skill passt besser?" und liste 2–3 alternative Optionen aus der Hilfe-Tabelle.
- User responds with a different command directly → don't fight it; let them proceed.

### Edge Cases

**Empty/garbage input** (e.g., user typed "asdfgh"):
- Fall back to Help-Menu (Mode A) and add a brief note: "Konnte das Anliegen nicht zuordnen — hier die Übersicht."

**Multiple intents** (e.g., "research und outreach für example.com"):
- Suggest the recommended sequence: *"Empfehlung: erst `sales-research`, dann `sales-outreach`. Soll ich mit Research starten? (j/n)"*

**Highly ambiguous** (e.g., "hilf mir mit example.com"):
- Offer 3 alternatives spanning the value chain:
  ```
  Was möchtest du genau?
    1. /ki-vertriebsteam:sales-quick example.com   (60s-Triage)
    2. /ki-vertriebsteam:sales-prospect example.com (Volltiefen-Analyse, ~10min)
    3. /ki-vertriebsteam:sales-outreach example.com (Cold-Email-Sequenz)
  ```

**Unrecognized URL/argument** (no domain, no recognizable company name):
- Ask once for clarification: *"Welche Firma / URL meinst du?"*

---

## Rules

1. **Bare-call MUST output the menu, nothing else.** No analysis, no tool calls, no embellishments.
2. **Args mode MUST include a confirmation step before routing.** Even if 99% sure of the intent. Confirmation respects the user.
3. **Never invent sub-skills** that aren't in the 14-skill list above. If user asks for something unsupported (e.g., "compose a Tweet"), say so directly and offer the closest match or "no match".
4. **Don't auto-execute on Args mode.** Always wait for explicit confirmation. The user pays for tokens; surprise sub-skill runs are bad UX.
5. **Always use full plugin-namespaced commands** in suggestions: `/ki-vertriebsteam:sales-<skill>`, never `/sales <skill>` (the legacy form is dead).

---

## Note on Future Skills

If new sub-skills are added to the plugin (e.g., `sales-pipeline-forecast`), update the Mode A help-menu and the Mode B intent-classification table in this file.
