---
tc-id: TC-001
title: Full Fork Context Workflow
---

## Objective

Verify that ace-assign correctly handles the `context: fork` frontmatter option through a complete workflow: regular phases show raw instructions, fork phases show Task tool instructions with working directory and assignment ID, and mixed regular/fork transitions work correctly through to assignment completion.

## Steps

### Phase 1: Assignment Creation and Regular Phase

1. Create assignment from fork context job.yaml
   ```bash
   CREATE_OUTPUT=$(ace-assign create job.yaml 2>&1)
   CREATE_EXIT=$?
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Assignment created" || echo "FAIL: Expected exit code 0, got $CREATE_EXIT"
   ```

2. Verify fork context parsed into phase files
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   grep -q "context: fork" "$ASSIGNMENT_DIR/phases/020-implement.ph.md" && echo "PASS: context: fork in implement phase" || echo "FAIL: context: fork missing from implement"
   grep -q "context: fork" "$ASSIGNMENT_DIR/phases/040-document.ph.md" && echo "PASS: context: fork in document phase" || echo "FAIL: context: fork missing from document"
   grep -q "context:" "$ASSIGNMENT_DIR/phases/010-prepare.ph.md" && echo "FAIL: prepare should not have context" || echo "PASS: prepare has no context field"
   grep -q "context:" "$ASSIGNMENT_DIR/phases/030-verify.ph.md" && echo "FAIL: verify should not have context" || echo "PASS: verify has no context field"
   ```

3. Verify regular phase shows raw instructions (not Task tool format)
   ```bash
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*prepare" && echo "PASS: Current phase is prepare" || echo "FAIL: Current phase is not prepare"
   echo "$STATUS_OUTPUT" | grep -q "Instructions:" && echo "PASS: Raw instructions header shown" || echo "FAIL: Instructions header missing"
   echo "$STATUS_OUTPUT" | grep -q "Load project context" && echo "PASS: Raw instruction content shown" || echo "FAIL: Raw instruction content missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "FAIL: Task tool shown for regular phase" || echo "PASS: No Task tool for regular phase"
   ```

### Phase 2: Fork Phase Display

4. Complete prepare phase and verify fork phase shows Task tool instructions
   ```bash
   ace-assign report prepare-report.md
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*implement" && echo "PASS: Current phase is implement" || echo "FAIL: Current phase is not implement"
   echo "$STATUS_OUTPUT" | grep -q "Context: fork" && echo "PASS: Context: fork displayed" || echo "FAIL: Context: fork not displayed"
   echo "$STATUS_OUTPUT" | grep -q "forked context" && echo "PASS: Fork execution instructions shown" || echo "FAIL: Fork instructions missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "PASS: Task tool mentioned" || echo "FAIL: Task tool not mentioned"
   ```

5. Verify fork prompt includes working directory and assignment ID
   ```bash
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Working directory:" && echo "PASS: Working directory present" || echo "FAIL: Working directory missing"
   echo "$STATUS_OUTPUT" | grep -q "Assignment:" && echo "PASS: Assignment line present" || echo "FAIL: Assignment line missing"
   echo "$STATUS_OUTPUT" | grep -q "Prompt for forked agent" && echo "PASS: Prompt section shown" || echo "FAIL: Prompt section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Onboard" && echo "PASS: Onboard section in prompt" || echo "FAIL: Onboard section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Work" && echo "PASS: Work section in prompt" || echo "FAIL: Work section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Report" && echo "PASS: Report section in prompt" || echo "FAIL: Report section missing"
   ```

### Phase 3: Mixed Transitions and Completion

6. Complete fork phase and verify transition back to regular phase
   ```bash
   ace-assign report implement-report.md
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*verify" && echo "PASS: Current phase is verify (regular)" || echo "FAIL: Current phase is not verify"
   echo "$STATUS_OUTPUT" | grep -q "Instructions:" && echo "PASS: Instructions header shown" || echo "FAIL: Instructions header missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "FAIL: Task tool shown for regular phase" || echo "PASS: No Task tool for regular phase"
   echo "$STATUS_OUTPUT" | grep -q "Context:" && echo "FAIL: Context shown for regular phase" || echo "PASS: No Context for regular phase"
   ```

7. Complete verify, check second fork phase, and complete workflow
   ```bash
   ace-assign report verify-report.md
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*document" && echo "PASS: Current phase is document" || echo "FAIL: Current phase is not document"
   echo "$STATUS_OUTPUT" | grep -q "Context: fork" && echo "PASS: Context: fork displayed" || echo "FAIL: Context: fork not displayed"
   echo "$STATUS_OUTPUT" | grep -q "Update documentation" && echo "PASS: Document instructions in prompt" || echo "FAIL: Document instructions missing"
   ace-assign report document-report.md
   FINAL_STATUS=$(ace-assign status 2>&1)
   echo "$FINAL_STATUS" | grep -q "Assignment completed!" && echo "PASS: Assignment completed" || echo "FAIL: Assignment not completed"
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   DONE_COUNT=$(grep -rl "status: done" "$ASSIGNMENT_DIR/phases/" 2>/dev/null | wc -l | tr -d ' ')
   [ "$DONE_COUNT" -eq 4 ] && echo "PASS: All 4 phases done" || echo "FAIL: Expected 4 done, found $DONE_COUNT"
   ```

## Expected

### Phase 1
- Assignment created with fork context parsed into phase file frontmatter
- Regular phases (prepare, verify) have no context field
- Fork phases (implement, document) have context: fork
- Regular phase status shows raw "Instructions:" header, not Task tool format

### Phase 2
- Fork phase status shows "Context: fork", "forked context", "Task tool"
- Fork prompt includes "Working directory:", "Assignment:", "Prompt for forked agent"
- Prompt contains phase content sections (Onboard, Work, Report)

### Phase 3
- Transition from fork to regular phase shows raw instructions again
- Second fork phase (document) shows fork context correctly
- Workflow completes with all 4 phases done
