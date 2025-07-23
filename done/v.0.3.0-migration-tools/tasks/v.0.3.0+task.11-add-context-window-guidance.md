---

id: v.0.3.0+task.11
status: done
priority: medium
estimate: 3h
dependencies: []
---

# Add Context Window Guidance to Review Workflow

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la dev-handbook/workflow-instructions/review-code.wf.md | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/workflow-instructions/review-code.wf.md
```

## Objective

Enhance the code review workflow with comprehensive guidance for handling large diffs that may exceed LLM context windows. This includes specific strategies for chunking content, prioritizing files, handling context overflow errors, and maintaining review quality across multiple LLM interactions. The enhancement ensures effective review of substantial changes while preserving context and maintaining thoroughness.

## Scope of Work

* Update review-code.wf.md with comprehensive context window management section
* Document specific strategies for large diffs (git diffs, file patterns, individual files)
* Provide file prioritization techniques based on impact and complexity
* Define chunking approaches with specific algorithms and size limits
* Include error handling patterns for context overflow scenarios
* Add guidance on maintaining context across chunks
* Document performance considerations for large review sessions
* Include examples of different content types and their optimal handling

### Deliverables

#### Create

* None

#### Modify

* dev-handbook/workflow-instructions/review-code.wf.md

#### Delete

* None

## Phases

1. Analyze current review workflow
2. Design context window strategies
3. Implement guidance section
4. Add practical examples

## Implementation Plan

### Planning Steps

* [x] Review current review-code.wf.md structure
  > TEST: Current Structure
  > Type: Pre-condition Check
  > Assert: Current workflow structure understood
  > Command: grep -n "^##" dev-handbook/workflow-instructions/review-code.wf.md | wc -l
* [x] Research effective context window management strategies
  > TEST: Research Completeness
  > Type: Knowledge Validation
  > Assert: Context window limits and chunking strategies documented
  > Command: echo "Research covers: token limits, chunking algorithms, error handling"
* [x] Design chunking approaches for different content types
  > TEST: Chunking Strategies
  > Type: Design Validation
  > Assert: Specific algorithms defined for diffs, files, and patterns
  > Command: echo "Chunking strategies: size-based, logical-based, priority-based"
* [x] Analyze current LLM token limits and optimal chunk sizes
* [x] Design error handling patterns for context overflow
* [x] Plan integration with existing error handling framework

### Execution Steps

- [x] Add "Context Window Management" section to review-code.wf.md after "Error Handling" section
- [x] Document file prioritization strategies with specific criteria
  > TEST: Prioritization Section
  > Type: Content Validation
  > Assert: File prioritization strategies documented with examples
  > Command: grep -c "prioritization" dev-handbook/workflow-instructions/review-code.wf.md
- [x] Define chunking approaches for different content types (git diffs, file patterns, individual files)
  > TEST: Chunking Approaches
  > Type: Content Validation
  > Assert: Multiple chunking strategies documented
  > Command: grep -c "chunking" dev-handbook/workflow-instructions/review-code.wf.md
- [x] Add context overflow error handling patterns
  > TEST: Error Handling
  > Type: Content Validation
  > Assert: Context overflow scenarios covered
  > Command: grep -c "overflow" dev-handbook/workflow-instructions/review-code.wf.md
- [x] Include practical examples of effective review splitting
- [x] Document indicators that suggest chunking is needed
- [x] Add guidance on maintaining context across chunks
- [x] Include performance considerations and benchmarks
  > TEST: Context Window Section
  > Type: Content Validation
  > Assert: Comprehensive context window guidance exists
  > Command: grep -i -c "context window" dev-handbook/workflow-instructions/review-code.wf.md

## Acceptance Criteria

* [x] Context window section is comprehensive and actionable with specific algorithms
* [x] Multiple strategies for large diffs are documented with examples
* [x] File prioritization guidance is clear with specific criteria
* [x] Error handling for overflow is addressed with recovery patterns
* [x] Examples demonstrate practical application across different content types
* [x] Integration with existing error handling framework is seamless
* [x] Performance considerations are documented with benchmarks
* [x] Guidance covers maintaining context across multiple LLM interactions
* [x] Token limits for different LLM providers are specified
* [x] Chunking indicators are clearly defined with thresholds

## Out of Scope

* ❌ Modifying review tools or scripts
* ❌ Implementing automated chunking
* ❌ Changing other workflow sections

## References

* Target file: dev-handbook/workflow-instructions/review-code.wf.md
* Related task from original plan: task.73
* Context: Handling reviews that exceed LLM token limits
* LLM Context Limits: Claude 3.5 Sonnet (200k tokens), GPT-4 (128k tokens), Gemini Pro (2M tokens)
* Existing error handling framework: Lines 594-881 in review-code.wf.md
* Integration point: After "Error Handling" section, before "Integration Points"