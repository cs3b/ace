---
tc-id: TC-001
title: Drive Workflow Enforces No-Skip Policy
---

## Objective

Verify assignment drive guidance enforces hard no-skip policy for planned phases and requires attempt-first failure evidence.

## Steps

1. Verify workflow forbids skip-by-assumption
   ```bash
   WF="ace-assign/handbook/workflow-instructions/assign/drive.wf.md"
   rg -n "Planned phases are mandatory work items\\. Do not skip them by judgment\\." "$WF" && echo "PASS: Mandatory no-skip rule present" || echo "FAIL: Missing no-skip rule"
   rg -n "Never use report text to \\\"skip\\\" or synthesize completion for planned phases\\." "$WF" && echo "PASS: Synthetic skip prohibition present" || echo "FAIL: Missing synthetic skip prohibition"
   ```

2. Verify old skip assessment section is removed
   ```bash
   WF="ace-assign/handbook/workflow-instructions/assign/drive.wf.md"
   if rg -n "^#### Skip Assessment" "$WF"; then
     echo "FAIL: Deprecated Skip Assessment still present"
   else
     echo "PASS: Skip Assessment removed"
   fi
   ```

3. Verify attempt-first failure contract exists
   ```bash
   WF="ace-assign/handbook/workflow-instructions/assign/drive.wf.md"
   rg -n "^### 4\\. External Action Rule \\(Attempt-First\\)" "$WF" && echo "PASS: Attempt-first section present" || echo "FAIL: Attempt-first section missing"
   rg -n "command attempted" "$WF" && echo "PASS: Command evidence requirement present" || echo "FAIL: Missing command evidence requirement"
   rg -n "exact error output" "$WF" && echo "PASS: Exact error requirement present" || echo "FAIL: Missing exact error requirement"
   ```

4. Verify skill wrapper remains thin (no duplicated policy text)
   ```bash
   SKILL=".claude/skills/ace-assign-drive/SKILL.md"
   if rg -n "Do not skip planned assignment phases|synthetic skip mechanism|attempt execution and fail with concrete command/error evidence" "$SKILL"; then
     echo "FAIL: Skill should not duplicate policy guardrails"
   else
     echo "PASS: Skill remains thin and defers policy to workflow"
   fi
   ```

## Expected

- Workflow contains explicit hard no-skip policy language.
- Legacy `Skip Assessment` section is absent.
- Workflow includes attempt-first external action + failure evidence requirements.
- `ace-assign-drive` skill stays thin and defers policy to workflow.
