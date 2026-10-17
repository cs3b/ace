---
doc-type: user
title: ace-hitl Usage Guide
purpose: Practical CLI reference for local HITL event creation, triage, and answer flows.
ace-docs:
  last-updated: 2026-10-17
  last-checked: 2026-10-17
---

# ace-hitl Usage

> **State owner:** `.ace-local/hitl/` -- HITL event markdown files owned by
> `ace-hitl`. See [docs/lab-flow.md](../../docs/lab-flow.md).

Canonical handbook resources:

- Workflow: `wfi://hitl`
- Skill: `as-hitl`

Runtime store default: `.ace-local/hitl/`.

## Event files

Each event is a markdown file with frontmatter (`id`, `title`, `kind`,
`status`, `tags`, `assignment`, `step`, `resume`) and the question/answer
sections. Folders:

- `.ace-local/hitl/` -- active events (`next`)
- `.ace-local/hitl/archive/` -- archived events

`--scope current` reads only the current worktree's events; `--scope all` reads
the main checkout's operator view. Without `--scope`, lookup is local-first and
falls back across worktrees when smart scope is active.

## Create

```bash
ace-hitl create "Which auth strategy?" \
  --kind decision \
  --question "JWT or sessions?" \
  --question "Refresh token storage?" \
  --assignment abc123 \
  --step 020 \
  --step-name implement-auth \
  --resume "/as-assign-drive abc123"
```

Kinds: `clarification`, `decision`, `approval`. Completion handoff uses
`--step completion`:

```bash
ace-hitl create "Review completed assignment results" \
  --kind approval \
  --question "Please confirm next action for abc123." \
  --assignment abc123 --step completion
```

## List

```bash
ace-hitl list
ace-hitl list --scope current
ace-hitl list --scope all
ace-hitl list --status pending
ace-hitl list --kind decision
ace-hitl list --tags auth,security
ace-hitl list --in archive
```

With no `--status`, all statuses in the selected folder scope are listed.

## Show

```bash
ace-hitl show abc123
ace-hitl show abc123 --scope all
ace-hitl show abc123 --path
ace-hitl show abc123 --content
```

When lookup resolves outside the current worktree, output includes an explicit
`Resolved Location:` line. Ambiguous matches under `--scope all` list candidate
paths instead of guessing.

## Update

```bash
ace-hitl update abc123 --set status=in-progress
ace-hitl update abc123 --add tags=reviewed
ace-hitl update abc123 --remove tags=stale
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens."
ace-hitl update abc123 --answer "close the assignment" --resume
ace-hitl update abc123 --move-to archive
ace-hitl update abc123 --move-to next
```

`--answer` writes the `## Answer` body and marks the event answered. `--resume`
optionally dispatches the event's resume instructions after the answer.

## Wait

Poll one specific event until it is answered:

```bash
ace-hitl wait abc123
ace-hitl wait abc123 --poll-every 600 --timeout 14400
ace-hitl wait abc123 --scope current
```

The default wait is indefinite; a positive `--timeout` bounds only this call
and never expires the request. `wait` never invents an answer.

## Lifecycle event names

HITL lifecycle signals use this namespace:

- `hitl.event.created`
- `hitl.event.answered`
- `hitl.event.wait_started`
- `hitl.event.wait_timed_out`
- `hitl.event.resume_dispatched`
- `hitl.event.resume_skipped_waiter_active`
- `hitl.event.resume_failed`
- `hitl.event.archived`

## Transport boundary

The installed Lab provider and the attempt-bound managed HITL path (`ask`, the
provider assignment binding, native Herdr delivery, managed/TLS `serve`) were
removed with the old authority model. The local file-based event commands above
remain the active path. The generic lifecycle/relay transport (`Lifecycle::*`)
and its commands (read/pending/states/duty/deliver/consume/cancel/overseer-*)
remain for adapters such as `ace-hitl-hermes`; `serve` supports
`--operator-only` only. The immutable second-commander proposal flow is
removed.

> **Planned (L2):** one unified report/question/reply interface with
> configurable provider adapters -- not available yet. Adapters
> (`ace-hitl-hermes`) and transports (tmux, Herdr) are not additional state
> owners.

## Testing

```bash
bin/ace-test ace-hitl
bin/ace-test ace-hitl all
```
