# ace-hitl

`ace-hitl` manages ACE human-in-the-loop (HITL) events in `.ace-local/hitl/`.

Canonical workflow and skill for agents:

- Workflow: `wfi://hitl`
- Skill: `as-hitl`

## Commands

- `ace-hitl create` creates a HITL event
- `ace-hitl ask` asks a human via HITL and forwards the request through a provider adapter (`--provider`, default `lab`); ONE operation: local event + transport send (`--work`, effect callback flags)
- `ace-hitl list` lists HITL events with filters (`--scope current|all`, all statuses by default)
- `ace-hitl show` renders event details, path, or raw content (`--scope current|all`)
- `ace-hitl update` updates frontmatter, answer content, and folder location
- `ace-hitl wait` polls a specific HITL event until answered (`--poll-every`, `--timeout`)

`ace-hitl` is a blocker-resolution tool, not a global dashboard:

- linked worktree default: local (`--scope current`)
- main checkout default: operator view (`--scope all`)

Use `ace-overseer status` for a global worktree dashboard.

## Provider adapters

`ace-hitl ask` dispatches through the `Ace::Hitl::Providers` registry
(selection: `--provider` flag → `ACE_HITL_PROVIDER` env → `lab`).

- `ask` is ONE operation: it creates the local HITL event and sends the
  provider transport request, then persists `provider`, `ref_schema`,
  `ref_session`, `ref_pane` plus the existing `lab_request_*` fields.
- The asker's reverse address (`ref`, versioned schema
  `ace.hitl.ref/v1`: herdr session + pane) is captured fail-closed from
  `HERDR_SESSION` / `HERDR_PANE`; absent or invalid values abort the ask
  before any event is created or transport is called.
- Error model: `UnknownProviderError`, `InvalidRefError`,
  `ProviderUnavailableError` (transport failure; surfaces the orphan
  event id when one was already created), `UnsupportedOperationError`.
- `deliver(ref, answer)` (push the answer back to the asker's pane) is
  declared by the interface; provider `lab` raises
  `UnsupportedOperationError` until the ace-herdr push-delivery
  integration lands. `ace-hitl wait` stays the pane-less script path and
  does not go through a provider.
- Every lab transport invocation is encapsulated in the provider=lab
  adapter (`Providers::Lab::Transport`); a guard test keeps all other
  agent-facing ace-hitl code free of direct lab transport references.

## Examples

```bash
ace-hitl list
ace-hitl list --scope all
ace-hitl create "Which auth strategy?" --kind decision --question "JWT or sessions?"
ace-hitl ask "Proceed with deploy?" --work W685 --effect-arg /bin/false --effect-cwd /tmp
ace-hitl ask "Proceed with deploy?" --provider lab --work W685
ace-hitl show abc123 --content
ace-hitl show abc123 --scope current
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens."
ace-hitl wait abc123
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens." --resume
```

## Testing

This package is **fast-only** in the ACE testing model.

- Deterministic test coverage lives under `test/fast/`.
- This migration does not introduce `test/feat/` or `test/e2e/` for this package.

Verification commands:

- `ace-test ace-hitl`
- `ace-test ace-hitl all`

## Ownership Boundary

`ace-hitl` owns HITL-specific event semantics and markdown contract.

`ace-support-items` remains generic support infrastructure and should not absorb HITL-specific domain behavior.
