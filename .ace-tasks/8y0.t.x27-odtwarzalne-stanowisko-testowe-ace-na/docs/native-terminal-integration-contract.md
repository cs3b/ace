# Native terminal integration contract

## Current live integration state (2026-11-04)

Native source `91026fe397b4e2f6b4c1566a006706f83c2a3fe4` is built by
its owner procedure and installed as diagnostic native77. Artifact SHA-256:
`e4bea13aebba5db4edb583d1f2e39d6ec3bce19ef322ce845530a574bf01828e`;
provenance SHA-256:
`c072d3439fced544fe60a5f760bf32a22b25dd15f27d5d7dad408f7667658ff1`.

Actual launch found and fixed a Ruby descriptor-class mismatch: systemd's
Socket.for_fd listener accepts Socket objects, while handoff required UNIXSocket.
The production check now validates an open AF_UNIX stream and the regression
uses Socket.pair. Tests: 12 / 65 assertions, report
`19f6c28d-0674-40a3-bd70-6298b8b6accf`; independent review found no blocker.
Failure diagnostics name only phase, exception class and containment booleans,
never exception text. Cleanup failure may retain the original operation phase.

Issuer80 is installed with normal IssuerInstaller readiness checks from
`c24b9dcf9c01a63194c6f79f5362fe0efe126234`, ace-lab 0.14.2.pre.utm80,
artifact SHA-256 `74eca8222ef25fa84b5c8f676f86ade713bf4b4676d97e1b6a60381516a28b3b`.
Worker runtime selection still points to the prior self-contained utm75 gem
home: this mixed diagnostic set is not an acceptance manifest.

Native CLI successfully admitted worker80 into w1:p3 / terminal
term_65f6a6411c4fb5. Pi 0.86.1 loaded installed worker instructions, project
AGENTS.md and protected ace-wake/herdr-agent-state extensions. Startup initially
blocked at project trust. SessionPreparation now seeds private settings with
`defaultProjectTrust: never`; installed project resources stay ignored and the
interactive trust dialog is absent. This is startup behavior, not an immutable
security boundary. Preparation tests 3 / 19 assertions passed; independently
reviewed. Pi still downloads its own missing rg/fd: final pinned installation
must supply these dependencies before clean acceptance.

The real native Pi worker completed a diagnostic public-CLI lease assignment:
`lease-cce2c3947c980e02`, task diagnostic-native80, assignment worker80.
Request used e2e-worker / worker / e2e-integrator/ace / TTL 1 minute.
Auth exec ran git ls-remote against local Forgejo, returned exit 0 and main
`6c0fe3b9487caa029c502630df675e45bef0c008`; cleanup was revoked. Subsequent
auth status reported state revoked, live false, cleanup at
2026-11-04T02:48:05Z. Pi's terminal shows eyes off. This is a component
vertical slice, not the autonomous bootstrap or recovery acceptance. Process/PTY admission and
visible Pi startup are proven; first-turn/eyes readiness, authenticated scoped
reporting, delegation routing, TS-MONO-003/004 and two clean identical-manifest
runs are still unaccepted. Existing historical probes below do not close them.

## Scoped reporting implementation contract

Native report handlers now accept exact terminal IDs using the existing guarded
terminal resolver. Missing terminals cannot fall back to a name or pane alias;
the terminal must still exist in AppState. The latter was caught by an executed
regression before completion. The test exercises both real report handlers,
spoofed names/aliases and removed terminal state. ARM64 regression passed
(nextest 1d819e26-8b6c-4c9a-b749-e0028ca7e241); existing report-agent filter
3/3 passed (3ceaf953-e223-4bbf-8a9c-c7fc101c4edb). Independent review approved
the exact-resolution approach. Native source is now
6d6fd9e29c4a412dd0dabfa1e70415584ad1207e, tree
4908ae9416e27b3f156a7187f8cdb78e43237576; mail replay reproduces it exactly.
Packaged-source verification: 13 tests / 42 assertions, report
cf4a5333-dcfd-4072-a44d-f7f2b41cc2d9. This new native source is not deployed yet.

