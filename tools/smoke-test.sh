#!/bin/bash
# ============================================================================
# ki-vertriebsteam Plugin — Pre-Release Smoke-Test
# ============================================================================
# Validiert strukturelle Integrität des Plugins vor Release.
# Checks werden inkrementell pro Issue erweitert (siehe PRD Testing-Decisions).
# ============================================================================

set -uo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PLUGIN_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local description="$1"
    local result="$2"
    if [[ "$result" == "PASS" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗${NC} $description"
        FAIL=$((FAIL + 1))
    fi
}

# Helper: get YAML frontmatter value for a key from a markdown file
get_frontmatter_value() {
    local file="$1"
    local key="$2"
    awk -v key="$key" '
        /^---$/ { if (in_fm) exit; in_fm=1; next }
        in_fm && $0 ~ "^"key":" {
            sub("^"key": *", "")
            print
            exit
        }
    ' "$file"
}

# Helper: check if file has YAML frontmatter with name + description
has_frontmatter() {
    local file="$1"
    if [[ ! -f "$file" ]]; then return 1; fi
    if [[ "$(head -1 "$file")" != "---" ]]; then return 1; fi
    if ! grep -q "^name:" "$file"; then return 1; fi
    if ! grep -q "^description:" "$file"; then return 1; fi
    return 0
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} ki-vertriebsteam Plugin Smoke-Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ----------------------------------------------------------------------------
# Check 1: plugin.json existiert am korrekten Pfad
# ----------------------------------------------------------------------------
if [[ -f ".claude-plugin/plugin.json" ]]; then
    check "plugin.json exists at .claude-plugin/plugin.json" "PASS"
    MANIFEST_OK=true
else
    check "plugin.json exists at .claude-plugin/plugin.json (häufigster silent-fail)" "FAIL"
    MANIFEST_OK=false
fi

# ----------------------------------------------------------------------------
# Check 2: plugin.json ist valides JSON
# ----------------------------------------------------------------------------
if [[ "$MANIFEST_OK" == "true" ]]; then
    if command -v jq &> /dev/null; then
        if jq . .claude-plugin/plugin.json > /dev/null 2>&1; then
            check "plugin.json is valid JSON" "PASS"
            JSON_OK=true
        else
            check "plugin.json is valid JSON" "FAIL"
            JSON_OK=false
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} jq not installed — skipping JSON validity check"
        JSON_OK=false
    fi
else
    check "plugin.json is valid JSON (skipped — file missing)" "FAIL"
    JSON_OK=false
fi

