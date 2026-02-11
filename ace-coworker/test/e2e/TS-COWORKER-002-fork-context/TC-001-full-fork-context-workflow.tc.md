---
tc-id: TC-001
title: Full Fork Context Workflow
---

## Objective

Verify that ace-coworker correctly handles the `context: fork` frontmatter option through a complete workflow: regular steps show raw instructions, fork steps show Task tool instructions with working directory and session ID, and mixed regular/fork transitions work correctly through to session completion.

## Steps

### Phase 1: Session Creation and Regular Step

1. Create session from fork context job.yaml
   ```bash
   CREATE_OUTPUT=$(ace-coworker create job.yaml 2>&1)
   CREATE_EXIT=$?
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Expected exit code 0, got $CREATE_EXIT"
   ```

2. Verify fork context parsed into step files
   ```bash
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   grep -q "context: fork" "$SESSION_DIR/jobs/020-implement.j.md" && echo "PASS: context: fork in implement step" || echo "FAIL: context: fork missing from implement"
   grep -q "context: fork" "$SESSION_DIR/jobs/040-document.j.md" && echo "PASS: context: fork in document step" || echo "FAIL: context: fork missing from document"
   grep -q "context:" "$SESSION_DIR/jobs/010-prepare.j.md" && echo "FAIL: prepare should not have context" || echo "PASS: prepare has no context field"
   grep -q "context:" "$SESSION_DIR/jobs/030-verify.j.md" && echo "FAIL: verify should not have context" || echo "PASS: verify has no context field"
   ```

3. Verify regular step shows raw instructions (not Task tool format)
   ```bash
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*prepare" && echo "PASS: Current step is prepare" || echo "FAIL: Current step is not prepare"
   echo "$STATUS_OUTPUT" | grep -q "Instructions:" && echo "PASS: Raw instructions header shown" || echo "FAIL: Instructions header missing"
   echo "$STATUS_OUTPUT" | grep -q "Load project context" && echo "PASS: Raw instruction content shown" || echo "FAIL: Raw instruction content missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "FAIL: Task tool shown for regular step" || echo "PASS: No Task tool for regular step"
   ```

### Phase 2: Fork Step Display

4. Complete prepare step and verify fork step shows Task tool instructions
   ```bash
   ace-coworker report prepare-report.md
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*implement" && echo "PASS: Current step is implement" || echo "FAIL: Current step is not implement"
   echo "$STATUS_OUTPUT" | grep -q "Context: fork" && echo "PASS: Context: fork displayed" || echo "FAIL: Context: fork not displayed"
   echo "$STATUS_OUTPUT" | grep -q "forked context" && echo "PASS: Fork execution instructions shown" || echo "FAIL: Fork instructions missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "PASS: Task tool mentioned" || echo "FAIL: Task tool not mentioned"
   ```

5. Verify fork prompt includes working directory and session ID
   ```bash
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Working directory:" && echo "PASS: Working directory present" || echo "FAIL: Working directory missing"
   echo "$STATUS_OUTPUT" | grep -q "Session:" && echo "PASS: Session line present" || echo "FAIL: Session line missing"
   echo "$STATUS_OUTPUT" | grep -q "Prompt for forked agent" && echo "PASS: Prompt section shown" || echo "FAIL: Prompt section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Onboard" && echo "PASS: Onboard section in prompt" || echo "FAIL: Onboard section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Work" && echo "PASS: Work section in prompt" || echo "FAIL: Work section missing"
   echo "$STATUS_OUTPUT" | grep -q "## Report" && echo "PASS: Report section in prompt" || echo "FAIL: Report section missing"
   ```

### Phase 3: Mixed Transitions and Completion

6. Complete fork step and verify transition back to regular step
   ```bash
   ace-coworker report implement-report.md
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*verify" && echo "PASS: Current step is verify (regular)" || echo "FAIL: Current step is not verify"
   echo "$STATUS_OUTPUT" | grep -q "Instructions:" && echo "PASS: Instructions header shown" || echo "FAIL: Instructions header missing"
   echo "$STATUS_OUTPUT" | grep -q "Task tool" && echo "FAIL: Task tool shown for regular step" || echo "PASS: No Task tool for regular step"
   echo "$STATUS_OUTPUT" | grep -q "Context:" && echo "FAIL: Context shown for regular step" || echo "PASS: No Context for regular step"
   ```

7. Complete verify, check second fork step, and complete workflow
   ```bash
   ace-coworker report verify-report.md
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*document" && echo "PASS: Current step is document" || echo "FAIL: Current step is not document"
   echo "$STATUS_OUTPUT" | grep -q "Context: fork" && echo "PASS: Context: fork displayed" || echo "FAIL: Context: fork not displayed"
   echo "$STATUS_OUTPUT" | grep -q "Update documentation" && echo "PASS: Document instructions in prompt" || echo "FAIL: Document instructions missing"
   ace-coworker report document-report.md
   FINAL_STATUS=$(ace-coworker status 2>&1)
   echo "$FINAL_STATUS" | grep -q "Session completed!" && echo "PASS: Session completed" || echo "FAIL: Session not completed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   DONE_COUNT=$(grep -rl "status: done" "$SESSION_DIR/jobs/" 2>/dev/null | wc -l | tr -d ' ')
   [ "$DONE_COUNT" -eq 4 ] && echo "PASS: All 4 steps done" || echo "FAIL: Expected 4 done, found $DONE_COUNT"
   ```

## Expected

### Phase 1
- Session created with fork context parsed into step file frontmatter
- Regular steps (prepare, verify) have no context field
- Fork steps (implement, document) have context: fork
- Regular step status shows raw "Instructions:" header, not Task tool format

### Phase 2
- Fork step status shows "Context: fork", "forked context", "Task tool"
- Fork prompt includes "Working directory:", "Session:", "Prompt for forked agent"
- Prompt contains job content sections (Onboard, Work, Report)

### Phase 3
- Transition from fork to regular step shows raw instructions again
- Second fork step (document) shows fork context correctly
- Workflow completes with all 4 steps done
