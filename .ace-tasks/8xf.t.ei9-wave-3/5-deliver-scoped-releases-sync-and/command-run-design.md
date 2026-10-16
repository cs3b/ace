# Project-command execution contract (ei9 .5 / iy6)

Current implementation plan, 2026-10-16. This extends the approved iy6 behavior;
source work and a nonsecret acceptance slice do not close delivery or publication.

## Owner and authority

Assign's existing ordinary owner registers a distinct `project-command/v1`
definition and immutable accepted request in its existing execution ref. This is
not PreparedWork, a synthetic task, legacy Work, or a local-only taskless
Assignment. Definition/result projection uses its own source-owned lifecycle.
All mutations use EvidenceJournal.mutate, the shared exclusion and mutation IDs.

The CLI directly authenticates to the owner. Agent admission observes current
native ancestry; operator admission requires an explicitly installed UID grant.
An operator has no fabricated pane. The existing root labd is the installed
launcher witness; its identity must be verified independently of requester and
executor. The caller cannot supply a UID, policy path, secrets, or launcher role.

## Policy and source

One root-owned project-command policy has a closed schema, explicit project,
executors (UID/GID/supplementary groups, HOME/cwd, nonsecret environment), services
(secret references and nonsecret additions), exact permitted command argv and
source identity, default executor/services, and grants. Each grant binds a
requester kind/UID, exact command, executor, and entire service combination.
Explicit service selectors replace defaults and deduplicate. No implicit union,
partial selection, broader identity, shell insertion, or ambient environment.
Policy/source revalidation occurs before claim and bind. Secrets are resolved
only in the admitted executor context; metadata stores references only.
Executable/source identity must survive admission-to-exec, using an immutable
accepted source view. A digest of a mutable script alone is insufficient.

## Execution protocol

CLI retains invocation identity before effects, admits directly to Assign, then
asks existing labd to execute that reference. Labd authenticates its actual caller
and owner compares it with the admitted requester. Source-closed owner operations
are admit, status, claim, bind and complete. Claim precedes fork. The child drops
identity, sets cwd/terminal, then waits on a private pipe. Parent submits actual
PID/birth, UID/GID/groups/cwd/process-group facts. Only a fresh non-replayed bind
acknowledgment releases that exact child. Lost acknowledgment/EOF closes the pipe;
committed but unacknowledged execution remains uncertain and never auto-replays.

Root-observed launch/exit facts remain distinct from executor delivery receipts.
The command's exit does not imply successful publication, installation or cleanup.
Status uses the original execution reference after requester/owner restart.

## Terminal and cleanup

Interactive mode uses a real PTY, resize, native no-echo getpass and signals.
Non-TTY mode uses pipes and reports stdin EOF truthfully. A framed protocol keeps
stdout/stderr bytes separate from terminal result frames. Socket EOF without a
result is uncertainty, never exit0. Teardown uses bounded generation-checked
process-group termination and reaping. Existing Work behavior is not refactored
as unrelated cleanup.

## Test responsibility map / implementation sequence

1. Assign owner lifecycle: real Git journal fixture, CAS/restart/status, concurrent
   claim, changed input, replayed claim/bind, lost responses and terminal outcomes.
2. Lab policy: closed schema, operator vs agent authority, exact defaults/replaced
   services/combinations, identity/cwd/argv/source mismatch, revocation and no-secret
   metadata. Pure decisions use units; trusted-file checks use real filesystem.
3. CLI + existing labd adapter: controlled socket composition and actual Linux
   distinct identities. Execute nonsecret probe through full gate first, never an
   injected callback presented as installed proof.
4. Real PTY: getpass/no echo, resize, EOF, Ctrl-C, exit0/nonzero/signal, trailing
   output; separate pipes test. Crash each boundary and prove no second execution.
5. Synthetic secret references, malicious environment names, changed executable,
   policy revocation, and detached descendants. Actual filesystem/root checks run
   from a fresh export. ACE package tests use ace-test and required ace-test-suite.
6. Independent adversarial review before deployment. Domain installation/real
   acceptance and publisher integration remain open until actually proved.

Planning friction: `bin/ace-task plan 8xf.t.ei9.5` produced no output for four
minutes (owned PID92729). Stopped with SIGINT per task-work planning guard;
current task spec plus this grounded plan is the retained implementation input.

## Implemented policy shape and bridge boundary

`project-commands.yml` version1 contains `projects` mapping. Each project has:
`launcher {socket_path,identity_path}`, `default_executor`, `default_services`,
`executors`, `services`, `commands`, and `grants` (all closed mappings).
Executor: `uid,gid,groups,home,cwd,path,environment`; service:
`environment,secret_references`; command: exact `argv,executable_sha256,source`
with source `{head,tree}` (both null for non-Git probes, both exact Git object IDs
for release source). Grant: exact `kind,uid,command,executor,services`.
Conflicting environment/secret destinations and ambient loader injection refuse.

