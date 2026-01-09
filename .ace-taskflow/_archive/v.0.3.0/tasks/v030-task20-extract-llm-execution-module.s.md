---

id: v.0.3.0+task.20
status: blocked
priority: high
estimate: 10h
dependencies: [v.0.3.0+task.18]
---

# Extract LLM Execution Module from Workflows

## 0. Directory Audit ✅

_Command run:_

```bash
grep -n "llm-query" .ace/handbook/workflow-instructions/review-code.wf.md | head -5 | sed 's/^/    /'
```

_Result excerpt:_

```
    (line numbers with llm-query references)
```

## Objective

Extract LLM execution logic from review-code.wf.md into a reusable module, providing standardized functions for LLM interactions in review and synthesis workflows.

## Scope of Work

* Extract LLM execution patterns (~200 lines)
* Create llm-execution.sh module
* Include prompt construction helpers
* Add response parsing utilities
* Support multiple LLM providers
* Document usage patterns

### Deliverables

#### Create

* .ace/tools/lib/bash/llm-execution.sh

#### Modify

* .ace/tools/lib/bash/review-utils.sh (add source statement)
* .ace/handbook/workflow-instructions/review-code.wf.md (update references)

#### Delete

* None

## Phases

1. Analyze LLM interaction patterns
2. Design standardized functions
3. Extract and modularize
4. Add provider abstraction
5. Document and test

## Implementation Plan

### Planning Steps

* [ ] Identify all LLM execution patterns
  > TEST: LLM Pattern Analysis
  > Type: Pre-condition Check
  > Assert: LLM patterns identified
  > Command: grep -c "llm-query" .ace/handbook/workflow-instructions/review-code.wf.md
* [ ] Study prompt construction methods
* [ ] Design provider-agnostic interface

### Execution Steps

- [ ] Create llm-execution.sh module
- [ ] Extract prompt construction functions
  > TEST: Prompt Functions
  > Type: Shell Test
  > Assert: Prompt helpers available
  > Command: source .ace/tools/lib/bash/llm-execution.sh && type -t construct_prompt
- [ ] Add LLM query execution functions
- [ ] Implement response parsing utilities
- [ ] Add provider selection logic
- [ ] Create error handling for API failures
  > TEST: Error Handling
  > Type: Shell Test
  > Assert: Error functions exist
  > Command: source .ace/tools/lib/bash/llm-execution.sh && type -t handle_llm_error
- [ ] Document all functions with examples
- [ ] Update review-utils.sh integration

## Acceptance Criteria

* [ ] LLM execution logic extracted and modularized
* [ ] Functions support multiple providers
* [ ] Prompt construction is standardized
* [ ] Response parsing handles common formats
* [ ] Comprehensive error handling included

## Out of Scope

* ❌ Creating new LLM functionality
* ❌ Modifying LLM behavior
* ❌ Extracting synthesis logic (next task)

## References

* Dependency: v.0.3.0+task.18 (bash library structure)
* Source: .ace/handbook/workflow-instructions/review-code.wf.md
* Target: .ace/tools/lib/bash/llm-execution.sh
* Estimated extraction: ~200 lines
* LLM tools: llm-query usage patterns