---
tc-id: TC-001
title: Scoped Fork Runs Only Subtree A
---

## Objective

Verify fork execution can target a subtree using scoped assignment syntax (`<assignment-id>@<phase>`) and complete only that subtree, without executing sibling/outside phases.

## Steps

1. Create assignment and capture ID
   ```bash
   CREATE_OUTPUT=$(ace-assign create job.yaml 2>&1)
   CREATE_EXIT=$?
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Assignment created" || echo "FAIL: Expected exit code 0, got $CREATE_EXIT"
   ASSIGNMENT_ID=$(echo "$CREATE_OUTPUT" | sed -n 's/.*Assignment: .* (\([^)]*\)).*/\1/p' | head -1)
   [ -n "$ASSIGNMENT_ID" ] && echo "PASS: Assignment ID resolved ($ASSIGNMENT_ID)" || echo "FAIL: Could not parse assignment ID"
   ```

2. Verify initial current phase is outside subtree A
   ```bash
   STATUS_OUTPUT=$(ace-assign status --assignment "$ASSIGNMENT_ID" 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase: 010 - precheck" && echo "PASS: Current phase starts outside subtree" || echo "FAIL: Expected current phase precheck"
   ```

3. Run fork for subtree A using scoped assignment target
   ```bash
   FORK_OUTPUT=$(ace-assign fork-run --assignment "$ASSIGNMENT_ID@020" 2>&1)
   FORK_EXIT=$?
   [ "$FORK_EXIT" -eq 0 ] && echo "PASS: fork-run succeeded" || echo "FAIL: fork-run failed (exit $FORK_EXIT)"
   echo "$FORK_OUTPUT" | grep -q "Starting fork subtree execution: 020 - subtree-a" && echo "PASS: Scoped root detected from assignment@scope" || echo "FAIL: Scoped root not detected"
   echo "$FORK_OUTPUT" | grep -q "completed successfully" && echo "PASS: Subtree completion confirmed" || echo "FAIL: Subtree completion missing"
   ```

4. Verify only subtree A phases completed
   ```bash
   ASSIGNMENT_DIR="$CACHE_BASE/$ASSIGNMENT_ID"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/020-subtree-a.ph.md" && echo "PASS: Subtree parent done" || echo "FAIL: Subtree parent not done"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/020.01-onboard.ph.md" && echo "PASS: Subtree child onboard done" || echo "FAIL: Subtree child onboard not done"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/020.02-plan-task.ph.md" && echo "PASS: Subtree child plan-task done" || echo "FAIL: Subtree child plan-task not done"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/020.03-work-on-task.ph.md" && echo "PASS: Subtree child work-on-task done" || echo "FAIL: Subtree child work-on-task not done"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/010-precheck.ph.md" && echo "FAIL: Outside phase 010 should not be done" || echo "PASS: Outside phase 010 unchanged"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/030-postcheck.ph.md" && echo "FAIL: Outside phase 030 should not be done" || echo "PASS: Outside phase 030 unchanged"
   ```

5. Verify status still points to non-subtree work
   ```bash
   STATUS_OUTPUT=$(ace-assign status --assignment "$ASSIGNMENT_ID" 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase: 010 - precheck" && echo "PASS: Current phase remains outside subtree" || echo "FAIL: Current phase unexpectedly changed"
   ```

## Expected

- `ace-assign fork-run --assignment "<id>@020"` resolves subtree root from scoped assignment target.
- Subtree `020` and all descendants complete successfully.
- Outside phases `010` and `030` remain not done.
- No global current-phase coupling blocks starting scoped fork-run.
