# Service-created resources — normative amendment candidate

2026-10-05. Draft for independent review against approved provisioning lineage
b6405f1bf, integrated main 31ce1349f. Source/document inspection only; no installed
claim, tests, probes or task promotion. This candidate supersedes only the stage
allocation of resource identities; every protected writer/resource obligation in
local-writer-boundary-proposal.md remains required.

## Ordering and exact schemas

The verified boundary manifest partitions the complete declared protected resource
set by creation lifecycle. Every existing backing root and immutable protected
ancestor is inspected before parent binding. A service-created resource must have
an exact fixed host path, in-unit view, creation directive and protected ancestor
in that manifest. The partition is derived from the authenticated fixed artifact,
not a caller-supplied omission list. No writable path may remain unclassified.

`scope_bound` additionally records `resource_mount_namespace_identity`, exactly
`{device, inode}` from its own opened `/proc/self/ns/mnt` object. This is
truthfully the authority resource-observation namespace, not a claim about PID 1
or an inferred globally shared host namespace. Together with parent `boot_id`,
it identifies every parent `mount_id`. The verified root-installed authority
profile exposes precisely the manifest backing paths/ancestors; actual open-object
observations and the cross-view join below establish those mappings. The
authority pins its namespace/object handles during observation; it needs neither
`/proc/1/ns/mnt` access nor CAP_SYS_PTRACE.

`scope_bound.resource_identities` contains the existing backing roots and protected
ancestors, using the unchanged closed identity object
`{host_path, view_path, mount_id, filesystem_type, device, inode, uid, gid}`.
An ancestor entry represents that ancestor itself; it never claims a future leaf
inode. The complete existing set must be present before service activation.

`scope_native_bound` becomes exactly
`{scope_generation, scope_binding_event_id, service_invocation_id,
server_identity, socket_identity, workspace_id, mount_namespace_identity,
resource_observer_identity, resource_identities}`. `mount_namespace_identity` is exactly `{device, inode}`
from the same-User readiness hook's opened mount-namespace object of the already authenticated native server
whose exact kernel identity is `server_identity`; the existing parent `boot_id`
and native binding event identify its origin. Namespace identity is observed and
pinned with that server, never supplied by the caller or taken from a same-PID
replacement. Every native `mount_id` belongs to this namespace.
Its resource array uses the same closed identity object and covers every declared
worker-visible resource view, including bind projections of parent-pinned roots
and views of service-created roots. Parent-only protected ancestors do not need a
worker-visible projection unless the fixed manifest declares one. Parent
`host_path` resolves the actual backing object in the host namespace; its
`view_path` is the manifest's intended service mapping, not a claim that the
service view exists yet. Native `host_path` names that same manifest backing path,
while native `view_path` resolves the actual object in the exact server namespace.
No mount ID is compared across namespaces or used as a global identity.

The union is a manifest-indexed join, not concatenation followed by pathname
uniqueness. The same `{host_path, view_path}` pair in parent and native arrays is
required for an existing root's genuine bind projection. Within each stage a
manifest role/view occurs exactly once; extra entries, conflicting duplicate
roles and undeclared cross-root aliases refuse. Legitimate declared projections
of one root are verified separately; they cannot grant a second slot access.
For an existing backing root, parent host observation and native view must agree
on `device`, `inode`, `filesystem_type`, `uid` and `gid`; their mount IDs may differ
and remain namespace-local. Fresh host revalidation must still match the parent
identity. For a service-created root, fresh host and service-view observations
must likewise agree on those five fields before its native entry is committed;
there is no fabricated parent leaf entry. Fixed manifest bind/mount projection
and namespace mount topology must positively explain each view, including bind
source/subtree, mount flags and absence of foreign writable substitutions. Equal
inode/device alone is insufficient. Ownership/mode changes that invalidate parent
identity or boundary refuse. The validated join covers the complete declared
backing, ancestor and writable-view set before payload release. An empty native
array is legal only when no worker-visible resources are declared. Missing,
aliased, replaced, incorrectly owned or foreign-mounted objects refuse native
binding and release. Native readiness and 09j original-child verification remain
unchanged.

RuntimeDirectory's fresh leaf belongs to the native array, while its installed
non-writable host ancestor belongs to the parent array. Existing private scratch,
checkout/Git metadata and harness/cache/output backing roots remain parent entries;
service activation must not create or repair them implicitly. Private temporary
and namespace views created during activation belong to the native array. Any
StateDirectory/CacheDirectory/LogsDirectory directive must refer only to already
prepared, verified parent resources; it cannot silently populate the late-created
set or restore prior worker startup content. Their ownership/mode changes must
also pass native boundary revalidation. This preserves the full usable harness
profile and does not permit a new provisioning controller or arbitrary OS verb.

