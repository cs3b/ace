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
