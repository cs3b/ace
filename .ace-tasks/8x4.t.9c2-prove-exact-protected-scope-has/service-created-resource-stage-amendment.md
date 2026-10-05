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

`scope_bound` additionally records `host_mount_namespace_identity`, exactly
`{device, inode}` from the opened host mount-namespace object. The authority must
positively verify that its resource observation namespace is the installed system
manager host namespace; a private authority namespace cannot silently substitute.
Together with parent `boot_id`, this identifies the namespace of every parent
`mount_id`. Host namespace/object handles remain pinned during observation.

`scope_bound.resource_identities` contains the existing backing roots and protected
ancestors, using the unchanged closed identity object
`{host_path, view_path, mount_id, filesystem_type, device, inode, uid, gid}`.
An ancestor entry represents that ancestor itself; it never claims a future leaf
inode. The complete existing set must be present before service activation.

`scope_native_bound` becomes exactly
`{scope_generation, scope_binding_event_id, service_invocation_id,
server_identity, socket_identity, workspace_id, mount_namespace_identity,
resource_identities}`. `mount_namespace_identity` is exactly `{device, inode}`
from the opened mount-namespace object of the already authenticated native server
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
* Parent bind: host namespace identity and existing roots/ancestors positively
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