No event is retrofilled. A native event references the exact original parent and
cannot replace its resources; native-stage replay returns that immutable event.
Readers derive the complete union only from the same canonical lineage, never
from current-path discovery. A missing native stage means no leaf identity was
admitted, not null fields, compatibility repair or permission to release.

## Existing readiness hook as the bounded observer

The fixed root-installed same-User ExecStartPost action observes the exact native
server through `/proc/<pid>/root`, `/proc/<pid>/mountinfo` and `/proc/<pid>/ns/mnt`.
It observes the server namespace, never substitutes its own per-command namespace.
No setns, ptrace attach, new capability, privileged prefix, native API extension
or additional controller is permitted. The action opens/pins server root and
namespace objects and checks the supplied exact server kernel birth/credentials
before and after the bounded object/topology observations; PID reuse, server
replacement, lost handles or access denial refuses readiness. Resource paths
remain fixed manifest inputs, not caller paths.

This READ_FSCREDS route requires the original native baseline's real/effective/
saved UID/GID to match the hook filesystem UID/GID, dumpable=1, the approved empty
capability sets, and installed proc/LSM access permitting these reads. Ordinary
unprivileged non-setuid/non-file-capability native exec is the supported baseline;
no dumpability/security setting is changed to obtain access. The worker gate's
separate non-dumpable condition remains intact. Enforced Yama=2 continues to deny
same-UID ATTACH/control; its kernel hook does not itself deny READ mode. Source
inspection found no dumpability/credential-changing operation in pinned Herdr
7b116c05bfda646af39d2524c54e70c751f57ee8 src. This is feasibility evidence only:
the installed artifact/profile and successful permitted reads must be verified,
not inferred from that absence. Failed reads cannot be repaired by relaxing Yama,
proc policy, credentials or adding capabilities.

The existing authenticated canonical authority endpoint gains a private readiness
exchange for this fixed hook, not a worker-callable admission verb. While that
exact fixed service is activating, authority authenticates the connected hook's
kernel PID/UID/GID/birth and same-parent membership against the system manager's
current exact service InvocationID and ExecStartPost ControlPID. The verified
fixed unit/artifact identifies the only permitted action. Same UID alone is
insufficient. The authority then supplies a fresh connection-bound challenge
and its already observed original server kernel identity plus exact manifest
selection. The hook replies on that authenticated connection with challenge,
server identity, server namespace identity, bounded resource observations and
bounded mount projection facts. Before accepting the reply, authority repeats
hook ControlPID/birth/membership and original server birth/incarnation checks.
Malformed, oversized, wrong peer/challenge/lineage or delayed post-activation
reports refuse. Only fixed baseline/hook processes can run at this phase; no
payload, restored sessions, extensions or outside same-UID executors may exist.

The report is an ephemeral observation input, not a journal/store or a reusable
file in worker-writable storage. Authority independently observes backing objects
in its own namespace and checks the complete join against the authenticated hook
report and fixed installation. It commits `scope_native_bound` only after that
same activation successfully completes and it independently verifies native
endpoint/readiness and unchanged server identity. The existing native payload
additionally records `resource_observer_identity` using the existing closed kernel
process identity schema, capturing the authenticated original hook origin. The
challenge is not durable authority and is not a replay token. Lost report,
authority restart before commit, hook/activation failure or seal means no native
binding; exact held-parent cleanup remains available without repeat activation.
After commit, replay reads the immutable canonical native event; the departed hook
and its old proc namespace need not still be live. This readiness snapshot never
replaces later boundary revalidation or whole-parent closure.

## Closed readiness exchange and activation ordering

Use the existing v1 Authority Server envelope and socket only. Add two fixed
source-owned private operations, `scope_readiness_challenge` and
`scope_readiness_report`; both require `mutation_id: null`. They are not public
worker operations. Before ordinary role dispatch, Server recognizes only these
operation names and applies the fixed mapping's same-User readiness admission:
live exact authenticated kernel peer equals the current system manager
ExecStartPost ControlPID, exact original service InvocationID, same recorded
parent membership and verified ExecStartPostEx installed command/configuration.
No caller role, PID, UID, path, executable or process binding is accepted. The
internal readiness role may dispatch only this exchange, never other owner APIs.
An absent/pending/replaced ControlPID or ambiguous fixed hook refuses.

