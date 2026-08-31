#!/bin/bash
# prompt-gate.sh - review a prompt BEFORE you send it to the agent.
# The gate detects bad patterns, asks clarifying questions, suggests a rewrite,
# and learns your recurring weaknesses over time.
#
# Usage:
#   ./prompt-gate.sh "build me an app"          (prompt as argument)
#   echo "build me an app" | ./prompt-gate.sh   (piped)
#   ./prompt-gate.sh -f myprompt.txt            (from file)

set -e

# Windows fix: ensure UTF-8 stdin decoding for the piped prompt (emoji/dashes)
export PYTHONIOENCODING=utf-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=""
if [ "$1" = "-f" ] && [ -n "$2" ]; then
  INPUT=$(cat "$2")
elif [ $# -gt 0 ]; then
  INPUT="$*"
elif [ ! -t 0 ]; then
  INPUT=$(cat)
fi

if [ -z "$INPUT" ]; then
  echo "Usage: ./prompt-gate.sh \"your prompt here\""
  echo "       echo \"prompt\" | ./prompt-gate.sh"
  echo "       ./prompt-gate.sh -f prompt.txt"
  exit 1
fi

if ! command -v kimi >/dev/null 2>&1; then
  echo "Error: kimi CLI not found in PATH."
  exit 1
fi

{
  cat "$SCRIPT_DIR/PROMPT_GATE.md"
  echo ""
  echo "# USER PROMPT TO REVIEW"
  echo '"""'
  echo "$INPUT"
  echo '"""'
} | kimi --quiet
