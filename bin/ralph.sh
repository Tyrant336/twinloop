#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop (agent-framework fork)
# Features: generator-evaluator loop, stuck detection, cost guard, auto-resume,
#           final VERIFY phase (end-to-end verification + FINAL-REPORT.md).
#
# Usage: ./ralph.sh [--tool kimi|amp|claude|cursor] [--max-daily N] [--no-eval] [--no-verify] [--no-progress-limit N] [max_iterations]

set -e

# Defaults
TOOL="kimi"
MAX_ITERATIONS=10
MAX_DAILY=0            # 0 = unlimited agent sessions per day
NO_PROGRESS_LIMIT=3    # stop early after N consecutive iterations with no new passing story
USE_EVALUATOR=1
USE_VERIFY=1           # end-to-end verify phase after the loop declares completion
MAX_VERIFY_ATTEMPTS=2  # how many times verify may fail+reopen stories before a human is required

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)        TOOL="$2"; shift 2 ;;
    --tool=*)      TOOL="${1#*=}"; shift ;;
    --max-daily)   MAX_DAILY="$2"; shift 2 ;;
    --max-daily=*) MAX_DAILY="${1#*=}"; shift ;;
    --no-eval)     USE_EVALUATOR=0; shift ;;
    --verify)      USE_VERIFY=1; shift ;;
    --no-verify)   USE_VERIFY=0; shift ;;
    --no-progress-limit)   NO_PROGRESS_LIMIT="$2"; shift 2 ;;
    --no-progress-limit=*) NO_PROGRESS_LIMIT="${1#*=}"; shift ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      else
        echo "Error: unrecognized argument '$1'."
        echo "Usage: ./ralph.sh [--tool kimi|amp|claude|cursor] [--max-daily N] [--no-eval] [--no-verify] [--no-progress-limit N] [max_iterations]"
        exit 1
      fi
      shift ;;
  esac
done

if [[ "$TOOL" != "amp" && "$TOOL" != "claude" && "$TOOL" != "kimi" && "$TOOL" != "cursor" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp', 'claude', 'kimi', or 'cursor'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
NOTES_FILE="$SCRIPT_DIR/user-notes.md"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
EVAL_TRACKER="$SCRIPT_DIR/.evaluated-stories"
ITER_LOG="$SCRIPT_DIR/.iterations.log"
VERIFY_STATE="$SCRIPT_DIR/.verify-attempts"

note_for_user() {
  # $1 = done line, $2 = attention line, $3 = next step
  {
    echo ""
    echo "## $(date '+%Y-%m-%d %H:%M') - Loop note"
    echo "- ✅ Done: $1"
    echo "- 👀 Needs your attention: $2"
    echo "- 👉 Suggested next step: $3"
  } >> "$NOTES_FILE"
}

count_passing() { jq '[.userStories[] | select(.passes==true)] | length' "$PRD_FILE" 2>/dev/null || echo 0; }
count_blocked() { jq '[.userStories[] | select(.blocked==true)] | length' "$PRD_FILE" 2>/dev/null || echo 0; }
count_total()   { jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo 0; }

unevaluated_ids() {
  [ -f "$PRD_FILE" ] || return 0
  touch "$EVAL_TRACKER"
  for id in $(jq -r '.userStories[] | select(.passes==true) | .id' "$PRD_FILE" 2>/dev/null); do
    grep -qx "$id" "$EVAL_TRACKER" || echo "$id"
  done
}

run_agent() {
  # $1 = prompt file; prints agent output to stdout (also tees to stderr for live view)
  local prompt_file="$1"
  case "$TOOL" in
    amp)    cat "$prompt_file" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr ;;
    claude) claude --dangerously-skip-permissions --print < "$prompt_file" 2>&1 | tee /dev/stderr ;;
    # cursor-agent headless: -p print mode, '-' reads the prompt from stdin,
    # --force applies file changes (without it, changes are only proposed),
    # --approve-mcps skips interactive MCP approval prompts.
    cursor) cursor-agent -p --force --approve-mcps - < "$prompt_file" 2>&1 | tee /dev/stderr ;;
    kimi)   kimi --quiet < "$prompt_file" 2>&1 | tee /dev/stderr ;;
  esac
}

# --- Pre-flight ---
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: $PRD_FILE not found."
  echo "Create it first (see prd.json.example), or run: $(dirname "$0")/doctor.sh"
  exit 1
fi

# --- Cost guard ---
touch "$ITER_LOG"
TODAY=$(date +%F)

