---
id: 8wr.t.qkb
status: pending
priority: high
created_at: "2026-09-28 17:42:35"
estimate: TBD
dependencies: [8wr.t.qk1, 8wr.t.qjl]
tags: [lab-readiness]
bundle:
  presets: [project]
  files: [.ace-tasks/8wr.t.qk1-complete-forge-neutral-worktree-review/8wr.t.qk1-complete-forge-neutral-worktree-review-and-task.s.md, .ace-tasks/8wr.t.qjl-persist-assignment-attempts-and-exact/8wr.t.qjl-persist-assignment-attempts-and-exact-execution.s.md, .ace-tasks/8wr.t.qjz-resolve-second-commander-proposals-with/8wr.t.qjz-resolve-second-commander-proposals-with-a-sixteen.s.md, ace-assign/.ace-defaults/assign/catalog/recipes/implement-with-pr.recipe.yml, ace-assign/.ace-defaults/assign/presets/work-on-task.yml, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/ux/usage.md]
  commands: []
needs_review: false
position: 6o000i
---

# Run assignment delivery workflows through named forge providers

## Outcome and ownership

A reviewed task proceeds through an assignment, draft PR, executed tests, independent review and authorized merge using GitHub, default Forgejo or another named Forgejo. The same exact provider/PR/head/provenance survives handoffs and restart. A merge ends delivery; publication/deployment/synchronization remain separate precisely presented operations.

Current evidence: assign create-pr/update-pr-desc catalog steps reference as-github-pr-create/update; work-on-task presets reference wfi://github/pr/create/update and gh pr ready. Generic implementation belongs to this ACE family; lab-overseer l2d.6/.7 only accept its receipts. Core PR interfaces are supplied by qk1.0 and durable attempt/evidence ownership by qjl.

## Real slices

- **qkb.0:** one provider-neutral assignment delivery with exact attempt-bound PR evidence, fork/canonical provenance and interruption recovery. Includes provider selection inputs and catalog/preset updates needed to run that assignment.
- **qkb.1:** canonical provider-neutral create/update/delivery workflows and skills resolve in fresh environments; every relevant handbook consumer follows the same evidence/role rules. Depends on .0 to prevent instructions referencing nonexistent behavior.

Each slice is large and includes concrete positive/negative verification. The parent holds no additional hidden implementation. Children are reviewed before parent. The resulting system has one final workflow vocabulary, no retained GitHub aliases or second Lab Work engine.

## Shared policy

`ace-assign` alone owns attempts and durable execution evidence. Remote steps use qk1 selection once and bind identity to qjl's attempt; local-only recipes need no provider. Missing capability/identity/provenance, uncertain mutation and moved head never become success by log parsing. Workers implement, independent reviewers judge, integrators merge and administrators execute scoped high-trust operations; credentials do not authorize them.

Merge gates are actual executed tests and independent reviewer approval on the current exact SHA. CI is advisory. Do not make publication or RubyGems release a prerequisite for merge; version/changelog preparation is distinct from publishing.

Operations consume valid direct Captain approval, an applicable scoped standing authorization, or a resolved proposal; existing valid authorization needs no new proposal. When authorization is absent, create the exact qjz proposal. Every precisely presented separate proposal may execute after confirmed Telegram delivery plus 16 hours without reply per qjz, including high privilege operations. That decision does not waive tests/review/exact SHA/scope/OTP. A merge authorizes no different release operation. This spec work performs none of these operations.

## Acceptance and verification

Children supply executed package/feature tests, exact head and independent review. Both provenance forms and all provider selections work; missing authority, changed head and unknown mutation outcome stop safely. No active recipe/workflow calls gh, hardcodes github.com as the correctness path, or invokes Python lab/labd. qkc owns the full cross-provider matrix; l2d.6/.7 accept those delivered artifacts without rebuilding them.

Run changed package `ace-test PACKAGE all` and `ace-test-suite`; verify protocol/skill resolution from a clean external working directory. No unresolved product decision; implementation scheduling waits for qk1 and qjl, with commander/service/role integration consumed through qjz/qjx/qk0 contracts.

## Atomic delivery constraint

qkb.0 and qkb.1 are reviewed as separate observable scopes but integrate in one coherent delivery. The final neutral workflow entrypoints, all catalog consumers and removal of old GitHub-specific names ship together; no intermediate installed release exposes mixed vocabularies or compatibility aliases.
