---
doc-type: user
purpose: Fixed protected authority deployment and canonical launch lifecycle
ace-docs:
  last-updated: 2026-10-05
  last-checked: 2026-10-05
  subject:
    - code:
        diff:
          paths:
            - ace-assign/lib/ace/assign/authority/**/*.rb
            - ace-assign/lib/ace/assign/molecules/execution_scope_lineage.rb
            - ace-runtime/lib/ace/runtime/molecules/systemd_scope_manager.rb
---

# Protected native launch

`ace-assign authority serve --authority AUTHORITY` runs the standalone launch
composition. Lab owns the services composition using the same Assign server,
router, lifecycle, journal and endpoint. Its full-service startup guard remains
closed while required finish, recovery, inbox and no-effect handlers are incomplete.
The installed `composition` must match the entrypoint. A project has exactly one
configured authority owner; duplicate project owners or endpoints fail before
listener creation.

An administrator provisions `/etc/ace/assignment-authorities.json`. There is no
caller-selected configuration path or local fallback. The outer object contains
`schema: "ace.assign.authorities/v2"`, `authorities`, `projects`, and
`launch_mappings`; unknown fields are refused. The fixed schema is implemented
by `Ace::Assign::Authority::Deployment`:

| Installed object | Required fields |
| --- | --- |
| `authorities.ID` | `uid`, `gid`, sorted unique `groups`, `socket_path`, `state_root`, `composition` (`launch` or `services`) |
| `projects.ID` | `journal_repository`, `evidence_git_ref` (`refs/ace/execution`), `evidence_checkout_root`, `assignment_root`, `candidate_root`, `launcher_uids`, `reviewer_uids`, `worker_uids`, `service_executor_uids`, `supervisor_uids`, `peer_credentials`, optional `service_receivers` |
| `projects.ID.peer_credentials.UID` | `gid`, sorted unique `groups`, `scratch_root`; every configured role UID has one fixed entry |
| `launch_mappings.ID` | `project_id`, `authority_id`, `launcher_uid`, `launcher_gid`, `launcher_groups`, `worker_uid`, `worker_gid`, `worker_groups`, `worker_actor`, `worker_cwd`, `worker_entry`, `worker_env`, `bootstrap`, `bootstrap_sha256`, `native`, `execution_scope`, `task_context_entry` |
| `launch_mappings.ID.native` | `socket_path`, `executable`, `executable_sha256`, `version` (`0.9.3`), `protocol` (`22`), canonical `workspace_id` (`wN`) |
| `launch_mappings.ID.execution_scope` | `backend` (`linux_systemd_cgroup_v2`), `slot_id`, `slice_unit`, `service_unit`, `unit_manifest_sha256`, `boundary_manifest_sha256`, `root_directory`, `runtime_directory`, `network_namespace_path` |

A services composition requires a nonempty installed `service_receivers` map; launch composition may omit it. Each fixed service ID maps to exactly `{executor_uid, socket_path, staging_root}`. The positive nonroot executor UID belongs to the project's executor allowlist and cannot also be any configured authority, launcher, reviewer, worker or supervisor. This keeps kernel role selection unambiguous and private authority journals inaccessible to executors.

Receiver socket and staging paths are canonical absolute paths with root-or-executor owned, nonwritable ancestry. Staging is executor-owned mode0700 and disjoint from other receiver staging and authority state roots. The endpoint resides outside private staging, where the actual authority can traverse its ancestry and inspect it. A pre-existing endpoint must be an executor-owned socket with its installed GID and no permissions for others. Duplicate receiver/authority endpoints, substituted paths and unreadable placement refuse before the authority opens its listener or creates journal state. These mappings select identity and placement; operation argv and grants remain the existing Lab ServicePolicy.