check_cost_guard() {
  # Re-checked before EVERY agent session (builder or evaluator), not just once
  # at startup — a single run can burn up to 2 sessions per iteration.
  local used
  used=$(grep -c "^$TODAY" "$ITER_LOG" 2>/dev/null || true)
  used=${used:-0}
  if [[ "$MAX_DAILY" -gt 0 && "$used" -ge "$MAX_DAILY" ]]; then
    echo "Cost guard: daily limit reached ($used/$MAX_DAILY agent sessions today). Stopping."
    note_for_user "loop paused by cost guard" "🚨 daily session limit hit ($MAX_DAILY). The loop stopped BEFORE doing more work; progress is saved." "raise --max-daily or wait until tomorrow, then re-run the same command"
    exit 1
  fi
}

DAILY_USED=$(grep -c "^$TODAY" "$ITER_LOG" 2>/dev/null || true)
DAILY_USED=${DAILY_USED:-0}
check_cost_guard

# --- Archive previous run if branch changed ---
if [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    echo "Archiving previous run: $LAST_BRANCH -> $ARCHIVE_FOLDER"
    mkdir -p "$ARCHIVE_FOLDER"
    cp "$PRD_FILE" "$ARCHIVE_FOLDER/" 2>/dev/null || true
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$NOTES_FILE" ] && cp "$NOTES_FILE" "$ARCHIVE_FOLDER/"
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
    rm -f "$EVAL_TRACKER" "$VERIFY_STATE"
  fi
fi

CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
[ -n "$CURRENT_BRANCH" ] && echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Ralph - Tool: $TOOL - Max iterations: $MAX_ITERATIONS - Evaluator: $USE_EVALUATOR - Verify: $USE_VERIFY - Daily cap: ${MAX_DAILY:-off} (used today: $DAILY_USED)"

# --- Final evaluation + VERIFY phase (runs where the loop used to just exit 0) ---

final_evaluation_pass() {
  # The builder can emit COMPLETE on the same iteration that flipped the last
  # story — before the evaluator ever saw it. Review unevaluated stories first,
  # so no story reaches verify without an independent review.
  if [[ "$USE_EVALUATOR" -eq 1 ]]; then
    local uneval
    uneval=$(unevaluated_ids)
    if [ -n "$uneval" ]; then
      echo ""
      echo "  Final evaluator pass before verify: $(echo $uneval | tr '\n' ' ')"
      check_cost_guard
      run_agent "$SCRIPT_DIR/EVALUATE.md" >/dev/null 2>&1 || true
      echo "$TODAY" >> "$ITER_LOG"
    fi
  fi
}

run_verify_phase() {
  # Returns 0 = product verified, safe to exit. Returns 1 = verify failed or
  # was inconclusive; stories were reopened and the build loop should resume.
  if [[ "$USE_VERIFY" -eq 0 ]]; then return 0; fi
  if [ ! -f "$SCRIPT_DIR/VERIFY.md" ]; then
    echo "Warning: VERIFY.md not found — skipping verify phase (re-run install.sh to get it)."
    return 0
  fi
  local attempts
  attempts=$(cat "$VERIFY_STATE" 2>/dev/null || echo 0)
  attempts=${attempts:-0}
  if [[ "$attempts" -ge "$MAX_VERIFY_ATTEMPTS" ]]; then
    echo "Verify phase has failed $attempts times. Builder and verifier are going in circles — a human must step in."
    note_for_user "verify phase stuck" "🚨 final verification failed $attempts times — the loop keeps reopening the same stories" "read progress.txt tail, fix or re-scope manually, then delete scripts/ralph/.verify-attempts and re-run"
    exit 1
  fi
  echo ""
  echo "==============================================================="
  echo "  Ralph VERIFY phase ($TOOL) [attempt $((attempts + 1))/$MAX_VERIFY_ATTEMPTS]"
  echo "==============================================================="
  check_cost_guard
  local voutput
  voutput=$(run_agent "$SCRIPT_DIR/VERIFY.md") || true
  echo "$TODAY" >> "$ITER_LOG"
  if echo "$voutput" | grep -q "<promise>VERIFY_FAILED</promise>"; then
    echo $((attempts + 1)) > "$VERIFY_STATE"
    echo "Verify FAILED — verifier reopened stories. Resuming the build loop."
    NO_PROGRESS=0
    return 1
  fi
  if echo "$voutput" | grep -q "<promise>VERIFIED</promise>"; then
    echo "Verify PASSED — FINAL-REPORT.md written at project root."
    echo "Human acceptance is still pending: review the report and tick its checkbox."
    return 0
  fi
  if echo "$voutput" | grep -q "<promise>VERIFY_INCOMPLETE</promise>"; then
    echo "Verifier reports prd.json still has unfinished stories — resuming the build loop."
    return 1
  fi
  # No clear signal — do NOT trust the completion claim silently.
  echo "Verify phase gave no clear verdict. Treating as failed (safety-first)."
  echo $((attempts + 1)) > "$VERIFY_STATE"
  note_for_user "verify phase inconclusive" "🚨 verifier ended without a VERIFIED/VERIFY_FAILED signal — completion is NOT confirmed" "re-run the same command; if it repeats, run the verify pass manually with VERIFY.md"
  return 1
}

finish_run() {
  # Called at every point where the loop used to exit 0 on completion.
  # Returns 0 = truly done (verified or verify disabled); 1 = keep building.
  final_evaluation_pass
  local total passing blocked
  total=$(count_total); passing=$(count_passing); blocked=$(count_blocked)
  if [[ $((passing + blocked)) -lt "$total" ]]; then
    echo "Final evaluator rejected work — resuming the build loop."
    return 1
  fi
  if run_verify_phase; then return 0; fi
  return 1
}

NO_PROGRESS=0

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL) [builder]"
  echo "==============================================================="

  BEFORE=$(count_passing)

  # NOTE: KIMI.md is the canonical builder prompt for all tools (amp/claude/kimi).
  # Amp- and Claude-specific prompts live in archive/ for reference only.
  check_cost_guard
  OUTPUT=$(run_agent "$SCRIPT_DIR/KIMI.md") || true
  echo "$TODAY" >> "$ITER_LOG"

  # --- Completion signals from the builder ---
  if echo "$OUTPUT" | grep -q "<promise>BLUEPRINT_GATE</promise>"; then
    echo ""; echo "Blueprint Gate is not satisfied. The loop cannot build yet."
    echo "Complete blueprint.md approvals first (see AGENTS.md -> Blueprint Gate)."
    exit 1
  fi
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""; echo "Ralph completed all tasks! (iteration $i of $MAX_ITERATIONS)"
    if finish_run; then exit 0; fi
    continue
  fi
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE_WITH_BLOCKERS</promise>"; then
    echo ""; echo "Ralph finished with blocked stories (iteration $i of $MAX_ITERATIONS)."
    echo "Check user-notes.md for 🚨 blocked items."
    if finish_run; then exit 0; fi
    continue
  fi

  # --- Evaluator pass (generator-evaluator) ---
  if [[ "$USE_EVALUATOR" -eq 1 ]]; then
    UNEVAL=$(unevaluated_ids)
    if [ -n "$UNEVAL" ]; then
      echo ""
      echo "  Ralph Iteration $i ($TOOL) [evaluator: $(echo $UNEVAL | tr '\n' ' ')]"
      check_cost_guard
      EVAL_OUTPUT=$(run_agent "$SCRIPT_DIR/EVALUATE.md") || true
      echo "$TODAY" >> "$ITER_LOG"
    fi
  fi

  # --- Auto-complete safety net (in case the agent forgot the signal) ---
  TOTAL=$(count_total); PASSING=$(count_passing); BLOCKED=$(count_blocked)
  if [[ "$TOTAL" -gt 0 && $((PASSING + BLOCKED)) -ge "$TOTAL" && -z "$(unevaluated_ids)" ]]; then
    echo ""
    if [[ "$BLOCKED" -gt 0 ]]; then
      echo "Ralph finished: $PASSING/$TOTAL stories passing, $BLOCKED blocked. Check user-notes.md."
    else
      echo "Ralph completed all $TOTAL tasks! (detected via prd.json state)"
    fi
    if finish_run; then exit 0; fi
    continue
  fi

  # --- Stuck detection ---
  AFTER=$(count_passing)
  if [[ "$AFTER" -le "$BEFORE" ]]; then
    NO_PROGRESS=$((NO_PROGRESS + 1))
    echo "No new passing story ($NO_PROGRESS/$NO_PROGRESS_LIMIT before early stop)."
  else
    NO_PROGRESS=0
  fi

  if [[ "$NO_PROGRESS" -ge "$NO_PROGRESS_LIMIT" ]]; then
    echo ""
    echo "Stuck detection: no progress in $NO_PROGRESS_LIMIT consecutive iterations. Stopping early."
    note_for_user "loop stopped early (stuck)" "🚨 $NO_PROGRESS_LIMIT iterations with no story passing — the agent is stuck. Read progress.txt tail for why." "open the project, read the last progress entries, and either clarify the story in prd.json or fix the blocker manually, then re-run"
    exit 1
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status. Re-run the same command to continue."
exit 1
