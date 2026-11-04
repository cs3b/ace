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

The host Herdr control socket must not be made generally accessible to dynamic
session UIDs to solve connectivity. Its ordinary pane/shell execution methods
run as the host owner and would let a worker escape its assigned filesystem
view. Session-originated delegation and lifecycle communication must retain
the authenticated system session at the existing native/API boundary; a role
or project named by the model is not authority. The root launch endpoint must
continue to resolve allowed projects/roles from the protected installation
configuration. Do not substitute an unprivileged shell proxy PID for the
systemd session identity.

Native Linux origin preparation now has a working-tree change in
`.ace-local/herdr-integration-source/src/platform/linux/guarded_origin.rs`:
consume a supplied OwnedFd, verify its kernel pidfd type and exact live PID,
then establish the existing guarded identity from kernel observations. The
ordinary spawn capture shares that implementation. Tests cover a correct live
handle, wrong descriptor, mismatched PID and exited process. This has not yet
been promoted into the selected source patch or accepted as tested. Native
validation sources are staged on the diagnostic VM under
`/home/lab-operator/herdr-validation`; Rust 1.96.1 is installed for the build
owner. Native runtime artifact and acceptance manifest are unchanged.

Independent static review found no actionable defect in that origin delta.
It confirmed that the remaining native route must reject origin-capture errors
(the ordinary backend currently converts them to None), replace numeric-PID
shutdown with authenticated session shutdown, and consume trusted terminal,
pidfd and lifecycle metadata as one launch result. Descriptor validation alone
is not authorization or proof of terminal/session association.

Validation tooling installed on the diagnostic VM: just 1.59.0 and
cargo-nextest 0.9.151, built with their locked dependency sets under the
unprivileged build owner. Rustfmt/clippy match Rust 1.96.1. After correcting the
formatter's two layout differences, the native `cargo fmt --check && just
test-one guarded_origin` command started in `herdr-validation`. Its cold
Rust/Zig build is in progress, not a passing test result. Continue observing
that same run before replacing or rerunning it.

Outstanding implementation: configured launch operation and descriptor
handoff; native Child/backend adapter and managed-agent start path; mounted
project access; session-local communication; actual issuer readiness; complete
TS-MONO-003/004 and two identical clean runs. No full-cycle criterion is met by
the terminal/component probes alone.
