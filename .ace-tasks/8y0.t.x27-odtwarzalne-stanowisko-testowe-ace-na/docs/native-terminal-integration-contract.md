# Native terminal integration contract

## Current diagnostic state (2026-11-04, candidate89 / overseer90)

The installed standard-start path is now proven through native Herdr and a real
DynamicUser coordinator. Public start returned started/ready:false; repeat start
reused the exact terminal and authenticated host readiness returned false.
The actual Pi first turn armed eyes but exposed two degraded sources: the old
project_sessions tab lookup and missing fixture HITL recipient. It then violated
the supervisory boundary by investigating host/transport details. This is a
failed diagnostic attempt, not acceptance. The exact session was exported and
stopped. Runtime `/opt/ace/diagnostic/utm89/gems` remains installed; native89
continues running. Full artifact identities and evidence are recorded in
`isolated-delegation-live-2026-11-04.md`.

Current corrections switch isolated project observation to authorized native
role/project inventory, supply the local HITL fixture, and make the first-turn
blocking condition explicit. They require a fresh installed probe. Still required:
positive first-turn/eyes readiness and role compliance; isolated coworker dispatch
and worktree execution; task/report/eyes and lease fault integration; TS-MONO-003/004
registration and two clean runs of one final pinned manifest. Existing fixture
runtime/start helpers still need the protected deployment path; rg/fd must be
supplied by that installation instead of downloaded per session. Historical
checkpoints below are component evidence, not complete acceptance.

## Startup observation integration (source, not deployed)

The authenticated control endpoint now permits only supervisory `agent.wait`
for `until: [idle]`, timeout 1–60000 ms, against an authorized other session.
It resolves the target to its immutable terminal, preserves caller liveness,
redacts private fields and checks interactive readiness. Worker completion must
still use observation and end-of-turn delivery, not this startup wait.

Native source `c17ef7290086f338dd33370ebc9304149c3fa9f4` closes the idle-before-ready
race found by independent review. Isolated idle requires interactive readiness
and no pending launch; transient or released idle cannot bypass it. The existing
headless deadline loop reconciles managed startup and emits `PaneUpdated`, so
settle readiness wakes the existing wait without another agent model turn.
No new state store or polling CLI is introduced.

Executed validation: endpoint/issuer/host readiness 36 tests, 181 assertions
(report `5671044c-06c8-40bf-897d-3bb29d0a0400`); Linux native startup predicate and
App-level settle-event transition each passed (`0839c523-09ad-446c-a19f-b7e35fe5e863`,
`ea80a8ab-9027-4c15-a2f7-661c707710aa`); existing native wait regressions 11/11
(`ffde9e96-4e5f-4244-a43e-36b8026b5437`); packaged source 13 tests /42 assertions
(`390f6a67-8b93-4973-9aa5-7df9a7e22cca`). Independent review approved the correction.
The exact mail-patch replay reproduces the source commit. These are component
checks; standard start/dispatch and two clean scenario runs remain outstanding.

## Standard start integration (source, pending live validation)

On a configured installed host or within `ACE_LAB_SESSION=1`, all standard
start entrypoints use `IsolatedStart`; no foreground Pi, project bundle setup,
ordinary shell command or ordinary agent launch is used. Bare start infers lab
versus project from canonical roots in the protected deployment manifest.
The host selects role/runtime/instructions. A lab start launches its coordinator;
project preparation remains the coordinator's delegated work. Explicit reconcile
starts/reuses configured project overseers and reports partial until all have
independent readiness evidence.

The session workspace endpoint permits list/create only to supervisors, only
for granted configured projects, with a host-selected cwd and no environment
or shell overrides. It returns grouping metadata, not host pane contents.
Herdr remains the sole workspace/terminal owner. A standard start discovers
owners by native role/project identity and reserved name, rejects ambiguity,
uses the isolated launcher and bounded input-ready wait, then submits the
canonical first prompt once without waiting for model work. The report remains
`ready: false` after submission. A reused owner is only checked for authenticated
first-turn/eyes evidence; uncertain prompt delivery never causes a resend.

Component validation: workspace/issuer 25 tests /101 assertions
(`88144016-f4b1-4026-8e57-b86d72e242ba`), isolated start 8 /27 including lost
prompt acknowledgement/reuse (`bad24421-ad48-4f04-ba37-bbb8923a1d5e`), existing
start integration 43 /204 with one platform skip (`a1884c40-cc54-4b2d-b8b0-9517a4fc23ca`),
Herdr executor 52 /88 (`e6d86b9f-24ad-484e-b90c-6eb345a17517`). These do not
replace the pending installed standard-start and clean E2E runs.

## Historical integration checkpoint: native77 / issuer80

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
- Delegated launches are authorized against the original authenticated session
  before forwarding. Issuer reconstructs the exact approved project/role request;
  native owns terminal reservation/adoption. The subsequent host authorization is
  an additional restriction, never a substitute for the original session policy.

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

