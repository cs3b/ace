---
id: 8wr.t.qkc
status: pending
priority: high
created_at: "2026-09-28 17:42:36"
estimate: TBD
dependencies: [8wr.t.qk1, 8wr.t.qkb, 8x0.t.ig4, 8x3.t.xz9]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [.ace-tasks/_archive/8x/v/8wr.t.qk1-complete-forge-neutral-worktree-review/8wr.t.qk1-complete-forge-neutral-worktree-review-and-task.s.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, .ace-tasks/_archive/8w/y/8wk.t.l1e-forge-neutral-git-core-with/8wk.t.l1e-forge-neutral-git-core-with-github-and.s.md, .ace-tasks/_archive/8x/v/8wr.t.qjl-persist-assignment-attempts-and-exact/8wr.t.qjl-persist-assignment-attempts-and-exact-execution.s.md, .ace-tasks/8wr.t.qkc-prove-the-complete-forge-neutral/ux/usage.md, .ace-tasks/8x0.t.ig3-unify-review-loop-ownership-and/8x0.t.ig3-unify-review-loop-ownership-and-effective-policy.s.md, .ace-tasks/8x0.t.ig4-bound-review-convergence-and-expose/8x0.t.ig4-bound-review-convergence-and-expose-escalation.s.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/protected-authority-contract.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/consumer-dependency-map.md]
  commands: []
needs_review: false
position: 6o000i
---

## Central Lab acceptance — Captain decision 2026-10-05

Lab installation and execution of the shared system test belong to **lab-config:8wl.t.gad.2**, checklist row `forge-matrix`. Installed scenario descriptions below define its referenced obligations, not a second deployment/run owned by this task. This source task must deliver its own implementation, automated package/integration verification and review; missing source behavior cannot be moved to the Lab test or marked done. Any reference below requiring whole installed Lab acceptance before source completion is superseded by this ownership split. Cross-repository acceptance records exact producer versions/source receipts, failures and retest evidence once in gad.2.

This task retains any package-level matrix/scenario/automation deliverables. Its actual deployed end-to-end run is a row in gad.2; that row is not an entry dependency which requires gad.2 to have already succeeded.


# Provide executable forge-neutral delivery acceptance scenarios

## Outcome and ownership

Maintainers receive executable scenario assets and a matrix covering local-only Git, GitHub, default Forgejo and another named Forgejo, with deterministic integration evidence and a classified source coupling inventory. This task delivers and reviews those assets locally. lab-config gad.2 owns their deployed execution and final installed matrix receipt; lab-overseer l2d.8 consumes that receipt without another run.

## Inputs and public artifact contract

Input: delivered qk1/qkb artifacts and their exact SHAs/versions, fresh installed package environment, scoped disposable repositories on each required provider and explicit test-operation scope. Required endpoints are configured named servers; no inferred production targets, credentials in fixtures or provider bypass. This task supplies executable acceptance scenario assets through existing test tooling plus `acceptance/matrix.md` beside the task; no new CLI/framework.

Each matrix row records scenario ID, selected server/provider/repository, task/assignment/attempt where relevant, expected result, observed result, tested head/version, exact command, exit status, artifact path and review reference. Provider/local not-applicable cells are explicit, never passed. Missing/skipped required rows block acceptance. Secrets never appear in artifacts.

## Required rows

| Behavior | Local-only | GitHub / default Forgejo / named Forgejo |
|---|---|---|
| Git / task / review isolation | No provider config, CLIs, credentials or network | Named/default/remote resolution and exact identity |
| Worktree PR lifecycle | Local branch/task no-PR path | PR checkout; task draft create; fork and canonical provenance; preview/apply evidence |
| Review lifecycle | Local subject and dry-run | Diff/comments/checks; exact-head verdict; opt-in post; advertised unsupported features |
| Task issue lifecycle | Local CRUD and hierarchy | Link/repeat/sync/close/reopen/clear; pending recovery; ownership conflict |
| Assignment delivery | Local recipe | Draft/review/ready/authorized merge; exact qjl evidence; restart reconciliation |
| Workflow installation | Resolve final sources from fresh external cwd | One canonical workflow, role handoffs, merge/release separation |

Every remote column includes unknown server/provider, invalid default, ambiguous/mismatched remote or URL, missing binary, authentication failure, offline state, malformed output, absent object and head change. Mutating rows include lost-response reconciliation; merge must have server-side expected-head enforcement or report unsupported rather than unsafe success. CI failure alone is advisory; actual test/reviewer/head failures block. An unsupported required merge capability is a failed acceptance row and must be repaired in its provider owner; it is never a permitted skip. Provider-specific unsupported optional features are explicitly recorded and must not be required by the common delivery scenario.

## Coupling closure

Inventory source, config, package dependencies, commands, URLs and active handbook/skills for ace-git-worktree, ace-review, ace-task, ace-assign and canonical workflows. Classify every direct gh/fj/GitHub match as provider-owned execution, non-operational metadata/history, or defect. Defects return to the exact qk1/qkb child and block this task; no new duplicate implementation owner and no unexplained match accepted. Confirm removed GitHub-specific interfaces and Python lab/labd paths are absent from the final active delivery route.

