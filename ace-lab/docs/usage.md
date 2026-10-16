# ace-lab usage

Topology, routing, and scoped service requests for the Lab. Resolves stable
project, agent, and service IDs without transient pane IDs or shared service
credentials.

## Commands

Topology commands accept `--format json` (the only supported format) and
`-q/--quiet`. Service status accepts `--format json`; service request always
emits JSON.

### `ace-lab projects`

List projects visible to the verified caller.

    $ ace-lab projects --format json
    {"status":"ok","data":{"projects":[{"id":"atlas","label":"Atlas platform"},{"id":"borealis"}]}}

A caller with no configured principal receives:

    {"status":"error","error":{"code":"unauthorized","message":"caller has no configured authorization for any lab project"}}

### `ace-lab agents --project PROJECT`

List agents in one project.

    $ ace-lab agents --project atlas --format json
    {"status":"ok","data":{"agents":[{"id":"atlas-planner","project":"atlas","role":"planner","capabilities":["planning"],"binding":{"kind":"runtime","state":"available"}}]}}

`binding.state` is `available` when the configured runtime binding is active
and its instance identity matches the attestation; otherwise `stale`.

### `ace-lab services --project PROJECT`

List services in one project.

    $ ace-lab services --project atlas --format json
    {"status":"ok","data":{"services":[{"id":"atlas-search","project":"atlas","capabilities":["search"],"default_for":["search"],"binding":{"kind":"service","state":"available","endpoint":{"kind":"http","url":"https://search.example.internal:8443"}}}]}}

The endpoint is a sanitized identity: scheme, host, and explicit port only.

### `ace-lab resolve --id ID`

Resolve one entry by exact stable ID.

    $ ace-lab resolve --id atlas-planner --format json
    {"status":"ok","data":{"entry":{"id":"atlas-planner","project":"atlas","role":"planner","capabilities":["planning"],"binding":{"kind":"runtime","state":"available"}}}}

Labels are display values and never resolve: `resolve "Atlas platform"` is a
`missing` error.

### `ace-lab route --project PROJECT --capability CAPABILITY`

Select a configured capable service in the requested project.

    $ ace-lab route --project atlas --capability search --format json
    {"status":"ok","data":{"entry":{"id":"atlas-search","project":"atlas","capabilities":["search"],"default_for":["search"],"binding":{"kind":"service","state":"available","endpoint":{"kind":"http","url":"https://search.example.internal:8443"}}}}}

Routing never invokes the service and never grants credentials.

### `ace-lab service request`

**Goal:** Ask a configured service to perform one named operation for an
active, task-attached assignment attempt. First create a JSON input file:

```json
{"target":{"resource":"release/1.2.3","artifact_digest":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},"arguments":{"version":"1.2.3"}}
```

Run a preview, then submit the exact request:

```sh
ace-lab service request --project atlas --assignment A --attempt ATT \
  --operation publish --input release.json --authorization DECISION \
  --request-id REQUEST --dry-run
ace-lab service request --project atlas --assignment A --attempt ATT \
  --operation publish --input release.json --authorization DECISION \
  --request-id REQUEST
```

The preview reports `outcome: accepted` with `dry_run: true` and the selected
service ID, target, and candidate head. It creates no request claim or effect.
The second command returns `succeeded`, `failed`, or `uncertain` with a
non-secret receipt when the executor confirms an outcome. A missing response
leaves `uncertain` in the assignment evidence ref; do not retry with a new ID
until the external outcome is reconciled. Repeating the same ID and input
returns its stored state without dispatching again. A changed binding under
the same ID is a `conflict` error.

Input must be a JSON object of at most 64 KiB. `target.resource` is a stable
resource ID; `target.artifact_digest`, when supplied, is a SHA-256 hex digest.
Credential, password, secret, token, private-key, authorization, and env keys
are rejected recursively. Operation arguments remain structured JSON sent to
the executor; no caller-provided shell command or argv is accepted.

