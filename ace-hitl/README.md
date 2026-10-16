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

## Unassigned operator questions

`ace-hitl operator-question ID --project lab-config --question "Which option?"`
creates a nonsecret question under an explicit installed operator grant. An
optional `--plan` adds question context; `--options A,B` supplies bounded choices.
The owner binds the exact Captain-visible body including this context and choices. It does not create an Assign execution,
request a command, grant a decision, or permit OTP/effects. Stable IDs support
exact retries after lost responses, restart and consumption; changed content,
principal, project or context is refused. `ace-hitl read ID` returns authenticated
nonsecret facts; existing `consume ID` retrieves the requester's answer and
replays its terminal receipt.

The public Ruby client exposes `operator_question(id:, project:, question:,
plan: "", options: [])`, `read`, and the existing pending/deliver/consume/cancel
methods. The request records the actual kernel peer UID/name. No caller can supply
requester attribution, assignment, attempt, OTP, effect or publication fields.
Secret-shaped questions, context, choices and answers are refused.

An operator-only service uses the existing owner and Unix protocol:

```sh
ace-hitl serve --operator-only --group ace-hitl-project \
  --socket /run/ace-hitl-project/lifecycle.sock --store-root /var/lib/ace-hitl-project \
  --grants-path /etc/ace-hitl-project/authorization.yml
```

The root-controlled grants document must explicitly name `hitl.service_uid`,
`hitl.operator_uids`, `hitl.transport_uids` and each UID's exact project list in
`authorization.principals`. Operator grants never interpret an empty project list
as all projects. Existing trusted-file ownership/traversal checks apply. The
operator-only binding refuses managed requests and requires no Assign journal.
Admission and requester grants are checked again on reads, answer transitions,
retries and terminal replay; transport delivery retains its independent project
grant. Revocation preserves request and terminal history. Operator questions
cannot be consumed as native execution or authorized-operation claims.

`ping` advertises the supported `request_contexts` (`managed` and/or
`operator-question`), not a grant to create or execute work. Hermes project
routes may require `request_contexts: ["operator-question"]` at startup. The
shared contract uses a closed tagged union of managed execution requests and
operator questions; neither missing IDs nor an unknown schema select a fallback.

One Unix UID with both roles is one OS trust domain. Use a distinct transport
principal where Captain reply isolation is required. Source tests using one UID
for both roles do not prove that isolation. Domain adapters must separately
preserve legacy unresolved host questions and prove the installed group handoff;
this API never migrates or deletes that legacy history.
