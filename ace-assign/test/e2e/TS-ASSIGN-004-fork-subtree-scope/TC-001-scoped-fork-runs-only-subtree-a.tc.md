---
tc-id: TC-001
title: Scoped Fork Runs Only Subtree A
---

## Objective

Verify scoped assignment syntax (`<assignment-id>@<phase>`) resolves subtree context deterministically via `ace-assign status`, without executing sibling/outside phases.

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

3. Verify scoped assignment target resolves subtree root and phase
   ```bash
   SCOPED_STATUS=$(ace-assign status --assignment "$ASSIGNMENT_ID@020" 2>&1)
   echo "$SCOPED_STATUS" | grep -q "Fork subtree detected (root: 020 - subtree-a)." && echo "PASS: Scoped root detected from assignment@scope" || echo "FAIL: Scoped root not detected"
   echo "$SCOPED_STATUS" | grep -q "Current Phase: 020.01 - onboard" && echo "PASS: Scoped current phase resolved to subtree child" || echo "FAIL: Scoped current phase mismatch"
   echo "$SCOPED_STATUS" | grep -q "^020[[:space:]].*subtree-a" && echo "PASS: Scoped subtree parent displayed" || echo "FAIL: Scoped subtree parent missing"
   echo "$SCOPED_STATUS" | grep -q "^|-- 020.01[[:space:]].*onboard" && echo "PASS: Scoped child 020.01 displayed" || echo "FAIL: Scoped child 020.01 missing"
   echo "$SCOPED_STATUS" | grep -q "^|-- 020.02[[:space:]].*plan-task" && echo "PASS: Scoped child 020.02 displayed" || echo "FAIL: Scoped child 020.02 missing"
   echo "$SCOPED_STATUS" | grep -q "^\\\\-- 020.03[[:space:]].*work-on-task" && echo "PASS: Scoped child 020.03 displayed" || echo "FAIL: Scoped child 020.03 missing"
   ```

4. Verify no phases were executed by scoped inspection
   ```bash
   ASSIGNMENT_DIR="$CACHE_BASE/$ASSIGNMENT_ID"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/020-subtree-a.ph.md" && echo "FAIL: Subtree parent should remain pending" || echo "PASS: Subtree parent unchanged"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/020.01-onboard.ph.md" && echo "FAIL: Subtree child onboard should remain pending" || echo "PASS: Subtree child onboard unchanged"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/020.02-plan-task.ph.md" && echo "FAIL: Subtree child plan-task should remain pending" || echo "PASS: Subtree child plan-task unchanged"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/020.03-work-on-task.ph.md" && echo "FAIL: Subtree child work-on-task should remain pending" || echo "PASS: Subtree child work-on-task unchanged"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/010-precheck.ph.md" && echo "FAIL: Outside phase 010 should not be done" || echo "PASS: Outside phase 010 unchanged"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/030-postcheck.ph.md" && echo "FAIL: Outside phase 030 should not be done" || echo "PASS: Outside phase 030 unchanged"
   ```

5. Verify status still points to non-subtree work
   ```bash
   STATUS_OUTPUT=$(ace-assign status --assignment "$ASSIGNMENT_ID" 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase: 010 - precheck" && echo "PASS: Current phase remains outside subtree" || echo "FAIL: Current phase unexpectedly changed"
   ```

## Expected

- `ace-assign status --assignment "<id>@020"` resolves subtree root from scoped assignment target.
- Scoped status view shows only subtree `020` and descendants `020.01/020.02/020.03`.
- Scoped view resolves current phase to subtree child `020.01 - onboard`.
- Outside phases `010` and `030` remain not done.
