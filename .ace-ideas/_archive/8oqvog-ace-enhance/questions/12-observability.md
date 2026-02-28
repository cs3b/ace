# Question: Observability

## The Question

What logs, reports, and status summaries are required for debugging and UI display?

## Context

Overseer should be inspectable via files and CLI status, not hidden in chat history.

## Prompts

- What is the minimal status summary `ace-overseer status` should show?
- Which logs should be persisted per step?
- How much history should be retained by default?
- Do we need structured step reports for tooling?

## Decision Status

- [x] Decided: **Dual logging with simple status file**

**`ace-coworker status` output:**
- List sessions (if multiple) with status of each
- Active session: current step, attempts, errors, progress
- Links to session logs/reports folder

**Logging (both formats):**
- JSONL: all events/steps (machine-readable)
- Markdown: every delegation + every report returned (debug-friendly for humans and agents)

**Retention:**
- Lives in `.cache/ace-coworker/`
- Cleanup happens when cache/worktree is removed
- No TTL complexity for MVP

**Status file:**
- MVP: single file per session with status (plan + realization)
- Future: event-driven architecture (status derived from logs)

Additional logging details → defer to logging task
