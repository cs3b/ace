# ace-hitl

`ace-hitl` manages ACE human-in-the-loop (HITL) events in `.ace-local/hitl/`.

Canonical workflow and skill for agents:

- Workflow: `wfi://hitl`
- Skill: `as-hitl`

## Commands

- `ace-hitl create` creates a HITL event
- `ace-hitl list` lists HITL events with filters (`--scope current|all`, all statuses by default)
- `ace-hitl show` renders event details, path, or raw content (`--scope current|all`)
- `ace-hitl update` updates frontmatter, answer content, and folder location
- `ace-hitl wait` polls a specific HITL event until answered (`--poll-every`, `--timeout`)

`ace-hitl` is a blocker-resolution tool, not a global dashboard:

- linked worktree default: local (`--scope current`)
- main checkout default: operator view (`--scope all`)

Use `ace-overseer status` for a global worktree dashboard.

## Examples

```bash
ace-hitl list
ace-hitl list --scope all
ace-hitl create "Which auth strategy?" --kind decision --question "JWT or sessions?"
ace-hitl show abc123 --content
ace-hitl show abc123 --scope current
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens."
ace-hitl wait abc123
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens." --resume
```

## Ownership Boundary

`ace-hitl` owns HITL-specific event semantics and markdown contract.

`ace-support-items` remains generic support infrastructure and should not absorb HITL-specific domain behavior.
