---
id: v.0.3.0+task.73
status: pending
priority: medium
estimate: 3h
dependencies: []
---

# Add Context Window Guidance

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
├── review-task.wf.md
├── save-session-context.wf.md
├── synthesize-reflection-notes.wf.md
├── synthesize-reviews.wf.md
├── update-blueprint.wf.md
├── update-roadmap.wf.md
└── work-on-task.wf.md
```

## Objective

Add guidance to the `review-code` workflow for handling large diffs or file sets that could exceed the context window of target LLMs. This addresses the risk of failures or truncated analysis when processing very large code reviews.

## Scope of Work

* Add section to review-code workflow for handling large context scenarios
* Document strategies for breaking down large reviews into manageable chunks
* Provide guidance on prioritizing files for review when context is limited
* Include error handling for context window overflow scenarios

### Deliverables

#### Create

* None

#### Modify

* dev-handbook/workflow-instructions/review-code.wf.md (add context window guidance)

#### Delete

* None

## Phases

1. Analyze current review-code workflow for context window considerations
2. Research best practices for handling large context scenarios
3. Add comprehensive guidance to workflow
4. Validate guidance addresses common overflow scenarios

## Implementation Plan

### Planning Steps

* [ ] Analyze review-code workflow for current context window handling
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current context limitations identified and documented
  > Command: bin/test --check-context-window-analysis
* [ ] Research strategies for handling large diff and file set scenarios
* [ ] Plan guidance structure covering chunking, prioritization, and error handling

### Execution Steps

* [ ] Add context window guidance section to review-code workflow
  > TEST: Verify Guidance Addition
  > Type: Action Validation
  > Assert: Context window guidance added with comprehensive strategies
  > Command: bin/test --check-context-window-guidance review-code.wf.md
* [ ] Include strategies for breaking down large reviews into manageable chunks
* [ ] Add prioritization guidance for files when context is limited
  > TEST: Verify Comprehensive Coverage
  > Type: Action Validation
  > Assert: Guidance covers chunking, prioritization, and error handling
  > Command: bin/test --check-context-guidance-completeness

## Acceptance Criteria

* [ ] AC 1: Context window guidance added to review-code workflow
* [ ] AC 2: Strategies included for breaking down large reviews into chunks
* [ ] AC 3: Prioritization guidance provided for files when context is limited
* [ ] AC 4: Error handling guidance included for context window overflow scenarios

## Out of Scope

* ❌ Implementing automatic context window detection or chunking
* ❌ Modifying LLM query tools to handle context limits
* ❌ Creating separate workflows for large review scenarios

## References

* Review finding: "The review-code workflow constructs a single large prompt. For very large diffs or file sets, this could exceed the context window of the target LLM, leading to failures or truncated analysis"
* Source: dev-taskflow/current/v.0.3.0-workflows/code_review/docs-handbook-workflows-20250705-173751/gpro-review.md
* Risk: Context window limits could cause workflow failures with large code reviews
* Related workflow: review-code.wf.md