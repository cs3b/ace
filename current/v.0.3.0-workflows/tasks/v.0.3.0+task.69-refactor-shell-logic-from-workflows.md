---
id: v.0.3.0+task.69
status: pending
priority: high
estimate: 20h
dependencies: []
---

# Refactor Shell Logic from Workflows

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
dev-handbook/workflow-instructions
├── README.md
├── commit.wf.md
├── create-adr.wf.md
├── create-api-docs.wf.md
├── create-reflection-note.wf.md
├── create-task.wf.md
├── create-test-cases.wf.md
├── create-user-docs.wf.md
├── draft-release.wf.md
├── fix-tests.wf.md
├── initialize-project-structure.wf.md
├── load-project-context.wf.md
├── publish-release.wf.md
├── review-code.wf.md
├── synthesize-reflection-notes.wf.md
├── synthesize-reviews.wf.md
├── update-blueprint.wf.md
├── update-roadmap.wf.md
└── work-on-task.wf.md
```

## Objective

Extract complex shell script logic from workflow instruction files into dedicated executable scripts in the `dev-tools/exe/` directory, particularly from `review-code.wf.md` and `synthesize-reviews.wf.md`. This will improve maintainability, testability, and clarity by separating the workflow instruction (what and why) from the implementation details (how). The extraction will focus on ~600+ lines of complex shell logic including session management, git operations, LLM execution, and report generation.

## Scope of Work

* Extract ~600+ lines of complex shell logic from two workflows
* Create modular scripts with clear interfaces and error handling
* Design parameter interfaces for backward compatibility
* Update workflows to call the new scripts with appropriate parameters
* Create shared utility functions for common operations
* Ensure new scripts are properly tested and documented

### Deliverables

#### Create

* dev-tools/exe/code-review-session (extracted shell logic from review-code.wf.md)
* dev-tools/exe/synthesis-session (extracted shell logic from synthesize-reviews.wf.md)
* dev-tools/lib/bash/review-utils.sh (shared utility functions)
* dev-tools/spec/exe/code-review-session_spec.rb (test file)
* dev-tools/spec/exe/synthesis-session_spec.rb (test file)

#### Modify

* dev-handbook/workflow-instructions/review-code.wf.md (update to call script)
* dev-handbook/workflow-instructions/synthesize-reviews.wf.md (update to call script)

#### Delete

* None

## Phases

1. Design script interfaces and parameter structure
2. Extract and modularize shell logic from review-code.wf.md
3. Extract and modularize shell logic from synthesize-reviews.wf.md
4. Create shared utility functions library
5. Update workflows to use new scripts
6. Test and validate script functionality

## Implementation Plan

### Planning Steps

* [ ] Audit review-code.wf.md and synthesize-reviews.wf.md for shell logic modules
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Complex shell logic identified and catalogued for extraction
  > Command: bin/test --check-shell-logic-audit
* [ ] Design parameter interfaces maintaining backward compatibility
* [ ] Plan shared utility functions (session management, git operations, report generation)
* [ ] Define error handling and logging strategy

### Execution Steps

* [ ] Create dev-tools/lib/bash/review-utils.sh with shared functions
  > TEST: Verify Utility Library
  > Type: Action Validation
  > Assert: Shared utility functions created and sourced correctly
  > Command: bash -c "source dev-tools/lib/bash/review-utils.sh && type -t generate_timestamp"
* [ ] Extract shell logic from review-code.wf.md into dev-tools/exe/code-review-session
  > TEST: Verify Script Creation
  > Type: Action Validation
  > Assert: Review code script created with proper functionality
  > Command: dev-tools/exe/code-review-session --help
* [ ] Extract shell logic from synthesize-reviews.wf.md into dev-tools/exe/synthesis-session
  > TEST: Verify Script Creation
  > Type: Action Validation
  > Assert: Synthesis script created with proper functionality
  > Command: dev-tools/exe/synthesis-session --help
* [ ] Update review-code.wf.md to call the new script with parameters
  > TEST: Verify Workflow Update
  > Type: Action Validation
  > Assert: Workflow updated to use script and maintains functionality
  > Command: grep -q "dev-tools/exe/code-review-session" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Update synthesize-reviews.wf.md to call the new script with parameters
  > TEST: Verify Workflow Update
  > Type: Action Validation
  > Assert: Workflow updated to use script and maintains functionality
  > Command: grep -q "dev-tools/exe/synthesis-session" dev-handbook/workflow-instructions/synthesize-reviews.wf.md
* [ ] Create RSpec test cases for new scripts
  > TEST: Verify Script Testing
  > Type: Action Validation
  > Assert: Test cases created and scripts pass all tests
  > Command: cd dev-tools && bundle exec rspec spec/exe/code-review-session_spec.rb spec/exe/synthesis-session_spec.rb

## Acceptance Criteria

* [ ] AC 1: ~600+ lines of complex shell logic extracted from both workflows
* [ ] AC 2: Scripts created in dev-tools/exe/ with proper error handling and clear interfaces
* [ ] AC 3: Shared utility library created for common functions
* [ ] AC 4: Workflows updated to call scripts while maintaining backward compatibility
* [ ] AC 5: All scripts pass RSpec tests and maintain original functionality
* [ ] AC 6: Documentation updated to reflect new script usage

## Out of Scope

* ❌ Modifying the core logic or functionality of the workflows
* ❌ Extracting simple command calls (only complex shell logic)
* ❌ Creating new workflow features beyond current capabilities

## References

* Review finding: "thats a big one, yes we should have a plan to extract this logic inside the tool, to simplify this workflow"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Problem: "The review-code and synthesize-reviews workflows contain extensive shell script logic. This blurs the line between a guide and a script"
* User note: Complex shell logic should be abstracted into dedicated scripts
* Target location confirmed: dev-tools/exe/ directory for extracted scripts

## Implementation Notes

### Key Modules to Extract

1. **Session Management Module** (~100 lines)
   * Timestamp generation and formatting
   * Directory creation with metadata
   * Session finalization and indexing

2. **Git Operations Module** (~150 lines)
   * Complex diff generation
   * File content extraction with XML wrapping
   * Target resolution logic

3. **LLM Execution Module** (~200 lines)
   * Multi-provider parallel execution
   * Error handling and retry logic
   * Output validation and logging

4. **Report Generation Module** (~150 lines)
   * Dynamic markdown generation
   * Statistics calculation
   * File link construction
