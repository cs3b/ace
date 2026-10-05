# Native readiness and socket ACL feasibility — draft

2026-10-05; bounded source/document review only. This is a required 9c2
feasibility result, not installed evidence or Captain architecture acceptance.
No source changes, service starts, permission changes or native probes occurred.
The earlier automatic-review restriction remains in force.

## Finding

A fixed readiness action can run unprivileged as Herdr's configured worker User
and change the ACL of that worker-owned socket. Root-installed means immutable
installation/configuration; it does not mean root-executed. This removes the
need for privilege merely to set that socket ACL. It does **not** close the
current complete protected-endpoint contract: its required root-owned,
non-writable final parent prevents the worker from creating a new socket there.
An unprivileged post-start action cannot change that parent to root ownership.
No ready implementation can be claimed from the ACL observation alone.

[systemd v257 service semantics](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.service.xml)
permit ExecStartPost under the configured identity. The '+' prefix bypasses
identity/security restrictions and is excluded. Type=exec establishes exec
success, not native application readiness; post-start failure fails activation.
The proposed action must have fixed installed arguments and environment, no
privilege/failure-ignore prefixes, and a bounded deadline. It completes before
the authority admits the generation or releases payload.

[setfacl's upstream manual](https://man7.org/linux/man-pages/man1/setfacl.1.html)
allows a file owner to change its ACL. Exact ACL replacement and verification
are required, with only installed authority/launcher principals admitted; no
caller-supplied ACL/path. Unsupported ACLs are activation failures. Physical
mode rejects a final symlink but can follow parent symlinks. A pathname check
followed by setfacl is not atomic object binding. Fixed arguments alone therefore
do not establish replacement safety.

## Actual native startup and endpoint contract

Inspected Herdr revision: 7b116c05bfda646af39d2524c54e70c751f57ee8.
[Headless bootstrap](https://github.com/herdrdev/herdr/blob/7b116c05bfda646af39d2524c54e70c751f57ee8/src/server/headless/bootstrap.rs)
binds the API listener before constructing App, seeding the workspace and
running startup hooks. Its stderr ready message precedes those hooks. No
sd_notify/NOTIFY_SOCKET implementation was found in this startup path or server
source. A socket or stderr message alone is insufficient. Require a bounded
native request that observes the exact fixed workspace after the application
loop is responsive, then authority verification of MainPID, OS birth, unit
InvocationID, socket object and protocol against that original generation.
Workspace response does not prove hook children absent; all baseline children
must remain in the owned scope.

[App construction](https://github.com/herdrdev/herdr/blob/7b116c05bfda646af39d2524c54e70c751f57ee8/src/app/mod.rs)
restores stored sessions under production policy. Disabling agent resume does
not disable terminal/session restoration. Each generation needs fresh session
storage, installed immutable configuration/HOME/plugin inputs, a fixed shell
and non-login mode, and an environment excluding shell startup-file overrides.
No worker rc/plugins or prior session state can execute before ACL/readiness.
The native baseline terminal is still a real contained process, not an empty
workspace assumption.

[Native API startup](https://github.com/herdrdev/herdr/blob/7b116c05bfda646af39d2524c54e70c751f57ee8/src/api/server.rs)
creates its listener and applies mode 0600. It does not consume a systemd
socket-activation listener. [Path preparation and chmod](https://github.com/herdrdev/herdr/blob/7b116c05bfda646af39d2524c54e70c751f57ee8/src/ipc.rs)
use pathname operations, including stale-path removal and metadata/chmod;
these do not supply an atomic no-symlink/replacement guarantee.

ACE ProtectedNativeControl.verify! calls ProtectedSocket.root_path! on the
socket's parent without an owner override. In this revision that requires UID 0
and forbids group/other write on every ancestor. Socket identity is separately
checked, and connected native peer birth is validated. Giving the worker parent
write through an ACL changes the ACL mask/mode and does not satisfy that existing
check. A systemd RuntimeDirectory owned by User likewise fails its final-parent
UID check. Precreating a filesystem socket is not listener activation and cannot
be substituted for native socket-activation support that is absent here.

## Concrete alternatives within this task

1. Preserve the existing root-owned endpoint-parent contract: the worker cannot
   bind a fresh socket there. This requires a separately justified OS-owned
   privileged lifecycle operation or native inherited-listener support. Neither
   exists in the inspected implementation. A '+' ExecStartPost chown command is
   privileged execution and does not meet the evaluated no-prefix proposal.
2. Explicitly change 9c2's scoped native endpoint verifier to allow a generation's
   worker-owned runtime parent, while immutable ancestors/config/artifacts stay
   root-owned. This can make unprivileged ACL provisioning possible, but is a
   changed endpoint protection model, not an automatic exception to 09j. It
   requires independent justification of path/object races and replacement,
   exact directory/socket identity checks, connected peer birth verification
   against systemd MainPID on every control, and refusal after any mismatch.
   Workers can rename their own socket after release; ACL/readiness once at
   startup cannot establish immutability afterward. No later native operation
   may rely solely on its original path or ACL.

The second alternative is the smallest candidate compatible with a same-User
post-start action, **conditional on closing those requirements in 9c2**. Plain
setfacl plus before/after lstat checks has not supplied an atomic target guarantee.
Do not claim acl_set_fd on an O_PATH Unix-socket descriptor works: those APIs
have different descriptor requirements, and no source-backed solution was
established in this review. Installation must also show the action and native
server see the same runtime directory object under their per-command mount
namespaces ([systemd execution semantics](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.exec.xml)).

## Decision and required evidence

No Captain product decision is inferred here. The original review identified
an explicit endpoint-model decision. The scoped proposal below now resolves
that technical choice for independent specification review using exact
connected-peer authentication; the alternatives remain recorded as rationale.
This is work inside 9c2, not orphan future work.

Generic ACE owns the scoped verifier/readiness contract and failure behavior.
Lab-config owns immutable fixed unit/profile/environment/runtime-layout/ACL
principal installation. Neither may provide a worker-selected path, restored
configuration or a privileged arbitrary-argument hook. Admission must remain
closed on timeout, ACL failure, wrong workspace, unexpected startup process,
symlink/replacement, peer mismatch or changed unit generation. After selection,
actual installed readiness, replacement failure, restart and continuous fresh
activation evidence remain mandatory acceptance work; this report supplies none.

## Scoped endpoint proposal for independent specification review

The proposed 9c2 mechanism is alternative 2 above: a worker-owned final runtime
directory, with root-owned immutable ancestors and installed configuration,
and exact connected-peer authentication as the authority boundary. This explicitly
replaces the final-parent ownership condition only for the proposed 9c2
canonically admitted generation endpoint in deployment mapping v2. Existing
mapping v1/09j retains its current checks; no fallback or implicit owner override
is introduced. It does not change authority/journal sockets or executable/config
ancestry. Task
remains draft and the dedicated-server product assumption still needs Captain's
preference. The selection here is a technical proposal for independent review.

### Why a replacement listener cannot authorize origin

[Linux Unix-socket semantics](https://man7.org/linux/man-pages/man7/unix.7.html)
define SO_PEERCRED as read-only credentials captured at connect/listen/socketpair.
Filesystem ownership, pathname, payload JSON and claimed server version cannot
supply that kernel identity. A worker-created replacement listener has its own
listener credentials. Before sending a ticket, command, request body or accepting
any reply, the authority must check its connected peer against the reserved
systemd generation's exact MainPID and captured OS birth/credentials, with the
original InvocationID and cgroup membership still current. PID equality alone
is insufficient. MainPID changes are failures, never an automatic repin.

Thus a path swapped after lstat can connect either to the genuine server or to a
replacement. In the second case authentication refuses before any authority data
is sent. In the first case the request reaches the already authenticated genuine
server; a concurrent pathname change does not turn that connection into a new
listener. Before/after path object checks still detect observable changes and
refuse canonical acceptance. They do not claim an atomic filesystem snapshot.
Every new connection repeats authentication. Existing ProtectedNativeControl
already checks kernel peer identity before wire.write; this task extends its
source of expected identity to the canonically reserved systemd generation.

This argument requires the trusted server to keep exclusive control of its API
listener and accepted control descriptors. SO_PEERCRED is not per-message proof
of which process currently holds a transferred descriptor. No listener/control
FD may be inherited into an executed worker or transferred to it, including via
SCM_RIGHTS, /proc descriptor access or ptrace. This is a mandatory artifact/profile
condition, not an inference from the server PID. Rust's Linux socket implementation
uses atomic SOCK_CLOEXEC ([standard-library source](https://doc.rust-lang.org/src/std/sys/net/connection/socket/unix.rs.html));
Herdr uses interprocess 2.4.2 for the API listener, so its actual creation and spawn
paths must retain this guarantee. This bounded review did not retrieve that
version's full listener internals and therefore does not certify the built artifact.

Herdr's inspected live-handoff code transfers terminal-runtime descriptors, not
the API listener ([headless lifecycle](https://github.com/herdrdev/herdr/blob/7b116c05bfda646af39d2524c54e70c751f57ee8/src/server/headless/lifecycle.rs)).
It can replace the server and recreate endpoints. Any such handoff during an
admitted generation must invalidate origin and hold ownership; no imported server
is adopted. A service restart is likewise a new generation requiring old closure.
Workers lack ptrace capabilities and cannot become an ancestor of MainPID;
[enforced Yama policy](https://docs.kernel.org/admin-guide/LSM/Yama.html) must forbid
child-to-server tracing, with no server-granted ptracer exception. No security
setting change is proposed. Root-controlled artifact and dynamic libraries,
immutable server configuration, and no untrusted in-process extensions are also
required; authenticating a compromised genuine server is not protection.

### ACL races have bounded consequences

The readiness action has the worker's existing UID, no extra capability and only
the installed runtime write view. It can alter an owned object's ACL, not grant
itself ownership or mutate the authority's root-protected files. ACL modification
is not authority admission. A raced target can break native access or expose a
worker-owned scratch object; it cannot make another PID pass exact connected-peer
authentication. Grant only the fixed trusted authority/launcher principals and
exclude outside untrusted processes of the slot UID. The writable view and fixed
ACL recipients must not permit exposing a sensitive unrelated owned object.

Atomic ACL targeting is therefore not necessary to establish authority provenance
under this profile. It remains an operational/information-exposure concern bounded
by those ownership, recipient and filesystem conditions. Use fixed path, reject
symlinks and changed directory/socket identities, replace the complete ACL and
check its effective entries, then independently reconnect/authenticate from the
actual authority principal. Do not claim pathname immutability or that lstat closes
all races. Any denial, mismatch or lost response preserves held/uncertain state.
A worker can remove its socket or change ACL after release; that is refusal or
denial of service, never positive scope closure or authorization to retry create.
No root ACL/chown hook or new privileged broker is needed by this proposal.

### Exact readiness and server-state contract

1. Root-installed systemd creates the fresh, exclusive slot runtime directory
   for User, with immutable root ancestry and restrictive startup umask; only
   this generation's server and baseline processes use that UID. No prior session data, worker configuration,
   plugin startup commands or shell rc can execute before admission. Default ACL
   inheritance is not assumed to survive Herdr's chmod 0600.
2. Fixed ExecStart runs the pinned executable, fixed environment/argv and contained
   non-login baseline. Type=exec is used without pretending it signals app readiness.
   Fixed ExecStartPost runs under the same User/security profile with no '+'/'!'
   or failure-ignore prefix. It boundedly waits for native app-loop workspace
   responsiveness, performs exact ACL replacement and verifies path/ACL outcomes.
   It has no claim/ticket or authority credentials and does not admit a generation.
3. After successful OS start job, authority independently reads the fixed unit's
   MainPID/InvocationID and kernel birth/membership, pins that process, verifies
   immutable deployment and scoped directory identity, then connects as its real
   principal. It authenticates the peer before ping/workspace requests. Workspace
   ID alone is insufficient: the returned state must match the installed fresh
   baseline (workspace identity/cwd, no restored panes/agents/plugins and only the
   expected baseline topology/processes). The fresh startup counter begins at one
   and creates w1 ([workspace ID implementation](https://github.com/herdrdev/herdr/blob/7b116c05bfda646af39d2524c54e70c751f57ee8/src/workspace.rs));
   restored state is excluded, not used to manufacture that fixed ID. Unexpected state refuses before 09j
   create. Deadline/reply loss never causes an uncontrolled second create/start.
4. Canonical admission records the verified generation. 09j retains its exact
   fresh-layout reply, kernel parent/credential checks and gated child release.
   After payload starts, later native access repeats peer/generation verification;
   workspace mutation or replacement cannot change original-child provenance.
   A native mutation outcome lost to a concurrent change remains uncertain.
5. Scope close still relies on the independently verified retained systemd parent
   slice and canonical seal, not native replies, ACLs or peer liveness. Replacement,
   genuine server death or MainPID handoff cannot authorize no-writer proof.

The proposal is technically justified against pathname replacement under these
explicit constraints, and is ready for independent specification review. Artifact
FD discipline, fresh baseline installation and actual kernel/manager checks remain
implementation/installed acceptance obligations of 9c2, not claims of completed
experiments. Broader filesystem/network writer-boundary feasibility and Captain's
server-lifetime preference remain as recorded in scope-owner-proposal.md.

### ADR-024 implementation boundary

Preserving current mapping-v1 checks above describes the unchanged delivered source while this proposal is unimplemented. Delivery of the replacement removes obsolete v1 rather than retaining a compatibility branch; unsupported old configuration refuses. Protected-origin guarantees remain mandatory in the replacement. Independent review of 4a824b95 confirms this interpretation.