## Restricted report endpoint implementation

IssuerRequest now authenticates native-shaped report requests through SessionPeer
and forwards only pane.report_agent and pane.report_agent_session via SessionReport.
The terminal must match its systemd binding; source/agent are fixed to herdr:pi/pi,
sequence and text fields are bounded, resume_argv and unknown fields are refused.
Session paths must be canonical under that session's private pi/sessions directory.
This is lexical metadata validation, not symlink containment: the native host must
not open/execute these paths as authority without separate validation.

The optional protected session_runtime.herdr selection contains exactly account
and socket. Forwarding verifies account-owned socket ancestry, inode continuity,
connected peer UID/GID, live caller/main pidfds and the systemd invocation before
and after I/O. Native errors are relayed as errors, not successful delivery.
No lease/state registry participates. Unit environment points Pi only at the
issuer socket with its bound terminal ID. A terminal-bound SessionCommand refuses
missing endpoint configuration. Ordinary environment overrides cannot change it.

Independent review found no blocker in the bridge; live adoption/delivery remains
unverified. Tests: endpoint/schema/issuer 63 tests / 402 assertions (770b4b33-
b615-4d04-be64-889a6bd17e3a); environment/command/report 12/91 (e1d05c3a-3eb5-
426f-9441-438d76b83c3c). Transport tests use real socketpairs with simulated kernel
identity and systemd boundaries; they do not prove Linux peer authentication.
Build and install the paired native/issuer candidate, configure its protected
Herdr endpoint, and exercise actual Pi reports before claiming live readiness.

## Live authenticated reporting on candidate81

Parent 9c1789b03f7b84318ddc17400b703ecdf84ac3c5 produced ace-lab
0.14.2.pre.utm81 (SHA-256 7876da32e8eead8f620b1921c6ddc1df8be0cdd04bdfbbe3952cc1eae8eb2fee)
and ace-herdr 0.10.1.pre.utm81 (93caff5f85802c15d59a5d49629c4f8ef3cdd0eaeab83075f5a4f50a71e80b59).
The self-contained /opt/ace/diagnostic/utm81/gems installation passed the default
IssuerInstaller checks. Protected manifest now selects this same worker runtime
and mo-owned /run/lab/herdr81/herdr.sock. Prior manifest and units are backed up.

Owner build of native dfb88ce05e26cf692d5cff000818550a6bfada85 completed:
artifact 54388175ba9aafaecff11bd7a415793b15262d6b7e38f34e6acc8a1d3336220e,
provenance b528a9f33fadec3c007bddc63a4a52574bc13b2035fef01204dd349f7c138a9f,
selection 4733d42c378686f9e31988a0b954ed03d8f0d4413db8a19f95d123d17b048055.
Native81 is root-installed; its integration install projected Pi integration v10
to the protected extension directory. The mo-owned diagnostic native server is
ace-e2e-herdr81.service, invocation e03c97ec018e403ab074624deb704bf5.

Actual native start worker81 created terminal term_65f6abb255f8e2 / w1:p2.
Authenticated reports populated its Pi session reference under private runtime
ace-auth-faeb0983982a33da. A diagnostic prompt asking role/reporting responsibilities
completed without file edits or commands. Native agent.list then reported
interactive_ready=true, agent_status=done, completion_seq=3, state_change_seq=3.
The diagnostic command waited only for idle and timed out because native maps
completion to done. That timeout is not a stalled model; no duplicate prompt
was sent. Terminal evidence confirms eyes off pending:0. First turn and scoped
report delivery are proven; eyes and autonomous delegation remain unaccepted.
Pi still downloads rg/fd, which final runtime pinning must eliminate.

Broader auth verification selected 30 actual test files: 288 tests, 1170
assertions, zero failures/errors, 9 skipped; report e24b02c5-6a6f-4630-927c-01a2203bbf3c.
The preceding attempt supplied a directory as a file and ran zero tests; it is
not verification. This diagnostic deployment is not either clean E2E run.

### Scoped native supervision (2026-11-04)

The existing issuer accepts closed `agent.list`, `agent.get` and `agent.prompt` requests from authenticated sessions. Native `AgentInfo.isolated_session` projects the server-selected project and role; report payloads cannot set it. The issuer filters list/get through the original session’s project/role grants (workers can inspect only their bound terminal) and returns status identifiers, never transcript paths, titles or arbitrary metadata.

Prompts are overseer-only. The issuer resolves the immutable terminal, obtains native guarded process origin, requires a DynamicUser process, and submits with `expected_origin`. Native rejects a changed incarnation before PTY write. `pane.process_info` resolves terminal IDs exactly, without agent-name or recycled-alias fallback. No raw keys, shell commands, caller origin, or wait loop are exposed through this endpoint. These are component checks, not full scenario acceptance.

### Authenticated eyes evaluation (2026-11-04)

