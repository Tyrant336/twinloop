#!/bin/bash
# doctor.sh - pre-flight check before running the Twinloop loop.
# Catches broken setups BEFORE they burn agent sessions.
# Usage: ./doctor.sh   (run from anywhere; checks the twinloop dir it lives in + its project root)

PASS=0; WARN=0; FAIL=0

ok()   { echo "✅ $1"; PASS=$((PASS+1)); }
warn() { echo "⚠️  $1"; WARN=$((WARN+1)); }
bad()  { echo "❌ $1"; FAIL=$((FAIL+1)); }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd || echo "$SCRIPT_DIR")"
PRD_FILE="$SCRIPT_DIR/prd.json"

echo "Twinloop doctor — checking $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo ""

# 1. Required tools
command -v jq >/dev/null 2>&1 && ok "jq installed" || bad "jq NOT installed (required by twinloop.sh)"
AGENT_CLI_FOUND=0
for cli in kimi claude amp cursor-agent; do
  if command -v "$cli" >/dev/null 2>&1; then ok "$cli CLI installed"; AGENT_CLI_FOUND=1; fi
done
if [ "$AGENT_CLI_FOUND" -eq 0 ]; then
  bad "no supported agent CLI found (kimi / claude / amp / cursor-agent) — install at least one"
fi

# 2. Git
if [ -d "$PROJECT_ROOT/.git" ]; then
  ok "project is a git repository"
  if git -C "$PROJECT_ROOT" config user.name >/dev/null 2>&1; then
    ok "git identity configured ($(git -C "$PROJECT_ROOT" config user.name))"
  else
    warn "git user.name not set — commits may fail"
  fi
else
  bad "project is NOT a git repository (Twinloop commits after each story — run: git init)"
fi

# 3. Framework link
if [ -f "$SCRIPT_DIR/.framework-dir" ]; then
  FW=$(cat "$SCRIPT_DIR/.framework-dir")
  if [ -d "$FW/memory" ]; then
    ok "framework memory found ($FW/memory)"
  else
    warn ".framework-dir points to '$FW' but no memory/ there — re-run install.sh"
  fi
else
  warn ".framework-dir missing — global memory unreachable. Re-run install.sh (harmless)"
fi

# 3b. Blueprint gate (engineering standards BEFORE code — see AGENTS.md)
BLUEPRINT="$PROJECT_ROOT/blueprint.md"
if [ ! -f "$BLUEPRINT" ]; then
  bad "blueprint.md missing — run the Blueprint Gate with your agent first: requirements → stack decision → architecture → pipeline"
else
  UNCHECKED=$(grep -c '^- \[ \]' "$BLUEPRINT" || true)
  if [ "${UNCHECKED:-0}" -gt 0 ]; then
    warn "blueprint.md has $UNCHECKED unapproved section(s) — human approval required before the loop builds code"
  else
    ok "blueprint.md fully approved"
  fi
fi

# 4. PRD
if [ ! -f "$PRD_FILE" ]; then
  bad "prd.json missing — create it (see prd.json.example in the framework)"
