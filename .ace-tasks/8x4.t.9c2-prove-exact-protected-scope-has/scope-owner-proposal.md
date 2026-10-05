# 9c2 scope owner proposal — dedicated reusable Herdr slots

Proposal for independent readiness review, 2026-10-05, based on ACE
`8b01f992b` and the retained pinned upstream research. Task remains draft /
needs_review pending whole-task independent specification review. Dedicated
worker Herdr, a separate persistent overseer and bounded outside capabilities
are the engineering baseline within the authorized program. The earlier optional
preference question can steer this baseline; silence is not an approval record
and creates no additional permission gate.
This document specifies required results of **9c2**, not future orphan work.
No implementation, native experiment, privilege/auth change or installed proof
was performed. The recorded automatic-filter restriction still applies.

## Proposed product boundary

One installed execution slot runs one protected attempt at a time. Its entire
Herdr server, baseline native container and every pane/descendant belong to that
attempt's protected scope. Closing the attempt stops that server. A later attempt
automatically starts a fresh server/scope generation in the same fixed slot after
the old attempt is positively empty and canonically released. This is continuous
operation through installed units, not manual per-attempt reinstall.

The operator/overseer Herdr servers remain separate long-lived services. Protected
workers cannot attach to them or write their files. Parallel protected attempts
use different slots and dedicated worker principals. Sharing one worker UID across
simultaneous writable domains is refused by this proposed profile; it is not
silently satisfied by UID-wide kill. If concurrent attempts in a persistent shared
worker server are mandatory, reject this proposal and select authenticated native
per-attempt spawn routing or a separately reviewed stronger isolation boundary.

## One existing OS owner

The **system systemd manager** owns every cgroup. ACE does not write cgroup.procs,
cgroup.kill or create delegated cgroups. Each fixed slot has a root-installed
`.slice` and one fixed root-installed Herdr `.service` below it. The authority
observes the parent slice's recursive cgroup.events; it asks systemd to stop the
child service. The parent stays active and retains its process-free cgroup until
9c2's positive proof is canonically recorded and the consuming lifecycle releases
the old attempt. This avoids a new supervisor daemon or second journal.

The service profile explicitly disables automatic restart, restart-force statuses,
socket/path/timer activation, restoration/handoff from a previous generation and
dependency-triggered restart. It uses full control-group termination with final
kill enabled. The parent slice has StopWhenUnneeded disabled and is not stopped as
a side effect of stopping the child. Unit/config/native files remain installer
owned; workers have no unit management or cgroup write authority. No unrelated
unit is placed below this slice.

The parent has a fixed Wants reference to its one service, retaining the service
unit metadata while the parent is active. It has no Requires/BindsTo/PartOf edge
that stops the parent when the service stops, and no Upholds edge that restarts
the stopped service. Starting the fresh parent may therefore start its configured
child; authority accounts for that fixed dependency in its provisioning job,
not a competing second activation. Exact dependency/GC behavior is part of
installed acceptance, rather than reliance on an authority D-Bus Ref lost when
the authority exits.

The existing authority principal receives noninteractive OS authorization for
only **StartUnit/StopUnit of the exact installed slice and service names**. No
wildcard transient unit creation, caller argv, SetProperties, daemon reload,
arbitrary unit selection, root shell, or broader manage-units permission is
granted. Public mapped launchers/supervisors call the existing authority; they do
not receive direct systemd privileges. The authority resolves all unit names from
the installed map, serializes their transitions in its existing lifecycle and
journal, and uses bounded OS jobs. A permission failure is unsupported/refusal.

This is an explicit new narrow installed OS permission, not an assertion that
today's authority already has it. systemd's polkit path exposes unit and verb
details; this supports the proposal but the actual rule must still be independently
tested for exact allow/deny behavior in a permitted environment.

## Fixed deployment map and generation records

Propose `ace.assign.authorities/v2`, replacing the old protected mapping contract
without a v1 compatibility path. Existing project/role/principal/root mappings
continue as fixed installation inputs. The launch mapping's native object becomes
exactly:

```text
{socket_path, executable, executable_sha256, version, protocol, workspace_id}
```

