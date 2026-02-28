# Question: Coworker vs Overseer Boundary

## The Question

Where is the exact responsibility boundary between `ace-coworker` and `ace-overseer`?

## Context

We want a clean separation:
- Coworker is the UI/lifecycle layer (sessions, approvals, status).
- Overseer is the workflow engine (state machine, step execution).

But there are gray areas such as session creation, status formatting, and gate notifications.

## Boundary Candidates

### Option A: Coworker Owns Sessions

Coworker creates worktrees and initializes session state. Overseer assumes an existing session and focuses on
workflow execution only.

**Pros:**
- Overseer stays minimal
- Clear CLI role separation

**Cons:**
- More coupling between coworder and overseer
- Harder to use overseer standalone

### Option B: Overseer Owns Sessions

Overseer creates/attaches/destroys sessions and exposes status data. Coworker is a thin wrapper over overseer
commands.

**Pros:**
- Overseer is fully usable without coworker
- Single source of truth for session state

**Cons:**
- Overseer grows larger
- UI layer has fewer customization hooks

### Option C: Shared Contracts

Overseer owns state and workflow; coworker owns worktree lifecycle. They communicate via a simple file contract
(session.json + state.json).

**Pros:**
- Each component stays focused
- Contract is file-based and inspectable

**Cons:**
- Requires tight contract definition
- Two components to coordinate

## Recommendation

**Option C** as the long-term model: keep a file-based contract and allow either tool to be run independently, but
avoid tight runtime coupling.

## Decision Status

- [x] Decided: **Flip the naming**

| Name | Role | Status |
|------|------|--------|
| **ace-coworker** | Single session workflow executor | Build first |
| **ace-overseer** | Orchestrates multiple coworkers/sessions | Postponed (backlog) |

ace-coworker works on ONE session - workflow execution, state, checkpoints, gates.
ace-overseer (future) manages MULTIPLE coworkers - spawning sessions, distributing work.

This matches natural meaning: overseer supervises multiple coworkers.

**Action:** Update all plan documents (000-overview.md, etc.) to reflect this naming.
