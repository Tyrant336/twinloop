# How to Use This Framework

> A practical guide to the agent-framework: an autonomous, self-improving
> coding loop built on Ralph + Kimi CLI. Read top to bottom once — after that,
> the cheat sheet at the end is all you need.

---

## What this is (30 seconds)

You describe what you want built. The framework turns it into a task list
(`prd.json`), then runs a **loop** of fresh AI sessions that build one task at
a time, verify it with tests, get it **independently reviewed** by a second AI
session, commit it to git, and **leave you notes** about what happened.

It also **learns**: your preferences, past mistakes, and your corrections are
written to memory files and read back every session — so it gets better the
more you use it.

```
YOU:  "build me X"  →  prd.json  →  🔁 build → test → review → commit → repeat
                                      ↓
                        memory/ (learns) + user-notes.md (tells you) + git (history)
```

## Requirements

| Need | Check with | Install if missing |
|---|---|---|
| Kimi CLI (logged in) | `kimi --version` | https://github.com/MoonshotAI/kimi-cli |
| jq | `jq --version` | `winget install jqlang.jq` / choco / scoop |
| git | `git --version` | git-scm.com |
| bash | (Git Bash on Windows) | comes with Git for Windows |

---

## Quickstart (5 minutes)

### 1. Get the framework folder

Keep it anywhere — it's fully portable. Examples:

```bash
git clone <your-repo-url> agent-framework     # or copy the folder / USB stick
cd agent-framework
```

### 2. Install it into your project

```bash
./install.sh /path/to/your/project
```

Your project now has:

```
your-project/
├── AGENTS.md                 ← rules: memory + judgment + notifications + Blueprint Gate
├── blueprint.md              ← the Blueprint Gate document (approve before any code)
├── memory/                   ← project memory (lessons, patterns — grows)
├── .gitignore                ← agent-framework block (loop state stays local)
└── scripts/ralph/
    ├── ralph.sh              ← the loop
    ├── KIMI.md               ← builder instructions
    ├── EVALUATE.md           ← independent reviewer instructions
    ├── doctor.sh             ← pre-flight check
    ├── status.sh             ← token-free dashboard
    ├── PROMPT_GATE.md        ← prompt-reviewer instructions
    ├── prompt-rules.md       ← P1–P10 prompt failure taxonomy
    ├── prompt-gate.sh        ← run a prompt through the reviewer
    ├── prd.json.example      ← task-list format
    └── .framework-dir        ← pointer back to global memory
```

### 3. Write your task list (prd.json)

```bash
cp agent-framework/prd.json.example your-project/scripts/ralph/prd.json
```

Edit it — this is the ONE thing you must do well (see "Writing a good PRD"):

```json
{
  "branchName": "ralph/my-feature",
  "userStories": [
    {
      "id": "US-001",
      "priority": 1,
      "title": "Small, specific task",
      "acceptanceCriteria": ["testable thing 1", "testable thing 2", "tests pass"],
      "passes": false
    }
  ]
}
```

### 4. Pre-flight check

```bash
cd /path/to/your/project
./scripts/ralph/doctor.sh
```