`workspace_id` is the fixed native container for a fresh slot (proposed `w1`), not
a search/current-workspace selector. Its actual returned identity is independently
matched during provisioning. The mapping adds exactly:

```text
execution_scope: {
  backend: "linux_systemd_cgroup_v2",
  slot_id, slice_unit, service_unit,
  unit_manifest_sha256, boundary_manifest_sha256,
  root_directory, runtime_directory, network_namespace_path
}
```

All paths/unit names are installer supplied, closed schema, canonical and bounded.
`unit_manifest_sha256` binds the exact root-owned unit fragments/drop-ins,
fixed executable/setup artifacts, native config, argv/env, placement and lifecycle
properties. `boundary_manifest_sha256` binds the actual filesystem/socket/network
profile described below. These manifests are verifiable installation inputs;
a claimed hash alone is never proof. Map validation rejects role collapse,
duplicate slot/unit ownership, overlapping writable slot roots, shared protected
worker principals and any mapping to the overseer's persistent units.

The map no longer stores a forever-valid server PID/socket inode. A canonical
scope-generation record instead pins observations established for that attempt:

```text
{project_id, assignment_id, attempt_id, mapping_id, slot_id,
 reservation_generation, scope_generation, deployment_digest,
 boot_id, slice_invocation_id, service_invocation_id,
 cgroup_identity: {path, mount_id, filesystem_type, device, inode},
 server_identity, socket_identity, workspace_id, original_process_binding,
 resource_identities: [{host_path, view_path, mount_id, filesystem_type,
                        device, inode, uid, gid}]}
```

`scope_generation` is the canonical binding event's journal generation in this
attempt chain. Full identity includes project/assignment/attempt/slot and manager
incarnations; the integer alone is never compared across unrelated attempts or
used as a globally unique slot counter. Invocation IDs come from the authenticated system manager, server identity
from MainPID plus the existing kernel PID/UID/GID/groups/birth/parent policy, socket
identity from the authenticated peer and fixed endpoint object, and original
process binding from 09j's genuine fresh layout reply and gate. Native version,
protocol and executable digest must match the installed artifact. The service
must belong to the installed slice; server and gated child must be observed in
its cgroup subtree before release. The cgroup object is opened and pinned during
live observation; a same-name replacement is not adopted. resource_identities
pin each declared protected root object before payload release. The immutable
ancestor/access policy comes from the verified boundary manifest; mutable worker
file modes are not mistaken for immutable installed policy. Alias/foreign mount,
root object replacement, changed ownership or an outside writer refuses proof.

The v2 change requires adapting 09j's existing source checks to a **canonically
admitted generation**, while retaining its fresh-pane, exact original child,
distinct-user gate and no retry-after-unknown-create invariants. A caller may not
supply server identity or choose a new generation. This compatibility adjustment
belongs to 9c2; it is not delegated to xz9.0/xz9.2 or a new prerequisite task.

## Sustainable admission and closure

1. **Reserve before OS start.** Under the existing project/task/attempt exclusion,
   reserve the installed slot and record provisioning intent in the canonical
   chain. If any prior attempt remains active/uncertain or lacks required positive
   closure, return conflict. No worker payload is running yet.
2. **Start a fresh generation.** Verify immutable installation and idle slot.
   For a previously used slot, only after its old attempt was positively empty
   and released, stop the old retained slice and start the slice/service anew.
   Use only fixed units. Pin the new InvocationIDs, cgroup object and native
   identity before admitting it. Ambiguous/lost OS-start reply is inspection of
   the reserved slot, not a second start; unexpected running generation refuses
   adoption. An acknowledged start with unavailable exact origin remains held.
3. **Provision native readiness.** Fresh runtime/session storage cannot restore
   worker-writable prior config, rc, plugins, panes or agents. Fixed startup
   settings/container creation establish the known workspace baseline inside the
   scope before 09j's layout call. Baseline shells/processes are explicitly part
   of this scope and teardown, never mistaken for the gated worker. Only the
   fresh original layout child obtains release. This is native generation setup,
   not a fallback workspace.create during the existing launch call.
4. **Run.** Admission checks include exact current slice/service/native/object
   identities and boundary verification. All native-created processes inherit
   the scope because the native server is inside it. Original child exit alone
   produces no positive cleanup proof while any scope process is live.