All paths are canonical and absolute. The native socket identity is the observed
`[device, inode, worker_uid]`. The server identity is the exact observed object
`{pid, uid, gid, groups, parent_pid, started_at, host}`, where `started_at` is
`linux:BOOT_ID:START_TICKS`. These observations must be made after the root-owned
native service starts; they cannot be invented, copied from a previous boot, or
supplied by a worker. The immutable per-attempt native stage owns these facts;
the deployment record contains no persisted live server/socket tuple. A replacement
cannot be repinned into the original generation.
The root-installed native service, its executable, environment and configuration
are trusted. Merely running arbitrary worker-supplied server code under the worker
account does not meet this deployment contract.

The authority, launcher and worker are distinct non-root accounts. Authority
journal/cache/import/candidate/assignment/state roots are authority-owned 0700
with protected ancestry. Peer scratch roots are private to their mapped account.
The authority socket's directory prevents worker/launcher replacement; its group
and narrow installer ACL must permit the configured peers to connect. Native
socket ACL permits the trusted launcher to use the pinned Herdr API. The
bootstrap, payload executable, native executable, mapping and their ancestors are
root-owned and non-writable by the worker. Payload argv/cwd/environment are fixed
installed data; loader and interpreter injection environment fields are refused.

Linux Yama `ptrace_scope=2`, empty Inh/Prm/Eff/Bnd/Amb capabilities,
`NoNewPrivs=1`, fixed real/effective/saved/filesystem UID/GID and supplementary
groups are mandatory for every participant, including the pinned native server.
The shipped [native build/install instructions](../../ace-runtime/native/README.md)
describe architecture, distro dependencies, immutable artifact digest and service
unit requirements. ACE verifies and refuses missing policy; it does not modify
sysctls, create accounts, change another user's Herdr, or install service policy.

After installation, the trusted launcher preflights without any mutation or
native creation:

```sh
ace-assign authority launch --mapping MAPPING --dry-run
```

Launch one managed definition using a stable invocation ID:

```sh
ace-assign authority launch --mapping MAPPING --assignment ASSIGNMENT \
  --definition /absolute/prepared-definition.json \
  --prepared-bundle /absolute/prepared-input.bundle --step 010 \
  --base-head EXACT_40_CHARACTER_COMMIT --mutation INVOCATION_ID
```

The final definition (maximum 32 KiB) includes the exact `prepared_work` Git
head/tree, manifest and selected subtree reference, with matching `session_id`,
`task_id` and installed `project_id`. `--prepared-bundle` is mandatory: it supplies
the original complete prepared-input Git bundle, bounded to 64 MiB. Both inputs
are read from held regular files with bounded reads and no final symlink following
before launch effects. The authority derives the final definition from the verified
prepared tree and commits it with the exact received bundle in one journal mutation.
Reusing the same definition with different bundle bytes refuses. The owner-private
definition cache remains separate from the worker queue. An active attempt blocks
changed definitions. A fresh reservation creates canonical intent/provisioning,
then the owner activates and binds its independent parent under the slot exclusion.
It pins existing resource objects, the authority mount namespace and the installed
nsfs network namespace. Parent binding selects protected network evidence references
without asserting policy readiness or requiring an available report.

Native service admission is a separate private canonical CAS after all required
readiness evidence succeeds. Only its fresh winner may start the fixed service;
replay and lost replies never permit another start. Native and original-child
bindings remain separate immutable stages before payload release.

The original authenticated native layout response fixes workspace/tab/pane and
exact child lineage. Record captures that original child; bind creates the running
attempt without payload permission. The immutable native bootstrap connects once,
sets non-dumpable before admission, and waits for the separate release. Release
commits issuance before one framed permission. Replay returns canonical issuance
without sending another frame. Reply loss after issuance is potentially executed.
A worker-controlled native input/close path can deny or interrupt launch, but cannot
replace the authenticated origin or forge authority release.

Inspect or request exact native termination through the same installed mapping.
Once the original launcher process has exited, run these commands as a mapped
recovery supervisor with the installed native close ACL; a new process under the
launcher UID does not inherit the original launcher incarnation:

```sh
ace-assign authority status --mapping MAPPING --assignment ASSIGNMENT --attempt ATTEMPT
ace-assign authority terminate --mapping MAPPING --assignment ASSIGNMENT --attempt ATTEMPT
```

