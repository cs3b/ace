# Detailed Review Format

## Enhanced Output Structure

### Deep Diff Analysis

The shared Assign claim boundary, immutable revision binding, and confirmed-delivery deadline are strong safeguards. **Changes requested: four verified findings.**

1. **Critical/Blocking — Retried veto can be discarded, permitting execution.**  
   [policy.rb:80](/private/tmp/ace-wave5-qjz/ace-hitl/lib/ace/hitl/proposals/policy.rb:80) rejects every sequence below `last_sequence`, assuming ordered delivery. Hermes can retain an unresolved veto at sequence 1, successfully deliver approval at sequence 2, then replay sequence 1. The veto is marked delivered but ignored. A real-socket regression reproduced `approved-explicitly` and a successful canonical service claim after this sequence.  
   **Fix:** Preserve per-request ingress order, defer later approvals behind unresolved earlier replies, and distinguish duplicate replies from previously unapplied lower sequences.

2. **High — Separated proposal and transport roles cannot run the overseer evaluator.**  
   [proposals.rb:84](/private/tmp/ace-wave5-qjz/ace-hitl/lib/ace/hitl/lifecycle/proposals.rb:84) requires transport authority to enumerate deadlines. The overseer invokes the evaluator under its own UID; spawning the Hermes executable preserves that UID. With the documented distinct proposer/transport principals, evaluation fails with `PermissionError` before reconciliation starts.  
   **Fix:** Provide an authenticated trigger that delegates reconciliation to the actual Hermes transport principal while preserving proposer/transport separation.

3. **High — A transient policy failure terminates the living watch loop.**  
   [status.rb:83](/private/tmp/ace-wave5-qjz/ace-overseer/lib/ace/overseer/cli/commands/status.rb:83) lets `ProposalTick` errors escape to the outer command handler. A single failed tick ends `status --watch`, eliminating subsequent refreshes and deadline retries. The startup call also prevents status display when reconciliation is unavailable.  
   **Fix:** Catch tick failures locally, report deferred resolution, and continue status collection and subsequent retries.

4. **Medium — Failed initial creation leaves an unrecoverable request.**  
   [proposals.rb:171](/private/tmp/ace-wave5-qjz/ace-hitl/lib/ace/hitl/lifecycle/proposals.rb:171) persists the lifecycle request before committing its canonical proposal. Injecting failure before the journal commit leaves a pending request whose `read` fails and whose `cancel` is refused. The failed caller receives no proposal ID; retrying creation generates another ID.  
   **Fix:** Add durable recovery for this commit boundary and stable creation identity, so interrupted creation can finish or clean up without leaving an orphan.

### Code Quality Assessment

*No issues found*

Complexity metrics and coverage percentages were not measured.

### Architectural Analysis

The role handoff in finding 2 needs correction. The existing separation between HITL decisions and Assign effect claims is otherwise preserved.

### Documentation Impact Assessment

*No issues found*

### Quality Assurance Requirements

Executed focused checks passed: **22 tests, 132 assertions** across HITL, Overseer, and Lab.

Four additional regression checks reproduced the findings:

- [HITL regression checks](/private/tmp/ace-wave5-qjz/.ace-local/review-checks/proposal_regression_test.rb)
- [Watch-loop regression check](/private/tmp/ace-wave5-qjz/.ace-local/review-checks/proposal_watch_regression_test.rb)

Add these scenarios to the maintained suites alongside the fixes. Full suites and installed acceptance were not re-executed. Tracked files remain unchanged.

### Security Review

Finding 1 permits a canonical effect claim after an admitted veto has been ignored. This is blocking for deployment, publication, and privilege-changing operations.

### Refactoring Opportunities

*No issues found*
## Root verification and disposition

Reviewed source: `a2cdb5804f98dce25c92fd3c1fae41c9017e20a0`. Root independently reran the supplied actual-socket/journal probes through source ACE tooling: HITL `8x42z4` (3 tests, 9 assertions, two failures and one error) and Overseer `8x42yz` (one test, error from failed tick). All four findings reproduced. Source is REJECTED and remains off main. Existing focused/full green package results do not override these counterexamples.

Root owns repair worktree `.ace-wt/codex-qjz-review-repair`; author has moved to separate `2jj` work. Preserve proposer/transport UID separation, durable ingress ordering, canonical Assign effect claim, and no message bodies in the Hermes metadata journal. Recovery must not manufacture a successful/no-effect outcome from missing evidence. Re-review all repaired paths before integration.
