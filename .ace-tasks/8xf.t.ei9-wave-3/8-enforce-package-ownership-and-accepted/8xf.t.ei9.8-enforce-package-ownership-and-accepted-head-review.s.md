---
id: 8xf.t.ei9.8
status: pending
priority: high
created_at: "2026-10-16 10:57:20"
tags: []
parent: 8xf.t.ei9
estimate: medium
dependencies: []
bundle:
  presets: [project]
  files: [AGENTS.md, docs/tools.md, .ace-tasks/8xf.t.ei9-wave-3/8xf.t.ei9-wave-3.s.md, .ace-tasks/8xf.t.ei9-wave-3/environment-contract.md, .ace-tasks/8xf.t.ei9-wave-3/observations-and-acceptance.md, .ace-tasks/8xf.t.ei9-wave-3/ux/usage.md, .ace-tasks/8x0.t.ig3-unify-review-loop-ownership-and/8x0.t.ig3-unify-review-loop-ownership-and-effective-policy.s.md, .ace-tasks/8wr.t.qkb-run-assignment-delivery-workflows-through/8wr.t.qkb-run-assignment-delivery-workflows-through-named-forge.s.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/8wr.t.qk0-coordinate-responsive-overseer-roles-without-the.s.md, ace-overseer/handbook/skills/as-overseer-configure-project/SKILL.md, ace-overseer/handbook/workflow-instructions/overseer/configure-project.wf.md, ace-assign/.ace-defaults/assign/presets/supervise-delivery.yml, ace-assign/.ace-defaults/assign/presets/integrate-batch.yml, ace-assign/.ace-defaults/assign/presets/deliver-release.yml, ace-assign/.ace-defaults/assign/presets/close-delivery.yml]
  commands: []
title: Enforce package ownership and accepted-head review
needs_review: false
---

# Enforce package ownership and accepted-head review

Advisory size: **medium**. Existing code owners: 8x0.t.ig3, 8wr.t.qkb, 8wr.t.qk0.
This child owns the observable program outcome; reuse/adopt their delivered work,
implement only remaining behavior there, and do not duplicate or reopen archived owners.
## Outcome and review contract

Effective review receives candidate/base, requirements and repository-wide context,
not only cut-out diff. Report maps changed responsibility → owning package → existing
API inspected → actual imports/call sites/dependency direction → verdict/evidence.
Review domain provider API, privileged runtime, canonical Assign journal and overseer
policy separately. Inspect reuse before new duplicated implementation. Material
wrong-layer behavior blocks APPROVE even with passing tests; useful thin adapters
(input conversion/public call/result mapping) remain allowed.

Forgejo HTTP/PR lifecycle belongs in ace-git-forgejo, not a duplicate under ace-lab.
Runtime delegates to provider; Assign owns canonical effects, overseer owns selection.
Tiny authority/uncertainty/architecture changes are not trivial by line count.
Actual resolved project review overlay must load this context and gate; an unused
checklist in generic docs does not count. Reuse ace-review/assign/handbook owners.

## Independent review and accepted-head policy

Author self-check is not independent review. Reviewer provides executed evidence
and formal Forgejo APPROVED with own actor/state/exact SHA readback; local report,
comment and formal review are distinct. Integrator verifies initial independence.
For moved head it records delta/context risk assessment: identical rebase may carry
review with executed identity checks; minor safe correction may be assessed by
integrator with tests; substantive or uncertain delta requires independent delta
review. Do not demand full campaign merely for changed SHA or transfer by patch-id
alone. Every accepted head has evidence and server-side exact guard at mutation.
Post/read back review evidence BEFORE dependent merge; failed posting halts merge.

Migrate effective integrate-batch step030, supervise-delivery step020 and
configure-project invariants from blanket new-SHA independent review to this policy.
Real authorized publication bindings replace placeholders through project config,
not by automatically granting publisher rights. Inspect resolved paths/digests.

## Verification

Seed duplicated Forgejo merge HTTP in ace-lab: reject with ownership/API evidence.
Thin delegation to provider may pass. Test identical rebase, minor safe correction,
small security-critical change, wrong reviewer actor, stale SHA and failed report
posting. Wrong-layer after prior approval still fails. Run review through effective
Assign/workflow, retain report and actual repository search/call evidence. Existing
ig3 failures stay explicit until repaired/retested; no paper close from other progress.

## Context and readiness

Load this child’s explicit bundle, including environment-contract.md and traceability.
Validate effective public interfaces on the selected source/runtime before effects;
missing capability is a precise readiness result, not permission to invent a route.
Use bin/ace-test or bin/ace-test-suite for focused source checks; installed proofs
are separately attributed. Captain overrides the brief; report results/conflicts to owner.