A child pidfd proving exit cannot release the whole parent reservation. The
connected never-native-admitted path seals the original parent before fixed service
stop, records fresh exact recursive-empty/no-pending/resource closure, selects that
canonical proof in the guarded pre-release abort, then privately commits reservation
release after service/inbox settlement at the same immutable journal commit. A lost
reply keeps the original accepted response. Restart can resume a missing private
release without issuing native or payload permission. A new reservation first retires
its exactly released predecessor through the same owner and slot exclusion.

`observe_execution_scope` is read-only. `close_execution_scope` is an ordinary
canonical mutation: the first fresh call seals, a later fresh call records closure
when verifiable. A fresh sealed close can resume a lost fixed service stop; replay
performs no manager I/O. The private `scope_service_admission` and
`scope_reservation_release` operations are absent from the public allowlist.
Reserve/close RPCs have a fixed 90-second ceiling for bounded manager waits;
other control calls retain their existing ceiling.

This source checkpoint proves the connected never-native-admitted failure/recovery
path with controlled native-owner observations and real canonical journals. Full
native hook/readiness and post-native writer observation, admitted-but-unbound
cleanup, non-abort terminal release, and complete original/candidate installation
maintenance remain separate required implementation work. The current maintenance
helpers do not yet implement the accepted candidate-deployment union contract.
No source fixture establishes installed namespace, network policy or containment
acceptance; every installed SC remains open.

Control replies are at most 16 KiB. Source-selected service transfer operations use
a 16 KiB authenticated header followed by bounded raw bytes, a shared 30-second
deadline, exact hashes, upload write-EOF and at most two active transfers. Exact
origin/role admission happens before private spool allocation and is revalidated
before canonical mutation. The standalone launch composition exposes no transfer
operations.

Source tests and Linux primitive fixtures are separate from installed deployment
acceptance. A Docker kernel with Yama=0 is expected to refuse the product gate;
it does not establish the required positive protected launch proof.

Protected launch uses only `layout.apply` in the installed workspace. `workspace.get` checks that exact workspace ID before creation; its reply must echo the ID even when another workspace is active. Missing or replaced containers refuse without fallback. Container contents supply no worker evidence. The original fresh layout reply remains the source of the new tab/pane identity.

Receiver admission reads Linux `system.posix_acl_access` on every directory from
the endpoint parent and private staging root to `/`, and evaluates search access
for the installed executor UID, primary GID and supplemental groups. Named user
entries override group/other entries; the ACL mask constrains named user and
group entries. Absence of an access ACL uses ordinary mode permissions;
unsupported, unreadable or malformed ACL data refuses startup. The authority
must also actually traverse the endpoint and staging parents. This inspection
does not claim an executor readiness handshake or bypass additional LSM policy;
the installed receiver still performs its own bind and private staging checks.

## Canonical result Client API

The source-owned services handlers accept a live mapped worker's bounded result
without terminalizing the attempt or releasing scope. The public seam is
`Ace::Assign::Authority::Client`; no result CLI is introduced. Launch-only
`attempt_status` retains its existing schema without a result selector. These
source handlers and their deterministic tests do not establish installed
full-service deployment acceptance.

From an admitted services attempt, discover its current candidate and authority
generation, then upload receipt JSON bytes followed by its declared artifact
bytes in order:

```ruby
require "ace/assign"
require "json"
require "digest"

client = Ace::Assign::Authority::Client.new(mapping_id: mapping_id)
binding = {"assignment_id" => assignment_id, "attempt_id" => attempt_id}
status = client.call("attempt_status", binding.merge(
  "result_candidate_generation" => nil
)).data
receipt_bytes = File.binread(local_receipt_path)
receipt = JSON.parse(receipt_bytes)
artifacts = receipt.fetch("artifacts").map { |ref| File.binread(ref.fetch("path")) }
params = binding.merge(
  "expected_generation" => status.fetch("authority_generation"),
  "candidate_generation" => status.fetch("result_candidate_generation"),
  "head" => receipt.fetch("head"),
  "receipt_sha256" => Digest::SHA256.hexdigest(receipt_bytes)
)
reply = client.call("submit_result", params, mutation_id: persisted_mutation_id,
  upload_parts: [receipt_bytes, *artifacts], purpose: :receipt_artifacts, timeout: 30)
result = reply.data
```

