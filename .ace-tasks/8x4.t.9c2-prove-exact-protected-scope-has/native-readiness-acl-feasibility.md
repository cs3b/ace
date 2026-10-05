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

No Captain product decision is inferred here. Independent architecture review
must explicitly choose whether replacing 09j's root-owned final-parent model
with exact generation/peer verification meets the protected-origin requirement,
or retain that model and select an actual native/OS mechanism that supports it.
This is a technical mechanism decision inside 9c2, not orphan future work.

Generic ACE owns the scoped verifier/readiness contract and failure behavior.
Lab-config owns immutable fixed unit/profile/environment/runtime-layout/ACL
principal installation. Neither may provide a worker-selected path, restored
configuration or a privileged arbitrary-argument hook. Admission must remain
closed on timeout, ACL failure, wrong workspace, unexpected startup process,
symlink/replacement, peer mismatch or changed unit generation. After selection,
actual installed readiness, replacement failure, restart and continuous fresh
activation evidence remain mandatory acceptance work; this report supplies none.