The installed root daemon publishes its actual birth identity in a root-owned
receipt. Its short-lived ACE Ruby bridge uses the existing OrdinaryClient. Owner
verifies real root ancestry to the pinned daemon and records that canonical daemon
identity; a new helper PID does not invalidate replay or become a fake worker.
Python remains the existing daemon's kernel/terminal adapter. It does not implement
Assign wire authentication, lifecycle or policy.

Operator grants are OS-account grants. When native agents and an operator share a
UID, that UID's processes share operator authority; no environment hint proves
human presence. Agent-selected requests still require genuine native ancestry.
Human-only grants require an independently attributable operator identity.

The initial complete acceptance target is a nonsecret probe. Secret-reference
execution is explicitly refused before claim in this slice. Publication remains
open: accepted code/cwd must stay immutable while artifacts/cache use configured
external writable storage, or the existing publisher consumes retained exact
built artifacts with digests. Do not make writable source pass as immutable or
mistake a manual prior publication for autonomous proof.

## Spawn-boundary correction and retained harness evidence

Kernel-r1's real Linux root checks passed41/zero skips, but exposed Python's
unsafe-fork warning: labd serves requests from threads. This warning invalidates
that spawn boundary as the final design. The command path now invokes a short-lived
ACE Ruby execution helper using Popen/pass_fds without preexec_fn. It has no socket
listener or journal of its own, enforces one live Ruby thread before fork, and uses
OrdinaryClient directly. Existing labd remains the root admission/FD adapter; the
ACE helper owns reviewed kernel gate/PTY/pipes/cleanup. Legacy Work paths are not
changed. Kernel-r1 remains superseded evidence, not final acceptance.

Root kernel-r2 harness friction: Lab has no installed ace-test runner or minitest;
its existing checkout binstub also lacks bundler/setup in raw SSH. Provision a
hash-verified disposable public ace-test-runner0.28.1 harness under /run, reusing
the immutable coordinator dependency graph. This is test harness setup, not a
product failure or a change to production graphs. Run package tests through that
public runner; never replace it with raw Ruby test execution.

Verification friction: default monorepo suite was executed and currently includes
an unrelated `ace-support-items` timeout in
`test_update_waits_for_lock_and_merges_latest_frontmatter` (report
`.ace-local/test/reports/support-items/a3ff4fd2-5775-413e-896b-596b01107fb0/`).
The child then reports ENOENT after fixture teardown. No support-items product or
test files are modified by this change. Retain this red result; a focused baseline
comparison must distinguish timing/fixture failure from any candidate regression.
Do not call the default suite green while this remains unresolved.

Publication readiness, source-verified: maintained
`.ace-bin/ace-rubygems-publish --scoped-publication` already consumes an exact
artifact/digest/gem/version without batch queue/build writes. Reuse retained,
digest-bound built artifacts through that path; do not invent an external-output
option merely because normal batch builds write package directories.

The ordinary composition currently supplies AssignmentBinding only. Existing
ServicePublicationBinding/ProtectedPublicationPublisher and with_publication_hitl!
are tied to the protected same-process authority; they are not automatically an
ordinary command publication capability. The remaining ordinary publication
admission/OTP/provenance join must reuse existing canonical service claims,
publication evidence and vault, without a new side ledger. A command definition
is not a managed TaskAttempt, and a nonexecuting operator-question envelope cannot
approve effects or OTP. These obligations remain open after the nonsecret slice.

Focused baseline diagnostic: `ace-test --filter TEST_METHOD` selected zero files
(the option is a file-pattern filter here), so that exit0 is not test evidence.
Use the explicit affected test file without that filter. The candidate and baseline
support-items/task/herdr package trees are byte-identical to2e9005f39.

Evidence retention friction: gitleaks classified fifteen path-key/SHA256 pairs in
R3 domain-manifest.json as generic API keys. Every finding was verified against
the frozen source bytes as a SHA256, not a credential. The committed evidence
uses a lossless typed-array representation with the original input manifest SHA;
the exact root-tested frozen manifest remains unchanged in the local export.

Independent review identified ordinary assignment IDs could squat the command-
journal namespace. All ordinary lifecycle routes, including transfer and status,
now reserve that prefix before any mutation or input admission; regression checks
reject registration/status and retain unchanged canonical history. Command replay
never releases the execution gate, including a lost bind ACK.

## Source acceptance closure (2026-10-16)

R3 root disposable acceptance verified exact frozen inventories/hashes: ACE686
and domain1210 files. Actual private-mount public CLI UID1000 → canonical owner
UID966 → existing labd → root ACE helper → executorUID65534 passed40 domain
tests/zero skips. Public ace-test kernel runner passed5 tests/52 assertions/zero
failures/errors/skips. Production ownerPID554643 remained active. Retained R2/R3
evidence proves source acceptance, not installed release or autonomous publication.

