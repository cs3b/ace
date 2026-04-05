---
doc-type: workflow
title: HITL Workflow
purpose: Standardize human-attention handling for blocked and completed work using ace-hitl events.
ace-docs:
  last-updated: '2026-04-02'
  last-checked: '2026-04-02'
---

# HITL Workflow

## Goal

Use `ace-hitl` as the canonical contract whenever agent flow needs explicit human attention.

## When To Use HITL

Create a HITL event in exactly two cases:

1. **Blocker requiring human judgment** (ambiguity, product decision, policy/approval gate).
2. **Work is complete but explicit user attention is required** before follow-up actions.

Do not create HITL events for routine status updates that do not require user action.

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
