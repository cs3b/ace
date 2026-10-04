# ace-hitl

`ace-hitl` manages ACE human-in-the-loop (HITL) events in `.ace-local/hitl/`.

Canonical workflow and skill for agents:

- Workflow: `wfi://hitl`
- Skill: `as-hitl`

## Commands

- `ace-hitl create` creates a HITL event
- `ace-hitl ask` asks a human via HITL and forwards the request through a provider adapter (`--provider`, default `lab`); ONE operation: local event + relay request through the authenticated boundary (`--assignment/--attempt/--project` managed binding, `--work` legacy, effect callback flags)
- `ace-hitl list` lists HITL events with filters (`--scope current|all`, all statuses by default)
- `ace-hitl show` renders event details, path, or raw content (`--scope current|all`)
- `ace-hitl update` updates frontmatter, answer content, and folder location
- `ace-hitl wait` polls a specific HITL event until answered (`--poll-every`, `--timeout`)
- `ace-hitl deliver` answers a pending relay request from stdin (configured transport operation through the boundary); executes the declared effect callback (non-OTP kinds)
- `ace-hitl consume` consumes one own relay request's answer (indefinite by default; `--timeout` bounds only the local wait)
- `ace-hitl cancel` cancels with an audited reason (the only way to abandon a request)
- `ace-hitl pending` / `ace-hitl states` / `ace-hitl duty` transport projections (pending, public lifecycle records, pending + escalated)
- `ace-hitl serve` runs the authenticated store boundary service (peer-credential UNIX socket; trusted grants authorize the transport)

Multi-user HITL state (spec 8wq.t.34i) is the PRIVATE state of the
`ace-hitl serve` boundary: identity comes from kernel peer
credentials, transport authority from the trusted grants document,
and OTP secrets are held in service memory only — never in files,
logs, or projections.
- `ace-hitl overseer-send` / `ace-hitl overseer-pending` / `ace-hitl overseer-ack` the Overseer reverse-address response channel

`ace-hitl` is a blocker-resolution tool, not a global dashboard:

- linked worktree default: local (`--scope current`)
- main checkout default: operator view (`--scope all`)

Use `ace-overseer status` for a global worktree dashboard.

## Provider adapters

`ace-hitl ask` dispatches through the `Ace::Hitl::Providers` registry
(selection: `--provider` flag → `ACE_HITL_PROVIDER` env → `lab`).

- `ask` is ONE operation: it creates the local HITL event and the relay
  request through the NATIVE generic lifecycle store
  (`Ace::Hitl::Lifecycle`; migration spec 8wm.t.y21), then persists
  `provider`, `ref_schema`, `ref_session`, `ref_pane` plus the existing
  `lab_request_*` fields.
- The asker's reverse address (`ref`, versioned schema
  `ace.hitl.ref/v1`: herdr session + pane) is captured fail-closed from
  `HERDR_SESSION` / `HERDR_PANE`; absent or invalid values abort the ask
  before any event is created or store state changes.
- Error model: `UnknownProviderError`, `InvalidRefError`,
  `ProviderUnavailableError` (store-create failure; surfaces the orphan
  event id when one was already created), `UnsupportedOperationError`.
- `deliver(ref, answer)` (push the answer back to the asker's pane) is
  declared by the interface; provider `lab` raises
  `UnsupportedOperationError` until the ace-herdr push-delivery
  integration lands. `ace-hitl wait` stays the pane-less script path and
  does not go through a provider.
- The generic lifecycle is provider-agnostic; all lab coupling lives in
  the provider=lab seams (the `Providers::Lab::DaemonBinding` labd
  binding client and the store factory), enforced by guard tests.

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