For isolated callers, `EyesReadiness` uses the existing issuer socket with a closed target-only `agent.readiness` request. Original-caller project/role authorization precedes independent authentication of the target native guarded process through the complete SessionPeer systemd policy. The target's MainPID, terminal, role, manifest project root and invocation must agree. Target lifetime is rechecked around private file opening and evaluation, followed by fresh native session-path and guarded-origin comparison.

`ace-lab` opens the bounded session file under the target UID and passes a read-only FD to a bounded, clean-environment installed `ace-overseer/libexec/eyes-ready` subprocess. This keeps interpretation in ace-overseer without a reverse gem dependency. Its existing branch reconstruction, exact first-turn prompt, process birth/UID, foreground membership, required sources and freshness checks remain authoritative. The response carries only a readiness boolean, terminal/invocation and project root/role. Missing evaluator, failed authentication, changed invocation or malformed response are failures, never source fallbacks. The local direct evaluator remains for ordinary non-isolated operation, not as fallback after an isolated error.

Live deployment 83 confirmed actual native foreground membership and `/proc` controlling TTY: Pi PID 116498, pgrp/session/tpgid 116498, tty_nr 34819. No synthetic foreground evidence was added. This integration still needs a built-artifact live run; it does not close the E2E acceptance criteria. Host-operator readiness and the protected coordinator-root contract remain part of standard-start integration.

## Standard-start scope selection contract

The existing protected installation manifest gains an optional `coordinator`
entry with exactly `id` and canonical absolute `path`. It is deployment
configuration, not a topology registry or project. Its ID and root cannot
collide with a configured project; existing grants may reference this ID.
Only the host principal assigned the `lab-overseer` role and explicitly
granted that coordinator ID can launch it. An isolated session cannot launch
another lab coordinator, and no worker/verifier/integrator can select the lab
root. Project roles continue selecting only configured projects. The same
scope resolver binds readiness to the protected root; project checkout data
cannot select a runtime or expand scope. This is the next integration slice,
not evidence that standard start already adopts it.

Implemented coordinator selection remains unaccepted live. Schema limits the
coordinator root to `/lab` or `/lab/<name>`, matching mount support. Mounting
`/lab` is restricted to lab-overseer; its source still requires nonroot owner,
while `/` is verified root-owned. The existing staging/idmap path binds over
the prepared `/lab` mountpoint without attempting to create it again. Ruby
and native terminal handoff both permit `/lab` only for an exact lab-overseer
unit. Review caught the ancestor-owner and handoff restrictions before the
live attempt; both are corrected with mount-path and real PTY/SCM regressions.
Native source `e70ad71d36b53b866743f3c81330813502db3627` replays exactly.
Linux isolated tests 17/17 (`fb2a8d8a-4c06-4a26-8079-9d167106c176`), handoff
3/3 (`7ded981a-a490-42ef-83e9-e456594828fc`), Ruby affected tests 69/494 and
native-source 13/42 pass. Full ace-lab before the final mount/handoff correction
passed 971 tests/4509 assertions, 16 platform skips; final changed paths were
then retested in the affected suite. Independent review found no remaining
scoped issue. A fresh built-artifact coordinator mount/start probe is next;
standard start adoption, positive eyes readiness and full E2E are still open.

## Operator readiness for standard start

A host `ace-overseer start` needs readiness without opening DynamicUser files.
Add one closed issuer action `readiness` with `project`, `role` and immutable
`terminal_id`. It is host-only: DynamicUsers keep the existing session-scoped
`agent.readiness` path. The existing SessionLaunchPeer authenticates host
socket credentials and pins its pidfd; the existing SessionConfiguration
requires the role account and explicit scope grant before any native lookup.
The native target must match the selected project/role. Reuse SessionReadiness
for independent target authentication and owner evaluation. Native transport
checks the host caller pidfd around each I/O; it never treats a host caller as
a session or permits arbitrary methods. No source fallback and no new state.

Operator-readiness source integration is implemented: HostReadiness uses the
existing host peer/scope grant, exact native selection and SessionReadiness.
IssuerRequest validates the closed action before dispatch; DynamicUsers are
refused on this route. SessionNativeTransport distinguishes a pinned host
caller from authenticated session identity and checks its lifetime around I/O.
IssuerClient validates target, role and boolean readiness. Tests 44/216 pass
(report `a2d91f8f-fb0b-4beb-a1e7-0d9556f5fb8e`); independent review found no
scoped security/dataflow issue. This endpoint is not installed on candidate88
yet and still requires a built-artifact host probe. Next standard-start work
must select protected scope/runtime, converge on actual native session identity,
handle initial interactive readiness before the first prompt, and preserve
uncertain-delivery idempotency. Session callers also need a narrowly scoped
workspace/startup-observation surface; do not use unrestricted native sockets
or have the E2E runner dispatch the work on the overseer's behalf.
