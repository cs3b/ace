---
id: 8wr.t.qk0.1.0
status: in-progress
priority: high
created_at: "2026-10-07 08:29:34"
estimate: large
dependencies: [8wr.t.qk0.0, 8x3.t.xz9.2]
tags: [protected, review]
parent: 8wr.t.qk0.1
needs_review: false
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/authority/endcap.rb, ace-assign/lib/ace/assign/authority/launch_driver.rb, ace-assign/lib/ace/assign/authority/launch_control_channel.rb, ace-assign/lib/ace/assign/authority/launch_steering.rb, ace-assign/lib/ace/assign/models/execution_receipt.rb, ace-assign/lib/ace/assign/molecules/receipt_verifier.rb, ace-review/lib/ace/review/organisms/review_manager.rb, ace-overseer/lib/ace/overseer/cli/commands/review.rb, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/1-retain-scoped-launchers-through-responsive/0-delegate-exact-candidate-review-through/review-delegation-contract.md]
  commands: []
---

# Delegate exact candidate review through the original launcher

## Reviewed contract repairs

The repair candidate in commit55ac1ab1e received independent review recorded in `readiness-review.md`:

- [x] Pin the accepted request generation; concurrent advances refuse without implicit refresh.
- [x] Define explicit canonical cancellation before a fresh request; cancellation revokes authority and makes no claim of process death.
- [x] Enforce the same canonical reservation on direct/delegated assignment and approval consumers.

Full readiness review now includes cancellation CLI modes, reserved mutation admission and the concrete test map below. Independent whole-child readiness review accepted d99ffab32; status is pending with needs_review false. These checkboxes record contract repair, not delivered source.

## Observable behavior

An actually provisioned independent reviewer requests one exact canonical candidate through the retained original launcher's authenticated channel, executes the maintained review engine against exported immutable candidate bytes and submits its actual receipt through Endcap. Changed input, lost acknowledgment, stale candidate or replaced original never creates another review assignment or accepted approval automatically. Existing assign_review/accept_review remain the only review assignment/acceptance owners; project role instructions do not grant credentials.

## Interface and ownership

review-delegation-contract.md and ux/usage.md define this proposed fixed consumer capability. This child owns source-required request/status/channel delegation plus actual Overseer→ReviewManager→ExecutionReceipt→Endcap composition. It does not weaken original launcher birth, manufacture reviewer binding, alter review receipt verification or introduce another acceptance ledger. Parent qk0.1 consumes this delivered outcome; this child does not own physical prune or prepared worker input.

## Success criteria / verification

- [ ] SC1: Real controlled Client/Server→durable request→original Driver→actual assign_review→export_candidate→maintained ReviewManager with injected provider→ExecutionReceipt/CanonicalEvidence→accept_review accepts exactly the candidate head/generation and independently mapped reviewer. No forged success fixtures or live provider/native/root probe.
- [ ] SC2: No channel/busy/sealed/stale/unauthorized preflight causes zero accepted request/delegation; two concurrent requests cannot silently overwrite an in-flight assigned reviewer; stopped original, foreign birth, author=reviewer, replaced candidate and transferred wrong report refuse before approval.
- [ ] SC3: Loss before/after canonical assignment and before/after receipt import preserves original mutation/purpose; same public retry only observes original request, never launches another review engine. Status exposes actual canonical assigned/accepted facts and immutable first response without reclassifying unknown as approval. Same-principal restart can observe, not impersonate original reviewer.
- [ ] SC4: Fixed frame/schema/ID/receipt/report bounds, trailing-body/type/duplicate refusal and no locks across socket/provider wait pass. Existing exact-head review and ordinary local review remain valid. Executed scoped ACE tests and independent verdict gate source integration.

Large distinct observable source outcome. Specification accepted after independent review; no implementation/installed acceptance implied. Parent qk0.1 remains a separate readiness decision.
