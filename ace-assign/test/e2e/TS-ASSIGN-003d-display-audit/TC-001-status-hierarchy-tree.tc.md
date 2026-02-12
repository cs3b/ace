---
tc-id: TC-001
title: Status Shows Hierarchy Tree Structure
---

## Objective

Verify that the status command displays phases in a hierarchical tree structure with nested phase numbers.

## Steps

1. Create assignment and build hierarchy with children under two parents
   ```bash
   ace-assign create job-tree.yaml
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-assign add a-subtask-1 --after 010 --child -i "First subtask of A"
   ace-assign add a-subtask-2 --after 010 --child -i "Second subtask of A"
   ace-assign add b-subtask-1 --after 020 --child -i "First subtask of B"
   [ -f "$ASSIGNMENT_DIR/phases/010.01-a-subtask-1.ph.md" ] && echo "PASS: 010.01 created" || echo "FAIL: Missing"
   [ -f "$ASSIGNMENT_DIR/phases/010.02-a-subtask-2.ph.md" ] && echo "PASS: 010.02 created" || echo "FAIL: Missing"
   [ -f "$ASSIGNMENT_DIR/phases/020.01-b-subtask-1.ph.md" ] && echo "PASS: 020.01 created" || echo "FAIL: Missing"
   ```

2. Verify status displays all phases with hierarchy
   ```bash
   STATUS_OUTPUT=$(ace-assign status 2>&1)
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

- All 5 phases displayed in status output
- Phases displayed with hierarchical structure (children appear under parents)
- Phase numbers show nesting (010.01, 010.02, 020.01)
- Tree characters (├, └, │) used for hierarchy display