| Option | Purpose |
|--------|---------|
| `--project` | Project stable ID |
| `--assignment` | Assignment ID |
| `--attempt` | Active managed attempt ID |
| `--operation` | Configured named operation |
| `--input` | Structured JSON file |
| `--authorization` | Exact decision or configured automation reference |
| `--request-id` | Idempotency key; use the same ID for retries/status |
| `--dry-run` | Validate and show scope without an effect |

### `ace-lab service status`

```sh
ace-lab service status --request REQUEST --format json
```

Expected output after a lost executor receipt:

```json
{"status":"ok","data":{"request_id":"REQUEST","outcome":"uncertain","state":"uncertain"}}
```

Only the original OS caller identity with project visibility can read the
request. The authoritative state survives loss of the local assignment cache
because it lives in the separate assignment evidence Git ref.

### `ace-lab service listen --mode ordinary-merge`

The installed ordinary service owns the Assign, HITL and merge endpoints in one
process. Start it as the configured service account:

```sh
ace-lab service listen --mode ordinary-merge --project atlas \
  --config /etc/lab/ace-lab/atlas-receiver.yml
```

The receiver configuration selects its existing forge, repository, principal and
merge socket. `/etc/lab/ace-lab/assign-owners.yml` separately selects the canonical
Assign journal and native execution owner. Both selections must agree with the
ordinary project mapping in the trusted authorization document. `repo_path` is
the merge candidate repository; it does not choose the execution journal.

Each project entry in the root-installed assignment document contains:

| Entry | Installed selection |
|---|---|
| `service` | Non-root owner UID/GID, assignment socket and private state root |
| `journal` | Service-owned repository, execution ref and private evidence checkout |
| `assignment_root`, `lifecycle_root` | Separate private prepared-input and exclusion directories |
| `runtime_binary`, `native` | Installed executable and exact native server/socket generation from the installation receipt |
| `worktrees` | Allowed worktree root and Git common directory |
| `participants` | OS UID/GID/actor, native workspace and supervisor panes |
| `hitl` | Private store root, distinct socket, dedicated group, trusted grants path and optional installed TLS authority reference |

For example, the `hitl` entry inside an already selected project can be:

```yaml
hitl:
  root: /var/lib/lab/assign/atlas/hitl
  socket_path: /run/lab/assign/atlas/hitl.sock
  group: atlas-lifecycle
  grants_path: /etc/lab/ace-lab/authorization.yml
```

The store must be a separate child of that project's `service.state_root`; the
installer creates `service.state_root` with mode `0700`, the HITL root with its
maintained mode `0711`, and socket access before startup. The private parent keeps
the HITL tree inaccessible to other accounts; Store maintains private request and
secret subdirectories. Startup and restart validate the same layout.
`hitl.service_uid` in the grants document must equal the Assign owner UID. Native
identities come from the installed receipt and live observation, not the project
configuration cascade. HITL requests, decisions and merge claims use the same
canonical Assign journal and lifecycle exclusion.

For the existing remote Hermes transport, install its project-scoped mTLS
authority and add its absolute configuration path to this same `hitl` entry:

```yaml
  tls_authority: /etc/lab/ace-hitl/atlas-tls.json
```

The referenced file uses the maintained `ace.hitl.tls.authority/v1` schema and
credential provisioning layout from `ace-hitl`. Its project must match this
owner; `service_user` and `service_group` must resolve to the owner's actual UID
and primary GID. The dedicated Unix control group remains `hitl.group`. Root
installs the credential references and Incus TCP proxy; callers cannot choose
them. Invalid ownership, identity, project or TLS material prevents startup.

The TLS listener runs in this same service process and shares its exact HITL
binding, store, decision policy and in-memory one-time OTP vault. Hermes uses its
verified project certificate as a remote transport identity; it does not need a
synthetic Unix transport UID. Keep `transport_uids` empty when no local transport
is installed. Configure the actual local proposer separately with
`proposal_uids` and its project grant. A proposer grant never authorizes replies
or delegates silence-based decisions. Restart the composed service after changing
its TLS authority or credential selection, retaining the canonical journal.