Required default monorepo suite:48 packages passed,3 failed;12,349 passed tests,
3 failures,42 skips,43,153 assertions. Changed Lab493/2756 and Assign1078/4746
passed. Unchanged support-items lock timeout, Herdr1s subprocess timeout and task
alias-lock race passed paired baseline/candidate explicit-file reruns:17/27,46/75
and104/330 respectively. Their source trees equal2e9005f39. Concurrent assembly
suite pressure plausibly explains timing, but does not make the red run green.
Parent's separate assembly suite at33bf2efe5 passed51 packages/12,358 tests.

Remaining gates: independent review, full domain suite before merge, coordinated
package versions/dependency floors, installed acceptance, secret/OTP/publication
authority join. No versions bumped; task remains in-progress.

## Next publication/OTP join (design only)

The smallest complete autonomous release uses the REAL ordinary delivery assignment
and attempt as publication authority. A taskless project command only builds
nonsecret retained artifacts; it does not need publication authority. iy6's
interactive publication/secret requirements remain OPEN under ei9.5 and must not
be claimed delivered by this first release path or moved outside the program.

1. Producer retains accepted gem bytes plus gem/version/platform/SHA256 and accepted
   source head/tree/project. Use scoped-publication input without rebuilding inside
   read-only accepted source or altering accepted bytes. Join that artifact to the
   real delivery attempt's reviewed head and candidate generation.
2. Extract shared fixed service admission/publication rules from Endcap into the
   existing ordinary Router/journal owner. Reuse request_service/begin_dispatch/
   service_status and publication_challenge/publication_continue CAS/effect semantics,
   backed by the ACTUAL ordinary assignment/attempt and reviewed candidate. Bind
   exact artifact/input digest, installed service grant and actual receiver process
   generation. No synthetic assignment, taskless attempt or command effect envelope.
3. Compose existing ServicePublicationBinding beside that same-process fixed owner
   and ordinary AssignmentBinding. Reuse current protected selector/envelope fields
   where they represent the real parent. Its with_publication! currently calls
   Endcap#with_publication_hitl!: expose that same owner-held authorization contract
   through the extracted owner, with original receiver/challenge/generation checks.
   The unassigned operator-question context cannot authorize effects. Keep OTP in
   the existing vault/channel, never journal, command definition or ambient IDs.
4. Reuse ProtectedServiceReceiver registry preflight, OTP challenge/consume, fresh
   publication_continue permit and uncertain-outcome reconciliation. Existing
   ProtectedPublicationPublisher#push! invokes maintained --scoped-publication with
   retained exact artifact/digest/gem/version; verify! independently compares registry
   SHA. Lost issuing ACK never permits push; ambiguous push reconciles exact registry
   bytes before any continuation.
5. Accept one actual scoped release with project-correlated OTP. Wrong/revoked real
   delivery attempt/service/artifact/challenge/project, expired/rejected OTP, lost
   ACK, partial/uncertain push and restart stay open until canonical exact-artifact
   proof. No new broker, ledger or command-publication schema is needed. A later
   separately authorized taskless publication feature would require its own real
   provenance design and cannot borrow this parent authority.

Final namespace-focused verification: ace-test selected ordinary_lifecycle_test.rb
and command_execution_test.rb;25 tests/214 assertions/zero failures/errors passed.
Report assign/6c08e10e-f8c0-44a0-835a-ad28cfbe3c86.

## Review correction: owned detached descendant cleanup

The initial group-only cleanup did not satisfy promised detached descendants.
Existing BoundedProcess and LLM ProcessSupervisor terminate only their original
PGID; the latter supplies the established Linux subreaper pattern. The ephemeral
single-thread command helper now uses a small Runtime OwnedChildScope: assert no
preexisting children, enable subreaper before fork, signal/reap only unreaped kernel
direct/adopted children, retain leader status and refuse completion if bounded
cleanup cannot prove only the zombie leader remains. No global PID/UID scan or
new process capability. Verify real setsid/double-fork descendants and client loss
in a fresh root R4 export INCLUDING new Runtime source and runner pins.
CommandExecutor itself must verify real AND effective UID0 before owner contact.
Taskless secret/publication remains open.

R4 acceptance friction: RED baseline correctly reproduced2 detached-child failures
(7 tests/64 assertions). GREEN unexpectedly failed6/7 with NoMethodError before
fork. Source diagnosis: IO#read(length) returns nil at EOF; an empty /proc children
inventory is normal before this helper forks. Normalize only that nil read to the
empty inventory. Keep invalid/oversized inventories refused. Add isolated real-IO
regression for empty reads; preserve failed R4 export and reports unchanged. Kernel
fixture now retains bounded exception message/backtrace for these nonsecret probes.

The sole ephemeral command helper establishes SIGCHLD DEFAULT after verifying its
child set is empty and before enabling subreaper/fork. An inherited ignored signal
or custom auto-reaper must not discard child wait status or unpin a PID. Real R6
ignored/custom incoming-state regressions reproduce both failures on the previous
code and pass after the reset; reports and Pi delta verdict are retained here.