# ----------------------------------------------------------------------------
# Check 3: Pflichtfelder im Manifest
# ----------------------------------------------------------------------------
if [[ "$JSON_OK" == "true" ]]; then
    REQUIRED_FIELDS=("name" "version" "description" "author" "repository" "license")
    MISSING_FIELDS=()
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! jq -e ".$field" .claude-plugin/plugin.json > /dev/null 2>&1; then
            MISSING_FIELDS+=("$field")
        fi
    done
    if [[ ${#MISSING_FIELDS[@]} -eq 0 ]]; then
        check "All required fields present: ${REQUIRED_FIELDS[*]}" "PASS"
    else
        check "Missing required fields: ${MISSING_FIELDS[*]}" "FAIL"
    fi
else
    check "Required fields check (skipped — JSON invalid or missing)" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 4: Jeder skills/*/SKILL.md hat YAML-Frontmatter mit name + description
# ----------------------------------------------------------------------------
SKILLS_MISSING_FM=()
for skill_md in skills/*/SKILL.md; do
    [[ -f "$skill_md" ]] || continue
    if ! has_frontmatter "$skill_md"; then
        SKILLS_MISSING_FM+=("$skill_md")
    fi
done
SKILL_COUNT=$(ls -1 skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
if [[ ${#SKILLS_MISSING_FM[@]} -eq 0 ]]; then
    check "All $SKILL_COUNT skills have YAML frontmatter (name + description)" "PASS"
else
    check "Skills missing frontmatter: ${SKILLS_MISSING_FM[*]}" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 5: Jeder agents/*.md hat YAML-Frontmatter
# ----------------------------------------------------------------------------
AGENTS_MISSING_FM=()
for agent_md in agents/*.md; do
    [[ -f "$agent_md" ]] || continue
    if ! has_frontmatter "$agent_md"; then
        AGENTS_MISSING_FM+=("$agent_md")
    fi
done
AGENT_COUNT=$(ls -1 agents/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ ${#AGENTS_MISSING_FM[@]} -eq 0 ]]; then
    check "All $AGENT_COUNT agents have YAML frontmatter" "PASS"
else
    check "Agents missing frontmatter: ${AGENTS_MISSING_FM[*]}" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 6: LANGUAGE.md existiert am Plugin-Root
# ----------------------------------------------------------------------------
if [[ -f "LANGUAGE.md" ]]; then
    check "LANGUAGE.md exists at plugin root" "PASS"
    LANGUAGE_OK=true
else
    check "LANGUAGE.md exists at plugin root" "FAIL"
    LANGUAGE_OK=false
fi

# ----------------------------------------------------------------------------
# Check 7: Inline-Sprachregel-Block byte-identisch in allen Komponenten
# ----------------------------------------------------------------------------
if [[ "$LANGUAGE_OK" == "true" ]]; then
    # Extract canonical block from LANGUAGE.md
    EXPECTED_BLOCK=$(awk '
        /^<!-- LANGUAGE-RULE-START -->$/ {capture=1}
        capture {print}
        /^<!-- LANGUAGE-RULE-END -->$/ && capture {exit}
    ' LANGUAGE.md)

    if [[ -z "$EXPECTED_BLOCK" ]]; then
        check "Could not extract LANGUAGE-RULE block from LANGUAGE.md" "FAIL"
    else
        DRIFT=()
        for component in skills/*/SKILL.md agents/*.md; do
            [[ -f "$component" ]] || continue
            ACTUAL_BLOCK=$(awk '
                /^<!-- LANGUAGE-RULE-START -->$/ {capture=1}
                capture {print}
                /^<!-- LANGUAGE-RULE-END -->$/ && capture {exit}
            ' "$component")
            if [[ "$ACTUAL_BLOCK" != "$EXPECTED_BLOCK" ]]; then
                DRIFT+=("$component")
            fi
        done
        if [[ ${#DRIFT[@]} -eq 0 ]]; then
            check "Language-rule block byte-identical in all components" "PASS"
        else
            check "Drift in language-rule block: ${DRIFT[*]}" "FAIL"
        fi
    fi
else
    check "Language-rule block check (skipped — LANGUAGE.md missing)" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 8: Keine relativen `python3 scripts/...`-Pfade in Skills (alle auf ${CLAUDE_PLUGIN_ROOT})
# ----------------------------------------------------------------------------
RELATIVE_SCRIPT_REFS=$(grep -rln "python3 scripts/" skills/ 2>/dev/null || true)
if [[ -z "$RELATIVE_SCRIPT_REFS" ]]; then
    check "No relative 'python3 scripts/' paths in skills (all use \${CLAUDE_PLUGIN_ROOT})" "PASS"
else
    check "Relative 'python3 scripts/' paths still exist in: $RELATIVE_SCRIPT_REFS" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 9: Keine Verweise auf zubair-trabzada oder ai-sales-team-claude in Plugin-Sources
# (Scope: skills/, agents/, .claude-plugin/, LANGUAGE.md, README.md — exkl. tools/, issues/, PRD.md, research.md)
# ----------------------------------------------------------------------------
SCAN_PATHS="skills agents .claude-plugin LANGUAGE.md README.md"
ZUBAIR_REFS=$(grep -rln "zubair-trabzada" $SCAN_PATHS 2>/dev/null || true)
AI_SALES_REFS=$(grep -rln "ai-sales-team-claude" $SCAN_PATHS 2>/dev/null || true)
if [[ -z "$ZUBAIR_REFS" && -z "$AI_SALES_REFS" ]]; then
    check "No stale references (zubair-trabzada / ai-sales-team-claude) in Plugin sources" "PASS"
else
    DETAIL=""
    [[ -n "$ZUBAIR_REFS" ]] && DETAIL="zubair-trabzada in: $ZUBAIR_REFS"
    [[ -n "$AI_SALES_REFS" ]] && DETAIL="$DETAIL ai-sales-team-claude in: $AI_SALES_REFS"
    check "Stale references found — $DETAIL" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 10: Templates in skills/<name>/templates/ werden vom Skill-Body referenziert
# ----------------------------------------------------------------------------
TEMPLATE_REF_MISSING=()
for tmpl in skills/*/templates/*.md; do
    [[ -f "$tmpl" ]] || continue
    skill_dir=$(dirname "$(dirname "$tmpl")")
    skill_md="$skill_dir/SKILL.md"
    tmpl_name=$(basename "$tmpl")
    if [[ ! -f "$skill_md" ]]; then continue; fi
    if ! grep -q "$tmpl_name" "$skill_md"; then
        TEMPLATE_REF_MISSING+=("$skill_md does not reference $tmpl_name")
    fi
done
if [[ ${#TEMPLATE_REF_MISSING[@]} -eq 0 ]]; then
    check "All templates are referenced by their owning SKILL.md" "PASS"
else
    check "Unreferenced templates: ${TEMPLATE_REF_MISSING[*]}" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 11: Repo-Root templates/ existiert nicht mehr
# ----------------------------------------------------------------------------
if [[ ! -d "templates" ]]; then
    check "Repo-root templates/ removed (templates moved into skills)" "PASS"
else
    check "Repo-root templates/ still exists — should be deleted (templates belong in skills/<name>/templates/)" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 13: Alle 4 Scripts sind in zugehörigen Skills referenziert
# (bash 3.2-kompatibel — parallel arrays statt associative array)
# ----------------------------------------------------------------------------
SCRIPT_NAMES=("analyze_prospect.py" "contact_finder.py" "lead_scorer.py" "generate_pdf_report.py")
SCRIPT_OWNERS=("skills/sales-prospect/SKILL.md" "skills/sales-contacts/SKILL.md" "skills/sales-qualify/SKILL.md" "skills/sales-report-pdf/SKILL.md")
SCRIPT_REF_MISSING=()
for i in "${!SCRIPT_NAMES[@]}"; do
    script="${SCRIPT_NAMES[$i]}"
    owner="${SCRIPT_OWNERS[$i]}"
    if [[ ! -f "$owner" ]]; then
        SCRIPT_REF_MISSING+=("$owner missing")
        continue
    fi
    if ! grep -q "$script" "$owner"; then
        SCRIPT_REF_MISSING+=("$owner does not reference $script")
        continue
    fi
    if ! grep -q "\${CLAUDE_PLUGIN_ROOT}.*$script" "$owner"; then
        SCRIPT_REF_MISSING+=("$owner references $script without \${CLAUDE_PLUGIN_ROOT}")
    fi
done
if [[ ${#SCRIPT_REF_MISSING[@]} -eq 0 ]]; then
    check "All 4 scripts referenced in owning skills with \${CLAUDE_PLUGIN_ROOT} prefix" "PASS"
else
    check "Script wiring issues: ${SCRIPT_REF_MISSING[*]}" "FAIL"
fi

# ----------------------------------------------------------------------------
# Check 12: Skill-Descriptions trigger-fähig (>50 chars + Trigger-Marker)
# ----------------------------------------------------------------------------
WEAK_DESCRIPTIONS=()
for skill_md in skills/*/SKILL.md; do
    [[ -f "$skill_md" ]] || continue
    DESC=$(get_frontmatter_value "$skill_md" "description")
    if [[ -z "$DESC" ]]; then
        WEAK_DESCRIPTIONS+=("$skill_md (empty)")
        continue
    fi
    if [[ ${#DESC} -le 50 ]]; then
        WEAK_DESCRIPTIONS+=("$skill_md (too short: ${#DESC} chars)")
        continue
    fi
    if ! echo "$DESC" | grep -qE "(Use when|Triggers on|Triggert)"; then
        WEAK_DESCRIPTIONS+=("$skill_md (missing trigger marker)")
    fi
done
if [[ ${#WEAK_DESCRIPTIONS[@]} -eq 0 ]]; then
    check "All skill descriptions are >50 chars AND contain trigger markers" "PASS"
else
    check "Weak descriptions: ${WEAK_DESCRIPTIONS[*]}" "FAIL"
fi

# ----------------------------------------------------------------------------
# Summary + End-to-End-Hinweis
# ----------------------------------------------------------------------------
echo ""
echo -e "${BLUE}----------------------------------------${NC}"
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}Total: $PASS passed, $FAIL failed${NC}"
    echo ""
    echo -e "Now run ${BLUE}claude --plugin-dir \"\$(pwd)\"${NC} and invoke ${BLUE}/ki-vertriebsteam:sales${NC} to verify end-to-end."
    exit 0
else
    echo -e "${RED}Total: $PASS passed, $FAIL failed${NC}"
    exit 1
fi