Only local byte strings cross the boundary; receipt paths are declarations, not
authority filesystem access. The authority checks exact canonical worker
attribution, original receipt digest and SHA256, candidate, native lineage and
current visibility. It normalizes artifact references and writes private
`result_submitted` metadata, imported blobs and a sanitized mutation reply in one
Git CAS. Failed results may have `artifacts: []`; no synthetic artifact is added.
Campaign receipts refuse until the trusted campaign owner is integrated.

Persist the exact params, mutation ID and ordered byte strings before submission.
An exact retry while the worker remains live and the attempt active returns the
same result without another import. A changed input or fresh mutation ID for the
same candidate conflicts. Correcting a result requires a new candidate generation
even at unchanged HEAD; both records remain immutable. Submission creates no
`receipt_accepted` event or terminal transition.

The reply contains result ID, head, candidate generation, verdict, ordered
canonical `{path, sha256}` references, generation and journal commit. Its
`uploaded_receipt_sha256`, `original_receipt_digest` and normalized
`receipt_digest` are distinct values. Private receipt, producer and process
binding are excluded from fresh and replay result replies.

After reply loss or worker exit, the exact owning launcher or mapped supervisor
can discover the retained result and fetch one referenced artifact:

```ruby
status = client.call("attempt_status", binding.merge(
  "result_candidate_generation" => retained_generation # nil selects latest
)).data
result = status.fetch("submitted_result")
if result && (reference = result.fetch("artifacts").first)
  fetched = client.call("evidence_fetch", binding.merge(
    "kind" => "result", "purpose_id" => result.fetch("result_id"),
    "artifact_id" => reference.fetch("path").delete_prefix("evidence/imports/")
  ), download: true, purpose: :artifacts, timeout: 30)
  artifact_bytes = fetched.parts.fetch(0)
end
```

Client closes its request write side for services status and evidence fetch;
Server refuses extra body bytes before exposing either read projection. Status
reads launch and result projections from one immutable canonical commit.
`authority_generation` is the current CAS generation; a known candidate without
a result has `submitted_result: null`. Unknown selected generation is `missing`;
corrupt or missing referenced provenance is `evidence_unavailable`. Disposable
caches and requester files never supply evidence.

Fetch returns exactly `descriptor`, `generation`, `journal_commit` and the
Server-generated `transfer` descriptor, with one binary part. Client validates
the closed canonical descriptor, exact selected purpose, one-part framing,
aggregate length and SHA256 before exposing bytes. Owning workers read only
their own results; assigned reviewers read their exact retained review and
same-candidate result under their live process binding; recorded executors read
only their own service evidence. Exact owning launchers and mapped supervisors
read permitted attempt evidence, including retained terminal history. Current
visibility and peer authorization apply to every read. Reassignment revokes the
old reviewer purpose. Inbox and observation evidence refuse until their existing
signer and observer owners provide complete canonical provenance.

The fixed worker entry is the closed `{interpreter: REF, wrapper: REF}` pair, with
exact path/bytes/SHA256 references (interpreter<=32MiB, wrapper<=1MiB). The
existing installed unit manifest associates the wrapper with `worker_executable`
and the interpreter uniquely with `runtime_dependency`. The wrapper is source,
so it need not carry executable permission; the selected interpreter must. The
original retained mapping pair is part of the authenticated compact release.
The native gate hashes held files, seals a readonly code snapshot, and uses the
fixed isolated Python FD4/FD5 command while preserving operational stdio. No
worker argv/shebang/PATH fallback remains. Native installed acceptance is separate.
