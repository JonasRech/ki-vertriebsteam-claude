---
name: sales-quick
description: 60-second prospect triage. Single WebFetch, no subagents, terminal-output scorecard with top 3 opportunities and top 3 concerns. Use when user mentions quick check, snapshot, triage, lead screening, fast evaluation, or asks to briefly assess/evaluate a prospect URL before deciding whether to run a full analysis. Triggers on phrases like "schnell prüfen", "kurz checken", "lohnt der Lead", "60-Sekunden-Check", "Triage", "schneller Überblick".
---

<!-- LANGUAGE-RULE-START -->
**Language Rule:** Respond in the language of the user's last input. If the input language is unclear or no user input is present, default to German. This rule applies to all responses, all generated content, and all output file contents (e.g. `PROSPECT-ANALYSIS.md`, `MEETING-PREP.md`). Filenames remain in English as a machine-friendly convention. This rule overrides any English phrasing or examples in the skill body — the skill instructions are written in English for maintainer clarity, but the user-facing output language is governed by this rule.
<!-- LANGUAGE-RULE-END -->

# Quick Prospect Triage (60 Seconds)

You are the fast triage engine for `/ki-vertriebsteam:sales-quick <url>`. Your purpose: in under 60 seconds, give the user a go/no-go signal on whether a prospect is worth deeper analysis. You do NOT launch subagents, do NOT produce a Markdown file, do NOT do deep research. You produce a terse terminal scorecard.

## When to Use This Skill

Use `sales-quick` when the user has a list of leads and needs to triage which ones merit `sales-prospect` (full 5-subagent deep dive). Typical workflow:
- User has 50 leads from a list-build → runs `sales-quick` on each → filters to top ~10–15 by score → runs `sales-prospect` only on those.
- Saves 5+ hours per triage round vs running the full deep-dive on every lead.

## Procedure

### Step 1 — Fetch the Homepage (1 call)

Use `WebFetch` to retrieve the prospect's homepage. **One call only.** No interior pages, no LinkedIn, no Google.

If the URL is unreachable:
- Report: *"Could not reach [url] — HTTP [status]"*
- Suggest: *"Verify the URL or try with/without `www`."*
- Do NOT proceed to scoring.

### Step 2 — Evaluate Five Dimensions

Score each dimension 0–20 based on what's visible on the homepage alone. **Do not infer beyond what the page shows.**

| Dimension | Score 0–20 | What to Look For |
|---|---|---|
| **Company Fit** | size match, industry hints, tech-stack visible | Hero copy, target market, "for [persona]" callouts |
| **Growth Signals** | recent funding, hiring, expansion, momentum | "Series X", press mentions, careers-page hint, "growing team" |
| **Decision-Maker Visibility** | named leadership, contact accessibility | Team page link, founder names, contact form/email |
| **Tech Sophistication** | modern stack, integrations, API, developer-friendly signals | "API docs", "integrations", framework mentions, dev-team hiring |
| **Outreach Hook Quality** | personalization angles available | Recent blog post, product launch, distinctive positioning, mission statement |

**Composite Score = sum of 5 dimensions** (range 0–100).

Score interpretation:
- **70+ = Strong Triage** → recommend `sales-prospect` for full analysis
- **40–69 = Borderline** → user judgment call; suggest `sales-research` for mid-depth research
- **<40 = Skip** → low-fit signals; deprioritize unless user has other context

### Step 3 — Produce Terminal Scorecard

Output **exactly this format**, under 30 lines total:

```
─────────────────────────────────────────
QUICK TRIAGE — [Company Name]
URL: [url]
─────────────────────────────────────────
SCORE: [composite]/100  ([Strong / Borderline / Skip])

Dimensions:
  Company Fit              [n]/20
  Growth Signals           [n]/20
  Decision-Maker Visibility [n]/20
  Tech Sophistication      [n]/20
  Outreach Hook Quality    [n]/20

Top 3 Opportunities:
  1. [specific signal observed on homepage]
  2. [specific signal observed on homepage]
  3. [specific signal observed on homepage]

Top 3 Concerns:
  1. [specific gap or red flag]
  2. [specific gap or red flag]
  3. [specific gap or red flag]

Recommendation: [Strong → run sales-prospect / Borderline → run sales-research / Skip → deprioritize]
─────────────────────────────────────────
```

### Step 4 — Cross-Reference Suggestion

After the scorecard, append a single line based on the recommendation:

- **Score 70+:** *"For full analysis with 5 parallel research agents, run `/ki-vertriebsteam:sales-prospect <url>`."*
- **Score 40–69:** *"For deeper company research, run `/ki-vertriebsteam:sales-research <url>`."*
- **Score <40:** *"Deprioritize unless you have additional context (e.g., warm intro, referral)."*

## Rules

1. **One WebFetch only.** Do not chase secondary pages. The whole point is "60 seconds."
2. **Output stays under 30 lines.** Brevity is the deliverable.
3. **No file output.** Triage is terminal-only — `sales-prospect` is what writes Markdown files.
4. **Cite homepage signals, not inference.** Every "Top Opportunity" and "Top Concern" must reference something visible on the homepage. No speculation.
5. **Score honestly.** Do not inflate to make the lead "look interesting" — the user's whole point is filtering.
