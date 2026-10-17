---
id: 8wr.t.qkb.0
status: done
priority: high
created_at: "2026-09-28 17:44:29"
estimate: TBD
dependencies: [8wr.t.qk1, 8wr.t.qjl, 8x2.t.z78, 8x3.t.vfw]
tags: [lab-readiness]
parent: 8wr.t.qkb
bundle:
  presets: [project]
  files: [.ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, .ace-tasks/_archive/8x/v/8wr.t.qk1-complete-forge-neutral-worktree-review/8wr.t.qk1-complete-forge-neutral-worktree-review-and-task.s.md, .ace-tasks/_archive/8x/v/8wr.t.qjl-persist-assignment-attempts-and-exact/8wr.t.qjl-persist-assignment-attempts-and-exact-execution.s.md, ace-assign/.ace-defaults/assign/catalog/recipes/implement-with-pr.recipe.yml, ace-assign/.ace-defaults/assign/catalog/steps/create-pr.step.yml, ace-assign/.ace-defaults/assign/catalog/steps/update-pr-desc.step.yml, ace-assign/.ace-defaults/assign/catalog/steps/mark-pr-ready.step.yml, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/0-make-assignment-delivery-evidence-provider/ux/usage.md, .ace-tasks/_archive/8x/v/8x2.t.z78-complete-forgejo-delivery-capabilities-with/8x2.t.z78-complete-forgejo-delivery-capabilities-with-verifiable.s.md, .ace-tasks/_archive/8x/v/8x2.t.z78-complete-forgejo-delivery-capabilities-with/ux/usage.md, .ace-tasks/_archive/8x/v/8x3.t.vfw-verify-forgejo-create-provenance-and/8x3.t.vfw-verify-forgejo-create-provenance-and-uncertain-outcomes.s.md]
  commands: []
needs_review: false
---

## Acceptance ownership — Captain decision 2026-10-05

This task owns source implementation and executed package/integration tests. **lab-config:8wl.t.gad.2, row `qkb-delivery`, owns Lab installation and shared system acceptance.** Original requirements are preserved in history/before-centralized-lab-acceptance-2026-10-05.md; no unexecuted installed scenario is marked passed. This decision supersedes older status prose keeping the source task open solely for installed proof.

Final independent-review-2026-10-05.md accepts d14e5afc source with Assign 829/3469 and independent 18/323; integrated at 855092590. Its final receipt supersedes earlier implementation-evidence pending prose. The coherent neutral vocabulary was published in the coordinated release. Actual protected workflow/role adoption remains qkb.1 implementation; fresh installed atomic vocabulary and executor trace belong to gad.2. Atomic release semantics are unchanged; no mixed vocabulary is newly authorized.


# Make assignment delivery evidence provider neutral

## User experience

Input: a reviewed task, assignment parameters and explicit PR provenance. Process: the assignment resolves the target forge, executes provider-neutral steps and records delivery evidence in its qjl attempt. Output: a complete exact-head delivery or a specific blocked/unknown outcome; local recipes remain independent of forge availability.

## Interface contract

- Remote-capable assignment presets/recipes accept optional `forge_server` (configured name) or `forge_default: true`, mutually exclusive; absence resolves repository remote under qk1 rules. Resolve at the first remote step and retain exact identity throughout the attempt. Local recipes ignore no remote input by accident: an explicitly requested remote-only action must resolve or fail.
- Remote delivery accepts `pr_provenance` with `mode` = `fork` or `canonical`, `head_repository_url`, `head_ref`, `base_repository_url`, `base_ref`; no credentials. A fork may share owner but must be explicitly identified; canonical mode requires matching head/base repositories. Validate actual pushed SHA and selected base repository; do not infer topology from actor identity.
- qjl is the authoritative envelope for attempt/task/actor/head and operation receipts. Consume its distinct `base_head`, `candidate_head`, `evidence_git_ref` and `journal_commit`: tests/review and remote PR bind to candidate_head; journal writes do not advance the deliverable head. A task edit committed to the deliverable branch is a real candidate change and requires renewed evidence; there is no metadata-only exemption. PR evidence adds qk1's resolved identity, provenance, PR URL/number and resulting head to that existing envelope; no parallel state store, runner or verdict schema.
- create-pr/update-pr-desc/mark-pr-ready/review steps use qk1 neutral PR/review interfaces. Provide final workflow names `wfi://git/pr/create`, `wfi://git/pr/update`, `skill://as-git-pr-create`, `skill://as-git-pr-update` with the assignment slice; qkb.1 owns complete canonical workflow/consumer adoption and packaging proof. This slice must run using the final vocabulary from its own delivered step artifacts, not transitional aliases.
- Draft PR creation is default. Readiness requires the current tests/review result under qjl; merge is performed by an authorized integrator/service with exact expected SHA. Worker or review credentials are not promoted to integration authority.
- Changed head invalidates ready/merge evidence and routes through rerun/review; review success for old head is retained only as history. CI failure remains visible and advisory.
- Repeat read/check steps are safe. Resume reconciles PR identity and remote receipts before repeating any mutation. If create returns unknown, search exact base/head-repo/head-ref and adopt only one matching PR. Unknown merge/publication outcome cannot be blindly retried; retain unknown pending reconciliation under qjl.
- Recipe completion checks real artifacts, test outcome, reviewer verdict, exact head and required authorization, not report file presence or shell status. Delivery-only recipes do not require publication; current `release-minor` preparation must clearly mean version/changelog changes, not RubyGems publishing. Publishing is a separate authorized recipe.