The remaining bridge must enforce all of these together:

- Only an authenticated host launch may provide the native reserved terminal ID;
  a dynamic session cannot select another terminal binding.
- Store the binding in root-created systemd unit Environment; SessionPeer reads
  exactly one value and verifies the live invocation before each forwarded report.
- Select native socket and expected account from protected installation config;
  verify path ownership and connected peer identity. Never accept a socket from
  an agent request or expose the unrestricted native socket to DynamicUsers.
- Permit only own state/session reports. Fix agent=pi and integration source;
  reject resume_argv and unneeded execution-bearing fields. Session paths require
  explicit namespace-safe treatment, not automatic host resume.
- Handle reports before native adoption: either retain the launch barrier until
  adoption acknowledgement, or explicitly retry missing-terminal reports.
  Acknowledgement parsing now rejects error responses, but adoption ordering remains unconnected.
- Delegated launches keep the original authenticated session authority. Do not
  forward ordinary start as the host account, which would erase role/project
  restrictions. Native owns terminal reservation/adoption, issuer owns authorization.

No new persisted registry is required. Session reports remain self-reports;
first-turn plus active eyes remains a separate readiness condition.

## Prior integration state (2026-11-04)

This section supersedes the historical progress entries below. Native
`agent.start_isolated` now asynchronously admits a configured project/role,
reserves the agent name, and attaches the authenticated PTY to a new terminal.
The root-selected `/lab/<project>` directory is part of the handoff. Starts are
server-owned: API disconnection does not cancel an accepted session, which is
rediscoverable by name. Numeric workspace aliases are bounds-checked and the
completion resolves the captured stable workspace ID.

Persisted terminals retain only project/role selection. Restoration goes back
through the protected launcher; disabled or failed restoration remains visibly
unavailable and never launches an ordinary shell. CLI `agent start-isolated`
and the ACE executor adapter expose the same closed selector, with no argv,
credential, UID, cwd or extension overrides. Success means process admission,
not first-turn/eyes readiness.

Independent static review closed the numeric-workspace panic and found no
additional issue in the API, restoration, lifecycle adoption or directory
handoff. ARM64 validation: 3933 Rust tests passed (14 skipped), nextest
`594bfe52-3732-4cd7-b023-12257f995aab`; after the CLI addition, isolated filter
11/11 passed (`03f810cd-6d05-41ca-8b9d-aee8519c83e3`). ACE executor tests:
51 tests / 87 assertions, report `159e48b0-0434-460c-99d3-85823d8e733b`.
The full recipe initially stopped after 149 passing Python tests because Bun
was missing. Bun 1.3.14 (the native CI pin) was downloaded and verified against
its published SHA-256 `a27ffb63a8310375836e0d6f668ae17fa8d8d18b88c37c821c65331973a19a3b`;
the remaining recipes passed separately: maintenance 149 Python + 5 Bun tests,
UI architecture 6, integration assets 55, and docs contracts 7.

Native source is pinned to `95f69ef3fc5ecbd4f450f99e3420361997b84eac`,
tree `748edb750067b2f575a89b4a7d1deee569f62dc9`; exact mail replay matches.
Packaging tests pass 13/42 (`e018d3eb-7bac-4c99-a27b-fd9f33ec0d38`).
Independent review also approved the CLI/wrapper and live-shell fixture changes.

Still required: build/deploy this native delta and the paired Ruby
handoff; actual configured Pi launch; authenticated session-scoped communication
without exposing the host Herdr control socket; product start/delegation route
selection; first-turn plus eyes readiness; TS-MONO-003/004 execution; two clean
identical-manifest runs. Installed diagnostic issuer74 still uses the old
handoff without `directory`, so it cannot be used with this native receiver.
None of these component results establishes full-cycle acceptance.

## Installed diagnostic candidate and artifact build