5. **Seal first.** Authenticated close request records `scope_sealed` with the
   exact generation under CAS before requesting service stop. From that canonical
   point the authority never releases a worker, starts/restarts the service or
   admits another attempt into that old generation. The public close operation
   does not finish the attempt. Workers cannot reach another admitted spawner.
6. **Stop and observe.** Existing authority asks the sole OS owner to stop the
   service, including server, baseline and descendants. A successful job, dead
   MainPID, pane disappearance, inactive/failed status or vanished child cgroup
   is insufficient. Revalidate exact retained **parent** slice object and read
   its populated value as zero, with no activation job/new incarnation and the
   original seal still current. An unkillable remaining process preserves held
   ownership. Parent remains active until proof and lifecycle release are durable.
7. **Record and consume.** Existing canonical journal records a verified
   `scope_closed_no_writers` observation referencing generation binding, seal
   event and owner/kernel observation. xz9.0/xz9.2 resolve that exact proof under
   their existing exclusive lifecycle/CAS and continue their own independent
   service/inbox/result conditions. 9c2 does not terminalize or settle effects.
   A stale CAS revalidates scope identity/closure before another admission.
8. **Reuse.** Only after canonical release may authority retire old slice and
   automatically start the next fresh generation. The old generation stays
   closed forever. Path/slot reuse is legitimate only with a new record; it never
   changes historical origin or allows old proof to authorize the new attempt.

Proposed private positive event payload is exactly
`{scope_generation, scope_binding_event_id, seal_event_id, boot_id,
slice_invocation_id, service_invocation_id, cgroup_identity, populated: 0}`.
The event is a new registered observation in the existing canonical chain, not
an accepted current event type or a new store. Binding/manifest/native/original
child details are resolved through scope_binding_event_id; the owner revalidates
them and the seal under lifecycle exclusion when building the event. Caller
JSON cannot submit this event or an asserted populated value. Its canonical
event ID becomes proof_id. Owner-observed identity/data, chain integrity and
admission exclusion carry evidence; a timestamp or metadata hash does not.

Seal means irreversible **admission closure for that incarnation**. Forks may
continue within the closing scope until stop completes; a sealed-but-populated
scope is not closed_no_writers. This avoids pretending that an ordinary kill,
freeze, empty reading or static unit setting is an independent seal primitive.

## Public owner interface and restart behavior

Proposed developer/agent interface uses existing Authority::Client/Server framing.
`observe_execution_scope` is read-only; exact params are
`{mapping_id, assignment_id, attempt_id}` with null mutation ID and no transfer.
`close_execution_scope` has those params plus `expected_generation`, with the
existing non-null mutation ID. Only the exact recorded live launcher or mapped
live supervisor may close/observe. Neither request takes raw unit/path/PID,
scope-generation override or a worker absence assertion.

Observation data is exactly
`{attempt_id, scope_generation, state, proof_id, required_action, generation,
journal_commit}`. `state` is running, closed_no_writers or unverifiable;
`proof_id` is null unless a verified canonical no-writer event exists for this
generation. `required_action` is exactly null for closed_no_writers, close_scope
for running or sealed-empty-without-recorded-proof, and inspect_exact_scope for
unverifiable identity/boundary evidence. Native/kernel/private manifest
details stay in owner records. Close returns the same bounded projection; it may
return running while OS stop is pending. Close is explicitly two-phase in this
bounded interface: the first mutation seals and records its running reply before
the owner requests stop; a later fresh close mutation, with current expected
generation, revalidates the already sealed scope and records positive empty
proof when available. It never reseals/reopens the generation. Read-only polling
cannot manufacture a proof event; empty sealed scope with no canonical positive
event reports unverifiable with required_action close_scope. There is no new
background owner or hidden query-side journal mutation. Malformed request is invalid_input,
wrong peer unauthorized, stale/occupied generation conflict, missing attempt
missing, unsupported/unreadable owner evidence evidence_unavailable. A valid
observation that can inspect a known binding but cannot verify its current scope
reports unverifiable and preserves ownership.

