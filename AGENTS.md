# Agent Instructions — agent-framework (Twinloop fork)

## Overview

This repo is a fork of [snarktank/ralph](https://github.com/snarktank/ralph), adapted into a portable agent framework that runs with **Kimi CLI by default** (`--tool amp`, `--tool claude` and `--tool cursor` are also accepted by the loop). Twinloop is an autonomous AI agent loop that runs a coding tool repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context.

## Memory protocol (MANDATORY in this repo)

A parent directory's `AGENTS.md` (workspace root, if present) may define a memory
protocol using `memory/` in this folder (profile, lessons, patterns, judgment).
When working in this repo, read those files at session start and update them at
session end, as described there.

## Commands

```bash
# Run the flowchart dev server
cd flowchart && npm run dev

# Build the flowchart
cd flowchart && npm run build

# Run the loop (from an INSTALLED project, not this repo):
./scripts/twinloop/twinloop.sh [max_iterations]              # Kimi (default)
./scripts/twinloop/twinloop.sh --tool claude [max_iterations]
./scripts/twinloop/twinloop.sh --tool amp [max_iterations]
./scripts/twinloop/twinloop.sh --tool cursor [max_iterations] # Cursor CLI headless
```

## Key Files

- `bin/twinloop.sh` — the bash loop that spawns fresh AI instances (default `--tool kimi`; `amp`/`claude`/`cursor` also supported — all receive `KIMI.md`; cursor runs `cursor-agent -p --force --approve-mcps` headless); runs builder → evaluator → **verify phase** at completion
- `loop/KIMI.md` — the canonical builder prompt (Blueprint Gate step 0, memory, judgment, notifications)
- `loop/EVALUATE.md` — evaluator prompt (independent per-story review pass)
- `loop/VERIFY.md` — verifier prompt (end-to-end final verification: full suite + happy-path smoke test + cross-story integration; writes `FINAL-REPORT.md` with a human-acceptance checkbox, or reopens stories on failure)
- `bin/doctor.sh` / `bin/status.sh` — pre-flight checks / token-free dashboard
- `loop/PROMPT_GATE.md` + `loop/prompt-rules.md` + `bin/prompt-gate.sh` — prompt reviewer (P1–P10 failure taxonomy)
- `archive/prompt.md`, `archive/CLAUDE.md` — upstream per-tool prompts, **archived, not used by the loop**
- `templates/BLUEPRINT.md` — Blueprint Gate template: requirements → stack decision → architecture → pipeline, human-approved BEFORE any code (installed as `blueprint.md`; enforced via AGENTS.project.md, KIMI.md step 0, and doctor.sh check 3b)
- `templates/AGENTS.project.md` — rules installed into target projects
- `templates/FINAL-REPORT.md` — final report format written by the verify phase (human acceptance = the exit gate, mirroring the Blueprint Gate at entry)
- `examples/prd.json.example` — example PRD format
- `docs/` — USAGE.md, QUICKSTART-zero.md, HACKATHON.md
- `flowchart/` — interactive React Flow diagram explaining how Twinloop works

## Conventions

- `loop/KIMI.md` is the single canonical builder prompt. If you change builder behavior, change it there — and keep `README.md`, `docs/USAGE.md`, and `templates/AGENTS.project.md` consistent with the change.
- If `bin/twinloop.sh` gains or changes a completion signal (`<promise>...</promise>`), the prompt that must emit it (builder: loop/KIMI.md, verifier: loop/VERIFY.md) and this file + README must document it.
- The verify phase is the exit gate: on completion, bin/twinloop.sh runs `loop/VERIFY.md` (full suite + smoke test + integration review) instead of exiting. PASS → `FINAL-REPORT.md` + human checkbox; FAIL → stories reopen and the loop resumes (state cap: `.verify-attempts`, max 2). Skip with `--no-verify`.
- **Folder layout:** scripts live in `bin/`, loop rule documents in `loop/`, guides in `docs/`, images in `assets/`, examples in `examples/`. `install.sh` flattens `bin/` + `loop/` into a project's `scripts/twinloop/` — sibling references between loop files must keep working after flattening (never reference `bin/` or `loop/` paths from inside copied files).
- Each iteration spawns a fresh AI instance with clean context; memory persists via git history, `progress.txt`, `prd.json`, `user-notes.md`, and `memory/`.
- Stories should be small enough to complete in one context window.

## Flowchart

The `flowchart/` directory contains an interactive visualization built with React Flow. It's designed for presentations — click through to reveal each step with animations.

To run locally:
```bash
cd flowchart
npm install
npm run dev
```
