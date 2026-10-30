---
name: git-mirror-sync
description: Repeatable host mirror-sync operation — explicit source/target/ref, both full SHAs read before acting, identity no-op, fast-forward only, divergence escalated for reviewed reconciliation
allowed-tools: Bash, Read
doc-type: workflow
title: Host Mirror Sync Workflow
purpose: Bind the host operator's forge-mirror sync as a repeatable, evidenced operation: never destructive, always checkable, with the actual source and target SHAs in the result.
ace-docs:
  last-updated: '2026-10-30'
  last-checked: '2026-10-30'
---
# Host Mirror Sync Workflow

## Goal

Synchronize an explicitly named target ref from an explicitly named source
ref (task 8xs.t.pu0.d — for this family: source `fg` Forgejo `cs3b/ace`,
target `origin` GitHub `cs3b/ace`) as a REPEATABLE host operation with a
checkable result. This is an ordinary Git workflow — no new script, no
hardcoded lab topology, no tool change; if a capability is missing it
belongs in ace-git's adapters.

## Instructions

Run the loaded workflow as the source of truth and execute it end-to-end
instead of only summarizing it.

### 1) Name the operation and read BOTH full SHAs first

Before ANY action, read and record the full SHAs of the exact source and
target refs. An operation without both SHAs is not runnable:

```bash
git ls-remote fg refs/heads/main     # source SHA (record it)
git ls-remote origin refs/heads/main # target SHA (record it)
```

### 2) Classify

- **Identity** (source SHA == target SHA): the sync is a NO-OP. Report both
  SHAs and the result `identity`; do not touch anything.
- **Fast-forward** (target SHA is an ancestor of source): proceed.
- **Divergence** (neither of the above): STOP. Divergence needs its own
  reviewed reconciliation decision — NEVER resolve it here with a reset,
  force push, or ref deletion. Report both SHAs and the divergence; a
  historical SHA (e.g. a recorded closeout base like `af68f8fc1…`) is INPUT
  EVIDENCE for the review, never a SHA to impose unconditionally on the
  live target.
- **Reversed direction** (the plan shows the target ahead of the source):
  report it explicitly — a dry-run that names source and target swapped is
  a caught error, not a sync.

### 3) Execute (fast-forward only)

```bash
git fetch fg main
git push origin <source-SHA>:refs/heads/main --force-with-lease=refs/heads/main:<target-SHA>
```

`--force-with-lease` with the READ target SHA is the guard: if anything
moved the target between the read and the push, the push is REFUSED — the
operation restarts from step 1. Plain `--force` is forbidden.

### 4) Verify and report

Re-read the target SHA; the result names the ref, the before/after SHAs of
BOTH sides, and the verification (`git ls-remote origin` equals the source
SHA). Repetition after success reports `identity` — the repeatable
operation is idempotent at the evidence level.

### 5) Dry-run

The same classification with no mutation: report source/target/ref, both
  SHAs, the planned action (no-op / fast-forward / divergence-blocked /
  reversed), and NOTHING else changed.

## Boundaries

- Never delete refs, never reset, never `--force` without a lease.
- Salvage branches, open HITL cases, and active resources on either side
  are untouched by a mirror sync; an active resource conflicting with the
  plan is reported as preserved with its reason.
- Closing a single Herdr pane remains a separate follow-up — never close a
  whole tab as a substitute.
