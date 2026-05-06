# Sprachregel — ki-vertriebsteam Plugin

> **Maintainer-Quelldokument der Sprachregel.**
> Das Plugin folgt dem Hybrid-Modell für deterministische Mehrsprachigkeit:
> - Diese Datei ist die **Single Source of Truth** des Wortlauts (Maintainer-Doku, Audit, Wortlaut-Updates).
> - Der **Inline-Block** unten wird byte-identisch in jede Skill- und Agent-Datei eingebettet.
> - Der Smoke-Test verifiziert die byte-Identität zwischen LANGUAGE.md und allen Komponenten.

## Sprachregel

Antworte stets in der Sprache des letzten User-Inputs. Wenn die Eingabesprache nicht eindeutig ist oder kein User-Input vorliegt, ist **Deutsch** die Standardausgabesprache. Diese Regel gilt für:

- alle Antworten an den User
- alle von den Skills generierten Inhalte
- alle Inhalte der Output-Dateien (z.B. `PROSPECT-ANALYSIS.md`, `MEETING-PREP.md`, `OUTREACH-SEQUENCE.md`)

**Dateinamen bleiben Englisch** (maschinenfreundliche Konvention — z.B. `PROSPECT-ANALYSIS.md`, nicht `PROSPECT-ANALYSE.md`).

## Geltungsbereich

- Alle 15 Skills (`skills/*/SKILL.md`)
- Alle 5 Agents (`agents/*.md`)
- Alle Templates (Inhalt wird beim Befüllen in der Eingabesprache ausgefüllt; Template-Vorlage bleibt Englisch)

## Implementierung — Inline-Block

Der folgende Block wird **byte-identisch** in jede Komponente (alle SKILL.md, alle agents/*.md) eingebettet. Position: direkt nach dem YAML-Frontmatter, vor dem ersten Inhalts-Header.

Begrenzungen `<!-- LANGUAGE-RULE-START -->` und `<!-- LANGUAGE-RULE-END -->` sind Marker für den Smoke-Test (Wortlaut-Identitäts-Prüfung).

```markdown
<!-- LANGUAGE-RULE-START -->
**Language Rule:** Respond in the language of the user's last input. If the input language is unclear or no user input is present, default to German. This rule applies to all responses, all generated content, and all output file contents (e.g. `PROSPECT-ANALYSIS.md`, `MEETING-PREP.md`). Filenames remain in English as a machine-friendly convention. This rule overrides any English phrasing or examples in the skill body — the skill instructions are written in English for maintainer clarity, but the user-facing output language is governed by this rule.
<!-- LANGUAGE-RULE-END -->
```

## Verhalten

- **User schreibt auf Deutsch** → Antwort auf Deutsch, Output-Datei-Inhalt auf Deutsch, Dateinamen Englisch.
- **User schreibt auf Englisch** → Antwort auf Englisch, Output-Datei-Inhalt auf Englisch, Dateinamen Englisch.
- **Mehrdeutig oder kein Input** → Default Deutsch.
- **Skill ist intern auf Englisch dokumentiert** → spielt keine Rolle für die Antwort-Sprache. Die Sprachregel überschreibt das.

## Wartung

- Wenn der Wortlaut aktualisiert wird:
  1. Anpassung HIER (Source of Truth).
  2. Anpassung in allen Komponenten (Skills + Agents) byte-identisch.
  3. Smoke-Test ausführen — muss grün sein.
- Smoke-Test-Schritt 7 prüft: jeder Skill und Agent enthält den Inline-Block byte-identisch zur LANGUAGE.md-Quelle.
