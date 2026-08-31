# QUICKSTART from Zero — your first loop in ~20 minutes

> You have an AI CLI tool (Kimi CLI) installed and logged in. You have **never
> used this framework** and know nothing about "loop engineering". This guide
> assumes nothing else. Follow it top to bottom, literally, and you'll finish
> with a small working program built by the AI — and you'll understand what
> happened.

---

## What is this thing? (plain language, 1 minute)

Normally you chat with an AI: you ask, it answers, you copy-paste code, you
test it yourself, you go back and forth. **You** are the loop.

This framework makes the **AI its own loop**:

1. You describe what you want (once).
2. The AI turns it into a task list.
3. Then it works **alone**: builds one task, tests it, gets it reviewed by a
   *second* AI that didn't write the code, commits to git, moves to the next.
4. When everything is done, a **third** AI runs the whole program end-to-end
   and writes you a report.
5. You read the report, try the program, and accept or reject the work.

Your job shrinks to three moments: **describe it well at the start, check in
occasionally, accept the work at the end.**

## The 8 words you'll see everywhere (glossary)

| Word | What it actually is |
|---|---|
| **loop** | The AI working alone: build → test → review → repeat |
| **story** | One small task, e.g. "load questions from a JSON file" |
| **prd.json** | The task list file. The loop reads it to know what to do |
| **acceptance criteria** | How we *test* that a story is done. THE most important part |
| **builder** | The AI session that writes code |
| **evaluator** | A second AI session that reviews the builder's work (like a teacher grading) |
| **verifier** | A third AI session that runs the *whole* program at the end |
| **blueprint.md** | The plan you approve BEFORE any code is written |

That's all the jargon you need.

---

## Step 0 — Check your tools (2 minutes)

Open **Git Bash** (on Windows: Start menu → "Git Bash"). NOT PowerShell, NOT CMD.

```bash
git --version     # need: some version number
jq --version      # need: jq-1.x
kimi --version    # need: some version number
```

If `jq` is missing on Windows: `winget install jqlang.jq`, then **close and
reopen Git Bash**. On macOS: `brew install jq`.

> ⚠️ Everything in this guide runs in Git Bash. If a command works weirdly,
> check you're not in PowerShell — this is the #1 beginner mistake.

## Step 1 — Create a toy project and install the framework (2 minutes)

We'll build a **quiz CLI**: a program that asks you questions in the terminal
and tells you if you're right. Small, but real.

```bash
cd /path/to/agent-framework      # go to the framework folder

mkdir ~/quiz-cli                 # make an empty project folder
cd ~/quiz-cli
git init                         # the loop needs git (it commits per task)

/path/to/agent-framework/install.sh .
```

Expected output (the ✅ lines):

```
✅ scripts/ralph/  (ralph.sh + KIMI.md + EVALUATE.md + VERIFY.md + ...)
✅ scripts/ralph/.framework-dir
✅ memory/lessons.md (seeded)
✅ blueprint.md (seeded — the Blueprint Gate: standards before code)
✅ AGENTS.md (memory + judgment + notification rules)
✅ .gitignore (created)
```

Your project now contains rules (`AGENTS.md`) that any AI session will read
automatically. You don't need to understand them yet.

## Step 2 — Describe what you want (5 minutes, WITH the AI)

Still in Git Bash, inside `quiz-cli`:

```bash
kimi
```

Now just say, in your own words:

```
I want to build a command-line quiz app. It loads questions from a JSON file,
asks them one by one, checks my answers, and shows a score at the end.
```

**The AI will now interview you** instead of coding. This is the Blueprint
Gate — it's on purpose. It will ask things like: who is this for? what should
the demo look like? what will you NOT build?

