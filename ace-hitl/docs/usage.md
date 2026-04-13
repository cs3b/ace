---
doc-type: user
title: ace-hitl Usage Guide
purpose: Practical CLI usage reference for ace-hitl event creation, triage, and resolution
  flows.
ace-docs:
  last-updated: '2026-04-02'
  last-checked: '2026-04-02'
---

# ace-hitl Usage

Canonical handbook resources:

- Workflow: `wfi://hitl`
- Skill: `as-hitl`

Runtime store default: `.ace-local/hitl/` (legacy `.ace-hitl/` is no longer used as default).

## Testing

`ace-hitl` is currently a **fast-only** package in the ACE testing model.

- Deterministic coverage lives under `test/fast/`.
- This package does not introduce `test/feat/` or `test/e2e/` in this migration.

Verification commands:

```bash
ace-test ace-hitl
ace-test ace-hitl all
```

## Create

```bash
ace-hitl create "Which auth strategy?" \
  --kind decision \
  --question "JWT or sessions?" \
  --question "Refresh token storage?" \
  --assignment 8qr5kx \
  --step 020 \
  --step-name implement-auth \
  --resume "/as-assign-drive 8qr5kx"
```

Common completion-attention handoff:

```bash
ace-hitl create "Review completed assignment results" \
  --kind approval \
  --question "Please confirm next action for 8qr5kx." \
  --assignment 8qr5kx \
  --step completion \
  --step-name assignment-complete \
  --resume "/as-assign-drive 8qr5kx"
```

## List

`ace-hitl list` is local-first by default:

- in a linked worktree: behaves like `--scope current`
- in the main checkout: behaves like `--scope all`
- if `--status` is omitted: includes all statuses in the selected folder scope

```bash
ace-hitl list
ace-hitl list --scope current
ace-hitl list --scope all
ace-hitl list --status pending
ace-hitl list --kind decision
ace-hitl list --kind clarification --status pending
ace-hitl list --tags auth,security
ace-hitl list --in archive
```

## Show

`ace-hitl show` also accepts `--scope current|all`.
Without `--scope`, lookup is local-first; if not found and smart scope is active, it retries across all worktrees.
When lookup resolves outside the current worktree, output includes an explicit `Resolved Location:` line.
When using `--scope all`, ambiguous matches return an error with candidate paths so the operator can select the intended event explicitly.

```bash
ace-hitl show abc123
ace-hitl show abc123 --scope current
ace-hitl show abc123 --scope all
ace-hitl show abc123 --path
ace-hitl show abc123 --content
```

## Update

```bash
ace-hitl update abc123 --set status=in-progress
ace-hitl update abc123 --add tags=reviewed
ace-hitl update abc123 --remove tags=stale
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens."
ace-hitl update abc123 --move-to archive
ace-hitl update abc123 --move-to next
ace-hitl update abc123 --answer "close the assignment" --resume
```

## Wait (Polling Default)

Wait only for a specific HITL id. This is the default reliability path for the requester agent.

```bash
ace-hitl wait abc123
ace-hitl wait abc123 --poll-every 600 --timeout 14400
ace-hitl wait abc123 --scope current
```

## Lifecycle Event Names

Canonical namespace for HITL lifecycle signaling:

- `hitl.event.created`
- `hitl.event.answered`
- `hitl.event.wait_started`
- `hitl.event.wait_timed_out`
- `hitl.event.resume_dispatched`
- `hitl.event.resume_skipped_waiter_active`
- `hitl.event.resume_failed`
- `hitl.event.archived`
