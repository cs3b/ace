# ace-hitl

Human-in-the-loop (HITL) event files for ACE agents and operators.

> **State owner:** `.ace-local/hitl/` -- HITL event markdown files owned by
> `ace-hitl`. Other tools must not write there directly. The agent event
> history is local and untracked. The canonical flow is
> [docs/lab-flow.md](../docs/lab-flow.md).

Canonical workflow and skill for agents:

- Workflow: `wfi://hitl`
- Skill: `as-hitl`

## What exists today

`ace-hitl` manages HITL events stored as markdown files under `.ace-local/hitl/`.
An event records a question or decision, its context (assignment/step), its
status, and the answer — or a report (work done / error) that never awaits an
answer. This is the local, file-based path; it needs no
listener, daemon, or database.

| Command | Purpose |
|---------|---------|
| `ace-hitl create` | Create a question event (kind, questions, assignment/step context, resume instructions) or a report event (`--type report --result success\|error --body ... --task ...`) |
| `ace-hitl list` | List events with status/kind/type/tag/folder/scope filters |
| `ace-hitl show` | Render event details, path, or raw markdown |
| `ace-hitl update` | Update frontmatter, write an answer, or move the event |
| `ace-hitl wait` | Poll one question event until it is answered (reports are rejected) |

`ace-hitl` is a blocker-resolution tool, not a global dashboard: in a linked
worktree it defaults to local (`--scope current`); in the main checkout it uses
the operator view (`--scope all`). Use `ace-overseer status` for a worktree
dashboard.

## Examples

```bash
ace-hitl create "Which auth strategy?" --kind decision \
  --question "JWT or sessions?" --assignment abc123 --step 020
ace-hitl create "Work done" --type report --result success \
  --body "Implemented JWT login" --task 8xg.t.sbz.1.0
ace-hitl list --status pending
ace-hitl list --type report
ace-hitl show abc123 --content
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens."
ace-hitl update abc123 --move-to archive
ace-hitl wait abc123 --poll-every 600 --timeout 14400
```

## Transport boundary

> The installed Lab provider and the attempt-bound managed HITL path (`ask`,
> provider assignment binding, native Herdr delivery, managed/TLS `serve`) were
> removed with the old authority model. The local file-based HITL events above
> remain the active path. The lifecycle/relay transport (`Lifecycle::*`) and
> its commands remain for `ace-hitl-hermes` and other adapters; `serve` supports
> `--operator-only` only. Second-commander proposals are removed as well.
>
> **Planned (L2):** the report/question distinction is available locally
> (`--type report` with `recorded` status; local write is not delivery). Remote
> addressing, reply routing, and configurable provider adapters are not
> available yet. `ace-hitl-hermes` remains an adapter package; tmux/Herdr
> remain transports.

## Testing

```bash
bin/ace-test ace-hitl
bin/ace-test ace-hitl all
```

## Ownership boundary

`ace-hitl` owns HITL event semantics and the markdown contract.
`ace-support-items` remains generic support infrastructure and does not absorb
HITL-specific behaviour.
