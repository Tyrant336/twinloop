#!/bin/bash
# status.sh - token-free project dashboard. No AI session needed.
# Usage: ./status.sh   (lives in scripts/ralph/, reads state from there + project root)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
NOTES_FILE="$SCRIPT_DIR/user-notes.md"
ITER_LOG="$SCRIPT_DIR/.iterations.log"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd || echo "$SCRIPT_DIR")"
FINAL_REPORT="$PROJECT_ROOT/FINAL-REPORT.md"

echo "==============================================================="
echo "  Ralph status — $(date '+%Y-%m-%d %H:%M')"
echo "==============================================================="

# Stories
if [ -f "$PRD_FILE" ]; then
  echo ""
  echo "📋 Stories ($(jq -r '.branchName // "no-branch"' "$PRD_FILE")):"
  jq -r '.userStories[] | "  \(if .passes then "✅" elif .blocked then "🚫" else "⬜" end) \(.id)  \(.title)"' "$PRD_FILE" 2>/dev/null
  TOTAL=$(jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo 0)
  DONE=$(jq '[.userStories[] | select(.passes==true)] | length' "$PRD_FILE" 2>/dev/null || echo 0)
  BLOCKED=$(jq '[.userStories[] | select(.blocked==true)] | length' "$PRD_FILE" 2>/dev/null || echo 0)
  [ "$TOTAL" -gt 0 ] && echo "  → $DONE/$TOTAL passing, $BLOCKED blocked"
else
  echo ""
  echo "📋 No prd.json yet — nothing scheduled."
fi

# Sessions today
if [ -f "$ITER_LOG" ]; then
  TODAY=$(date +%F)
  USED=$(grep -c "^$TODAY" "$ITER_LOG" 2>/dev/null || true)
  TOTAL_SESSIONS=$(wc -l < "$ITER_LOG" | tr -d ' ')
  echo ""
  echo "🔁 Agent sessions: ${USED:-0} today, $TOTAL_SESSIONS all-time"
fi

# Final verification / human acceptance (VERIFY phase)
if [ -f "$FINAL_REPORT" ]; then
  echo ""
  if grep -q '^- \[ \]' "$FINAL_REPORT"; then
    echo "🏁 FINAL-REPORT.md written — 👉 your acceptance checkbox is still unchecked"
  else
    echo "🏁 FINAL-REPORT.md — ✅ accepted by human"
  fi
fi

# Needs attention (from user-notes.md)
if [ -f "$NOTES_FILE" ]; then
  ATTENTION=$(grep -A0 "Needs your attention" "$NOTES_FILE" | grep -v "nothing" | tail -3)
  if [ -n "$ATTENTION" ]; then
    echo ""
    echo "👀 Recent items needing you:"
    echo "$ATTENTION" | sed 's/^/  /'
  fi
fi

# Last progress
if [ -f "$PROGRESS_FILE" ]; then
  echo ""
  echo "📖 Last progress entries:"
  grep "^## " "$PROGRESS_FILE" | tail -3 | sed 's/^/  /'
fi
echo ""
