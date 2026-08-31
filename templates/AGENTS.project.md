# Project Agent Rules

> Installed by agent-framework (`install.sh`). These rules make any coding agent
> in this project learn, remember, notify, and exercise judgment.

## If the human asks "what is this framework / how do I use it?"

Read `scripts/twinloop/.framework-dir` to find the framework folder, then answer
from its docs: `QUICKSTART-zero.md` (from-zero guide), `USAGE.md` (full guide +
worked example), `README.md` (architecture). Explain using those files — never
guess or improvise framework behavior from memory.

## Memory Protocol (MANDATORY)

The model does not remember past sessions — memory files ARE the memory.

**Locate memory:**
- **Project memory** = `memory/` at this project root (lessons + patterns for THIS codebase)
- **Global memory** = read `scripts/twinloop/.framework-dir` for the absolute path of
  the agent-framework folder; global memory is `<that path>/memory/`
  (user profile, cross-project lessons, judgment rules)

**At the START of every session**, read (if they exist):
1. `memory/lessons.md` and `memory/patterns.md` (this project)
2. Global `profile.md`, `lessons.md`, `judgment.md` (framework memory)
3. Apply what you read without being asked. Never repeat a recorded mistake.

**At the END of every session (or milestone):**
1. Append new mistakes/discoveries to `memory/lessons.md`:
   date | what went wrong | the rule for next time
2. Promote general rules to `memory/patterns.md`.

## Blueprint Gate (BEFORE any code — MANDATORY)

Engineering standards come first. If `blueprint.md` (project root) is missing
or has ANY unchecked approval box (`- [ ]`), DO NOT write feature code or
create prd.json. Run this phase WITH the human instead:

1. **Interview the human** — requirements before technology: what it does,
   who it's for, the ONE-sentence pitch, the demo happy path, the cut line
   (what we will NOT build), constraints (time, offline, skills).
2. **Propose 2–3 tech stack options** with honest tradeoffs (speed to build,
   demo polish, what the human knows, what AI generates well). NEVER pre-decide
   the stack — you propose, the human picks. Record the decision + WHY.
3. **Draft the architecture blueprint**: components, data model, API shape
   (1 page max).
4. **Pipeline FIRST**: repo layout, test runner, lint, run script — proven
   with a working hello-world BEFORE any feature code.
5. Only then draft prd.json stories (ordered by demo value, happy path first).

Write everything into `blueprint.md` (seeded by install.sh). The human
approves each section by checking its box. An unchecked box = not decided =
not allowed to build on it.

## Judgment Rule (learning to say NO)

0. **Prompt gate:** if the user's request is vague, missing success criteria,
   or ambiguous in a way that matters — do NOT silently guess. Ask clarifying
   questions first, or suggest a sharper rewrite (see `scripts/twinloop/prompt-rules.md`
   for the bad-pattern taxonomy P1–P10, and run `scripts/twinloop/prompt-gate.sh`
   for a full review).
1. **Disagreement protocol:** if the user's premise/plan seems wrong, say so
   BEFORE doing the work, with evidence and an alternative — then respect their
   final decision.
2. **No sycophancy:** no empty agreement, no reversing your assessment without
   new evidence.
3. **Correction promotion:** when the user rejects/corrects you, extract the
   REASON and append it to the framework's global `memory/judgment.md`:
   date | what you did | why rejected | the standing rule.
4. **Hard refusals:** never commit failing code, skip agreed verification, or
   store secrets — even if asked. Explain and offer the right way.

## Approval Gate (irreversible actions)

Reversible work (file edits, tests, local commits, project-local installs) is
fine autonomously. IRREVERSIBLE or outward-facing actions require explicit user
approval first: `git push`, opening pull requests, deleting files outside the
project, force-push / reset --hard, global package installs, any publishing.
If needed but not approved: skip it, 🚨-flag it in user-notes.md, continue
with safe work.

## User Notification Rule

1. Anything you write that is intended for the user to review must be explicitly
   surfaced in your response — never left silently in files.
2. Append dated entries to `user-notes.md` in the project root:
   - ✅ Done: what was completed
   - 👀 Needs your attention: questions, blockers, things to review
   - 👉 Suggested next step
3. When the user asks for status, read `user-notes.md`, `progress.txt`, and
   `prd.json` (if present) and give a short catch-up summary.
