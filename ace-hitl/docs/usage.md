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

`ace-hitl` includes isolated fast tests and deterministic scoped integration tests.

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

## Ask and scoped live client

```bash
ace-hitl ask --question "Proceed with deploy?" \
  --assignment assign685 --attempt attempt685 --project ace \
  --effect-arg /usr/bin/notify-send --effect-arg "{answer}" --effect-cwd /tmp
```

Assignment and attempt are required compact managed IDs. The coordinator verifies
an active owner and its exact native reverse binding, using the kernel peer PID
and Runtime's existing process ancestry/birth authority. Missing peer PID or
native evidence refuses an exact-owner claim. Darwin uses LOCAL_PEERPID; Linux
uses SO_PEERCRED. UID equality alone never selects another attempt. There is no
Work binding, Lab daemon socket or environment-derived reverse target.

An agent explicitly hosts its watcher in its own process:

```ruby
client = Ace::Hitl::LiveClient.new(root: checkout_root)
watcher = client.watch(request: request_id) { |delivery| handle_queue_result(delivery) }
watcher.value
client.status(request: request_id)
```

`deliver` consumes an authorized ordinary answer, enqueues one incarnation-bound
Herdr event, registers its digest/key with Assign, and attempts exact native
submission. The accepted owner's terminal, agent and immutable native session ID
are captured before consumption and checked under the Inbox event lock. A thread
restart in the same pane refuses delivery rather than changing that original
identity. Repeated calls reuse the same event and never resubmit an uncertain
intent. A stopped watcher leaves the request/native intent visible in
`pending --project ace`; it never chooses a new pane or launches a replacement
watcher. The configured Hermes transport publishes created requests for its
explicitly registered project channels and owns their Telegram polling.

Queue acceptance (`delivered`) and wake are transport facts. Business effects
run once through the scoped service under the requester's declaration; their
separate receipt reference cannot be inferred from native delivery. Actual
consumption requires the existing trusted supervisor/observer signing context:

```ruby
client.reconcile(request: request_id, receipt_path: signed_receipt_path)
# Explicit retry only after verified supersession/non-consumption:
client.reconcile(request: request_id, receipt_path: signed_receipt_path, retry_delivery: true)
```

Herdr verifies the signature, exact event/attempt/digest/generation/native binding
and accepted registration under the event lock. Assign journals the verified
observation. Missing authority or signer, wrong key, changed target and stale
proof stay refused/unknown. Signed supersession leaves ordinary `deliver` and
`watch` calls queued; only `reconcile(..., retry_delivery: true)` submits again.
No elapsed-time rule establishes success or retries.
Keep the original trusted verification/signing context for unresolved events or
defer key rotation; a replacement fingerprint cannot rebind an existing event.

The shared versioned envelope is semantically owned by HITL and packaged in
`ace-hitl-contract` to preserve the acyclic HITL → Assign → Herdr → contract
graph. Its nested Hermes message and reverse reference are distinct schemas.
OTP answers and their hashes are excluded from the envelope and native delivery.

## Scoped Store Boundary (spec 8wq.t.34i)

The relay request store is the PRIVATE state of one authenticated
boundary service. `ace-hitl serve` owns the store and speaks a bounded
JSON protocol over a UNIX socket; every client operation
(`ask`/`deliver`/`consume`/`cancel`/`pending`/`states`/`duty`/`read`)
runs through the authenticated boundary client — the CLI never touches
shared store files directly.

Identity is a kernel fact: the service resolves each connection's peer
uid from the OS (`getpeereid`), and payload fields or environment
variables can never name a requester. Clients authenticate the
endpoint back: the socket must be owned by the trusted service uid,
must not be world-writable, and the connected peer must BE the service
uid. Authorization facts (service uid, transport uids, per-project
Captain visibility) come only from the trusted deployment grants
document — the same file and traversal trust rules as ace-lab
(default `ACE_HITL_GRANTS_PATH`, `/etc/lab/ace-lab/authorization.yml`).

```bash
# Deployment (root runs the service under its own account):
ace-hitl serve                      # ACE_HITL_SOCKET, ACE_HITL_STORE_ROOT,
                                    # ACE_HITL_GRANTS_PATH override paths
```

Store layout (all service-owned): `0711` traverse-only root;
`requests/ answers/ secrets/ effects/ locks/ terminals/` are `0700`;
`public/` is `0755` with `0440` non-secret projections. There is no
chmod-to-world-writable mode: requesters receive answer bytes over the
authenticated connection, never through file ownership.

Roles:

- requester: create, consume and cancel its OWN requests (request
  facts come back from `ask`/`consume`; the boundary `read` protocol
  operation is available to library clients);
- configured transport (grants `hitl.transport_uids` + principals):
  `deliver`, `pending`, `states`, `duty`;
- unknown identity is an error, never permission.

Failures are classified end to end: `PermissionError`,
`BindingError`, `StateError`, `AnswerError`, and `TransportError`
(unavailable/untrusted boundary, deadline, malformed frame) — transport
failures are visible and recoverable, and duplicate consume/cancel are
idempotent (the committed receipt replays; a conflicting transition is
an error).