Parent source `d23c484a847c9e0480ef743b8713d71bda857a23` produced:

- ace-lab 0.14.2.pre.utm75: SHA-256 `6df2a56aada161decc1ff51e45ea18d3c8758f17a7835fd4921da61a919db735`.
- ace-herdr 0.10.1.pre.utm75: SHA-256 `333acb0dc1743229792b82671679b2062a0756894a6ce23138b4bbd5991ee4dd`.

Both were installed into the self-contained root-owned diagnostic gem home
`/opt/ace/diagnostic/utm75/gems`. Default IssuerInstaller reported installed;
previous units and installation manifest are preserved under utm75. The
configured worker command resolves installed standing instructions and protected
extensions successfully. Credential preparation uses a root0600 source; values
were not printed. Debian's `/bin` symlink was removed from the fixture PATH in
favor of canonical `/usr/bin`, without weakening protected-path checks.

The native owner build failed for the actual aarch64-musl target: libc's
`msghdr.msg_controllen` is u32 under musl but usize under glibc. Its fixed ancillary
buffer now converts explicitly at this ABI boundary. The failed owner-build
output is retained under `/home/lab-operator/herdr-native75-build`; a diagnostic
`just build` there is not a releasable artifact or a provenance receipt. After
verification the corrected native source must be pinned and rebuilt by the owner.
Corrected native source `a90bc55ad5b26ff95e145499b2bda02a4cf941fa`, tree
`28b917f9bab93dabd6db7ae3e8d349a4fa62fdb0`, reproduces exactly by mail replay.
GNU handoff tests 2/2 passed (`90e78cdd-e7bd-4d1b-b77b-a7f83275cea3`);
the diagnostic musl release build passed in 85 seconds. Owner rebuild remains
required for its final artifact and provenance.

The builder also now reports a bounded UTF-8 compiler reason instead of dropping
stderr. Independent review closed the invalid-byte expansion issue; tests cover
both invalid UTF-8 and partial multibyte boundaries (9 tests / 59 assertions).

## First actual native launch attempt

The owner build of native source a90bc55 completed with artifact SHA-256
`2ef6b0156e5036e6abc53f8e96d71519cc659bc259057cbdfacdbbd16b6f8b31`,
provenance `22518de5155a27d31a083289aa02e8fe56b6f1e48c148bb678981b8dfc2d48a8`
and selection `4366ad989dc46c753d162edff8c56a45347898a0d56a9e9425366726a7bf9ef1`.
It is installed root-owned at `/opt/ace/diagnostic/native76/herdr`, with a
separate mo-owned server `ace-e2e-herdr76.service` and private socket
`/run/lab/herdr76/herdr.sock`. Its workspace w1 points at `/lab/ace`.

Real `agent start-isolated worker76 --workspace w1 --project ace --role worker`
returned `deferred_launch_required`: headless dispatch omitted the new method.
No isolated worker was admitted in this attempt. The dispatcher now routes the
method to deferred admission. A headless server regression exercises this route,
not only the App handler. TerminalId is reserved before launch and retained
through adoption, without inserting premature terminal state.

Independent review approved the correction. ARM64 isolated filter 12/12 passed,
nextest `9d4f3cfe-66c1-479a-8f1e-06a796b97a38`. Corrected source
`91026fe397b4e2f6b4c1566a006706f83c2a3fe4`, tree
`e35a0ed911dfd544aa6a60017a70bc40ba3ef4b9`, reproduces by exact patch replay.
The installed native76 remains the observed failing candidate until replaced
by a freshly built artifact. Terminal reservation is not yet an issuer mapping.

## Remaining session communication contract

The first scoped communication increment is self-reporting through the existing
issuer: only `pane.report_agent` and `pane.report_agent_session`, using an
immutable root-selected systemd mapping. Native terminal identity must be reserved
before launch or registered while the entry barrier is still held. Model-supplied
pane/workspace values are not that mapping. A report does not itself prove eyes
or readiness.