Lost close reply rereads canonical seal and the same manager job/generation; it
never opens or starts a scope. Exact same-ID replay returns its original
committed projection, which may be running; it does not change that old reply
into a later proof. Consumers obtain current read projection and, if needed,
use a fresh close mutation to complete verification. Repeating StopUnit for the same sealed service is
permitted only after exact generation verification, is idempotent OS cleanup, and
cannot repeat effectful service work. `mutation_id` replay has normal exact-param
rules and current peer/visibility checks. After a crash between seal commit and
OS request, the fresh close owner may resume the same exact stop job or idempotent
StopUnit; after the service is already stopped, it only verifies/records proof.
A close mutation's CAS retry revalidates the exact seal/object and cannot
terminate a new generation. Read-only observation records nothing; positive
observation uses the existing canonical mutation boundary.

After authority restart on the same boot, reconstruct binding and seal from the
canonical chain, verify the installed manifests and current system manager,
reopen the exact active parent slice, compare InvocationIDs/object identity and
read population again. Missing in-memory descriptors alone need not make a
retained exact slice unverifiable. Missing/replaced slice, changed native/service
generation, identity mismatch or denied read does. Unsealed native restart is not
a new allowed worker origin. Manager reexec/restart must retain matching unit
incarnation and object or refuse. Boot change without previously committed
closure gives no new positive proof; ownership stays uncertain. A previously
terminal canonical record can replay retained historical proof after later slot
reuse; it cannot produce a fresh positive decision for an unreleased attempt
from a filesystem cache. Corrupt canonical proof/lineage refuses replay.

## Outside spawners and writable files

Whole-server membership closes the evidenced Herdr external-child gap only for
the dedicated native server. It does not close arbitrary host control surfaces.
The proposed installed worker profile therefore needs an enforced minimal mount
root, fixed read-only binaries/native config, distinct slot UID, no login/SSH/user
manager/cron entrypoint for that UID, no cgroup delegation, no effective/bounding
capabilities, existing NoNewPrivs/Yama policy, denied namespace creation, and
private IPC/network namespace. A preinstalled NetworkNamespacePath can retain
necessary routed provider egress without introducing an application broker.
Host abstract Unix sockets must be absent from that namespace; hiding filesystem
paths alone is insufficient. These are required profile results, not installed evidence. The concrete local
resource set, usable Codex/Pi profile, OS permissions and outside-effect boundaries
are specified in local-writer-boundary-proposal.md.

Only this slot's native control socket and the canonical authority endpoint are
mounted into the minimal root. Docker/Podman/Incus sockets, user/system bus,
outside Herdr client/API sockets, SSH agents, mutable plugin paths and host
credential helpers are absent. An allowed provider endpoint cannot hold a
credential or mount that lets it write the local slot tree. Network routes/firewall
must deny reachable host/internal process-control services. Exposing a new
spawner fails readiness unless its writes are exhaustively accounted inside this
same scope or through a separately canonical bounded service effect.

The worker can write only its mapped scratch/candidate worktree and private temp
roots; all belong to this exclusive slot domain and are outside canonical
authority/evidence storage. Other attempt UIDs and persistent overseer services
cannot write them. Each native baseline/default-shell startup reads only root-owned
fixed home/config; mutable prior scratch cannot execute before gate release.
Open descriptors, inherited environment, bind mounts and network filesystems
must be included in the profile; permission-path descriptions alone do not prove
the boundary. Service executor staging/effects remain separately owned under
the existing family contract. Killing this scope cannot falsely settle them.

This profile is materially stricter than lab-config's present writable `/lab`
and user home units. It may constrain worker SSH, local containers, host terminals
and credentials. Those capabilities require explicit mapped services or another
chosen design; silently exposing their sockets would invalidate the proposal.

## Generic ACE and Lab installer responsibilities

**9c2 / generic ACE** owns the closed map/manifest and generation contracts,
system-manager/native observation integration, public owner calls, lifecycle
admission/seal/proof journal semantics, sealed-service settlement-only recovery
and final receiver seal guard (sealed-service-settlement-contract.md),
restart/refusal/reuse, 09j adaptation,
portable installer validation and permitted installed acceptance fixtures. It
must provide an auditable bounded native readiness/ACL setup contract and verify
its actual artifacts. It implements no Lab project policy or second state owner.