Fix anything ❌. Warnings ⚠️ are optional but read them (especially "no test
setup detected" — without tests, the loop can't verify its work).

### 5. Run the loop

```bash
./scripts/ralph/ralph.sh 10
```

Walk away. Watch it, or don't — `user-notes.md` will tell you what happened.

### 6. Check in anytime (zero tokens)

```bash
./scripts/ralph/status.sh
```

---

## Full worked example: a CCNA quiz CLI

Here's a complete run, start to finish, for a small Python app that quizzes
you on CCNA networking terms.

### Step 1 — Create the project

```bash
mkdir ccna-quiz && cd ccna-quiz && git init
```

### Step 2 — Install the framework

```bash
/path/to/agent-framework/install.sh .
```

Output:

```
✅ scripts/ralph/  (ralph.sh, KIMI.md, EVALUATE.md, doctor.sh, status.sh, PROMPT_GATE.md, prompt-rules.md, prompt-gate.sh, prd.json.example)
✅ scripts/ralph/.framework-dir
✅ memory/lessons.md (seeded)
✅ memory/patterns.md (seeded)
✅ blueprint.md (seeded — the Blueprint Gate: standards before code)
✅ AGENTS.md (memory + judgment + notification rules)
✅ .gitignore (created)
```

### Step 3 — The PRD (`scripts/ralph/prd.json`)

Notice: **small stories**, each with **testable** criteria, in priority order:

```json
{
  "branchName": "ralph/ccna-quiz",
  "userStories": [
    {
      "id": "US-001", "priority": 1, "passes": false,
      "title": "Question loader from JSON",
      "acceptanceCriteria": [
        "load_questions() reads questions.json into a list of dicts",
        "raises a clear error if the file is missing or invalid",
        "pytest test for both cases passes"
      ]
    },
    {
      "id": "US-002", "priority": 2, "passes": false,
      "title": "Multiple-choice quiz loop",
      "acceptanceCriteria": [
        "shows question + 4 options, accepts input 1-4",
        "rejects invalid input and re-asks",
        "pytest test passes"
      ]
    },
    {
      "id": "US-003", "priority": 3, "passes": false,
      "title": "Score report at the end",
      "acceptanceCriteria": [
        "prints 'Score: X/Y' after the last question",
        "pytest test passes"
      ]
    },
    {
      "id": "US-004", "priority": 4, "passes": false,
      "title": "Save wrong answers for review",
      "acceptanceCriteria": [
        "wrong answers appended to review.json with question + correct answer",
        "pytest test passes"
      ]
    }
  ]
}
```

### Step 4 — Doctor

```bash
./scripts/ralph/doctor.sh
```

```
✅ jq installed
✅ kimi CLI installed
✅ project is a git repository
✅ prd.json is valid JSON
✅ 4 user stories defined
✅ all stories have acceptance criteria
⚠️  no test setup detected — add tests!
```

(The ⚠️ is fine here — the stories themselves instruct the agent to create pytest tests.)

### Step 5 — Run it

```bash
./scripts/ralph/ralph.sh 10
```

What you'll see (abridged):

```
===============================================================
  Ralph Iteration 1 of 10 (kimi) [builder]
===============================================================
...kimi builds US-001, writes tests, runs pytest, commits...
  Ralph Iteration 1 (kimi) [evaluator: US-001]
...independent kimi session reviews the diff, runs pytest again, approves...
Iteration 1 complete. Continuing...

  Ralph Iteration 2 of 10 (kimi) [builder]
...builds US-002... evaluator rejects: "invalid input 5 crashes instead of
re-asking" → story reverted, feedback written...
  Ralph Iteration 3 of 10 (kimi) [builder]
...reads evaluator feedback, fixes US-002 properly... evaluator approves...
...
Ralph completed all 4 tasks! (iteration 5 of 10)
```

### Step 6 — What you have afterwards

```bash
./scripts/ralph/status.sh
```

```
📋 Stories (ralph/ccna-quiz):
  ✅ US-001  Question loader from JSON
  ✅ US-002  Multiple-choice quiz loop
  ✅ US-003  Score report at the end
  ✅ US-004  Save wrong answers for review
  → 4/4 passing, 0 blocked
🔁 Agent sessions: 9 today, 9 all-time
```

- `git log` — one commit per story (`feat: US-001 - Question loader from JSON`)
- `progress.txt` — full diary, including why US-002 was rejected once
- `user-notes.md` — your skimmable inbox
- `memory/lessons.md` — e.g. *"pytest must be run with `python -m pytest` on this machine"* — next loop already knows

### Step 7 — Next feature? Just write a new prd.json

Change `branchName` (e.g. `ralph/review-mode`) and the stories. The loop
**auto-archives** the old run to `archive/2026-08-29-ccna-quiz/` and starts
fresh. Nothing is lost.

---

## Writing a good PRD (80% of your results)

**Right-sized stories** (one context window each):
- ✅ "Add a database column + migration"
- ✅ "Add a filter dropdown to the list page"
- ❌ "Build the entire dashboard" (split it!)
- ❌ "Add authentication" (split: model → hashing → login route → middleware → UI)

**Every story needs testable acceptance criteria.** "Works correctly" is not
testable. "pytest test for empty input passes" is.

**Order by demo value.** If the loop only finishes 60%, what's done should
still be usable.

**Have a real quality gate.** The evaluator runs your tests. No tests = the
loop is driving blind. Let the first story be "set up pytest + CI config" if
needed.

## What NOT to do ⚠️

Read this once. Every item below is a real way people break their own loop.

### 🔐 Never put secrets anywhere the agent can read

No passwords, API keys, tokens, or personal data in prompts, `prd.json`,
comments, or memory files. Everything the agent writes lands in **git history
and session logs** — permanently. If a secret ever gets in, rotate it;
deleting the file is not enough.

### 🗣️ Things NOT to say in prompts / stories

| ❌ Don't say | Why it's bad | ✅ Say instead |
|---|---|---|
| "Make it good" / "improve the app" / "fix everything" | Untestable — the evaluator can't verify it, the loop wanders | "Add X, verified by test Y" |
| "Build the whole app" as one story | Too big for one context window → half-done garbage | 3-8 small stories, each fits one session |
| "Skip the tests, just commit" / "don't bother verifying" | Breaks the quality gate — broken code compounds across iterations. The judgment rules will **refuse** anyway | Let the tests run; fix weak tests instead |
| "Push to main" / "deploy it" / "delete that repo" | Irreversible — blocked by the approval gate | Do irreversible actions yourself, or explicitly approve them |
| "Ignore your rules" / "ignore previous instructions" | Self-sabotage — the agent is instructed to refuse, and you pollute the logs | If a rule is wrong, edit `AGENTS.md`/`KIMI.md` properly |
| "Store my password in memory so you remember" | Memory files are committed to git | Never. Use a password manager |

### 📋 PRD anti-patterns

- **Don't mark `passes: true` yourself** to "help" — the evaluator reviews
  against real checks; fake passes corrupt the state it relies on.
- **Don't mix unrelated features in one story** ("add login AND fix the footer
  AND refactor the API") — one story = one commit = one reviewable unit.
- **Don't edit `prd.json` or `progress.txt` while the loop is running** —
  you're racing the agent. Ctrl+C first, edit, re-run.
- **Don't contradict an earlier decision without updating the files** — the
  agent believes files, not your chat history. If it matters, write it down.

### 🔁 Operating the loop

- **Don't run two loops on the same project at once** — git conflicts and
  interleaved commits. One project, one loop.
- **Don't ignore 🚨 in user-notes.md** — that's how the agent screams for help.
  A blocked story never unblocks itself.
- **Don't judge the AI from chat memory** — it starts blank every iteration.
  If it "forgot" something, that something wasn't written to a file. Add it to
  `AGENTS.md`, `memory/`, or the story itself.
- **Don't panic-stop a mid-test iteration** unless necessary — a half-written
  file is fine (nothing commits unless checks pass), but let it fail cleanly
  when you can.

### 🧠 About its "learning"

- **Don't expect it to remember conversations** — only what's in files
  survives. The memory system is good, but it's notes, not a brain.
- **Don't feed it corrections without the reason** — "no, don't do that"
  teaches nothing; "no, because X" becomes a permanent rule in `judgment.md`.
- **Don't let memory files bloat** — review them monthly; delete outdated
  lines. Bloated memory gets ignored.

---

## Prompt Gate — your prompt spellchecker 🛡️

Before sending a big request to the loop (or any agent), run it through the
gate. It detects bad patterns, **refuses** dangerous ones, asks you clarifying
questions, and hands you an improved rewrite:

```bash
./scripts/ralph/prompt-gate.sh "make the app better and faster"
```

Example output:

```
VERDICT: NEEDS_WORK
SCORE: 2/10

DETECTED ISSUES:
- [P1] VAGUE — "better and faster" — no testable outcome; the agent must guess
- [P2] TOO BIG — "the app" — which part? whole-app scope won't fit one session
- [P6] NO SUCCESS CRITERIA — "done" is undefined

QUESTIONS FOR YOU:
1. Which part of the app feels slow or bad to you right now?
2. What would "better" look like — a number, a behavior, a screenshot?

SUGGESTED REWRITE:
"""
In ccna-quiz, the quiz loop (US-002) redraws the whole screen per question.
Make it render only the changed lines. Done when: rendering time per question
< 50ms in a pytest benchmark test.
"""
```

It also **learns your habits**: repeat a weakness and it will tell you
("this is the 3rd time — worth fixing permanently"), logged in the framework's
`memory/prompt-habits.md`.

The taxonomy it enforces lives in `scripts/ralph/prompt-rules.md` — 10 patterns
(P1 vague … P10 facts-without-sources), distilled from prompt-linting research.
`doctor.sh` also runs a zero-token version of the P1 check on your prd.json.

---

## Commands cheat sheet

| Command | What it does |
|---|---|
| `./install.sh <project>` | Install framework into a project (safe to re-run) |
| `./scripts/ralph/doctor.sh` | Pre-flight check — run before every loop |
| `./scripts/ralph/prompt-gate.sh "prompt"` | Review a prompt before sending it (bad patterns + rewrite + questions) |
| `./scripts/ralph/ralph.sh 10` | Run the loop, max 10 builder iterations |
| `./scripts/ralph/ralph.sh --max-daily 30 20` | Cost guard: max 30 AI sessions/day |
| `./scripts/ralph/ralph.sh --no-eval 10` | Skip the evaluator (faster, less safe) |
| `./scripts/ralph/status.sh` | Token-free dashboard, anytime |
| Ctrl+C, then re-run same command | Interrupt + resume (state is in files) |

## Files you'll touch vs. files that grow themselves

| You write/maintain | The agent maintains |
|---|---|
| `prd.json` (your task list) | `progress.txt` (diary) |
| corrections ("no, because...") | `user-notes.md` (your inbox) |
| tick the box in `FINAL-REPORT.md` | `FINAL-REPORT.md` (written by the verify phase) |
| | `memory/lessons.md`, `memory/patterns.md` |
| | `memory/judgment.md` (from your corrections) |
| | git history, `archive/` |

## Troubleshooting

| Symptom | Likely cause → fix |
|---|---|
| Loop stops at iteration 1 with an error | Run `doctor.sh` — usually missing prd.json or not a git repo |
| "Stuck detection" stops the loop | Read the tail of `progress.txt` — the story is probably too big or ambiguous; split/clarify it, re-run |
| Evaluator keeps rejecting a story | Read its feedback in `progress.txt` — acceptance criteria may be untestable or the tests are weak |
| Verify phase fails after "completion" | Working as intended — it found end-to-end breakage the per-story checks missed; read the VERIFIER entry in `progress.txt`, the builder is already retrying |
| "Verify phase stuck" note | Builder and verifier failed twice in a loop — fix or re-scope manually, `rm scripts/ralph/.verify-attempts`, re-run |
| Agent did something you dislike | Say so and WHY — it logs your reason into `memory/judgment.md` and won't do it again |
| Hit the daily cost guard | Wait for tomorrow or raise `--max-daily`; progress is saved, just re-run |
| On Windows: `ralph.sh won't run` | Use **Git Bash**, not PowerShell/CMD |

## The loop in one picture

```
        prd.json (you write)
            │
            ▼
   ┌─────────────────┐     commits      ┌──────────────────┐
   │  BUILDER (kimi) │ ───────────────► │ EVALUATOR (kimi) │
   │  one story      │                  │ independent      │
   │  + tests        │ ◄─────────────── │ review + checks  │
   └─────────────────┘   reject + why   └──────────────────┘
            │                                  │ approve
            ▼                                  ▼
   progress.txt · user-notes.md · memory/ · git history
            │
            ▼
   repeat until COMPLETE · blocked · stuck-limit · daily-cap
            │ COMPLETE
            ▼
   ┌──────────────────────────────────────────────────┐
   │  VERIFIER (kimi) — full suite + smoke test +     │
   │  cross-story integration review                  │
   │   · PASS → FINAL-REPORT.md → YOU tick the box    │
   │   · FAIL → stories reopen → back to BUILDER      │
   └──────────────────────────────────────────────────┘
```