## Relay Lifecycle (Generic HITL Request Store)

The generic relay request lifecycle is native to the gem
(`Ace::Hitl::Lifecycle`; migration spec 8wm.t.y21, scoped by
8wq.t.34i). Requests never expire on a timer, every terminal
transition shares one stable per-request lock, and the store root is
`ACE_HITL_STORE_ROOT` (default `/run/lab/hitl`); the Overseer channel
root is `ACE_HITL_OVERSEER_CHANNEL_ROOT` (default
`/lab/state/overseer-channel`). Machine output is one JSON line.

Managed binding (the default authority):

```bash
ace-hitl ask --question "Choose the next scope" \
  --assignment 8x3abc --attempt a1b2c3 --project ace
```

The request binds to the exact ACTIVE MANAGED attempt of the calling
identity, verified through the ace-assign coordinator under the
assignment exclusion: a stale, ended, replaced, or uncertain attempt
cannot acquire authority, and the exclusion is HELD across every
consume/deliver transition so an attempt cannot end between the
liveness check and the commit. Assignment and attempt identity are always explicit;
there is no legacy Work-only contract.

Transport side:

```bash
ace-hitl pending                    # answerable requests
ace-hitl states                     # all public lifecycle projections
ace-hitl duty                       # pending + escalated projection
ace-hitl deliver hitl-0a1b2c3d4e5f6708 <<< "approved"
```

`deliver` reads the answer from stdin and relays it unchanged. OTP
bytes go to the service's memory vault; plain answers to the
service-owned `0600` answers file. Liveness is re-verified under the
lock, and the declared effect callback (non-OTP kinds only) executes:
exec-style argv (never a shell), `{answer}` substituted once per
element, optional fullmatch regex gate, bounded timeout, attempts
logged redacted in the effects log, and one deduped escalation with
`effect_state: callback-escalated` in the public projection on failure
(`callback-ok` on success). Duplicate deliveries are idempotent: the
committed answer is reported without re-running any effect.

Requester side:

```bash
ace-hitl consume hitl-0a1b2c3d4e5f6708
ace-hitl consume hitl-0a1b2c3d4e5f6708 --timeout 600
ace-hitl cancel hitl-0a1b2c3d4e5f6708 --reason "operator stopped the work"
```

A consume timeout bounds ONLY the local wait — the request stays
pending and answerable. OTP consumption requires the challenge's
authorized operation (`--operation <name>`); the secret transfers
exactly once and a consumed retry replays the receipt WITHOUT the
bytes. The persisted challenge deadline is checked at the locked handoff;
consumption at or after that deadline refuses with an expired error and
discards the pending secret. Memory retention ends at the earlier of the
challenge deadline and the vault TTL. Delivery, duplicate delivery, waits,
and service restarts cannot extend the authorized window. Request a fresh
authorized challenge after expiry. Cancel is the ONLY way to abandon a request, requester-only;
it records `cancelled_by` and the `reason` in the public projection,
and late answers/consumes fail closed against the committed receipt.

Overseer reverse address (bounded, type-tagged responses):

```bash
ace-hitl overseer-send --reply-to 321 <<< "[decyzja] Rekomendacja: A."
ace-hitl overseer-pending
ace-hitl overseer-ack msg-0123456789abcdef
```

Responses are 1..1200 characters and must open with a type tag
(`[decyzja]`, `[pytanie]`, or `[info]`); full SHAs, Work/Attempt/task
IDs, or the word "SHA" are rejected. `overseer-send` is the overseer
user's operation; `overseer-pending`/`overseer-ack` are host-broker
(root) operations used by the transport to drain and acknowledge
relayed responses.

## Wait (Polling Default)

Wait only for a specific HITL id. This is the default reliability path for the requester agent.

```bash
ace-hitl wait abc123
ace-hitl wait abc123 --poll-every 600 --timeout 14400
ace-hitl wait abc123 --scope current
```

Managed event waits resolve `lab_request_id` and consume through authenticated
IPC. They never read folder projections or persist returned answers into the
local event. Explicit pane-less scripts can wait without any local event:

```bash
ace-hitl wait --request hitl001 --timeout 30
ace-hitl wait --request otp001 --operation gem-push
```

The default managed wait is indefinite; a positive timeout bounds only this
call. It never expires the request. OTP consumption requires the authorized
operation and returns its bytes only over protected IPC. Local event polling
remains available for ordinary unbound local events. Managed events cannot use
`update --resume` to launch unscoped session/shell delivery.

Installed acceptance still requires real registered Telegram ingress, native
owner observation and trusted signer/OS-user evidence in Lab. Controlled local
transport and synthetic native observations do not satisfy those gates.

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

## Pending recovery history across bounded IPC pages

`ace-hitl pending --project ace` continues to show unresolved native delivery
claims even after their answers have been consumed. A large retained history
must not prevent newly created questions from reaching Telegram.