else
  if jq empty "$PRD_FILE" 2>/dev/null; then
    ok "prd.json is valid JSON"
    BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE")
    [ -n "$BRANCH" ] && ok "branchName set: $BRANCH" || warn "branchName missing in prd.json"
    TOTAL=$(jq '.userStories | length' "$PRD_FILE")
    if [ "$TOTAL" -gt 0 ]; then ok "$TOTAL user stories defined"; else bad "userStories is empty — nothing for the loop to do"; fi
    NO_CRIT=$(jq '[.userStories[] | select((.acceptanceCriteria // []) | length == 0)] | length' "$PRD_FILE")
    [ "$NO_CRIT" -eq 0 ] && ok "all stories have acceptance criteria" || warn "$NO_CRIT stories lack acceptanceCriteria — the evaluator can't verify them"
    NO_TITLE=$(jq '[.userStories[] | select((.title // "") == "")] | length' "$PRD_FILE")
    [ "$NO_TITLE" -eq 0 ] && ok "all stories have titles" || warn "$NO_TITLE stories missing titles"
    DONE=$(jq '[.userStories[] | select(.passes==true)] | length' "$PRD_FILE")
    BLOCKED=$(jq '[.userStories[] | select(.blocked==true)] | length' "$PRD_FILE")
    echo "   progress: $DONE passing, $BLOCKED blocked, $((TOTAL - DONE - BLOCKED)) remaining"
    # Vague-word lint on acceptance criteria (deterministic, zero tokens — P1 from prompt-rules.md)
    VAGUE_HITS=$(jq -r '.userStories[].acceptanceCriteria[]?' "$PRD_FILE" 2>/dev/null | grep -Einc '\b(good|better|best|nice|fast|user[- ]friendly|optimize|improve|clean|modern|etc\.?|and so on|appropriate|reasonable|properly|correctly)\b' || true)
    if [ "${VAGUE_HITS:-0}" -gt 0 ]; then
      warn "$VAGUE_HITS acceptance criteria contain vague words (good/fast/improve/etc.) — untestable criteria break the evaluator. See prompt-rules.md P1"
      jq -r '.userStories[].acceptanceCriteria[]?' "$PRD_FILE" 2>/dev/null | grep -Ein '\b(good|better|best|nice|fast|user[- ]friendly|optimize|improve|clean|modern|etc\.?|and so on|appropriate|reasonable|properly|correctly)\b' | head -3 | sed 's/^/     → /'
    else
      ok "no vague words in acceptance criteria"
    fi
  else
    bad "prd.json is INVALID JSON — the loop will fail immediately"
  fi
fi

# 5. Quality gate detection (the loop needs tests/checks to verify work)
if [ -f "$PROJECT_ROOT/package.json" ] && jq -e '.scripts.test' "$PROJECT_ROOT/package.json" >/dev/null 2>&1; then
  ok "test command detected (npm test)"
elif ls "$PROJECT_ROOT"/test_*.py "$PROJECT_ROOT"/tests/ >/dev/null 2>&1 || [ -f "$PROJECT_ROOT/pytest.ini" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
  ok "python test setup detected (pytest-style)"
elif [ -f "$PROJECT_ROOT/Makefile" ] && grep -q '^test:' "$PROJECT_ROOT/Makefile" 2>/dev/null; then
  ok "test command detected (make test)"
else
  warn "no test setup detected — without a quality gate, the loop can't verify code. Add tests!"
fi

# 6. Final verification state (VERIFY phase — the exit gate, mirrors 3b)
FINAL_REPORT="$PROJECT_ROOT/FINAL-REPORT.md"
if [ -f "$FINAL_REPORT" ]; then
  if grep -q '^- \[ \]' "$FINAL_REPORT"; then
    warn "FINAL-REPORT.md exists but human acceptance is unchecked — review the report, run the product, tick the box"
  else
    ok "FINAL-REPORT.md accepted by human"
  fi
elif [ -f "$PRD_FILE" ] && jq empty "$PRD_FILE" 2>/dev/null; then
  TOTAL=$(jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo 0)
  DONE=$(jq '[.userStories[] | select(.passes==true)] | length' "$PRD_FILE" 2>/dev/null || echo 0)
  BLOCKED=$(jq '[.userStories[] | select(.blocked==true)] | length' "$PRD_FILE" 2>/dev/null || echo 0)
  if [ "${TOTAL:-0}" -gt 0 ] && [ $((DONE + BLOCKED)) -ge "$TOTAL" ]; then
    warn "all stories done but no FINAL-REPORT.md — the verify phase hasn't run yet (twinloop.sh runs it by default; use --no-verify to skip)"
  fi
fi

echo ""
echo "----------------------------------------"
echo "Result: $PASS ok, $WARN warnings, $FAIL failures"
if [ "$FAIL" -gt 0 ]; then
  echo "❌ Fix the failures above before running twinloop.sh"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "⚠️  Runnable, but review the warnings"
  exit 0
else
  echo "✅ All good — run: ./scripts/twinloop/twinloop.sh 10"
  exit 0
fi