Delegated start must retain the original authenticated SessionPeer through the
actual root launch and native adoption. Relaying it as an ordinary host
`agent.start_isolated` would reconnect as mo and become a confused deputy.
Herdr reserves/adopts terminals; issuer authenticates and launches; configuration
owns project/role grants; LeaseStore owns leases. This boundary is not yet wired.

## Historical component evidence

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

Native Linux origin preparation was implemented in
`.ace-local/herdr-integration-source/src/platform/linux/guarded_origin.rs`:
consume a supplied OwnedFd, verify its kernel pidfd type and exact live PID,
then establish the existing guarded identity from kernel observations. The
ordinary spawn capture shares that implementation. Tests cover a correct live
handle, wrong descriptor, mismatched PID and exited process. Native
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
test-one guarded_origin` command passed: 3 tests, 3928 intentionally filtered.
The broader `just test-one guarded` then passed 33 tests, 3898 filtered. This
compiled the actual native crate and its 17 test binaries on ARM64. Four
existing irrefutable-pattern warnings refer to unchanged pane.rs code.

Selected native source is now `ef3089b24e6f3839d8331926edc295f3b6921dfe`,
tree `986592607a29d2f3ffb48458d3b2832a7251a859`. Replaying the packaged mail
patch from the pinned baseline reproduced both exact hashes. Packaging tests
pass (20 tests, 88 assertions) after updating the expected reviewed-source pin.
The release manifest and deployed native binary still select the previous
artifact; the new source must be built through the owner procedure as part of
the complete native integration candidate.

Outstanding implementation: configured launch operation and descriptor
handoff; native Child/backend adapter and managed-agent start path; mounted
project access; session-local communication; actual issuer readiness; complete
TS-MONO-003/004 and two identical clean runs. No full-cycle criterion is met by
the terminal/component probes alone.

## Authenticated stop validation

SessionLauncher now stops the retained single-use systemd unit only after
checking its invocation and, while live, its pidfd binding. The systemd stop
job must succeed and the retained pidfd must confirm process exit. The first
live probe exposed that transient units are garbage-collected immediately
after stopping: post-stop property lookup incorrectly rejected a successful
stop. The implementation no longer requires that vanished unit to persist.

Installed diagnostic artifact `ace-lab 0.14.2.pre.utm71`, source
`b992f84c0b34ff46c6a60b8d9d7471daa80d12af`, SHA-256
`32a506bd5e0b1ccc9f142f91f62345009cde50fee925ac5f1d711f900773454e`,
passed the live UTM stop probe. Unit
`ace-auth-session-worker-7cde6bffa67539c1.service`, invocation
`41773156385448dd86b7293a4fe37b06`, returned confirmed_stop=true.
Five launcher tests / 23 assertions pass. This verifies a gated service stop,
not yet native Herdr pane shutdown or Pi readiness. The root launch owner must
keep unit names single-use; this is not an arbitrary unit-stop public API.

Independent integration review identifies the next complete cut: dispatch an
authenticated host launch handler under the existing IssuerServer, leaving
lease SessionPeer authentication unchanged; retain terminal/pidfd/lifecycle in
that supervised handler; connect native SpawnedPty and Child to it. Host operator
and delegated-session authorization must be explicit in SessionConfiguration.
Do not expose the ordinary mo-owned Herdr control socket to DynamicUsers.

## Native Child lifecycle adapter

Selected native source now includes `platform/linux/session_child.rs`:
`ec8d6b4a7643227ad3066eb740b8886e83d8483e`, tree
`97aea9aa90b3188dee59436d84b5728a59b43c13`. The internal Child adapter reads
a bounded launcher termination response, matches unit/invocation, requires
cleanup confirmation, preserves exit code, and reports lost channels as errors.
Its cloned ChildKiller sends an invocation-bound stop request rather than a PID
signal. It clears handshake nonblocking/read-timeout settings; try_wait uses
MSG_DONTWAIT independently. Partial replies remain nonblocking.

Native UTM `just test-one session_child` passed 4 tests (3931 filtered), nextest
`f7305b23-67bd-4d7b-b1bc-31f927a271af`. This follows independent static review
and correction of inherited handshake settings. Packaging verification passed
20 tests / 88 assertions. Replaying the mail patch reproduces exact source and
tree. The native compiler correctly reports this adapter as unused: backend
handoff and pane lifecycle selection are still outstanding. No release binary
or full-cycle acceptance has been produced from this source.

Wire contract for this internal lifecycle channel: newline-delimited JSON,
maximum 1024 bytes for the terminal response. Stop request contains action=stop,
unit and invocation. Terminal response contains exactly unit, invocation,
exit_code (0..255), cleanup_confirmed (true required for a confirmed result).
The authenticated launch handler must retain natural completion separately;
SessionLauncher.stop cannot inspect a unit already garbage-collected after
natural exit. Authentication and PTY/pidfd association precede constructing
SessionChild; the constructor does not establish authority.

## Terminal descriptor handoff

SessionLauncher.handoff sends BE32 payload length followed by JSON metadata
(protocol=ace.session-launch/v1, unit, invocation, pid, rows, cols), with exactly
two SCM_RIGHTS descriptors on the first bytes: PTY master then pidfd. It checks
root execution, live identity and current unit binding before sending; handles
remain owned by the launch supervisor. Six sender tests / 35 assertions pass.

Native source `8ba0cc36639448ff2223f7893caf22d05ec38ae8` receives this handoff
through platform/linux/session_handoff.rs. It requires a root socket peer,
bounded metadata, exactly two CLOEXEC rights, PTY-master ioctl, and a matching
live pidfd. The lifecycle stream then belongs to SessionChild. UTM ARM64 tests
passed (2, 3935 filtered), nextest e416b0a2-9f71-40d4-91bc-cb11e6824ec2: missing,
extra and truncated rights are refused; rejected rights do not leak; a fragmented
header with a valid pair preserves both handles and CLOEXEC. Independent review
found no actionable FD/framing flaw. Exact packaged source/tree replay passed.

These are transport tests, not a native agent launch. Caller authorization and
PTY/process association still belong to the configured launch handler, which
is not wired yet. The new receiver still has no production caller. Next complete
cut remains IssuerServer launch dispatch, configured Pi preparation, native
SpawnedPty selection and pane shutdown through SessionChild.

## Configured Pi launch inputs

The existing protected install manifest now owns `session_runtime`: canonical
Node executable, Pi entry file, additional PATH directories, provider, model,
and credential-source path. No secret value is accepted in this configuration.
SessionConfiguration requires this section for a launch selection. SessionCommand
uses that selection to build fixed Pi argv, a clean installed gem environment
and session-local HOME/PI_CODING_AGENT_DIR. Role protocol references resolve
through installed ace-nav with cwd=/ and no inherited environment. Protected
extensions reuse ace-herdr's InstalledPiExtensions policy; ace-lab now declares
the ace-herdr dependency rather than duplicating that owner.

The command builder does not yet prepare directories or copy credentials.
Those operations and host/session caller authentication belong to the supervised
launch handler before releasing SessionEntry. No arbitrary argv/environment
will be accepted by that handler. Runtime readiness and two clean E2E runs
remain outstanding.

## Delegation authority and private Pi preparation

SessionUnit fixes ACE_LAB_PROJECT_ROOT from its configured initial directory.
SessionPeer reads that value, installed mode and the session marker from typed
systemd Environment properties, rejects ambiguity, and carries project_root in
its authenticated identity. It never derives authority from the running agent's
environment or cwd. SessionConfiguration requires explicit session-role grants;
project-overseer can start worker/verifier/integrator only within that project,
lab-overseer can additionally start project-overseer for granted projects, and
executors cannot launch new sessions.

SessionPreparation reuses SessionPeer's runtime-directory claim before adding
private HOME and Pi directories. It checks root0600 bounded JSON credentials,
copies only the selected provider into a DynamicUser-owned0700 Pi directory,
and creates auth.json0400 before the entry barrier is released. Independent
review found no actionable authority or credential-exposure flaw in this scope.
Targeted tests: 23 tests / 94 assertions pass. Installed guest preparation and
actual endpoint wiring are not yet validated.

Confirmed integration requirement: session-close cannot simply snapshot leases
after main PID exit. An authenticated request can be waiting in provider or
correlation work before creating its record. The existing LeaseStore now
serializes issuance finalization and exact-session cleanup by (unit, invocation),
with a liveness recheck inside the lock. The lock order is issuer lifecycle→
session→correlation→record; live lock files are never replaced. Full cgroup containment must precede
cleanup success; main pidfd death alone is insufficient.

Session cleanup uses Service.revoke_session under the shared issuer lifecycle
lock and exact-session lock, reusing the existing revoke/recovery implementation
and execution containment checks. A different session, unit or issuer remains
untouched. Corrupt records and unconfirmed execution cleanup still block a clean
result. Targeted verification passed 118 tests / 448 assertions; independent
review passed with no actionable findings. Tests include actual flock exclusion,
stable inode reuse, separate invocation keys, a dead-session recheck while the
lock is held, and exact cleanup selection. The native close endpoint and a live
issuance/close race remain unverified; this does not claim full-cycle acceptance.

## Configured launch dispatch in the singleton issuer

The issuer connection now accepts a closed `launch` request containing only
`project`, `role`, `rows`, and `cols` (plus `action`). Host accounts are resolved
from SO_PEERCRED with a live SO_PEERPIDFD; DynamicUser callers must pass the
existing SessionPeer authentication and SessionConfiguration delegation policy.
A caller cannot supply argv, environment, UID, runtime paths or principal.

SessionLaunchRequest owns a PTY and the systemd transport. It selects the
protected Pi command, acknowledges issuer supervision, starts the gated unit,
prepares credentials and project mounts, releases the barrier and sends the
existing framed handoff. Natural exit, authenticated stop, caller exit and
channel loss all require whole-unit stop followed by existing-store session
lease cleanup before a confirmed terminal outcome. A lost client after
confirmed cleanup is a local refusal, not an issuer-fatal cleanup failure.
Independent review found and closed that distinction; a regression covers it.

Verification: targeted issuer/launch/peer tests 27/103; complete ace-lab suite
927 tests, 4230 assertions, zero failures/errors, 13 skips. These tests are
not evidence of native pane integration or actual Pi launch. The native
client/backend/pane route, scoped session communication, first-turn/eyes
readiness and installed configured endpoint probe remain outstanding.

## Native launch client and terminal construction

Selected native source `7405a1259c4f25332fc0b90f7d64355e8808b01b`, tree
`176ddaac492dbb92b89654b96a1fb491f90f2c23`, adds the fixed protected issuer
client and `TerminalRuntime::from_isolated_session`. It reuses SpawnedPty,
the PTY actor, guarded origin and child watcher. Pane shutdown retains the
launcher ChildKiller instead of numeric-PID signalling. Isolated sessions
refuse the existing terminal-only server-handoff mechanism because that
mechanism does not transfer their lifecycle owner. Preparation has a bounded
45-second handshake; this is process-start evidence, never agent readiness.

Independent review found an actor-construction failure leak: the detached
watcher retained the lifecycle channel before fallible actor initialization.
The watcher now starts after successful actor creation. An injected actor
failure test proves that all native lifecycle descriptors close, allowing the
issuer to contain the session; ordinary process failures kill and reap their
child. Review closed the finding after inspecting this correction.

ARM64 validation: configured request tests 2/2 (nextest
`ce421eb0-27d0-4d9c-a45e-0480943af6e4`); isolated lifecycle/transfer/failure
filter 6/6 (`2647a642-e062-46f4-9279-70d30e065a8b`); complete pane test module
139/139 (`cc6a19cc-33a4-4bd8-8b88-839dfba87a1e`). Formatted with pinned
Rust 1.96.1. Exact patch replay reproduces both source and tree hashes;
packaging tests 13/42 pass. Full `just check` and non-Linux builds were not run.

The native API still does not call this constructor. Compiler unused-path
warnings accurately reflect that remaining work. Native managed start must
be asynchronous, expose an advertised capability, and avoid replacing an
ordinary shell under the same pane identity while its old PaneDied event is
still pending. Session-originated scoped communication also remains open.

The root singleton endpoint is installed diagnostically as ace-lab
`0.14.2.pre.utm74` from `3b9c5c79cab8f9d090598f8d90340a91f10e2727`, SHA-256
`4558e65b56d50c65c5a1541309f1ea5e9a64c2ef337695b51b60b94eda8fb681`,
in `/opt/ace/diagnostic/utm74/gems` with the utm73 runtime correction.
Default IssuerInstaller passed all runtime/unit/host checks and returned
installed; previous units are preserved in utm74/previous-units. The guest
manifest has not yet been configured with session roles/model runtime, and
no live configured Pi launch has been attempted. Acceptance manifest remains
unchanged. All of this is component evidence only.

## Report acknowledgement correction

Native source e884a1608d316d322a673c5905d8b67d8a51bf53 (tree
3b9bc960ca483470d00fa7a68657aa0b6677e35a) raises the managed Pi integration
version to 10. Delivery now requires bounded, newline-framed JSON with matching
request ID, non-null result and no error. Wrong-ID, error, malformed, oversized
and unanswered replies retry the same request; successful fragmented replies
are accepted. Independent review found no blocker and requested the added
fragmentation/oversize tests. Integration-assets recipe passed 59 tests on ARM64;
version detection passed nextest 8122e317-591c-4deb-b197-fae6135804e4. Exact mail
replay matches, packaged selection tests passed 13/42 (report
a859da19-e3a4-486a-9d05-35fd947ec849). Neither this source nor the preceding
terminal-target delta is deployed yet. This fixes false acknowledgements only;
the existing two attempts are not a full adoption/readiness protocol.

## Host-bound terminal identity implementation

Native source dfb88ce05e26cf692d5cff000818550a6bfada85 reserves a TerminalId
before both new launch and restoration, transmits it to the root launcher,
and adopts the same ID into TerminalState. Root launch accepts this field only
from the authenticated host principal; dynamic session callers cannot choose
a terminal binding. SessionUnit writes ACE_LAB_TERMINAL_ID as a fixed systemd
environment value and preserves it through the preparation wrapper. Generic
environment injection cannot set it. SessionPeer reads it from typed systemd
properties, rejects duplicate/invalid values and returns it with the verified
invocation. Terminal-free lower-level sessions have no binding and must be
refused by the future report endpoint. No reporting permissions are enabled by
this field alone.

Independent review found no authority/lifecycle defect. Ruby verification:
47 tests / 203 assertions (b3c1145d-3bf3-4b7b-9cd7-50f43a1635c1), followed by
expanded schema tests 14/61 (90e06f5d-1988-4fea-9998-e0d43e5b3db4). ARM64:
isolated filter 13/13 (2f6675e1-c846-49a6-b6e2-4a580bfe55ab), launch request
filter 2/2 (5a0bc4db-291c-4a76-b6ba-c736e8aba58f). Exact patch replay matches;
packaged source 13/42 (b9553dbc-9342-46bf-947b-2a8a85909cae). This paired
change is not deployed yet. Issuer80/native77 diagnostic deployment is unchanged.

Next required implementation is the authenticated restricted report endpoint,
protected native socket selection/peer verification and live invocation check,
then adoption ordering and actual Pi report/eyes evidence. Delegation must still
preserve original session authority. Full TS-MONO-003/004 acceptance remains open.
