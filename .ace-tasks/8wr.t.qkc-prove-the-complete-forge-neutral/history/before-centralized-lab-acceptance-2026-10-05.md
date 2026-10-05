---
id: 8wr.t.qkc
status: pending
priority: high
created_at: "2026-09-28 17:42:36"
estimate: TBD
dependencies: [8wr.t.qk1, 8wr.t.qkb, 8x0.t.ig4, 8x3.t.xz9, 8x3.t.xza]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [.ace-tasks/_archive/8x/v/8wr.t.qk1-complete-forge-neutral-worktree-review/8wr.t.qk1-complete-forge-neutral-worktree-review-and-task.s.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, .ace-tasks/_archive/8w/y/8wk.t.l1e-forge-neutral-git-core-with/8wk.t.l1e-forge-neutral-git-core-with-github-and.s.md, .ace-tasks/_archive/8x/v/8wr.t.qjl-persist-assignment-attempts-and-exact/8wr.t.qjl-persist-assignment-attempts-and-exact-execution.s.md, .ace-tasks/8wr.t.qkc-prove-the-complete-forge-neutral/ux/usage.md, .ace-tasks/8x0.t.ig3-unify-review-loop-ownership-and/8x0.t.ig3-unify-review-loop-ownership-and-effective-policy.s.md, .ace-tasks/8x0.t.ig4-bound-review-convergence-and-expose/8x0.t.ig4-bound-review-convergence-and-expose-escalation.s.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/protected-authority-contract.md, .ace-tasks/8x3.t.xza-observe-native-inbox-outcomes-before/observation-authority-contract.md, .ace-tasks/8x3.t.xz9-execute-scoped-services-across-os/consumer-dependency-map.md]
  commands: []
needs_review: false
position: 6o000i
---

# Prove the complete forge-neutral delivery acceptance matrix

## Outcome and ownership

Maintainers receive one executable acceptance matrix proving the delivered core/providers and all migrated consumers work across local-only Git, GitHub, default Forgejo and another named Forgejo. It identifies exact code/package versions, executed scenarios and independent review. lab-overseer l2d.8 verifies this receipt; it does not own or rerun this matrix. lab-config gad uses the accepted receipt as one condition for the next full Lab test.

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
3. Install the exact delivered packages into a clean isolated environment and execute the required real-provider success paths on explicitly scoped disposable endpoints, then verify fetched receipts against remote state. Test-only credentials stay scoped/out of artifacts.
4. Obtain independent review of exact tested changes and the completed row/coupling inventory. Compare task IDs/versions/SHAs across receipts; contradictions are failures, not documentation cleanup.
5. Re-run only impacted rows after fixes and reconcile the final set to one coherent delivered version combination. Record retained valid evidence explicitly; never mix stale review heads into a newer delivery claim.

No endpoint availability or authority means an unexecuted row, not a pass. Preserve evidence and report the exact missing endpoint/scope. No blanket disabled test, package test stub or report exit 0 can replace the row. Re-reading/revalidating unchanged evidence is idempotent. A changed head invalidates affected evidence and requires rerun/review.

## Completion and boundaries

All required rows executed and verified, coupling inventory fully classified, exact installed versions/SHAs retained and independent verdict present. The receipt identifies acceptance for lab-overseer l2d.8 and lab-config gad, with no implication that the full Lab system test already passed. Single verification slice, advisory size: large. No production release, uncontrolled cleanup, service redesign, new task engine or bypass of authorization. Tests cannot send privileged production operations under the guise of fixture setup. No unresolved product questions; live infrastructure prerequisites are explicit execution inputs.

## Carried endpoint proof — uj0 closure, 2026-10-02
- [ ] On the actual Lab installation, record installed fj version and sanitized per-subcommand capabilities, then run a read-only explicitly named-server/repository query from a different checkout and confirm returned identity. Record exact package versions and endpoint identity in the matrix. uj0 delivered repository binding and tested the upstream fj v0.6.0 binary; its current-Lab smoke half lacked evidence. The Captain closed that implementation on 2026-10-02; this already-required named-Forgejo acceptance row owns the remaining installed endpoint proof. No access means unexecuted, never pass.

## Review-program final gate — 2026-10-04

R1 (8x0.t.ig2) is delivered storage/evidence foundation, not proof of caps or escalation. Required input now includes accepted R2 (8x0.t.ig3) and R3 (8x0.t.ig4) receipts for the installed review workflow. Verify effective policy/session/worktree binding, restart without duplicate repair, discovery/delivery round limits, infra retry accounting and escalation with retained history on the exact installed manifest. Missing limits or an unbounded review is a failed required row. Cross-repo lab-config:gad.2 consumes this proof; experimental ig5 does not gate acceptance. No dependency from qkb/qk0 to R3 is introduced.

- [ ] Final review-policy row binds R2/R3 revisions and executes cap/escalation/restart negative scenarios before full Lab acceptance.

## Protected execution and native settlement acceptance

Required input also includes accepted xz9 and xza source receipts on the exact installed manifest. Add required rows for protected cross-user execution and for actual native Codex and Pi inbox outcomes. Use xz9's real authenticated launcher/worker/reviewer/authority/executor route, approved immutable candidate and canonical imported receipt; worker-local success JSON, mutable refs, same-UID stubs and direct journal injection are negative controls, never acceptance evidence. Run duplicate/lost-response/restart and no-effect-versus-uncertain cases; retain actor UIDs, candidate generation/head, claim/import references and observed effect count.

For each native runtime, execute the actual deployed producer, bound endpoint, observer and signer through consumed/superseded reconciliation. Retain exact event/digest/native-session/attempt/OS-birth correlation and trusted observation references. Exercise busy queues, duplicate/equal-text messages, lost replies, runtime restart and cancellation/dequeue races. Empty queue, elapsed time, generic enqueue acknowledgement or a direct app-server capability fixture cannot stand in for signed trustworthy consumption/nonexecution. Missing supported correlation is a failed required row, not a permitted skip.

Cross-repository prerequisites are explicit evidence references: lab-config:8wl.t.gad.8 proves exact authority accounts, protected paths/topology, runtime endpoints and signer-key installation on this manifest; lab-config:8wl.t.gad.b proves migrated scoped domain handlers and actual signed settlement using the same authority. Record their IDs, tested revisions, receipts and matching deployment manifest in acceptance/matrix.md. qkc consumes these installation/operation proofs, not gad.2 completion; lab-config:gad.2 consumes qkc afterward, preventing a cycle. Keep R2/R3 mandatory and ig5 outside the gate. No live installed proof is claimed by this specification amendment.

- [ ] Protected execution row binds xz9 source, actual peer identities and gad.8/gad.b installation/handler receipts to the installed manifest.
- [ ] Both native settlement rows bind xza source and real producer/observer/signer evidence, including race and restart negatives.
