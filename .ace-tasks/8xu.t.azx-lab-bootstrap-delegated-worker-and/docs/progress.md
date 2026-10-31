# Integration evidence — 2026-10-31

## Preserved source

Omarchy `/home/mo/Projects/ace-bootstrap-slice`, branch `feat/lab-self-bootstrap`,
was clean (no tracked modifications or untracked nonignored files).
All six commits fetched into `refs/remotes/omarchy/lab-self-bootstrap` and
retained unchanged in `codex/lab-bootstrap-delegation`:

- fc72f8fea9c637cf526bfbd0cee2c2908deb1d75
- fce6d7db308642afe974c8ebabc155022966ef10
- 8f0c0bbb9b11f09433785ea701ea9466408708f1
- db6667ffbc2aa68052f3ba577c9fa1dfd20c9e4c
- 799c71b02e603f4ab0c286b13ff5cc45d498f3f2
- c4703dfdcf8925a1e191aed6a69c710af600bdae

Both remotes' main refs were ae302461183afbc4fc4bf45c1f3204a204aee107.
Forgejo fix/lab-start-native-herdr was fc72f8fea9c637cf526bfbd0cee2c2908deb1d75
(the reported PR #84 branch); it is already an ancestor, not duplicated.

Existing Omarchy artifacts, not rebuilt or claimed accepted:
- `.ace-local/candidates/pre2/ace-overseer-0.28.0.pre.2.gem`:
  c6e83d2e8ea87397687223c9fe7c3aa5e4d8cb58562b860e03302a538074a640
- `.ace-local/candidates/pre3/ace-overseer-0.28.0.pre.3.gem`:
  c493fee37aca75ccdae62bb1c132c5fe25aa3cb70de95cc041dfc5a1a93cd3ae
Payload source equivalence is now verified in prerelease-provenance.md (all68files); actual historical build invocation is not attested.

## Defects found

1. Lab start guide explicitly instructed the coordinator to edit config and
   install bundles. Replace with lab-worker commissioning.
2. ProjectBundle dropped explicit installed mode and executed project binstubs.
3. Eyes could only be armed by an interactive slash command, not its agent tool.
4. coworker start only prints a brief; delegation must explicitly launch an agent.
5. Imported foreground test compares /var with canonical /private/var on macOS;
   fix fixture expectation, keeping production canonicalization.

## Remaining

Runtime test suite, independent review, packaged installed rehearsal, publication,
deployment, real worker/verifier cycle and five-minute live idle acceptance.
No claim that documentation alone completes the task.

## Scope addition: project layout

Captain chose `/lab/<project>` with `.ace-wt/` and project state inside each
project; a shared versioned operational ACE installation in installed mode,
separate from development bundles. This supersedes lab-config AGENTS.md's
2026-10-31 project-selected operational ACE rule. Added child .7.

Read-only inventory: /lab/projects/{ace,ace-integrator,nervus,overseer};
/lab/repos/ace.git; /lab/worktrees/{ace,nervus,overseer}; /lab/state contains
credentials, backups, runtime, Herdr, control, historical works and reports.
Do not remove these blindly. The canonical ACE worktree is af68f8fc1 with
nested .ace-wt/8xs-overseer-start at 92072cad6. Live project configuration and
sessions must be reconciled before changing canonical paths.

## Observation boundary defect

Local/remote observe rows had readable keys and missing/invalid wire IDs,
whereas eyes validates 64-hex keys/revisions and safe IDs. Normalize only those
rows at EventObservation's wire boundary, retaining source_key/source_id;
canonical HITL identities stay unchanged. Add a Ruby-to-shipped-JS validator
integration test. This was not covered by the prior isolated tests.

Live inspection also found NO eyes configuration and NO persisted eyes state
in the coordinator's current/previous sessions. The live Pi has installed mode
but a coordinator-local bundle; its parent shell references a removed runtime.
Explicit runtime selection and extension reload are required for acceptance.

## Preservation and review checkpoint

All lab agents and the two identified host lab-config writers were stopped by
explicit Captain authorization. Herdr session `lab` returned agents: [].
Snapshot: `/var/lib/lab/backups/8xu.t.azx/projects-before.tar` (root-only),
SHA256 893b8394b67647256907fed6f7a0713822de6b4f4a082261b8a76470a6f7a974.
Includes canonical ACE and coordinator, ACL/xattrs/numeric ownership.

Independent direct review found mutable terminal titles used as ownership;
fixed using stable tab identity with ambiguity refusal. Imported subprocess
startup now uses existing bounded runner. Dedicated operational bootstrap roles
resolve the ordinary worker's worktree-only scope conflict. Latest full
Overseer suite:448 tests/1986 assertions,0 failures,1 existing skip.
Coworker suite:405 tests/1900 assertions,0 failures; added shipped-role
composition regression:21 tests/134 assertions,0 failures. Eyes JS suite is
executed through its Ruby test wrapper, not just syntax checked.

Provider review review-8xub4g covered an earlier snapshot; findings are being
verified and fixed, and a new full-delta review is running. No release verdict
yet. Host documentation updated for new policy; actual cutover is not yet done.

## Current full-delta review and ownership gate

Provider review `review-8xubj5` completed against the functional integration
delta and found no merge-blocking core defects. Its missing-owner-workspace
edge case is being hardened to explicit refusal; first-turn eyes wording and
session source-health reset are also being corrected before artifact rebuild.
The status-option documentation finding was already fixed before this report.

Captain explicitly requires canonical projects owned by `mo:mo` and additional
access scoped to executor sessions. The ACE-only cutover preflight passed for
2 worktrees, 63,395 filesystem entries and 4 configuration files. It found
49 loose Git objects hardlinked outside ACE: isolate verified bytes before any
ownership change. Two exact assignment selector symlinks retain the same IDs
using relative targets. 38 historical transport envelopes are preserved as
evidence, with orphan replies explicitly unresolved. Apply has NOT run.

Three release versions are prepared (not published): ace-wake 0.2.0,
ace-coworker 0.8.0, ace-overseer 0.28.0. Rebuild after final source corrections;
do not deploy the earlier prepared artifacts as the final candidate.

## Reviewed candidate ffa64e234

Independent review approved the final missing-workspace refusal, first-turn
agent-callable eyes instruction and binding-generation guard against late
source-health writes from disposed sessions. Wake full suite passed through
ace-test; targeted lab-start tests passed 21/135. Earlier full suites remain
green as recorded above. Review approval is not live acceptance.

Fresh installed rehearsal resolved 42 gems, including transitive json and
ace-hitl-hermes 0.9.6. One public dependency ships 0640 source files: the
root-owned public runtime requires a+rX,go-w convergence so mo can load it.
This permission normalization does not apply to project/private files.

Host policy docs committed 0b3d3c7 after independent review. Focused host tests:
18 passed,1 skipped,1 baseline missing evidence_transfer failure, reproduced
from clean e176247cd93281e5216193250e750efeeffa547e. No host deployment yet.
Candidate checksums are in release-candidate.json. OTP/publication, migration,
new runtime activation and the live delegated cycle remain outstanding.

## Published release and integration

PR400 merged by rebase after Captain approval, integrated main
2f6da30113e01378d369e493448ea5ba46bf40e1. The tree matches the reviewed
branch; source artifact provenance remains ffa64e23419eb3cf15ee0f15ba28b4843bcc98d0.
Operator published all three versions in5.1seconds. RubyGems v2 metadata
independently confirms all three SHA-256 values in release-candidate.json.
Do not rerun publisher to verify. Installed candidate can now be selected
after fresh migration preflight. SSH currently requires Tailscale reauthentication;
no cutover has been executed.

## Live migration completed (publication verified)

Canonical ACE moved to /lab/ace; two worktree HEADs preserved. Forty-nine
externally shared loose Git objects were isolated with hash verification before
ownership changes. Tree ownership is mo:mo, named/default ACLs removed and
directory SGID cleared. Historical transport evidence preserved root-only;
orphan replies remain unresolved.

Migration verification initially refused because root git status atomically
recreated exactly two indexes as root:root0664. Independent inspection and
backup headers identified both; scoped recovery restored mo:mo0660, verified
all ownership/modes/HEADs and late-frame checks, then resumed only remaining
steps. Do not rerun apply. Git verification must use mo/GIT_OPTIONAL_LOCKS=0.

Herdr service now selects the published ffa64e closure; mo removed from
lab-control and fresh service groups verified. Completion receipt:
/var/lib/lab/backups/8xu.t.azx/ace-cutover-complete.json. No live agent cycle yet.

TS-MONO-001 setup refused missing authoritative full installation manifest;
12 historical packages lack verified artifact build-source SHAs. Selected
versions inventory exists locally, but is not substituted for provenance.
No test case executed; this remains an explicit verification limitation.

## Installed readiness and first coordinator turn

ace-lab install completed ok:true and verify ready:true with58pass/0fail.
All12 projected wake files independently match published ffa64e runtime and
are mo:mo. Removed obsolete coordinator self-project entry/grant after
installer refused foreign-grant mismatch; preserved authorization backup.
Set UTF-8 locale explicitly (cleanenv previously caused US-ASCII error).
Coordinator domain instructions and mise selection committed649daed locally;
unrelated README/Gemfile/vendor WIP preserved.

Bare installed ace-overseer start launched Pi in existing w3:p1 on
2026-10-31T12:50:02Z. Session:
/home/mo/.pi/agent/sessions/--home-mo-Labs-overseer-lab--/2026-10-31T12-50-02-003Z_01a19202-8892-7af3-b488-e95a67f9aa68.jsonl
Actual first turn recognized installed runtime and historical private tasks.
Delegation/eyes/worker result acceptance still in progress, not yet claimed.

## Delegation behavior finding

Eyes enabled and healthy on the live coordinator, but the initial turn pursued
project runtime implementation diagnosis instead of commissioning a worker.
An explicit current commission superseded historical HITL8xu80c; a second
clarification explicitly assigned diagnosis to the worker. The actor then
created private8xu.t.jh7 with three children and executable8xu.t.jh8.
A regex parse truncated child IDs and created a self-dependency; the actor
recognized and corrected its task metadata. No worker launch proven yet.

Packaged guide fix a71893d93 assigns diagnosis/reproduction to the worker,
requires only observed symptom+desired outcome for commission, and gates
project startup on worker+independent verification. Independently reviewed,
not yet published/deployed. Current lab remains published0.28.0.

## First real worker and least privilege evidence

Independent read-only audit confirms bootstrap-worker PID2937792 in w5:p1,
assignment8xujj4, task8xu.t.jh8, worktree .ace-wt/t.jh8. UID/GID1000 and only
supplementary group1000; installed ffa64e runtime, no Bundler/Ruby overrides,
packaged bootstrap-worker guide loaded. Coordinator ended turn at
13:04:45.549Z after dispatch; eyes delivered one baseline pending-revision wake.
At13:10:42Z coordinator had41 assistant messages (last13:08:27.101Z), active
eyes,0errors,no breaker,0pending,40observations/1wake. Idle verification ongoing.

Guest permission audit: sudo denies mo; primary group only; sudoers.d/Polkit
local rules empty; inspected local wrappers have no setuid/capability grants;
legacy lab-admin scripts gate operations by effective identity. Host mo Incus
operator capability remains deliberately separate. No extra privileged lease
was needed by this bootstrap worker.

## Live idle acceptance PASS

Paired snapshots cover326.812seconds (>=5minutes): assistant messages
41→41, observations40→50, wakes1→1, pending0→0, eyesenabled and0errors.
Coordinator Herdr status idle; worker independentlyworking. Evidence is
idle-baseline.json, idle-after.json and idle-result.json. This verifies the
coordinator silence requirement, not worker completion or project readiness.

Generic failure-reporting fix preserves the real early blocked message instead
of replacing it with no-project-scope-report. Independentreviewapproved; full
Overseer suite451tests/2030assertions/0fail/0errors/1existing skip, report759ef382.
Not deployed yet.

## Worker and independent verifier completed; final startup still blocked

Worker assignment8xujj4 finished step010 and reported success event8xuk0q.
It identified renamed-root mise/Pi trust gates, applied per-user trust for
/lab/ace, preserved project Git state, and removed diagnostic tabs.
Independent assignment8xujj41 rechecked readiness without repair or launch;
success event8xuk86. Report/evidence live in executable task8xu.t.jh8 worktree.
Coordinator received the results and invoked actual reconcile only afterwards.

Fresh target w4:p3 did not boot: shell reported pi command not found. Visible
environment setup line is very long and its PATH appears truncated. Source
launcher investigation underway; no project first turn/eyes acceptance claimed.

Permission convergence initial full lab suite:678tests/3266assertions,0fail,
0errors,4skips,58.39s; reportb08844ac-2d64-4247-b5f5-45b44f113e8f. Independent
review found missing-transitive-dependency dryrun regression; fixing before
commit/release. Slowest tests are existing real installation/readiness checks
(6.19s fresh installation,2.30s installed gemset).

## Follow-up defects verified and repaired in source

Launcher root cause:3613bytes of selector unset plus482bytes remaining text
exactly fills Linux canonical TTY4095-byte input; PATH tail is lost. Source
commit0a342ce30194dc5903d3dc5a8a6342af6dcfce55 uses a private0600 script
in a checked0700 project handoff directory, short dot command, actual output
acknowledgement before harness start, and cleanup. Independent review approved;
real canonical PTY regression executed (50tests/280assertions/0fail,1existing
skip across targeted files, reportd35cc395). Not deployed yet.

Permission review initially missed RubyGems stripping installedspec.files.
Actual live ace-support-fs specification has0files; initial implementation
would not repair the real library defect. Correction5e2378eaa inventories
verified exact-identity cached .gem archive contents, preserves unknown files,
and refuses absent/mismatched cache. Real fresh installed library0640fixture
now proves normalization. Independent review approved; full lab680tests,
3286assertions,0fail/0errors,4skips, report13e7056f.

Live report audit: worker8xujj4 / event8xuk0q and verifier8xujj41 / event8xuk86
were accepted in sidecar notes but assignment and processed_report fields
were absent from actual private taskmetadata. Notes were initially written
to a guessed sibling slug. Never treat these notes as machine receipt proof.
process-reports dryrun also incorrectly matched readiness8xujjf to remaining
confirm-start step. No blanket apply was executed. Source fixes under review
require explicit planner allocation, durable assignment/receipt fields, and
actual resolved taskpaths; final confirmation must remain coordinator-owned.

Late wake audit:6messages had6distinct batchhashes. Last batches13:34:21,
13:36:23,13:37:06 reflected distinct earlier revisions; wakecounter stayed6
through continued observations. No duplicateenqueue defect confirmed; do not
modify eyes based on stale queued messages alone. Coordinator nowdone/idle
with eyes active and actualstart blocked awaiting published fix.

## Final source verification before patch release

Report acceptance cc898b91f963b32844b78a78371109d8b177fc0c requires actual
task-worktree owner resolution, role allocation and completed nonempty
assignment before success writes (including duplicate continuation). Explicit
confirm-start remains a coordinator operation. Real queue-cycle integration
9tests/200assertions passes including premature/wrongrole refusal and crash
recovery. Independent reviewer approved final source with no open findings.

Monorepo run:52otherpackages passed; Overseer's2 failures exposed the now-fixed
worktree metadata interpretation. Full final Overseer rerun471tests,
2209assertions,0fail/0errors,1existing skip (ca974e8c). Lab680tests passed
(bd73dabb). Other packages were unchanged after that suite; not falsely
claiming the initial suite invocation itself exited successfully.

Preparing patch-only ace-overseer0.28.1 and ace-lab0.14.1. No dependency
follower bumps required. These follow-up fixes remain undeployed.
