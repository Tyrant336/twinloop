# Twinloop — Agent Framework (Kimi fork)

![Twinloop](assets/twinloop.webp)

> **This is a fork of [snarktank/ralph](https://github.com/snarktank/ralph).**
> **This fork** runs with [Kimi CLI](https://github.com/MoonshotAI/kimi-cli) as the coding agent (default `--tool kimi`), and extends the original Ralph loop into a **portable agent framework**: loop + memory + judgment + user notifications, installable into any project with one command.
>
> **📖 Start here:** never used this (or any) agent framework before? → **[QUICKSTART-zero.md](docs/QUICKSTART-zero.md)** — assumes nothing, first loop in ~20 min. Otherwise: [USAGE.md](docs/USAGE.md) — full guide with a worked example.

Twinloop is an autonomous AI agent loop that runs AI coding tools (Kimi CLI by default; [Amp](https://ampcode.com), [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Cursor CLI](https://cursor.com/docs/cli/headless) also supported via `--tool`) repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

## The Pipeline (what it is, end to end)

This framework is a **pipeline**, not a single command. It enforces software-engineering standards in order — **nothing gets coded until the foundations are decided WITH you and approved BY you**:

```
 HUMAN + AI (together)         AI LOOP (autonomous)              HUMAN
─────────────────────────  ─────────────────────────────  ─────────────────
 1️⃣  BLUEPRINT GATE          4️⃣  BUILDER: one story +      8️⃣  Check in:
    requirements interview      tests, commits             FINAL-REPORT.md,
  →  stack decision (AI        5️⃣  EVALUATOR: independent    tick the human-
    proposes 2–3 options,       review + runs your checks    acceptance box
    YOU pick)                  6️⃣  repeat until COMPLETE /
  →  architecture blueprint       blocked / stuck-limit /
  →  pipeline (tests, lint)     daily-cap
  →  stories (prd.json)      7️⃣  VERIFY: full suite +
 2️⃣  doctor.sh (pre-flight)      smoke test + integration
 3️⃣  twinloop.sh (start loop)       review → FINAL-REPORT.md
                                 (fail → stories reopen,
                                  loop resumes)
```

**Phase 1 — Blueprint Gate (human + AI, before any code).** After `install.sh`, every project has a `blueprint.md` and AGENTS.md rules that **forbid** coding before it is approved:

1. **AI interviews you** — what the software does, who it's for, the one-sentence pitch, the demo happy path, the cut line (what you will NOT build), constraints.
2. **AI proposes 2–3 tech stack options** with honest tradeoffs — **you pick**. The stack is never pre-decided by the framework.
3. **Architecture blueprint** — components, data model, API shape (1 page max).
4. **Pipeline first** — repo layout, test runner, lint, run script, proven by a working hello-world.
5. **Stories** — turned into `prd.json`, ordered by demo value, happy path first.

You approve each section by checking its box in `blueprint.md`. Enforcement is mechanical: `doctor.sh` fails if the blueprint is missing and warns on unapproved sections, and the builder prompt itself (`KIMI.md` step 0) refuses to build without an approved blueprint — the loop stops immediately with `<promise>BLUEPRINT_GATE</promise>`.

**Phase 2 — the loop (AI, autonomous).** Each builder iteration runs `kimi --quiet < KIMI.md` — a fresh, non-interactive Kimi instance that auto-approves its own tool calls. After each builder pass, an independent **evaluator** pass (`EVALUATE.md`) reviews the new work against the story's acceptance criteria — the builder never grades its own homework. The loop exits when everything passes (`<promise>COMPLETE</promise>`), when only blocked stories remain, when the blueprint gate is unmet, or early via stuck detection / cost guard.

**Phase 3 — VERIFY (AI verifier, then human acceptance).** When the loop declares completion, it doesn't just stop: a fresh **verifier** session (`VERIFY.md`) re-runs the *full* test suite, smoke-tests the happy path, and reviews cross-story integration (stories were only ever evaluated in isolation). On PASS it writes `FINAL-REPORT.md` at the project root with a **human-acceptance checkbox** — the exit gate mirroring the Blueprint Gate at the entrance. On FAIL it reopens the responsible stories in `prd.json` and the build loop resumes automatically (capped at 2 verify attempts, then it flags you). Skip it with `--no-verify`.

### Example: one full run through the pipeline

Say you want a **CCNA quiz CLI**. It looks like this:

```bash
# 1. Create + install
mkdir ccna-quiz && cd ccna-quiz && git init
/path/to/agent-framework/install.sh .

# 2. Open the project in your AI tool and just say:
#    "I want to build a CLI that quizzes me on CCNA terms"
#    → the Blueprint Gate in AGENTS.md takes over: the agent interviews you,
#      proposes stack options (e.g. "Python + pytest" vs "Node + vitest"),
#      YOU pick, it drafts architecture + pipeline, fills blueprint.md.
#      You review each section and tick its checkbox.

# 3. Pre-flight, then let it run
./scripts/twinloop/doctor.sh        # ✅ blueprint fully approved, prd.json valid, ...
./scripts/twinloop/twinloop.sh 10      # the loop builds story by story

# 4. Check in anytime (zero tokens)
./scripts/twinloop/status.sh
```

What you get afterwards: one git commit per story (`feat: US-001 - Question loader from JSON`), a full diary in `progress.txt` (including any evaluator rejections and why), a skimmable inbox in `user-notes.md`, an end-to-end verified `FINAL-REPORT.md` waiting for your acceptance checkbox, and lessons already written to `memory/` so the next run is smarter. The full version of this example — including the prd.json, doctor output, and an evaluator rejection/retry — is in **[USAGE.md](docs/USAGE.md#full-worked-example-a-ccna-quiz-cli)**.

## Usage with Kimi CLI

Prerequisites: `kimi` CLI installed and authenticated, `jq` installed (`winget install jqlang.jq` on Windows, `brew install jq` on macOS), and your project is a git repository.

### One-command install into any project

```bash
./install.sh /path/to/your/project
```

This installs into the target project:
- `blueprint.md` — the Blueprint Gate document (requirements → stack → architecture → pipeline, human-approved before any code)
- `scripts/twinloop/` — `twinloop.sh`, `KIMI.md`, `EVALUATE.md`, `VERIFY.md`, `doctor.sh`, `status.sh`, `PROMPT_GATE.md`, `prompt-rules.md`, `prompt-gate.sh`, and `.framework-dir` (portable link back to this framework's global memory)
- `memory/` — empty project memory (lessons + patterns, grows as the agent works)
- `AGENTS.md` — memory + judgment + notification + Blueprint Gate rules for any agent working in that project

Then open the project in your AI tool and describe your idea — the Blueprint Gate runs the requirements/stack/architecture/pipeline phase **with you**, fills `blueprint.md`, and only then produces `scripts/twinloop/prd.json`. After that:

```bash
cd /path/to/your/project
./scripts/twinloop/doctor.sh                        # pre-flight: tools, git, prd quality, test setup
./scripts/twinloop/twinloop.sh [max_iterations]        # defaults: --tool kimi, 10 iterations
./scripts/twinloop/twinloop.sh --tool cursor 10        # use Cursor CLI (cursor-agent) instead
./scripts/twinloop/twinloop.sh --max-daily 30 20       # optional cost guard: max 30 agent sessions/day
./scripts/twinloop/twinloop.sh --no-verify 10          # optional: skip the end-to-end verify phase
./scripts/twinloop/status.sh                        # token-free dashboard (no AI session needed)
```

### Loop features (this fork)

| Feature | What it does |
|---|---|
| 🏛️ **Blueprint Gate** | Engineering standards BEFORE code: requirements interview → stack decision (AI proposes, you pick) → architecture → pipeline → stories, each human-approved in `blueprint.md`; the loop refuses to build without it |
| 🔍 **Evaluator pass** | Independent second AI session reviews each story's diff + runs the checks before the pass is accepted; rejections revert the story and feed detailed feedback to the next builder iteration |
| ✅ **Verify phase** | After completion, a fresh verifier session (`VERIFY.md`) re-runs the FULL suite, smoke-tests the happy path, and checks cross-story integration. PASS → `FINAL-REPORT.md` with a human-acceptance checkbox (the exit gate); FAIL → stories reopen and the loop resumes (max 2 attempts, `--no-verify` to skip) |
| 🚨 **Stuck detection** | A story failing 2 attempts is marked `blocked` and skipped; 3 consecutive iterations with zero progress stops the loop early and flags you in user-notes.md |
| 💰 **Cost guard** | `--max-daily N` caps agent sessions per day; re-checked before **every** builder and evaluator session, so the loop stops before exceeding the cap and leaves you a note |
| 🩺 **doctor.sh** | Pre-flight check: jq/kimi/git, prd.json validity, acceptance-criteria coverage, test-setup detection |
| 📊 **status.sh** | Token-free dashboard: story board, sessions used, items needing you, latest progress |
| 🔒 **Approval gate** | Loop never pushes, opens PRs, or does irreversible/outward actions without your explicit approval — it 🚨-flags and continues safe work |
| 🚦 **Prompt Gate** | `prompt-gate.sh` reviews a task prompt against `prompt-rules.md` (P1–P10 failure taxonomy) before you burn a loop on a vague prompt |

### Fork structure (fully portable — move this folder anywhere)

```
agent-framework/
├── install.sh                  # one-command installer into any project
├── bin/                        # executable scripts
│   ├── twinloop.sh                #   the loop: builder + evaluator + verify phase, stuck detection, cost guard
│   ├── doctor.sh               #   pre-flight checks
│   ├── status.sh               #   token-free status dashboard
│   └── prompt-gate.sh          #   prompt reviewer (uses loop/PROMPT_GATE.md + loop/prompt-rules.md)
├── loop/                       # the loop's rule documents (copied into projects by install.sh)
│   ├── KIMI.md                 #   builder prompt: blueprint gate + task + memory + judgment + notifications
│   ├── EVALUATE.md             #   evaluator prompt: independent review of each "done" story
│   ├── VERIFY.md               #   verifier prompt: end-to-end final verification + FINAL-REPORT.md
│   ├── PROMPT_GATE.md          #   prompt-reviewer agent prompt
│   └── prompt-rules.md         #   P1–P10 prompt failure taxonomy
├── docs/                       # guides
│   ├── USAGE.md                #   full guide with worked example
│   ├── QUICKSTART-zero.md      #   zero-to-running quickstart
│   └── HACKATHON.md            #   🏆 playbook: using the pipeline to win a hackathon
├── assets/                     # images (twinloop-flowchart.png, twinloop.webp)
├── examples/
│   └── prd.json.example        # task-list format
├── memory/                     # 🌍 GLOBAL memory — travels with this folder
│   ├── profile.md              #    who the user is, preferences, style
│   ├── lessons.md              #    cross-project mistakes + rules
│   ├── patterns.md             #    proven ways of working
│   ├── judgment.md             #    when to say NO (distilled from user corrections)
│   └── prompt-habits.md        #    recurring prompt mistakes the gate has caught
├── templates/
│   ├── BLUEPRINT.md            # the Blueprint Gate document (seeded as blueprint.md)
│   ├── AGENTS.project.md       # rules installed into target projects (incl. Blueprint Gate)
│   └── project-memory/         # empty per-project memory seeds
├── skills/                     # prd + twinloop skills (Amp/Claude ecosystem, from upstream)
├── archive/                    # archived per-tool prompts (Amp/Claude) + run archives
└── flowchart/                  # interactive React Flow diagram of the loop
```

**Portability:** nothing in the framework hardcodes paths to a specific machine folder. Projects find the framework's global memory through `scripts/twinloop/.framework-dir`, written by `install.sh`. Move/clone this folder anywhere, re-run `install.sh` in your projects, done.

**User notifications:** every iteration appends a dated, skimmable entry to `user-notes.md` (next to prd.json): what was done, what needs your attention, and the suggested next step. Check this file first when you come back after being away — or just ask your agent "catch me up on this project" and it can read `prd.json` + `progress.txt` + `user-notes.md` to summarize.

## Using other AI tools (Amp / Claude Code)

The loop accepts `--tool amp` and `--tool claude` and will invoke those CLIs — but note that **all tools receive `KIMI.md` as the builder prompt** (it is tool-agnostic markdown). The original Amp- and Claude-specific prompts from upstream are kept in [`archive/`](archive/README.md) for reference, but are not wired into the loop.

The `skills/` directory (`prd`, `twinloop`) works with the Amp/Claude skill system. To install manually:

```bash
# Amp
cp -r skills/prd skills/twinloop ~/.config/amp/skills/

# Claude Code
cp -r skills/prd skills/twinloop ~/.claude/skills/
```

(The upstream project also publishes a Claude Code marketplace listing — that belongs to the [original repo](https://github.com/snarktank/ralph), not this fork.)

## Workflow

### 1. Create a PRD

```
Load the prd skill and create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Twinloop format

```
Load the twinloop skill and convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Twinloop

```bash
# Using Kimi (default)
./scripts/twinloop/twinloop.sh [max_iterations]

# Using Amp or Claude Code
./scripts/twinloop/twinloop.sh --tool amp [max_iterations]
./scripts/twinloop/twinloop.sh --tool claude [max_iterations]
```

Default is 10 iterations. Twinloop will:
1. Verify the Blueprint Gate (stops immediately if blueprint approvals are missing)
2. Create a feature branch (from PRD `branchName`)
3. Pick the highest priority story where `passes: false`
4. Implement that single story
5. Run quality checks (typecheck, tests)
6. Commit if checks pass
7. Update `prd.json` to mark story as `passes: true`
8. Append learnings to `progress.txt` and a note to `user-notes.md`
9. Repeat until all stories pass, blocked, stuck, or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `bin/twinloop.sh` | The bash loop that spawns fresh AI instances (`--tool kimi` default, `amp`/`claude`/`cursor` supported) |
| `loop/KIMI.md` | The canonical builder prompt (used for ALL tools) — includes Blueprint Gate step 0 |
| `loop/EVALUATE.md` | Evaluator prompt for the independent review pass |
| `loop/VERIFY.md` | Verifier prompt for the end-to-end final check; writes `FINAL-REPORT.md` |
| `templates/FINAL-REPORT.md` | Final report format: what was built, verification performed, known issues, human-acceptance checkbox |
| `prd.json` | User stories with `passes` status (the task list) |
| `examples/prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `user-notes.md` | Dated, skimmable inbox of what the loop did and what needs you |
| `blueprint.md` | Blueprint Gate approvals (installed into projects) |
| `skills/prd/` | Skill for generating PRDs (Amp/Claude ecosystems) |
| `skills/twinloop/` | Skill for converting PRDs to JSON (Amp/Claude ecosystems) |
| `archive/` | Archived upstream per-tool prompts + per-run archives |
| `flowchart/` | Interactive visualization of how Twinloop works |

## Flowchart

![Twinloop Flowchart](assets/twinloop-flowchart.png)

The `flowchart/` directory contains an interactive React Flow visualization (source in this repo). To run locally:

```bash
cd flowchart
npm install
npm run dev
```

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new AI instance** with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)
- `memory/` (project + global lessons, patterns, judgment rules)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Twinloop updates the relevant `AGENTS.md` files with learnings. This is key because AI coding tools automatically read these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

### Feedback Loops

Twinloop only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Stop Conditions

- All stories pass → builder outputs `<promise>COMPLETE</promise>` → **verify phase** runs → `VERIFIED` → loop exits 0 (human acceptance still pending in FINAL-REPORT.md)
- Verify finds end-to-end breakage → `<promise>VERIFY_FAILED</promise>` → stories reopen, build loop resumes (max 2 attempts, then a human is flagged)
- Only blocked stories remain → `<promise>COMPLETE_WITH_BLOCKERS</promise>` → verify phase → loop exits 0
- Blueprint not approved → `<promise>BLUEPRINT_GATE</promise>` → loop exits 1
- No progress for N consecutive iterations (default 3) → stuck detection stops the loop
- Daily session cap hit → cost guard stops the loop before the next session starts

## Debugging

Check current state:

```bash
# Token-free dashboard (preferred)
./scripts/twinloop/status.sh

# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes, blocked}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Customizing the Prompt

`KIMI.md` (installed into projects at `scripts/twinloop/KIMI.md`) is the canonical builder prompt. Customize it for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

If you run a project with `--tool amp`, `--tool claude` or `--tool cursor`, that project's copy of `KIMI.md` is still what the agent receives.

**Cursor notes:** `--tool cursor` runs `cursor-agent -p --force --approve-mcps` (headless print mode). Headless sessions count against your Cursor plan's request quota — pair with `--max-daily` on limited plans. If a run hangs at iteration 1, check `cursor-agent` auth and known headless-mode issues first.

## Archiving

Twinloop automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/` inside the project's `scripts/twinloop/` directory.

## Credits & References

- Forked from [snarktank/ralph](https://github.com/snarktank/ralph) (MIT, © snarktank)
- Based on [Geoffrey Huntley's Twinloop pattern](https://ghuntley.com/twinloop/)
- [Upstream author's in-depth article on how he uses Ralph](https://x.com/ryancarson/status/2008548371712135632)
- [Amp documentation](https://ampcode.com/manual)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Kimi CLI](https://github.com/MoonshotAI/kimi-cli)
