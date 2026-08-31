#!/bin/bash
# agent-framework installer — set up the Twinloop+Kimi loop, memory, judgment,
# and notification rules in ANY project.
#
# Usage:
#   ./install.sh /path/to/project
#
# What it does:
#   1. Copies twinloop.sh + KIMI.md into <project>/scripts/twinloop/
#   2. Writes .framework-dir so agents can locate the framework's GLOBAL memory
#   3. Seeds empty project memory (<project>/memory/) — never overwrites
#   4. Installs AGENTS.md rules into the project root (backs up existing)
#   5. Warns if the target is not a git repo (Twinloop needs git)

set -e

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$1"

if [ -z "$TARGET" ]; then
  echo "Usage: ./install.sh /path/to/project"
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  echo "Error: '$TARGET' is not a directory."
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
echo "Installing agent-framework into: $TARGET"
echo "Framework home (global memory):  $FRAMEWORK_DIR"
echo ""

# 1. Twinloop loop files
mkdir -p "$TARGET/scripts/twinloop"
cp "$FRAMEWORK_DIR/bin/twinloop.sh" "$TARGET/scripts/twinloop/"
cp "$FRAMEWORK_DIR/loop/KIMI.md" "$TARGET/scripts/twinloop/"
cp "$FRAMEWORK_DIR/loop/EVALUATE.md" "$TARGET/scripts/twinloop/"
cp "$FRAMEWORK_DIR/loop/VERIFY.md" "$TARGET/scripts/twinloop/"
cp "$FRAMEWORK_DIR/bin/doctor.sh" "$TARGET/scripts/twinloop/"
cp "$FRAMEWORK_DIR/bin/status.sh" "$TARGET/scripts/twinloop/"
cp "$FRAMEWORK_DIR/loop/PROMPT_GATE.md" "$TARGET/scripts/twinloop/"
cp "$FRAMEWORK_DIR/loop/prompt-rules.md" "$TARGET/scripts/twinloop/"
cp "$FRAMEWORK_DIR/bin/prompt-gate.sh" "$TARGET/scripts/twinloop/"
chmod +x "$TARGET/scripts/twinloop/twinloop.sh" "$TARGET/scripts/twinloop/doctor.sh" "$TARGET/scripts/twinloop/status.sh" "$TARGET/scripts/twinloop/prompt-gate.sh"
echo "✅ scripts/twinloop/  (twinloop.sh + KIMI.md + EVALUATE.md + VERIFY.md + doctor.sh + status.sh + prompt-gate.sh)"

# 2. Framework locator (portable link back to global memory)
echo "$FRAMEWORK_DIR" > "$TARGET/scripts/twinloop/.framework-dir"
echo "✅ scripts/twinloop/.framework-dir"

# 3. Project memory (never overwrite existing)
mkdir -p "$TARGET/memory"
for f in lessons.md patterns.md; do
  if [ ! -f "$TARGET/memory/$f" ]; then
    cp "$FRAMEWORK_DIR/templates/project-memory/$f" "$TARGET/memory/$f"
    echo "✅ memory/$f (seeded)"
  else
    echo "⏭️  memory/$f already exists — kept"
  fi
done

# 4. Blueprint template (never overwrite — the human fills it WITH the agent)
if [ ! -f "$TARGET/blueprint.md" ]; then
  cp "$FRAMEWORK_DIR/templates/BLUEPRINT.md" "$TARGET/blueprint.md"
  echo "✅ blueprint.md (seeded — the Blueprint Gate: standards before code)"
else
  echo "⏭️  blueprint.md already exists — kept"
fi

# 5. AGENTS.md rules (back up existing)
if [ -f "$TARGET/AGENTS.md" ]; then
  cp "$TARGET/AGENTS.md" "$TARGET/AGENTS.md.bak"
  echo "⚠️  Existing AGENTS.md backed up to AGENTS.md.bak"
fi
cp "$FRAMEWORK_DIR/templates/AGENTS.project.md" "$TARGET/AGENTS.md"
echo "✅ AGENTS.md (memory + judgment + notification rules)"

# 6. Project .gitignore — keep runtime state local, keep history tracked
GITIGNORE_BLOCK="# >>> agent-framework >>>
# Machine-specific / regenerable loop state — stays LOCAL, never pushed.
scripts/twinloop/.framework-dir
scripts/twinloop/.last-branch
scripts/twinloop/.evaluated-stories
scripts/twinloop/.verify-attempts
scripts/twinloop/.iterations.log
scripts/twinloop/archive/
AGENTS.md.bak
# NOTE: prd.json, progress.txt, user-notes.md, FINAL-REPORT.md and memory/
# stay TRACKED — they are your history and learning system. Do not ignore them.
# <<< agent-framework <<<"

if [ -f "$TARGET/.gitignore" ]; then
  if grep -q "# >>> agent-framework >>>" "$TARGET/.gitignore"; then
    echo "⏭️  .gitignore already has the agent-framework block — kept"
  else
    printf '\n%s\n' "$GITIGNORE_BLOCK" >> "$TARGET/.gitignore"
    echo "✅ .gitignore (appended agent-framework block)"
  fi
else
  printf '%s\n' "$GITIGNORE_BLOCK" > "$TARGET/.gitignore"
  echo "✅ .gitignore (created)"
fi

# 7. Git check
if [ ! -d "$TARGET/.git" ]; then
  echo ""
  echo "⚠️  '$TARGET' is not a git repository. Twinloop commits after each story —"
  echo "    run 'git init' there before starting the loop."
fi

echo ""
echo "Done! Next steps:"
echo "  1. Open the project in your AI tool and describe your idea — the"
echo "     Blueprint Gate (AGENTS.md) runs WITH you: requirements interview →"
echo "     stack options → architecture → pipeline → stories, filling blueprint.md"
echo "  2. Pre-flight check: cd $TARGET && ./scripts/twinloop/doctor.sh"
echo "  3. Start the loop:   ./scripts/twinloop/twinloop.sh 10"
echo "  4. Track progress:   memory/, user-notes.md, progress.txt, git log"
