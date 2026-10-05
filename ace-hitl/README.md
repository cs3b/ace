# ace-hitl

`ace-hitl` manages ACE human-in-the-loop (HITL) events in `.ace-local/hitl/`.

Canonical workflow and skill for agents:

- Workflow: `wfi://hitl`
- Skill: `as-hitl`

## Commands

- `ace-hitl create` creates a HITL event
- `ace-hitl ask` asks a human via HITL and forwards the request through a provider adapter (`--provider`, default `lab`); ONE operation: local event + relay request through the authenticated boundary (`--assignment/--attempt/--project` managed binding, effect callback flags)
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

`ace-hitl ask --question ... --assignment ... --attempt ...` creates a scoped
request through authenticated IPC. The managed coordinator verifies the exact
active native owner and reverse address; caller environment variables cannot
supply authority. No Lab daemon or Work binding is used.

`Ace::Hitl::LiveClient` provides explicit in-process `deliver`, `watch`, `wait`,
`status`, `pending`, and signed `reconcile`. `watch` returns a thread owned by
its calling agent. Native delivery commits an incarnation-bound event through
Herdr Inbox and registers it through Assign. Queue acceptance and wake do not
prove consumption. Only an event-bound signed native observation verified by
Herdr and journaled by Assign completes delivery. Business callbacks have
separate authorization and receipts and are never rerun by native retries.

Pane-less `wait --request ID` consumes an existing authorized request over IPC;
it neither creates a native target nor proves a business effect. OTP answers
use that protected path with their authorized operation; no OTP bytes or OTP
hash enter the shared envelope, folder or native inbox.

## Examples

```bash
ace-hitl list
ace-hitl list --scope all
ace-hitl create "Which auth strategy?" --kind decision --question "JWT or sessions?"
ace-hitl ask --question "Proceed with deploy?" --assignment assign685 --attempt attempt685 --effect-arg /bin/false --effect-cwd /tmp
ace-hitl ask --question "Proceed with deploy?" --provider lab --assignment assign685 --attempt attempt685
ace-hitl show abc123 --content
ace-hitl show abc123 --scope current
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens."
ace-hitl wait abc123
ace-hitl update abc123 --answer "Use JWT with server-side refresh tokens." --resume
```

## Testing

This package has deterministic fast and scoped integration tests.

- Deterministic test coverage lives under `test/fast/`.
- This migration does not introduce `test/feat/` or `test/e2e/` for this package.

Verification commands:

- `ace-test ace-hitl`
- `ace-test ace-hitl all`

## Ownership Boundary

`ace-hitl` owns HITL-specific event semantics and markdown contract.

`ace-support-items` remains generic support infrastructure and should not absorb HITL-specific domain behavior.