Challenge params are exactly `{mapping_id}`. Existing project_id must select that
mapping. The existing scope owner resolves its single canonically bound, unsealed,
currently activating parent/attempt for this mapping; no caller chooses attempt.
Successful data is exactly `{challenge, assignment_id, attempt_id,
scope_generation, scope_binding_event_id, service_invocation_id, server_identity,
boundary_manifest_sha256, deadline_ms}`. Challenge is 64 lowercase random hex
characters, single-use and bound to this authenticated connection, peer birth,
parent event and activation incarnation. IDs/digests/process identity retain the
existing canonical bounds; deadline_ms is a positive remaining duration <=10000.
The hook's immutable local manifest must match that digest. No filesystem paths
or manifest edits arrive over the exchange.

Report params are exactly `{mapping_id, challenge, scope_generation,
scope_binding_event_id, service_invocation_id, observation_sha256, transfer}`.
Selectors must equal the connection's outstanding challenge. The source-owned
transfer purpose `scope_boundary_observation` uses the existing strict Transfer
codec with exactly one nonempty UTF-8 JSON part <=64 KiB; recomputed raw SHA256
must equal observation_sha256. Existing 16 KiB control-header/response bounds
apply. No extra part, trailing byte, missing write-EOF, duplicate JSON key,
unknown field or numeric coercion is accepted. The required construction
uses one connection for both frames and a report-body half-close after the second
frame; separate connections or reusable session tokens are forbidden. Server must explicitly implement this private two-frame branch rather than
assuming ordinary one-request dispatch supports it.

The report object is exactly `{server_identity, mount_namespace_identity,
resource_identities, mount_projections}`. Resource and namespace objects use the
schemas above; server_identity must equal the challenged exact server.
resource_identities has 0..64 entries; zero is valid only for the exact empty
worker-visible resource set allowed above. mount_projections has one entry per native
resource view, exactly `{host_path, view_path, mount_id, mount_root, mountpoint,
read_only, source_device, source_inode, filesystem_type}`. Paths are canonical
absolute strings <=4096 bytes, integers are nonnegative (mount_id positive),
read_only is boolean, filesystem_type is nonempty ASCII <=64 bytes. Each entry
must match that resource and fixed manifest's intended backing subtree, mount
flags and server-namespace mount topology. No caller-supplied topology bypasses
host-object join. Arrays/encoded total size are hard bounds; oversized valid
profiles refuse installation rather than truncate proof. Source-selected maximum
10 seconds covers challenge, observation, upload and acknowledgement; normal
StartUnit timeout must exceed this plus its existing bounded startup/readiness
budget. No timeout retry starts a second service or repeats layout.

Successful report acknowledgement data is exactly `{accepted: true,
scope_generation, scope_binding_event_id, service_invocation_id,
observation_sha256}` with `replayed: false` in existing transport. It means pending
observation received/validated, never native binding, worker release or positive
closure. Existing errors apply: malformed/bounds invalid_input; wrong peer or
mapping unauthorized; stale/sealed/conflicting challenge conflict; inaccessible
objects, missing origin or incomplete observation evidence_unavailable. Errors
contain fixed sanitized reasons, no filesystem/process dumps. Challenge/report
never writes a canonical mutation reply and mutation replay is inapplicable;
duplicate frame/challenge use conflicts and cannot yield a second observation.

Ordering is mandatory: (1) owner records canonical parent and admits one exact
activation under lifecycle exclusion, marking that activation pending; (2) owner
releases assignment/qjl/owner locks before blocking StartUnit; (3) Server callback
revalidates canonical parent/seal and exact manager peer/incarnation, validates
report and acknowledges pending input without waiting for StartUnit completion
or acquiring a lock held by its waiter; (4) hook receives matching acknowledgement
and exits success; (5) StartUnit completes; (6) owner reacquires exclusion/CAS,
rechecks unchanged parent/seal, completed activation, server/native endpoint and
full boundary, then commits the immutable native event. Callback performs no
native/journal commit. The scope owner's pending activation and bounded report
are transient coordination inputs to this one lifecycle, not independent durable
authority. Seal may win at any point: no native commit/release; admitted activation
is cleanup work until stopped/settled, and close cannot assert empty while it or
its fixed cleanup remains pending.

Hook must exit nonzero on lost/error/mismatched acknowledgement or deadline.
Owner must not accept completed activation without its matching validated report.
Connection loss, lost acknowledgement, owner restart or crash before canonical
native commit discards pending report/challenge and leaves the exact bound parent
held; no callback replay/restart creates native provenance. Cleanup can close
that known parent through the approved pre-release path. After canonical commit,
only the immutable journal event replays, never this ephemeral exchange.