The lifecycle wire `pending` operation returns `{items, next}`. `next` is an
exclusive request-ID cursor; send it as `after` with the same project for the
next page. Each response, including framing, fits the IPC byte limit. Every
page rechecks transport/project authorization. `Lifecycle::Client#pending`
collects the pages for existing Ruby/CLI callers; `pending_page(project:, after:)`
exposes a single bounded page. `read(id)` remains available for exact recovery.
No consumed claim is deleted to make the list fit. A record too large for one
page produces a classified error, never a successful truncated list.

This is a live keyset scan, not a frozen snapshot: a newly inserted ID before
the current cursor appears on the next scan. Repeated polling therefore remains
required; a cursor is not proof of delivery or native consumption.

## Immutable second-commander proposals

`ace-hitl proposal create proposal-0123456789abcdef01234567 --assignment ID --attempt ID --project ID --file proposal.json`
returns immutable proposal/revision/request IDs in awaiting-delivery state. The sole Hermes
polling actor publishes the full precise proposal and records confirmed submission before
HITL persists delivered_at and a deadline exactly sixteen hours later. Failed or uncertain
submission cannot arm the window. A Telegram Reply `approve [rationale]`, `veto [rationale]`
or `clarify [rationale]` applies only to the correlated immutable revision; other replies
stop automatic approval and require revision. Missing rationale remains absent.

The JSON proposal requires operation, target (`resource` and optional `artifact_digest`),
candidate_head, input_digest, context, options, recommendation and prerequisites; rationale
is optional. Contents are bounded and non-secret. Input digest uses the canonical service
input digest. Candidate head is separate from base head and the evidence journal commit.
Every precisely presented operation is eligible for sixteen-hour silence, including
publishing, deployment and access/privilege expansion. Fixed service scope, current head,
independently executed review/tests, bound running attempt and operation-specific OTP gates
still apply at execution. Proposal authorization never supplies credentials or runs a callback.

`ace-hitl proposal show ID --format json` shows decision, deadline, actual Assign claim/outcome
and a bounded history page; continue with `--history-after HISTORY_NEXT`.
`ace-hitl proposal history --project ID --query TEXT` retrieves relevant prior decisions;
continue with `--after NEXT`. Project visibility and exact requester identity gate history.
`ace-hitl proposal revise ID --file changed.json` supersedes the prior decision and creates a
new request with a fresh full window after acknowledgement. An unresolved claimed effect
must be reconciled before revision; known successful or proven no-effect settlement can be
followed by a new revision. Interrupted revision creation can retry the exact same file.

Set ACE_HITL_SOCKET and ACE_HITL_PROJECT for the living overseer. It calls
`ace-hitl proposal resolve-due --project PROJECT` on start/status/watch ticks.
The authenticated proposer queues an idempotent reconciliation wake in the
canonical Assign proposal; the command returns `queued-for-transport`, never an
approval claim. The existing installed Hermes `serve` loop polls Telegram under
its own configured transport UID and reconciles queued deadlines after polling.
No proposer subprocess opens transport configuration or impersonates transport.
Hermes holds its ingress lock across checkpoint and HITL decision transition;
unknown health/backlog defers resolution. Failed ticks remain visible while
watch/status continues. Production `--now` is rejected.

Creation requires an explicit stable ID (`proposal-` followed by 24 lowercase
hex digits). Persist that ID before invocation and retry the exact same ID,
assignment, attempt, caller and document after failure or a lost reply. Changed
binding/content is refused. Assign commits the immutable prepared lifecycle
request first; exact retry or the transport pending scan materializes it after
restart. No pending lifecycle orphan exists before canonical commit. Concurrent
materialization creates once and preserves current delivered/answered state.

Unresolved earlier same-request ingress blocks later approval delivery. Exact
reply sequence/content/time deduplication uses canonical decision history;
unseen lower sequence is applied, and changed duplicate content is refused.
History grows in the existing canonical event chain, while public responses use
bounded pages. Hermes metadata never stores message bodies.

The immutable authorization reference is the revision ID, passed to `ace-lab service request`.
Assign atomically checks the canonical proposal under its sole journal claim lock/CAS;
a forged prefix/YAML string or changed operation/target/head/input/caller cannot authorize.
A late veto before claim denies execution. After claim it records stop_requested without
rewriting performed effects; the service rechecks it before safely stoppable invocation.
An uncertain claim remains uncertain on restart and is never automatically dispatched again.
Canonical sanitized decision history shares the qjl evidence ref; no parallel executor or
execution ledger exists in HITL. This source workflow is not installed/native/Telegram or
multi-UID acceptance proof.

### Proposal admission configuration

The protected HITL service reads proposer admission from the same trusted grants
policy as transport and project authorization. For example:

```yaml
hitl:
  service_uid: 1200
  transport_uids: [1201]
  proposal_uids: [1202]
authorization:
  principals:
    "1201":
      projects: [ace]
    "1202":
      projects: [ace]
```

`proposal_uids` admits authenticated kernel peers to create and revise proposals
only for their configured projects. Transport admission alone cannot create a
proposal; proposer admission cannot acknowledge delivery, fabricate ingress, or
resolve silence. Missing role or project admission refuses the operation,
including direct library calls. This is a source configuration contract;
installed deployment adoption remains part of gad.8 acceptance.
