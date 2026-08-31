# Hackathon Playbook 🏆

> How to use this agent-framework to win a hackathon.
> Read this BEFORE the event. During the event, you should only execute.

---

## 1. What to bring (the full framework checklist)

- [ ] This `agent-framework/` folder (USB + cloud + laptop — 3 copies)
- [ ] Kimi CLI installed, logged in, quota checked → run `kimi --version` TODAY, not at the venue
- [ ] `jq`, `git`, Git Bash working
- [ ] Stack + architecture **decided together with the AI** (see §2 — do this BEFORE the event),
  then its toolchain pre-installed — **venue Wi-Fi is always bad; install everything early**
- [ ] A "hello world" of your stack already built once (proves the toolchain works offline)
- [ ] This framework installed into a throwaway repo and test-run once:
  `./install.sh /tmp/test && cd /tmp/test && ./scripts/ralph/doctor.sh`

## 2. Decide the tech stack TOGETHER (human + AI)

> The stack is NOT pre-decided in this playbook. It is chosen per project,
> like a developer scoping a build with a client — requirements first,
> options with tradeoffs, then the human decides.

### The decision conversation (run BEFORE the event / at hour 0)

1. **AI interviews the human** — requirements before technology:
   - What does the software DO? Who is it for? The ONE-sentence pitch?
   - What must the 3-minute demo show? (the happy path)
   - Constraints: time limit, offline/venue Wi-Fi, team skills, what you already know.
2. **AI proposes 2–3 stack options**, each with honest tradeoffs: speed to build,
   demo polish, how well you know it, how well AI generates it. No single
   "just use this" answer — the tradeoffs must be explicit.
3. **Human picks.** The decision belongs to the human; the AI's job is to make
   the choice informed. Record the choice + WHY (in `user-notes.md` / prd.json)
   so the loop never re-litigates it.
4. **Lock it.** Switching stack mid-event = death.

### Guardrails (advice, not decisions)

| Guardrail | Why |
|---|---|
| Prefer tools you already know + AI generates well | Learning a new stack at the venue = death |
| Simple persistence (e.g. SQLite) over "real" DBs | Zero setup, demo-safe |
| No Docker/K8s/exotic infra | Setup time is the enemy |
| Tests are part of every stack (pytest / vitest / ...) | THE quality gate — non-negotiable, the loop needs it |
| Don't burn hours on slides tooling | Markdown export is enough |

## 2b. Engineering standards BEFORE code (the blueprint phase)

> Like any real software project: nobody writes code before the foundations
> are agreed. The loop enforces this order.

```
Requirements (interview) → ONE-sentence pitch + demo script + cut line
  → Stack decision (§2, human picks from AI's options)
  → Architecture blueprint: components, data model, API shape (1 page max)
  → Pipeline FIRST: repo layout, test runner, lint, run script — proven with a hello-world
  → prd.json stories (ordered by demo value, happy path first)
  → ONLY THEN the build loop starts
```

The AI's job in this phase: ask the questions, draw the options, write the
blueprint draft. The human's job: approve every arrow before the next one.

## 3. The golden split: HUMAN decides vs AI builds

### 🧠 ONLY the human (decide BEFORE / during sparingly)
| Decision | When | Why you, not AI |
|---|---|---|
| **The idea + the ONE-sentence pitch** | Before / hour 0 | Judges reward a sharp problem, not code |
| **The 3-minute demo script** (the happy path) | Hour 0-1 | Everything gets built backwards from this |
| **Scope cut line** — what we will NOT build | Hour 1 | AI never cuts scope; you must |
| **Tech stack + architecture** — human picks from AI's options (§2) | Before / hour 0 | Switching mid-event = death |
| **prd.json stories + priorities** | With AI's help, YOU approve | Ordering by demo value is strategy, not coding |
| **Every push/PR/irreversible action** | Anytime | Approval gate — by design |
| **The pitch narrative** ("why this matters") | Last 2 hours | AI drafts, YOU own the story |

### 🤖 Delegate to the AI (the loop)
- All implementation, one story per iteration
- Tests for every story (it writes them — require it in acceptance criteria)
- Bug fixes and retries (stuck detection flags you if it needs help)
- Boilerplate: configs, CI, README, .gitignore
- First drafts of: pitch text, demo talking points, architecture diagram descriptions
- Code review (evaluator pass — keep it ON for hackathons)

### ⚡ The hackathon workflow (time-boxed)

```
Hour 0-1   HUMAN+AI: requirements interview → pitch sentence + demo script +
           cut line → stack + architecture blueprint (§2) — human approves each step
Hour 1     HUMAN+AI: pipeline FIRST (repo layout, test runner, lint, run script —
           hello-world proves it) → prd.json (stories ordered by DEMO VALUE,
           happy path first) → doctor.sh → must be all ✅
Hour 1-6   AI LOOP: ralph.sh --max-daily 40 15
           HUMAN: build the pitch/deck while the loop builds the product
Hour 6+    HUMAN: status.sh every hour; clear any 🚨 in user-notes.md
Final 2h   FREEZE features. Loop only on demo-blockers.
           HUMAN: rehearse the 3-minute demo 3 times on the real build
```

## 4. Rules that win hackathons

1. **Demo > polish > features > code.** 3 working features beat 7 half-done ones.
2. **Happy path first.** Stories ordered so that even 50% completion = demoable.
3. **Tests are not optional.** The evaluator + tests are what keep hour-20 code from being mush.
4. **Never fight a stuck loop.** 🚨 in user-notes.md → clarify the story or cut it. 10 minutes max.
5. **Feature freeze 2 hours before judging.** Period.
6. **Standards before code.** Requirements → stack decision → blueprint →
   pipeline → stories → THEN the loop (§2b). Skipping straight to code is how
   hour-20 becomes mush.
7. **Sleep is a feature.** A loop can run while you nap — that's the whole point. Check `status.sh` when you wake up.

## 5. Pre-written emergency commands

```bash
./scripts/ralph/status.sh                     # where are we? (0 tokens)
./scripts/ralph/doctor.sh                     # is the setup sane?
./scripts/ralph/ralph.sh --max-daily 40 15    # hackathon loop run
./scripts/ralph/prompt-gate.sh "story idea"   # is this story well-defined?
git log --oneline                             # what got built?
```

## 6. What judges actually score (and what maps to it)

| Judge criterion | Your answer |
|---|---|
| Working demo | The loop + evaluator + tests = it actually runs |
| Innovation | Your idea (human job §3) |
| Technical depth | "Our build pipeline is itself agentic: generator-evaluator loop, memory, judgment rules" — TRUE and impressive |
| Completeness | Cut-line discipline → everything shown works |
| Presentation | Your 3-minute script (human job) |

> 💡 The meta-flex: if asked "how did you build so fast?" — show `status.sh`,
> `git log`, and the prd.json. "We didn't just use AI to code. We engineered
> the loop around the AI." That's a winning sentence.

---

*Written 2026-08-29. Framework v2 + Prompt Gate.
Fixed 2026-08-30: stack/architecture is a joint human+AI decision (§2),
engineering standards phase added before code (§2b). Good luck. 🏆*
