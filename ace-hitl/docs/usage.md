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

## Ask (Provider adapter with effect callback)

`ace-hitl ask` dispatches through the provider adapter registry
(`--provider`, default: `ACE_HITL_PROVIDER` env, then `lab`). ONE
operation: it creates the local HITL event, forwards the question through
the provider transport bound to the event via `--ace-hitl-id`, and prints
both ids. Effect declarations are validated client-side (exact bounds)
and passed through verbatim; the lab tool remains the authority.

```bash
ace-hitl ask "Proceed with deploy?" \
  --work W685 \
  --effect-arg /usr/bin/notify-send "{answer}" \
  --effect-cwd /tmp
```

- `--attempt` defaults to `LAB_ATTEMPT_ID`; `--project` to `ace`;
  `--harness` to `lab-admin`; `--plan` to `ace-hitl ask`.
- Reverse address (fail closed): the asker's herdr session + pane are
  read from `HERDR_SESSION` / `HERDR_PANE` and persisted on the event as
  `ref_session` / `ref_pane` with `ref_schema: ace.hitl.ref/v1` and
  `provider: lab`. Absent or invalid values abort the ask before any
  event is created or transport is called — an ask must always know
  where its answer can be delivered.
- Effect flags: `--effect-match` (regex, <= 200 chars, must compile),
  `--effect-arg` (repeatable, 1..16 x 1..512 chars after the lab's
  strip-then-bounds check; whitespace-only elements fail fast, valid
  values pass through verbatim; `{answer}` substituted lab-side),
  `--effect-cwd` (absolute, must exist), `--effect-timeout-s` (1..600).
- Whether an effect was declared is recorded on the event as
  `lab_request_effect: declared|none` so `wait` can apply the right
  terminal semantics.
- The answer is always relayed unchanged; consumption stays on the
  operator side via the lab relay tool.
- If the transport send fails after the local event was created, the
  error surfaces the event id as an orphan (created but never bound to a
  relay request); inspect it with `ace-hitl show <id>` and delete or
  re-ask as needed.
- `deliver(ref, answer)` — pushing the answer back to the asker's pane —
  is declared by the adapter interface; provider `lab` reports it as
  unsupported until the ace-herdr push-delivery integration lands.

## Wait (Polling Default)

Wait only for a specific HITL id. This is the default reliability path for the requester agent.

```bash
ace-hitl wait abc123
ace-hitl wait abc123 --poll-every 600 --timeout 14400
ace-hitl wait abc123 --scope current
```

When the event carries a Lab request (`lab_request_id`), wait also observes
the Lab public projection instead of hanging blind. Both projection fields
are observed: the lifecycle `state` (created / answer-delivered / consumed /
cancelled) and the separate `effect_state` (callback-pending-with-answer /
callback-ok / callback-escalated). Terminal semantics are effect-aware:

- Requests without a declared effect terminate on lifecycle states
  (`answer-delivered`, `consumed`, `cancelled`).
- Effect-declaring requests keep waiting until the callback verdict
  (`callback-ok` or `callback-escalated`) appears — they never end
  silently at answer delivery; `callback-escalated` output points at
  the lab duty projection for the escalation.
- The event's `lab_request_state` records the effective state, so it
  never claims plain `answer-delivered` while an effect outcome exists.

Relay consumption stays on the operator side via the lab relay tool.
`wait` is the pane-less script path: agents with a herdr pane ask
through the provider adapter and receive answers delivered back to
their pane.

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