## Verification sequence and failure behavior

1. Run each modified package through `ace-test PACKAGE all` and the monorepo `ace-test-suite`, preserving actual reports and exact head.
2. Run deterministic integration cases against real temporary Git and controlled provider IO, including all failure paths and unknown outcomes.
3. Deliver runnable installed scenario assets specifying exact package inputs, disposable endpoint scope, outcome collection and remote receipt verification. Execute them only as part of lab-config gad.2; its rows retain installed evidence. Test-only credentials stay scoped/out of artifacts.
4. Obtain independent review of exact source/scenario assets, executed deterministic checks and classified coupling inventory. Unexecuted installed rows stay explicitly open in gad.2, not reported as passed here.
5. Re-run only impacted rows after fixes and reconcile the final set to one coherent delivered version combination. Record retained valid evidence explicitly; never mix stale review heads into a newer delivery claim.

No endpoint availability or authority means an unexecuted row, not a pass. Preserve evidence and report the exact missing endpoint/scope. No blanket disabled test, package test stub or report exit 0 can replace the row. Re-reading/revalidating unchanged evidence is idempotent. A changed head invalidates affected evidence and requires rerun/review.

## Completion and boundaries

Source completion requires executable assets for every required row, executed deterministic integration/failure checks, fully classified coupling inventory and independent source/scenario review. The one installed completion requirement—every deployed row executed against an exact manifest with independent verdict—is owned by gad.2 and consumed by l2d.8. No live matrix pass is required or claimed to close this source task. Single verification slice, advisory size: large. No production release, uncontrolled cleanup, service redesign, new task engine or bypass of authorization. Tests cannot send privileged production operations under the guise of fixture setup. No unresolved product questions; live infrastructure prerequisites are explicit execution inputs.

## Carried endpoint proof — uj0 closure, 2026-10-02
Central gad.2 `forge-matrix` obligation: On the actual Lab installation, record installed fj version and sanitized per-subcommand capabilities, then run a read-only explicitly named-server/repository query from a different checkout and confirm returned identity. Record exact package versions and endpoint identity in the matrix. uj0 delivered repository binding and tested the upstream fj v0.6.0 binary; its current-Lab smoke half lacked evidence. The Captain closed that implementation on 2026-10-02; this already-required named-Forgejo acceptance row owns the remaining installed endpoint proof. No access means unexecuted, never pass.

## Review-program final gate — 2026-10-04

R1 (8x0.t.ig2) is delivered storage/evidence foundation, not proof of caps or escalation. Required input now includes accepted R2 (8x0.t.ig3) and R3 (8x0.t.ig4) receipts for the installed review workflow. Verify effective policy/session/worktree binding, restart without duplicate repair, discovery/delivery round limits, infra retry accounting and escalation with retained history on the exact installed manifest. Missing limits or an unbounded review is a failed required row. Cross-repo lab-config:gad.2 consumes this proof; experimental ig5 does not gate acceptance. No dependency from qkb/qk0 to R3 is introduced.

Central gad.2 `REVIEW` obligation: Final review-policy row binds R2/R3 revisions and executes cap/escalation/restart negative scenarios before full Lab acceptance.

## Protected execution and live runtime observation — Captain correction, 2026-10-08

Required source inputs include xz9 for scoped cross-user execution. Use its
actual authenticated launcher/worker/reviewer/authority/executor route and
operation/result evidence. Worker-local success JSON is not independent
confirmation of a privileged effect. Keep bounded duplicate/lost-response and
uncertainty checks for those real effects.

The xza consumption-proof requirement is removed. No signed consumed or
superseded row, observer/signer service, dedicated Codex app-server or root
socket ACL is required. The existing ace-llm CLI executes in Herdr/tmux; query
or capture the selected live panel/process directly when the overseer needs
current state. Report submission as submission, observed output as output and
verified task results as results, without constructing message-read evidence
or a duplicate current-state ledger.

lab-config:gad.8/gad.b supply installed accounts, scoped handlers and ordinary
runtime wiring. gad.2 remains the single installed task/test owner. Its first
run launches a real task and observes the live runtime, output, result and
stop behavior. R2/R3 and genuine scoped-effect checks remain separate program
requirements; ig5 remains outside the gate. No installed pass is claimed here.

## Source completion checklist

- [ ] Executable scenario assets cover all required positive, negative and uncertainty rows with explicit provider applicability.
- [ ] Deterministic real-Git/controlled-provider integration and failure tests executed; affected package checks retained.
- [ ] Coupling inventory classified and source defects resolved by their owners.
- [ ] Independent source/scenario review accepts exact revisions and evidence contract.
- [ ] Hand off runnable assets and required manifest/endpoint inputs to gad.2; deployed result checkboxes exist only there.
