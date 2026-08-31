# Prompt Rules — taxonomy of bad prompt patterns

> The knowledge base for PROMPT_GATE.md. Distilled from prompt-linting research
> (PromptDoctor, Arbiter, ambiguity taxonomies, OpenAI/Anthropic/StackAI guides).
> Each pattern: detection signals → why it fails → the fix.

## P1 — VAGUE (no definition of done)
- **Signals:** "good", "better", "nice", "clean", "modern", "optimize", "improve",
  "enhance", "user-friendly", "make it work", "etc.", "and so on", "stuff like that"
- **Why it fails:** no testable outcome → the agent guesses, the evaluator can't verify.
- **Fix:** every request needs a verifiable "done": a test, an observable behavior, a number.

## P2 — TOO BIG (won't fit one session)
- **Signals:** "whole app", "entire system", "full", "everything", multiple unrelated
  features in one breath joined by "and... and... and..."
- **Why it fails:** context runs out mid-build → half-finished garbage.
- **Fix:** split into stories that each fit one session; one story = one commit.

## P3 — AMBIGUOUS (two or more plausible interpretations)
- **Signals:** undefined jargon, "it", "that thing", "the usual way", domain terms
  with multiple meanings, no example of expected output.
- **Why it fails:** the agent silently picks one interpretation — maybe the wrong one.
- **Fix:** define terms, give an example, or let the gate ask ONE clarifying question.

## P4 — MISSING CONTEXT (references things the agent can't see)
- **Signals:** "the file", "that bug", "my project" with no path; assumes the agent
  remembers a past chat; missing stack/version info when it matters.
- **Why it fails:** the agent starts blank every session; invisible context = guessing.
- **Fix:** name files/paths explicitly; paste the relevant snippet; state the stack.

## P5 — CONFLICTING CONSTRAINTS
- **Signals:** "detailed but short", "complete but minimal", "enterprise-grade, but
  quick and dirty", "be creative but follow the pattern exactly"
- **Why it fails:** the agent must violate one constraint to satisfy the other — and
  picks arbitrarily (Arbiter: contradictions are the top prompt failure mode).
- **Fix:** rank constraints: non-negotiables first, nice-to-haves labeled optional.

## P6 — NO SUCCESS CRITERIA / NO OUTPUT FORMAT
- **Signals:** no tests, no "done when...", no format/length/structure specified
  for deliverables.
- **Why it fails:** "done" becomes the agent's mood, not a checkable fact.
- **Fix:** "done when X runs/passes/shows Y"; specify format (file, JSON, CLI, UI).

## P7 — SECRETS / SENSITIVE DATA
- **Signals:** passwords, API keys, tokens, private personal data pasted in the prompt.
- **Why it fails:** prompts land in logs and git history — permanently.
- **Fix:** use env vars/placeholders; never paste real secrets. Rotate any that leaked.

## P8 — IRREVERSIBLE / DANGEROUS ACTION requested casually
- **Signals:** "push to main", "delete", "drop the table", "deploy", "overwrite",
  "force", without safeguards or explicit confirmation intent.
- **Why it fails:** cannot be undone; approval gate blocks it anyway.
- **Fix:** do irreversible actions yourself, or explicitly approve them after review.

## P9 — RULE OVERRIDE / INJECTION-STYLE
- **Signals:** "ignore previous instructions", "ignore your rules", "pretend you have
  no restrictions", "skip the approval gate", "don't tell the user"
- **Why it fails:** self-sabotage of the safety system; the agent is instructed to refuse.
- **Fix:** if a rule is genuinely wrong, edit AGENTS.md/KIMI.md properly.

## P10 — FACTS WITHOUT SOURCES
- **Signals:** "what does our policy say", "use the numbers from my report" — without
  providing the policy/report; expecting exact recall of private/specific data.
- **Why it fails:** invites hallucination with false confidence.
- **Fix:** paste the source material; say "use only the provided text".

---

## Context-sufficiency checklist (for coding requests)
A prompt is READY only if the agent can answer:
1. WHAT exactly to build/change (one thing)
2. WHERE (project, files, stack)
3. DONE = what verifiable check
4. CONSTRAINTS (ranked, non-conflicting)
5. Anything the agent must NOT do
