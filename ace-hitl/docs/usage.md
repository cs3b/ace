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

## Recipient addressing and Reply

Every event can carry an explicit recipient address read from the `hitl`
configuration cascade (`.ace/hitl/config.yml` project override; HITL reads
the address config — consumers pass a configured name, no client-side
routing):

```yaml
hitl:
  machine: lab01                 # this machine's identity for addresses
  default_recipient: overseer    # optional name applied when --to is absent
  recipients:
    overseer:                    # folder form: machine + events folder (+ case ID)
      machine: lab01
      folder: .ace-local/hitl
    captain:                     # panel form: machine + panel
      machine: lab02
      panel: telegram
```

```bash
ace-hitl create "Blocked on auth" --kind decision --to overseer --task 8xg.t.sbz.1.1
```

- The folder form stamps the new event's ID as the case ID; the panel form
  carries no case ID. Questions additionally record a `reply_to` address
  (sender machine + events folder + own case ID), so an answer binds to the
  original case and the right agent — task/assignment/step are context,
  never an ID substitute.
- Local Reply is unchanged: `update <ref> --answer` binds by exact ID with
  strict ambiguity handling and an explicit not-found error; a transport
  later reads `reply_to` from the answered event instead of searching for the
  "last question".
- Unknown recipient names, malformed configured addresses, and a missing
  `hitl.machine` (needed for `reply_to`) fail closed before anything is
  written. Ambiguous shortcuts list candidates instead of guessing.
- `--to` absent with no `default_recipient` creates a local-only event with
  no address keys (legacy flow unchanged). `show` prints `Recipient:` and
  `Reply-To:` when present; local write is not delivery (adapters and
  redelivery land in the remaining L2 leaves).

## Reports

The same interface records reports — completion or error notifications that do
not await an answer:

```bash
ace-hitl create "Work done" \
  --type report --result success \
  --body "Implemented JWT login" \
  --body "Tests green" \
  --task 8xg.t.sbz.1.0 --assignment abc123 --step 010

ace-hitl create "Step failed" \
  --type report --result error \
  --body "Verifier crashed after merge" \
  --task 8xg.t.sbz.1.0 --step 020
```

Rules:

- `--type report` requires `--result success|error`; `--question`, `--kind`,
  and `--resume` are rejected on reports.
- `--result` and `--body` are only valid with `--type report`.
- Reports are created with status `recorded` and never appear as pending
  questions: `wait <report>`, `update <report> --answer`, and
  `update <report> --resume` exit 1 with an explicit error. Generic updates
  (`--set`, `--add`, `--remove`, `--move-to archive`) still work.
- `--task` is accepted for both questions and reports.
- Local write is not delivery: `recorded` means the event is persisted under
  `.ace-local/hitl/`, not that it reached the recipient. Remote addressing and
  configurable adapters are planned follow-up leaves (8xg.t.sbz.1.1–.1.3).

Questions keep the existing pending → answered cycle; files without a `type`
frontmatter key load as questions.

## Send — delivery routes

`create` persists locally; `send` is the explicit delivery step through the
configured adapter routes. Switching transports is pure configuration — no
assignment or coworker logic changes.

```yaml
hitl:
  adapters:
    routes:
      - route: overseer-terminal   # display name; defaults to the adapter name
        adapter: terminal          # built-in: any ace-runtime terminal
        runtime: herdr             # tmux | herdr
        pane: p5                   # opaque pane handle (runtime-owned)
      - route: captain-telegram
        adapter: hermes            # ships in ace-hitl-hermes
        channel: project
        machine: lab01             # defaults to hitl.machine
        folder: /run/hermes/project
        sender: lab01              # defaults to machine
```

```bash
ace-hitl send 8xhkep
```

```
HITL event 8xhkep sent through 2 route(s):
  overseer-terminal (terminal): delivered - text pushed to herdr pane p5
  captain-telegram (hermes): unavailable - ...
```

Rules:

- One result line per route; a route's success never hides another route's
  failure. Exit 0 only when every route is `delivered`; exit 1 on any
  `failed`/`unavailable` route, no configured routes (concrete error naming
  `hitl.adapters.routes`), unknown adapter, or unknown/ambiguous ref.
- Every route receives the identical shared rendering: `[HITL question]`/
  `[HITL report <result>]` prefix, one `Q:` line per question, `Reply-To:`
  on questions only, task/assignment/step context.
- `delivered` means accepted by the route's transport. An unavailable
  adapter never reroutes to another recipient. Delivery results are
  reported, not persisted — retaining undelivered messages with failure
  reasons and redelivering them is the next L2 leaf (8xg.t.sbz.1.3).
- Adding an adapter requires no ace-hitl change: a gem ships
  `lib/ace/hitl/adapters/<name>.rb` calling `Ace::Hitl::Adapters.register`
  (duck contract: `factory.call(route)` → adapter with
  `deliver(event:, text:, recipient:, reply_to:)` returning a
  `RouteResult`; status `:delivered`/`:failed`/`:unavailable`). Nervus is
  the out-of-scope future example.

## List

```bash
ace-hitl list
ace-hitl list --scope current
ace-hitl list --scope all
ace-hitl list --status pending
ace-hitl list --kind decision
ace-hitl list --type question
ace-hitl list --type report
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
paths instead of guessing. Report events print `Type: report`, `Result:`, and
the report body instead of `Kind:`/`Questions:`/`Answer:`.

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
and its commands (read/pending/states/duty/deliver/consume/cancel) remain for
adapters such as `ace-hitl-hermes`; `serve` supports `--operator-only` only.
The immutable second-commander proposal flow is removed, and so is the unused
old-lab Root Overseer reverse-address channel (`overseer-*` commands); generic
transport has no replacement role-specific queue.

> **Planned (L2):** the report/question distinction is available locally
> (`--type report`; local write is not delivery — deliver with
> `ace-hitl send` through the configured adapter routes). Recipient
> addressing and Reply binding are recorded locally (`--to`, `reply_to`,
> fail-closed resolution). Retention and redelivery of undelivered
> messages are not available yet. Adapters (`ace-hitl-hermes`) and
> transports (tmux, Herdr) are not additional state owners.

## Testing

```bash
bin/ace-test ace-hitl
bin/ace-test ace-hitl all
```
