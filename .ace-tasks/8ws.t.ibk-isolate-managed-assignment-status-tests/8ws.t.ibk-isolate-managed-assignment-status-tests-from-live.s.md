---
id: 8ws.t.ibk
status: draft
priority: high
created_at: "2026-09-29 12:12:52"
estimate: medium
dependencies: []
tags: [ace-assign, test-isolation, lab-readiness]
bundle:
  presets: [project]
  files: [ace-assign/test/fast/commands/status_command_test.rb, ace-assign/test/test_helper.rb, ace-assign/lib/ace/assign/molecules/evidence_calculator.rb, ace-assign/lib/ace/assign/molecules/evidence_journal.rb]
  commands: []
needs_review: true
title: Isolate managed assignment status tests from live evidence state
---

# Isolate managed assignment status tests from live evidence state

## Behavioral specification

A developer runs managed-assignment status tests from any checkout without reading, creating, resetting, deleting or pruning that checkout's real evidence journal or worktree registrations. Results depend only on test-owned assignment and evidence fixtures.

### Evidence and current limits

At main dbb9bde1e, the sandboxed full suite failed in `test_status_json_evidence_reflects_the_displayed_assignment`: EvidenceCalculator constructed an EvidenceJournal rooted at /Users/mc/Ps/ace and attempted to rebuild `.ace-local/assign/evidence-checkout/journal`. Git reported a missing but already registered worktree. Failure evidence is retained in `evidence/sandbox-failure.json`. The same package passed outside the sandbox (724 tests). This is a confirmed fixture-isolation gap, not proof that the production recovery algorithm is broken in an unrestricted environment. Do not fix it by deleting the operator's journal or globally pruning worktrees.

### Expected behavior and interface boundary

- Existing `bin/ace-test ace-assign all` and `bin/ace-test-suite` use explicit test-owned repository/journal context for managed status fixtures, including cases with a real evidence ref.
- An empty, populated, absent or stale journal in the invoking checkout cannot affect fixture results; tests must not repair that external state.
- Keep the assertion that JSON evidence belongs to the displayed assignment, with no receipt/attempt leakage from another assignment. Exercise the real evidence calculation boundary through isolated fixtures or a deliberate component seam rather than bypassing the assertion.
- Keep product authority, separate evidence-ref semantics and public status output unchanged. If implementation discovers a distinct product recovery defect, retain evidence and create a separate scope rather than silently enlarging this test-isolation task.

### Success criteria and verification

- [ ] SC1: Run the managed status case against a test-owned repository containing evidence; assert exact displayed attempt and exclusion of the other assignment.
- [ ] SC2: Use a separate sentinel repository with existing evidence refs/registered worktrees and verify its refs, registrations and files are unchanged before/after the tests.
- [ ] SC3: Run package and full-suite contexts, including missing/stale fixture checkout states; results are independent of the caller's evidence state. Tests clean only their own fixtures.
- [ ] SC4: `bin/ace-test ace-assign all` and `bin/ace-test-suite` contain no regression attributable to this scope; record exact SHA and independent review.

Owner: ace-assign tests. Single observable slice; medium. Follow-up to delivered qjl and tp0, whose original scopes stay done. Consumers qjx/y23 may be developed concurrently, but their acceptance must use isolated evidence fixtures. No CLI/API/config change; no separate usage file required. Draft awaiting review; no product implementation performed.