**Lab installer/configuration** supplies concrete fixed slot units, distinct
accounts/groups, trusted unit/native/setup binaries/config, mount/runtime roots,
network namespace/routes, systemd polkit exact unit/verb permissions, endpoint
ACL installation on every activation, and root-owned map/manifests. It keeps
overseer services separate and routes Lab workers through the generic profile.
The real existing Lab deployment work consumes these assets; 9c2 does not depend
on a Lab install to define/prove its generic contract. Root privilege is installer
or existing OS manager authority, never a runtime caller-selectable root command.

## Verified facts, unresolved technical feasibility and decisions

[systemd v257 slice source](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/slice.c)
starts a slice with a fresh invocation ID, realizes its cgroup, and retains active
state until stopped. This supplies the retained-parent candidate.
[Service source](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/service.c)
prunes even SERVICE_EXITED; RemainAfterExit alone cannot retain the observation
object. [Cgroup source](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/cgroup.c)
releases only recursively empty groups, while a failed unit may still retain
processes; manager stopped/failed status alone cannot prove emptiness.
[Manager GC source](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/manager.c)
retains units referenced by a live unit; this supports the fixed parent reference
candidate, not a claim that process-local bus references survive owner restart.
[Authorization source](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/dbus-util.c)
passes unit/verb to manage-units polkit, and
[unit D-Bus source](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/dbus-unit.c)
distinguishes start/stop/restart methods. Neither source proves the installed rule.

[Kernel cgroup v2](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)
provides inherited membership and recursive population; it does not supply a
permanent application admission seal. [systemd execution documentation](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.exec.xml)
documents minimal roots and joining preinstalled network namespaces, but those
settings do not validate the entire writer boundary. The installed profile must
prove them rather than assume namespace support. systemd v257 is inspected source,
not a declared minimum compatible version or detected Lab version.

Exact inspected Herdr commit is `7b116c05bfda646af39d2524c54e70c751f57ee8`.
[Server bootstrap](https://raw.githubusercontent.com/herdrdev/herdr/7b116c05bfda646af39d2524c54e70c751f57ee8/src/server/headless/bootstrap.rs)
loads production session/config, can seed a startup workspace and runs plugin
startup hooks. [Workspace creation](https://raw.githubusercontent.com/herdrdev/herdr/7b116c05bfda646af39d2524c54e70c751f57ee8/src/app/api/workspaces.rs)
creates native processes; it is not an empty container primitive.
[Native socket server](https://raw.githubusercontent.com/herdrdev/herdr/7b116c05bfda646af39d2524c54e70c751f57ee8/src/api/server.rs)
restricts newly bound endpoint permissions. Local Linux platform source
`src/platform/mod.rs:192` returns false for prepare_server_process; the macOS
persistent-service path is not a Linux migration primitive.

## Specification readiness versus acceptance

The selected behavior, owner, supported platform, exact public calls, map and
proof schema, native readiness, local resource boundary, service seal integration,
restart and continuous reuse are specified in this proposal and its two bounded
reports. They form the whole-task specification readiness candidate. No remaining
Captain decision or undefined behavior is claimed for this engineering baseline.
Independent readiness review may identify a concrete gap; task remains draft until
that verdict. Source implementation and executed installed proof are later task
acceptance, not prerequisites for drafting a complete behavior contract.

Mandatory implementation/acceptance results remain: exact fixed-unit authorization
allow/deny; real namespace/mount/ACL/FD/native artifact enforcement; fresh workspace
and provider startup; canonical exclusion/seal/proof/replay and receiver guards;
retained parent identity across owner/manager restart; true descendant emptiness,
replacement refusal and safe automatic slot reuse. Failure must refuse/hold
ownership, never replace these requirements with broad /lab writes or PID/group
absence. The scoped mapping-v2 replacement removes obsolete v1 at delivery under
ADR-024; unchanged source until then is not indefinite compatibility.

The requested bounded service roles handle capabilities outside the worker profile.
Arbitrary worker host-admin/shared-write access is not required by this program.
A later user request for persistent shared worker servers or those broader
capabilities would change the specification and must be assessed then; it does
not block the current authorized engineering default.