## Closure, cleanup and reuse

Before native binding, closure still seals the exact recorded retained parent,
settles pending activation, stops its service/descendants and verifies recursive
population zero. It revalidates the pinned parent resources and immutable
ancestor/access/namespace installation that restrict every possible service-created
resource to this generation's writer boundary. Current leaf inspection may detect
conflict or outside-write access, but cannot invent historical native identity.
A failed/lost start or readiness reply is therefore cleanup of a known parent,
not an unexplained outside generation. Unknown parent origin remains held.

Systemd-owned directory setup/removal must be finished, with no admitted/pending
activation or cleanup job that can later write the protected set. Root/system
manager is the already trusted fixed lifecycle owner, not an untracked payload
writer. A late-created persistent backing root, unexpected retained runtime leaf,
foreign writer, changed ancestor or unverifiable cleanup refuses positive closure.
RuntimeDirectoryPreserve=no and Restart=no are verified fixed requirements. The
runtime leaf may be absent after completed stop; absence never proves closure.
If native binding exists, its historical leaf identity remains immutable and
service-owned removal is checked against that fixed lifecycle; same-path
replacement or conflicting retained leaf refuses. Retained exact parent identity,
seal and empty-population proof remain mandatory even when the runtime leaf or
stopped service metadata has disappeared.

The positive close payload remains unchanged. Closure does not assert filesystem
durability or cancellation of remote effects. Existing service/inbox settlement,
guarded pre-release abort and canonical release-before-reuse remain separate
requirements in the same owner/CAS path. Only after those checks may the next
reserved generation recreate its fresh runtime leaf; old inode identity is never
adopted or copied into the next lineage.

## Required implementation and fixture map

* Manifest verification: exhaustive lifecycle partition; reject omitted writable
  roots/views, duplicate/overlapping aliases, runtime ancestor writable by workers,
  preservation/restart changes and implicit persistent-root creation.
* Parent bind: authority observation namespace identity and existing roots/ancestors positively
  pinned, nonexistent runtime
  leaf does not require a fake inode; unexpected pre-existing leaf refuses start.
* Native bind/reader: exact server mount namespace and fresh runtime/view
  observations form one immutable
  native resource array; exact union required before layout/release. Reject
  missing/extra identities, resource substitution and cross-lineage replay. Test
  legitimate same-pair cross-stage bind projections with unequal mount IDs; reject
  namespace replacement, wrong inode/device/filesystem, unexplained mount topology
  and duplicate roles within a stage. Never compare mount IDs across namespaces.
* Lost start/readiness: no native event fabricated; known parent can close after
  verified fixed cleanup, empty retained parent and settled effects. Unknown
  parent, pending cleanup/activation and outside-writer conflict remain held.
* Hook provenance: same-UID passive reads with Yama=2 succeed in the supported
  fixture; denied proc/LSM or non-dumpable server refuses. Wrong ControlPID/birth,
  unrelated same-UID reporter, stale challenge, replacement server, own-namespace
  substitution and late report refuse without canonical native binding.
* Stop/reuse: native-bound leaf removed by completed fixed stop is compatible
  with whole-parent proof; absence alone, replacement leaf and persistent late
  root are negative cases. Release then fresh next-generation inode succeeds.
* Restart reconstruction: parent-only and full-lineage records retain their exact
  immutable sets; no live socket/leaf is required to replay old canonical facts.

## Primary semantics inspected

[systemd v257 execution source](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.exec.xml)
defines directory creation at unit execution, host-backed views under RootDirectory,
runtime leaf removal on stop, persistent state/cache/log directories, ownership
adjustment and RuntimeDirectoryPreserve. These justify stage timing only; they do
not prove an installed profile, completed cleanup or writer absence. All such
claims require the existing authenticated owner and boundary observations.

[Linux v6.12 ptrace access source](https://raw.githubusercontent.com/torvalds/linux/v6.12/kernel/ptrace.c)
and [Yama source](https://raw.githubusercontent.com/torvalds/linux/v6.12/security/yama/yama_lsm.c)
distinguish same-credential/dumpability READ checks from Yama ATTACH restrictions.
[proc root semantics](https://man7.org/linux/man-pages/man5/proc_pid_root.5.html)
provides the target process's filesystem/mount view;
[namespace semantics](https://man7.org/linux/man-pages/man7/namespaces.7.html)
defines namespace handles and READ_FSCREDS access. Kernel/profile equivalence on
the installed supported platform remains acceptance work.