All selected endpoints must become ready before assignment ingress opens. A
failed endpoint shuts down the complete owner. A stale assignment endpoint needs
installer inspection; startup does not remove it or recover merge effects first.

## Ordinary assignment client

`ace-lab assignment` selects the root-installed project owner and uses the
existing Assign protocol. Assign remains the only accepted execution journal.
Preparation captures reviewed task context and the existing managed assignment
graph; it does not start a worker or register accepted work.

```sh
ace-lab assignment prepare --project atlas --task 8wr.t.abc --pane w1:pS \
  --output .ace-local/prepared-task
ace-lab assignment request --project atlas --input .ace-local/prepared-task/request.json
```

The output directory must not exist. Preparation retains the definition, bundle,
and registration request with one stable mutation ID. `--dependency-reports FILE`
selects an explicit JSON array of `{task_id, assignment_id, number}` entries for
dependency reports. A failed preparation keeps partial files for inspection;
it never rebuilds an existing directory. In this source checkout use
`bundle exec ace-lab` because no `bin/ace-lab` binstub is committed.

Every request file has exactly these fields:

```json
{
  "version": 1,
  "project_id": "atlas",
  "operation": "start_attempt",
  "mutation_id": "original-start-001",
  "params": {
    "assignment_id": "assignment-id",
    "attempt_id": "attempt-id",
    "expected_generation": 0,
    "scope": "010",
    "head": "0123456789012345678901234567890123456789",
    "pane": "w1:p2"
  },
  "parts": []
}
```

Use actual retained IDs, scope, head and native pane. The actual worker executes
its start request: the owner verifies caller ancestry, live process and checkout.
A supervisor cannot impersonate another pane by changing `pane`. A new terminal
or prompt acknowledgement alone is not running proof.

| Operation | `params` beyond `assignment_id` | Transfer / authority |
|---|---|---|
| `register_assignment` | Generated by prepare | Exact prepared bundle; supervisor |
| `registration_status` | None | Read; `mutation_id: null` |
| `start_attempt` | `attempt_id`, `expected_generation: 0`, `scope`, `head`, `pane` | Actual worker start |
| `assignment_snapshot` | `attempt_id` (or null), `kind: queue` or `prepared_work` | Download; `mutation_id: null` |
| `queue_start` | `attempt_id`, `expected_generation`, `pane`, `step` (or null for next) | Original worker |
| `queue_finish` | Same as queue_start | One UTF-8 report part |
| `queue_fail` | `attempt_id`, `expected_generation`, `pane`, `message` | Original worker; unfinished work stays failed |
| `submit_result` | `attempt_id`, `expected_generation`, `pane`, `head`, `receipt_sha256` | Receipt first, then its ordered artifacts; original worker |
| `result_status` | `attempt_id` | Read; `mutation_id: null` |
| `result_snapshot` | `attempt_id`, `result_id` | Canonical receipt/artifacts download; `mutation_id: null` |
| `finish` | `attempt_id`, `expected_generation`, `pane`, `head`, `result_id`, `receipt_digest` | Supervisor accepts exact submitted result after settlement |

Upload `parts` are ordered `{file, bytes, sha256}` entries. Relative files resolve
beside the retained request. Changed, oversized or symlinked inputs refuse before
connection. Requesters never supply a wire `transfer` descriptor. Downloads require
`--output NEW_DIRECTORY`; numbered byte files and `response.json` are private
projections of the authenticated reply, not another execution store. For queue
snapshots, the first byte file contains the current step instructions and reports
as JSON; prepared-work snapshots contain the original Git bundle.

Retain each request and its exact parts before invoking it. On response loss,
inspect `registration_status` or `result_status` and reuse the same original
mutation when replay is appropriate. Never refresh its generation, replace its
bytes, or create a second worker because a reply was lost. Queue completion and
`submit_result` keep the attempt running; only the canonical accepted `finish`
reply proves terminal completion. Unknown effect or Inbox settlement refuses it.

