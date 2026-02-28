# Question: Gate Mechanics (Pause/Resume)

## The Question

How should human gates pause the workflow and resume it safely?

## Context

Gates are the safety valve for plan review, code review, or any human approval. The overseer must support clean
pause/resume without losing state or leaving zombie processes.

## Options

### Option A: Exit on Gate (Suspend)

When a gate is reached:
- Write `status: paused` and `gate: { id, status: "waiting" }` to state.
- Exit the process.
- Resume only when an explicit approval command updates the state.

**Pros:**
- Simple and resource-friendly
- No long-running process
- Resilient to crashes/restarts

**Cons:**
- Requires a resume command
- Needs clear notification channel

### Option B: Long-Running Wait (Polling)

Overseer pauses but stays running, polling for approval.

**Pros:**
- Immediate resume
- Single process handles full workflow

**Cons:**
- Idle process consumes resources
- Harder to recover after crash

### Option C: External Gate Service

Gates are handled by a separate service (TUI/daemon) that notifies overseer.

**Pros:**
- Rich UX
- Can support multiple channels

**Cons:**
- More components and complexity

## Recommendation

**Option A** for Phase 1: exit on gate with explicit resume command. This aligns with CLI-first, file-based state,
and minimal complexity. Add optional notifications later.

## Open Prompts

- Which component validates gate transitions (overseer vs coworker)?
- How is feedback captured on rejection (file, CLI args, prompt)?

## Decision Status

- [x] Decided: **Option A - Exit on gate**

Write state and exit. Resume via explicit command (`ace-overseer resume --approve` or `--reject --reason "..."`).

**Additional:** Log gate questions to session log. If long-running agents get terminated, the log shows what's pending/missing for recovery.
