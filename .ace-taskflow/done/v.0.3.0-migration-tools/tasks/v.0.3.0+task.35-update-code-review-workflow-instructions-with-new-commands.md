---
id: v.0.3.0+task.35
status: done
priority: medium
estimate: 4h
dependencies: [v.0.3.0+task.34]
---

# Update Code Review Workflow Instructions with New Commands

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions/
      - README.md
      - review-code.wf.md
      - ... (20 workflow files total)
```

## Objective

Replace custom bash scripts and manual processes in the code review workflow documentation with the recently developed Ruby gem commands (`code-review` and `code-review-prepare`), making the workflow more reliable, maintainable, and easier to use.

## Scope of Work

- Replace all bash script snippets with appropriate Ruby gem commands
- Update command structure documentation to reflect new interface
- Simplify process steps by leveraging built-in command functionality
- Update all examples to use new command syntax
- Ensure error handling guidance matches new command behaviors

### Deliverables

#### Create

- None (documentation update only)

#### Modify

- .ace/handbook/workflow-instructions/review-code.wf.md

#### Delete

- None

## Phases

1. Audit current workflow documentation
2. Map bash scripts to new commands
3. Update documentation with new command syntax

## Implementation Plan

### Planning Steps

- [x] Review current review-code.wf.md to identify all bash script sections
  > TEST: Script Identification Check
  > Type: Pre-condition Check
  > Assert: All bash script sections requiring replacement are identified
  > Command: grep -n "```bash" .ace/handbook/workflow-instructions/review-code.wf.md | wc -l
- [x] Map each bash script functionality to corresponding new command
- [x] Verify new command options match workflow requirements

### Execution Steps

- [x] Update Command Structure section (lines 17-44)
  - Replace `@review-code` with `code-review` command
  - Update parameter documentation to match `code-review --help` output
  - Add `--session`, `--dry-run`, `--model`, `--output` options
  > TEST: Command Structure Update
  > Type: Content Validation
  > Assert: Command structure matches actual code-review command interface
  > Command: code-review --help | head -20

- [x] Replace Session Directory Creation (lines 74-96)
  - Replace bash script with `code-review-prepare session-dir` command
  - Update metadata handling to use command output
  > TEST: Session Creation Command
  > Type: Command Validation
  > Assert: Session directory creation uses new command
  > Command: grep -A5 "session-dir" .ace/handbook/workflow-instructions/review-code.wf.md

- [x] Update Project Context Loading (lines 112-128)
  - Replace manual loading with `code-review-prepare project-context` command
  - Simplify context parameter handling
  > TEST: Context Loading Update
  > Type: Content Check
  > Assert: Context loading uses code-review-prepare command
  > Command: grep -B2 -A2 "project-context" .ace/handbook/workflow-instructions/review-code.wf.md

- [x] Replace Target Content Resolution (lines 130-201)
  - Replace git diff scripts with `code-review-prepare project-target` command
  - Remove manual XML construction
  > TEST: Target Resolution Update
  > Type: Content Validation
  > Assert: Target resolution uses new command
  > Command: grep -n "project-target" .ace/handbook/workflow-instructions/review-code.wf.md

- [x] Update Combined Prompt Construction (lines 231-314)
  - Replace manual prompt building with `code-review-prepare prompt` command
  - Simplify YAML frontmatter generation
  > TEST: Prompt Construction Update
  > Type: Content Check
  > Assert: Prompt construction uses new command
  > Command: grep -A3 "code-review-prepare prompt" .ace/handbook/workflow-instructions/review-code.wf.md

- [x] Simplify Multi-Model LLM Execution (lines 324-387)
  - Update to show how `code-review` command handles multi-model execution
  - Remove manual llm-query orchestration
  > TEST: LLM Execution Update
  > Type: Content Validation
  > Assert: LLM execution section references code-review command
  > Command: grep -B2 -A5 "code-review.*--model" .ace/handbook/workflow-instructions/review-code.wf.md

- [x] Update Usage Examples (lines 503-577)
  - Replace all `@review-code` with `code-review` command syntax
  - Add examples with `--session` for resuming sessions
  - Include `--dry-run` examples
  > TEST: Examples Update
  > Type: Example Count
  > Assert: All examples use new command syntax
  > Command: grep -c "code-review " .ace/handbook/workflow-instructions/review-code.wf.md | grep -E "[5-9]|[1-9][0-9]"

- [x] Update Error Handling section (lines 593-841)
  - Adjust error recovery to match new command behaviors
  - Update session management error handling
  > TEST: Error Handling Update
  > Type: Content Check
  > Assert: Error handling references new commands
  > Command: grep -A5 "code-review.*--session" .ace/handbook/workflow-instructions/review-code.wf.md

## Acceptance Criteria

- [x] All bash script sections replaced with appropriate Ruby gem commands
- [x] Command documentation matches actual `code-review --help` output
- [x] Examples demonstrate all major command options and use cases
- [x] Workflow remains functionally equivalent but simpler to execute
- [x] Error handling guidance updated for new command behaviors

## Out of Scope

- ❌ Changing the fundamental workflow logic or review process
- ❌ Modifying the review templates themselves
- ❌ Updating other workflow files (only review-code.wf.md)
- ❌ Creating new commands or modifying existing command behavior

## References

- Recently completed task: v.0.3.0+task.34 (Implement Code Review Module)
- Command help: `code-review --help` and `code-review-prepare --help`
- Current workflow: .ace/handbook/workflow-instructions/review-code.wf.md