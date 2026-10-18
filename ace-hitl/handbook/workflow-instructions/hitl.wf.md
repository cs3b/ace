---
doc-type: workflow
title: HITL Workflow
purpose: Standardize human-attention handling for blocked and completed work using ace-hitl events.
ace-docs:
  last-updated: '2026-10-18'
  last-checked: '2026-10-18'
---

# HITL Workflow

## Goal

Use `ace-hitl` as the canonical contract whenever agent flow needs explicit human attention.

## When To Use HITL

Create a HITL event in exactly two shapes:

1. **Question requiring a decision** (blocker needing human judgment: ambiguity,
   product decision, policy/approval gate, or completed work that needs explicit
   confirmation). Questions stay pending and can hold the assignment until the
   Reply arrives; no answer is never consent or success.
2. **Report** (work done / error notification that needs no reply):
   `--type report --result success|error` with optional `--body` lines and
   task/assignment/step references. Reports are recorded, never pending, and
   `wait`/`--answer`/`--resume` on them are explicit usage errors.

Do not create question events for routine status updates that do not require
user action; use a report instead.

## Planned surface (L2)

The normal local path uses plain event files: `create`, `list`, `show`, `update`,
`wait` below -- for both questions and reports. A `serve` boundary service,
grants, OTP challenges and proposals are not required for this path. Reply
routing to the correct remote case and configurable adapters (single or in a
set) land in the remaining L2 leaves; local write is not delivery.

## Commands

### 1) Create a blocker HITL

```bash
ace-hitl create "Need product decision" \
  --kind decision \
  --question "Should retries be visible?" \
  --assignment <assignment-id> \
  --step <step-number> \
  --step-name <step-name> \
  --resume "/as-assign-drive <assignment-id>"
```

If the active assignment step is blocked, fail it using canonical format:

```bash
ace-assign fail --message "HITL: <hitl-id> <hitl-path>" --assignment "<assignment-id>"
```

### 2) Create a completion-attention HITL

```bash
ace-hitl create "Review completed assignment results" \
  --kind approval \
  --question "Please confirm next action for <assignment-id>." \
  --assignment <assignment-id> \
  --step completion \
  --step-name assignment-complete \
  --resume "/as-assign-drive <assignment-id>"
```

### 2b) Create a work-done or error report (no reply expected)

```bash
ace-hitl create "Work done" \
  --type report --result success \
  --body "Implemented the change; tests green." \
  --task <task-ref> --assignment <assignment-id> --step <step-number>
```

Reports land with status `recorded`; never wait on them and never answer them.
The overseer reads them and archives processed reports with
`ace-hitl update <hitl-id> --move-to archive`.

### 3) Discover HITL work

```bash
ace-hitl list
ace-hitl list --scope current
ace-hitl list --scope all
ace-hitl list --status pending
```

### 4) Resolve and archive

```bash
ace-hitl show <hitl-id>
ace-hitl update <hitl-id> --answer "<human decision>"
```

Polling is the default reliability path for the requesting agent:

```bash
ace-hitl wait <hitl-id>
```

If the waiter is no longer active, operator fallback can dispatch resume:

```bash
ace-hitl update <hitl-id> --answer "<human decision>" --resume
```

## Completion Contract

After answer is applied:

- Continue normal assignment retry/resume flow.
- Keep `ace-assign` mechanics unchanged (no paused assignment state).
- Archive HITL event after resolution.

## Event Names

Canonical lifecycle namespace: `hitl.event.*`

- `hitl.event.created`
- `hitl.event.answered`
- `hitl.event.wait_started`
- `hitl.event.wait_timed_out`
- `hitl.event.resume_dispatched`
- `hitl.event.resume_skipped_waiter_active`
- `hitl.event.resume_failed`
- `hitl.event.archived`

## Success Criteria

- Blockers always produce canonical `HITL: <id> <path>` failure reason.
- Human-required completion handoffs generate approval HITL events.
- Resolved HITL events are archived only after successful resume dispatch.