Then it will **propose 2–3 tech stacks** (e.g. "Python + pytest" vs "Node.js +
vitest") with honest pros and cons. **You pick one.** If you have no
preference, say: *"I'm a beginner, pick whichever is simplest for me to run."*

Finally it fills in `blueprint.md` and writes the task list
(`scripts/ralph/prd.json`). When it's done, exit kimi (Ctrl+C or `/exit`).

**Now do the one human approval step:** open `blueprint.md` in any editor and
change every `- [ ]` to `- [x]` after reading each section. You're saying
"yes, build this". The loop refuses to work until you do this — that's the
point: nothing gets coded without your approval.

## Step 3 — Look at the task list (2 minutes, just look)

```bash
cat scripts/ralph/prd.json
```

You'll see a few stories. Notice each has `acceptanceCriteria`. Compare:

❌ Bad (untestable — the AI will guess): `"the quiz works well"`
✅ Good (testable — no guessing): `"running 'python quiz.py' asks the first question and waits for input"`

If any criterion reads like the ❌ example, edit it now — **vague tasks are the
#1 reason first runs fail.** Ask the AI to rewrite them if unsure.

## Step 4 — Pre-flight check (30 seconds)

```bash
./scripts/ralph/doctor.sh
```

Expected: mostly ✅, ending with something like:

```
Result: 12 ok, 1 warnings, 0 failures
⚠️  Runnable, but review the warnings      ← or "✅ All good" if zero warnings
```

Warnings (⚠️) are OK to start with. If anything is ❌, the message tells you
exactly how to fix it. Don't start the loop until there are zero ❌.

## Step 5 — Run the loop (the AI works alone now)

```bash
./scripts/ralph/ralph.sh 5
```

You'll see iterations like:

```
===============================================================
  Ralph Iteration 1 of 5 (kimi) [builder]
===============================================================
...the AI reads the task list, builds one story, runs tests, commits...
```

Then possibly:

```
  Ralph Iteration 1 (kimi) [evaluator: US-001]
...a second AI reviews the diff and re-runs the tests...
```

**You can walk away.** Get coffee. It stops by itself when done, when stuck,
or when it hits the iteration limit. It's safe to Ctrl+C anytime — re-running
the same command resumes where it left off (progress lives in files, not in
the AI's head).

While it runs (in a second Git Bash window), you can peek — for free, no AI
session needed:

```bash
./scripts/ralph/status.sh        # story board: ✅ done / 🚫 blocked / ⬜ todo
cat scripts/ralph/user-notes.md  # plain-English notes the AI left for you
```

## Step 6 — The end: verify + YOUR acceptance

When all stories pass, one more AI session runs automatically — the
**verifier**. It runs the *entire* test suite and actually launches your
program, because "every task passed" is not the same as "the program works".

- **If it passes** → you'll see `Verify PASSED` and a new file
  `FINAL-REPORT.md` appears in your project.
- **If it finds breakage** → it reopens the broken tasks and the loop keeps
  building. You don't do anything; this is normal and it's the system working.

Now the last human step — the exit gate, mirroring the blueprint at the start:

```bash
cat FINAL-REPORT.md      # read: what was built, what was tested, known issues
python quiz.py           # (or whatever the run command is) — TRY IT YOURSELF
```

If it works: open `FINAL-REPORT.md` and change `- [ ]` to `- [x]` under
"Human acceptance". Done. 🎉

If you want the code on GitHub: **you** push it. The loop is never allowed to
push, open PRs, or publish anything — by design.

```bash
git push    # only if you have a remote set up; your call, not the loop's
```

## Step 7 — Clean up or keep going

- Toy project served its purpose → delete the folder, keep the framework.
- Want your own idea built? New empty folder, `git init`, `install.sh .`,
  and go back to Step 2 — this time describe YOUR idea.

---

## When something goes wrong

| You see | What it means → what to do |
|---|---|
| `Blueprint Gate is not satisfied` | You skipped the checkboxes → open `blueprint.md`, tick all `- [x]` |
| `jq: command not found` | Step 0 → install jq, reopen Git Bash |
| `Stuck detection... stopping early` | A task failed 3× → `tail -30 scripts/ralph/progress.txt` tells you why; usually the story was too big or vague → edit prd.json, re-run |
| Evaluator rejected a story | Normal — read the feedback in `progress.txt`; the builder retries automatically |
| Verify FAILED after "completion" | Also normal — it found a real end-to-end bug; the loop is fixing it |
| `daily limit reached` | Cost guard → wait or re-run with `--max-daily 30` |
| Weird errors, colors broken | You're in PowerShell → use Git Bash |
| `Verify phase has failed 2 times` | AI is going in circles → you fix the issue, then `rm scripts/ralph/.verify-attempts` and re-run |

Golden rule: **read `scripts/ralph/progress.txt` first.** It's the AI's diary
and almost always says exactly what's wrong.

## Cheat sheet (print this)

```bash
./install.sh <project>          # one-time setup per project
kimi                            # describe idea → Blueprint Gate interview
# → tick all boxes in blueprint.md
./scripts/ralph/doctor.sh       # pre-flight (zero ❌ before continuing)
./scripts/ralph/ralph.sh 10     # start the loop, walk away
./scripts/ralph/status.sh       # peek anytime (free)
cat FINAL-REPORT.md             # when done: read, try the program, tick the box
```

Loop guarantees to remember: it **stops by itself** (done / stuck / cost cap),
it **never pushes or publishes** without you, and **re-running the same
command always resumes** — nothing is lost.