These commands do not silently route to a local `ace-assign` cache. Missing or
changed installed owner selection is an explicit failure. Native wake consumers
must read the same canonical status and adopt its original attempt/result IDs.
Changed owner selection refuses new admission and dispatch until a controlled
restart. Existing canonical receipts remain the source for reconciliation.

## Error semantics

Errors are one deterministic JSON document on stdout plus a non-zero exit.

| Code | Meaning |
|------|---------|
| `missing` | No entry with that stable ID, or no capable service in the project |
| `ambiguous` | Several equally capable services without a configured `default_for` |
| `stale` | Binding is inactive, unattested, or the instance identity was replaced |
| `unauthorized` | Caller's verified local identity has no principal for the project |
| `invalid_configuration` | Topology config violates the schema; message is actionable |
| `invalid_input` | Service input or request ID is malformed |
| `invalid_attempt` | Assignment attempt is absent, unmanaged, terminal, or has a stale candidate head |
| `conflict` | Request ID is already bound to different input or scope |
| `evidence_unavailable` | Assignment evidence ref cannot be written or read |

Example:

    $ ace-lab resolve --id atlas-coder --format json; echo $?
    {"status":"error","error":{"code":"stale","message":"stable ID \"atlas-coder\" has a stale runtime binding; a replaced process must re-attest before routing","id":"atlas-coder","project":"atlas"}}
    1

## Configuration

Schema version 1, resolved through the ADR-022 cascade (project `.ace/lab/`
over user `~/.ace/lab/` over gem defaults; gem defaults are an empty, safe
topology). Cascade documents carry **topology only**:

```yaml
schema_version: 1
topology:
  projects:
    - id: atlas               # globally unique across all entries
      label: Display name     # display only; never resolves
  agents:
    - id: atlas-planner
      project: atlas          # must reference an existing project
      role: planner
      capabilities: [planning]  # non-empty; normalized (stripped, lowercased)
      binding:
        kind: runtime           # agents bind to runtimes, services to services
        state: active           # routeable only when active
        instance_id: i1         # runtime identity fact
        attested_instance_id: i1  # must equal instance_id to be fresh
  services:
    - id: atlas-search
      project: atlas
      capabilities: [search]
      default_for: [search]     # exactly one default may win among candidates
      endpoint:
        kind: http              # http or https
        url: "https://search.example.internal/query?token=secret"  # stored, never published
      binding: { kind: service, state: active, instance_id: i2, attested_instance_id: i2 }
```

### Authorization grants

Grants never live in the cascade: project and user documents are
caller-writable, so an `authorization` section there is rejected as
`invalid_configuration`. Grants come from a single deployment-controlled
file at the **fixed path** `/etc/lab/ace-lab/authorization.yml` (installed
by the `lab-config` deployment). The location is not caller-selectable --
there is no flag or environment override. At every query the tool verifies
the file and every directory on its real path are root-owned and not
group/world-writable, and opens the file `O_NOFOLLOW`; any failed
verification fails closed:

```yaml
principals:
  "<verified-local-uid>":     # passwd username or numeric uid of the caller
    projects: ["atlas"]
```

The grants file is machine-global: it is validated structurally only, so a
principal may reference projects absent from the current directory's
topology. Such grants are valid but never match a locally configured
project. All-digit principal keys are matched as uids only -- an all-digit
passwd username is authorized solely through its uid, so it can never
consume a different account's numeric-uid grant.

A missing trusted file means nobody is authorized (fail closed).

### Trusted service policy

The same deployment-owned file may contain `operations` and
`authorizations`. An operation names one exact project and stable service ID,
an executor OS UID, a valid lease, and either a fixed local argv or an absolute
Unix socket path. The domain deployment owns actual handlers and credentials.
The Unix service must authenticate the client's OS peer identity, validate
the exact authorization and current lease itself, and return a structured
receipt; ACE verifies the service peer UID before accepting that response.