## Success criteria and verification

1. One complete task-to-draft-to-review-to-ready flow works for GitHub/default Forgejo/named Forgejo in both provenance modes. Feature tests use real temporary Git and controlled provider IO and assert the qjl evidence fields at each boundary.
2. Local-only assignment operates without forge tools/config; invalid selection and mismatched provenance fail before remote writes. Test missing mode, canonical mismatch and ambiguous configuration.
3. Head movement between review/readiness/merge prevents use of stale approval. Test actual changed commit identity and no merge call; red CI with valid tests/reviewer does not block solely on CI.
4. Crash/timeout after PR creation and before receipt persistence reconciles rather than duplicating; zero/multiple candidates remain explicit unresolved/conflict outcomes. Unknown merge is not retried automatically.
5. A fabricated report/exit-0, missing independent verdict or wrong exact head cannot complete delivery. No parallel Lab Work status overrides qjl.

Run `ace-test ace-assign all`, changed git/provider package suites and `ace-test-suite`. Record exact commands and SHA/review for qkc and l2d.6. Interface docs cover input parameters, provenance and recovery.

## Boundaries and decisions

Single end-to-end slice, advisory size: large. Depends on qk1 delivered capabilities and qjl durable attempts. This task does not implement the ledger, credentials, service authorization, commander timer or native runtime. qkb.1 removes remaining old canonical skill/workflow entrypoints and proves global projection. No compatibility aliases are part of the final result. No unresolved behavioral questions.

## Atomic delivery constraint

qkb.0 and qkb.1 are reviewed as separate observable scopes but integrate in one coherent delivery. The final neutral workflow entrypoints, all catalog consumers and removal of old GitHub-specific names ship together; no intermediate installed release exposes mixed vocabularies or compatibility aliases.

## Provider acceptance prerequisite — 2026-10-04

ACE 8x2.t.z78 owns the actual missing Forgejo fork/draft/ready/atomic expected-head and uncertainty behavior. Its accepted provider receipt is required before this delivery scope is accepted. Existing safe unsupported errors are not completed matrix rows. qkb.0 and qkb.1 remain one atomic installed vocabulary change; no release with mixed old/new workflow names. R2 follows completed qkb, and R3 follows R2; neither is an upstream qkb prerequisite.

## Post-delivery repair gate — 2026-10-04

The added prerequisite tasks repair observed producer defects, not a change to this consumer's behavior. Development may use the delivered API in parallel, but acceptance/integration waits for the named repairs and reruns the affected consumer cases after rebase. No local bypass or duplicate validation substitutes for fixing the owning producer. Pending means the specification is ready, not that its prerequisites are already complete.

## Source acceptance map — 2026-10-05

- [x] SC1: Controlled provider/real Git task-to-ready traces cover GitHub, default/named Forgejo and fork/canonical provenance.
- [x] SC2: Local-only and invalid/provenance selection refusal before writes.
- [x] SC3: Exact-head movement invalidates stale test/review approval.
- [x] SC4: Uncertain creation/merge reconciliation preserves one effect across attempts.
- [x] SC5: Forged, missing-review and wrong-head evidence cannot complete delivery.

Evidence: final independent-review-2026-10-05.md. Lab deployment and its verification are tracked only at lab-config:8wl.t.gad.2 `qkb-delivery`; qkb.1 still owns missing source adoption.
