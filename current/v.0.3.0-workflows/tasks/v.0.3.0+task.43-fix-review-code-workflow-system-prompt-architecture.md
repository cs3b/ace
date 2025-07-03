---
id: v.0.3.0+task.43
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Fix Review Code Workflow System Prompt Architecture

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la dev-handbook/workflow-instructions/review-code.wf.md .claude/commands/handbook-review.md
```

_Result excerpt:_

```
-rw-r--r--@ 1 michalczyz  staff  20401 Jul  3 23:11 dev-handbook/workflow-instructions/review-code.wf.md
-rw-r--r--@ 1 michalczyz  staff  13420 Jul  4 00:04 .claude/commands/handbook-review.md
```

## Objective

Resolve critical system prompt duplication in review workflows where system prompts are both embedded in prompt.md AND passed via --system flag, causing LLM confusion and incorrect review behavior. Implement proper separation between user prompts and system instructions.

## Scope of Work

* Remove system prompt embedding from prompt.md construction
* Fix conflicting prompt architecture in review-code.wf.md
* Update handbook-review command to use clean separation
* Ensure all review commands use consistent prompt/system pattern

### Deliverables

#### Modify

* dev-handbook/workflow-instructions/review-code.wf.md
* .claude/commands/handbook-review.md

## Phases

1. Audit current system prompt duplication patterns
2. Remove embedded system prompt from prompt construction
3. Verify LLM command patterns maintain --system flag usage
4. Test review workflow functionality

## Implementation Plan

### Planning Steps

* [ ] Analyze current prompt construction in review-code.wf.md lines 224-229
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: System prompt duplication patterns are identified
  > Command: grep -n "System Prompt" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Review handbook-review command for consistent separation patterns
* [ ] Identify all locations where system prompts are incorrectly embedded

### Execution Steps

* [ ] Remove lines 224-229 from review-code.wf.md that embed system prompt
* [ ] Update prompt construction to exclude system prompt section
  > TEST: Verify System Prompt Removal
  > Type: Action Validation
  > Assert: prompt.md construction no longer includes system prompt content
  > Command: grep -A 10 "## System Prompt" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Verify LLM command patterns maintain --system flag (line 293)
* [ ] Test handbook-review command end-to-end with proper separation
  > TEST: Verify Handbook Review Function
  > Type: Integration Test
  > Assert: handbook-review creates prompt.md without system prompt duplication
  > Command: @handbook-review workflows --dry-run

## Acceptance Criteria

* [ ] AC 1: review-code.wf.md no longer embeds system prompts in prompt.md
* [ ] AC 2: All LLM commands use --system flag for system prompt separation
* [ ] AC 3: handbook-review command works without prompt duplication
* [ ] AC 4: Generated prompt.md files contain only user prompt content

## Out of Scope

* ❌ Changing system prompt content itself
* ❌ Modifying LLM query tool interface
* ❌ Adding new review focus areas

## References

* Session feedback: "System prompt duplication causes LLM confusion"
* review-code.wf.md lines 224-229: Problematic system prompt embedding
* .claude/commands/handbook-review.md: Fixed implementation pattern