```yaml
operations:
  forge-sync:
    project: atlas
    service_id: atlas-sync
    transport: unix
    socket_path: /run/lab/atlas-sync.sock
    executor_uid: 997
    lease_expires_at: '2026-10-02T16:00:00Z'
authorizations:
  DECISION:
    operation: forge-sync
    project_id: atlas
    assignment_id: A
    attempt_id: ATT
    input_digest: <sha256-of-canonical-json>
    target: { resource: forge/repository, artifact_digest: null }
    candidate_head: <exact-git-head>
    caller_uid: 1000
    expires_at: '2026-10-02T16:00:00Z'
```

The decision must match every listed field exactly and remain valid. A
decision never supplies missing executor capability or credentials. For
authenticated host maintenance, the policy also identifies an executable and
evidence sink outside the deployment being replaced; its domain handler must
enforce quiescence for all other product work. Environment `review-approval`
is a named operation and never substitutes for an independent code review.

Validation of the topology cascade rejects duplicate IDs (globally unique
across projects, agents, services), unknown project references, malformed
capabilities, defaults for undeclared capabilities, unusable endpoints
(absolute http(s) URL with a host and a port in 1–65535; `endpoint.kind` is
`http` or `https`), unsupported binding kinds, and principals referencing
unknown projects.

**Error messages are value-free by design:** validation runs before
authorization, so messages use positional field locations
(`topology.agents[0].project references an unknown project`) and never echo
configured IDs, project names, or principal names -- configuration defects
cannot disclose topology to unauthorized callers.

**Ownership:** deployed topology and authorization values are maintained by
the `lab-config` repository (`8wl.t.gad`). `ace-lab` defines the schema and
reads; it never provisions.

## Guarantees and boundaries

- Public output is built from a strict allowlist: `id`, `project`, `label`,

  `role`, `capabilities`, `default_for`, binding `kind` + availability state,
  and a sanitized endpoint identity. Tokens, auth-file paths, URL userinfo,
  paths, query parameters, fragments, pane/session IDs, and instance
  identities never appear in any command output.

- Caller identity comes from the verified local process owner

  (username or uid). `--role`, `--principal`, and `--caller` flags are
  rejected: authorization is a property of the caller, not an input.

- A replaced process keeps its stable ID; until re-attested, queries

  classify it `stale` -- an explicit unavailable result, never a routeable
  answer.

- No Works or scheduling. Service request claims and receipts use

  `ace-assign`'s evidence journal. The Lab execution binary
  (`/usr/local/bin/lab`) is never invoked or required.

### Protected handler cleanup boundary

Handlers retain the fixed closed environment and 30-second execution deadline, with 16KiB stdout and 8KiB stderr caps. Owned cleanup adds at most one second of confirmed reaping; unresolved cleanup remains uncertain and cannot return a service receipt. It cannot establish an arbitrary domain target or surviving writer is absent. The gad.b operation-specific fresh inspector remains required source work; installed verification is centralized in gad.2.

### Selected receiver no-effect recovery

The existing protected receiver exposes `recover_no_effect(binding:, input_bytes:, mutation_id:, expected_generation:)`. Supply the original assignment/attempt/candidate/head/request binding, original structured input, stable mutation ID and unchanged original positive authority generation. The receiver snapshots those inputs, authenticates canonical status and input before any settled return, and adopts an already accepted current challenge without claiming again. A needed claim uses the supplied generation unchanged. Lost acknowledgements remain uncertain; status retry never repeats the original effect.

Trusted operation configuration must provide a distinct fixed `no_effect_argv` for the original project/service/executor. Inspection may proceed after the effect lease expires, but it never renews effect permission or selects normal effect argv. The selected inspector must produce operation-specific original target/handler/writer observations and existing strict challenge-bound artifacts; only the authority's canonical import can establish `failed-settled`. This source API and controlled composition do not deliver the outstanding gad.b inspector or installed acceptance.
