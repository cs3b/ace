# Native terminal integration contract

Scope: the accepted isolated launcher integration, not a second terminal
runtime or agent-state store.

Verified native source: selected Herdr baseline plus guarded-prompt patch in
ace-herdr. `src/pty/backend/unix.rs` returns `SpawnedPty { master_fd, child,
origin }`. `src/pane.rs::spawn_command_builder` installs this master in the
existing PtyIoActor, reads `child.process_id()`, and runs `child.wait()` to emit
PaneDied. This is the integration boundary; terminal parsing, resizing, input,
rendering and event handling stay in their existing owners.

The isolated backend must return the real session PID, not systemd-run's PID.
SessionLauncher.start and identify have now been exercised from a built gem
on UTM. The service process is not a child of Herdr: a waitpid-based adapter
would be incorrect. Its Child implementation must use the trusted launch
connection's termination result; loss of this connection is an unconfirmed
termination, never a successful exit. The kernel pidfd pins the process used
by native guarded-origin checks. The root endpoint remains responsible for
stopping the exact unit/invocation and confirming cleanup.

Required handoff, all from the authenticated host endpoint:

- PTY master descriptor, with matching terminal geometry;
- exact unit, invocation ID and actual process identity;
- pinned process descriptor and lifecycle connection;
- no credential values and no agent-declared identity.

The endpoint accepts only a configured project and role plus bounded harness
options. It resolves executable/runtime and protected extensions from host
configuration. It must not expose SessionUnit's arbitrary command constructor
as a JSON API. The first implementation must retain the existing lease socket
service as the single system issuer and keep LeaseStore as the only lease
state owner.

Before handing the terminal to Herdr, the launcher must complete project
idmapping and hide private overseer tasks and other session data. Pi cannot
start unrestricted and be restricted after its first turn. Native readiness
then requires the real Pi first turn and active eyes. Successful unit creation
or receipt of the handoff is only process-start evidence.

Outstanding implementation: configured launch operation and descriptor
handoff; native Child/backend adapter and managed-agent start path; mounted
project access; session-local communication; actual issuer readiness; complete
TS-MONO-003/004 and two identical clean runs. No full-cycle criterion is met by
the terminal/component probes alone.
