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
Their build-source provenance is not yet verified from archive contents.

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
