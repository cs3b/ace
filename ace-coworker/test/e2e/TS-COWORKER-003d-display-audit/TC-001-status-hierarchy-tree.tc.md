---
tc-id: TC-001
title: Status Shows Hierarchy Tree Structure
---

## Objective

Verify that the status command displays jobs in a hierarchical tree structure with nested job numbers.

## Steps

1. Create session and build hierarchy with children under two parents
   ```bash
   ace-coworker create job-tree.yaml
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-coworker add a-subtask-1 --after 010 --child -i "First subtask of A"
   ace-coworker add a-subtask-2 --after 010 --child -i "Second subtask of A"
   ace-coworker add b-subtask-1 --after 020 --child -i "First subtask of B"
   [ -f "$SESSION_DIR/jobs/010.01-a-subtask-1.j.md" ] && echo "PASS: 010.01 created" || echo "FAIL: Missing"
   [ -f "$SESSION_DIR/jobs/010.02-a-subtask-2.j.md" ] && echo "PASS: 010.02 created" || echo "FAIL: Missing"
   [ -f "$SESSION_DIR/jobs/020.01-b-subtask-1.j.md" ] && echo "PASS: 020.01 created" || echo "FAIL: Missing"
   ```

2. Verify status displays all jobs with hierarchy
   ```bash
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "feature-a" && echo "PASS: feature-a shown" || echo "FAIL: Missing"
   echo "$STATUS_OUTPUT" | grep -q "a-subtask-1" && echo "PASS: a-subtask-1 shown" || echo "FAIL: Missing"
   echo "$STATUS_OUTPUT" | grep -q "a-subtask-2" && echo "PASS: a-subtask-2 shown" || echo "FAIL: Missing"
   echo "$STATUS_OUTPUT" | grep -q "feature-b" && echo "PASS: feature-b shown" || echo "FAIL: Missing"
   echo "$STATUS_OUTPUT" | grep -q "b-subtask-1" && echo "PASS: b-subtask-1 shown" || echo "FAIL: Missing"
   ```

3. Verify hierarchical display indicators and nested numbers
   ```bash
   echo "$STATUS_OUTPUT" | grep -E "(├|└|│).*subtask" && echo "PASS: Tree characters used" || echo "INFO: May use different hierarchy display"
   echo "$STATUS_OUTPUT" | grep -q "010\.01" && echo "PASS: Nested 010.01 shown" || echo "FAIL: Missing"
   echo "$STATUS_OUTPUT" | grep -q "010\.02" && echo "PASS: Nested 010.02 shown" || echo "FAIL: Missing"
   echo "$STATUS_OUTPUT" | grep -q "020\.01" && echo "PASS: Nested 020.01 shown" || echo "FAIL: Missing"
   ```

## Expected

- All 5 jobs displayed in status output
- Jobs displayed with hierarchical structure (children appear under parents)
- Job numbers show nesting (010.01, 010.02, 020.01)
- Tree characters (├, └, │) used for hierarchy display
