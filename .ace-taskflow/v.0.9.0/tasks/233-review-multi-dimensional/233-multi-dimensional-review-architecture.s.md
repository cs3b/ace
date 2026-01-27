---
id: v.0.9.0+task.233
status: pending
priority: high
estimate: large
dependencies: []
type: orchestrator
subtasks:
  - 233.01
  - 233.02
  - 233.03
  - 233.04
  - 233.05
  - 233.06
  - 233.07
---

# Multi-Dimensional Review Architecture

## Vision

Transform ace-review from "send diff to LLM, get review" into a **multi-dimensional, adaptive review system** where:
- **Presets** orchestrate the entire review strategy (context, subject handling, reviewers)
- **Reviewers** are configured entities with focus areas, not just model names
- **Subject strategies** adapt to model capabilities and change characteristics
- **Reviews can be multi-dimensional** (test review + code review + doc review)

## Problem Statement

Current limitations:
1. **Context overflow** - Large PRs fail on models with smaller context windows
2. **One-size-fits-all** - Same approach for Gemini (2M tokens) and Claude (200k)
3. **Reviewers = model names** - No concept of specialized focus or expertise
4. **Single dimension** - Can't do parallel test + code + security reviews

## Architecture: Review as Orchestrated Process

```
Preset (orchestration unit)
    │
    ├── context: project docs, system prompt customizations
    │
    ├── subject_strategy: how to handle the diff/code being reviewed
    │   ├── full        → send complete subject (large context models)
    │   ├── chunked     → ace-bundle style splitting (parallel chunks)
    │   ├── progressive → review with context carryover (sequential)
    │   └── routed      → route by file type to specialized reviewers
    │
    └── reviewers: [] (configured entities, not just model names)
        ├── Reviewer 1: {model: gemini-2.5-pro, focus: code_quality, prompt: ...}
        ├── Reviewer 2: {model: claude-sonnet, focus: security, prompt: ...}
        └── Reviewer 3: {model: gpt-4o, focus: test_coverage, prompt: ...}
```

## Subject Strategies

### 1. `full` - No splitting (for large context models)
- **When**: Model context > subject size (e.g., Gemini 2M, Codex)
- **How**: Send complete diff with full context
- **Best for**: Comprehensive single-pass review

### 2. `chunked` - Parallel chunk reviews
- **When**: Subject exceeds context, fast parallel execution desired
- **How**: Split by file boundaries, review in parallel, synthesize
- **Trade-off**: Speed vs cross-chunk context awareness

### 3. `progressive` - Sequential with context carryover
- **When**: Need cross-chunk awareness, detailed review
- **How**: Review chunk 1 → summarize findings → include summary in chunk 2 review → ...
- **Best for**: Complex changes where later code depends on earlier

### 4. `routed` - Route by change type
- **When**: Multi-dimensional review desired
- **How**: Classify changes (test/code/docs/config), route to specialized reviewers
- **Best for**: Large PRs with mixed change types

## Subtask Breakdown

| ID | Name | Description |
|----|------|-------------|
| 226.01 | Token Estimation Foundation | Token counting + model context limits |
| 226.02 | Subject Strategy Interface | Strategy pattern + full strategy |
| 226.03 | Chunked Strategy | Parallel chunk reviews via ace-bundle |
| 226.04 | Adaptive Strategy Selection | Auto-select based on model + subject |
| 226.05 | Progressive Strategy | Sequential with context carryover |
| 226.06 | Reviewer Entity Model | Reviewers as configured entities |
| 226.07 | Multi-Dimensional Synthesis | Parallel reviewers + weighted synthesis |

## Implementation Order

```
226.01 (foundation)
    → 226.02 (interface + full)
        → 226.03 (chunked)
            → 226.04 (adaptive)
                → 226.05 (progressive)
                    → 226.06 (reviewer entity)
                        → 226.07 (multi-dimensional)
```

Each subtask builds on the previous. First 4 subtasks (226.01-226.04) address the immediate problem of large PR handling. Later subtasks (226.05-226.07) add sophistication.

## Error Handling Strategy

All strategies must handle failures gracefully:

### LLM Failures
- **Timeout**: After 2 minutes, mark reviewer as failed, continue with others
- **Rate limit**: Exponential backoff (1s, 2s, 4s), max 3 retries
- **API error**: Log error, mark reviewer failed, include in output notice

### Partial Results
- **Single reviewer fails**: Continue synthesis with remaining reviewers
- **All reviewers fail**: Return error with diagnostic info (no partial synthesis)
- **Synthesis fails**: Return raw concatenated reviews with failure notice

### Progressive Strategy Failures
- **Summary extraction fails**: Fall back to empty summary, log warning
- **Mid-sequence failure**: Complete remaining chunks without carryover

### Output Format for Failures
```markdown
## Reviewer Failures

- security-reviewer: Timeout after 120s
- test-reviewer: API rate limit exceeded

## Available Reviews

... synthesis from successful reviewers ...
```

## Acceptance Criteria

- [ ] Large PRs work with adaptive strategy (no context overflow)
- [ ] Gemini 2M uses full strategy for most PRs
- [ ] Claude 200k uses chunked strategy for large PRs
- [ ] Progressive strategy carries context between chunks
- [ ] Multi-reviewer presets execute in parallel
- [ ] All existing reviews continue working (backward compatible)
