---
id: v.0.3.0+task.45
status: pending
priority: medium
estimate: 2h
dependencies: [v.0.3.0+task.44]
---

# Add YAML Frontmatter to Review Prompts

## 0. Directory Audit ✅

_Command run:_

```bash
head -10 dev-taskflow/current/v.0.3.0-workflows/code_review/*/prompt.md | grep -E '^(---|\w+:)'
```

_Result excerpt:_

```
---
generated: 2025-07-03T23:51:00Z
target: workflows
git_range: working directory
focus: docs (handbook-specific analysis)
context: docs/**/*.md
---
```

## Objective

Replace plain text metadata headers in review prompts with machine-readable YAML frontmatter to enable structured session tracking, automation, and better metadata handling across the review system.

## Scope of Work

* Update prompt header construction in review-code.wf.md
* Standardize YAML frontmatter format across all review types
* Ensure metadata includes generated timestamp, target, focus, context
* Maintain backward compatibility with existing LLM processing

### Deliverables

#### Modify

* dev-handbook/workflow-instructions/review-code.wf.md

## Phases

1. Define standard YAML frontmatter schema
2. Update prompt construction logic
3. Test YAML parsing compatibility
4. Validate across different review focus areas

## Implementation Plan

### Planning Steps

* [ ] Analyze current plain text header format in review-code.wf.md
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current metadata format is documented
  > Command: grep -A 10 "Generated:" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Define standard YAML frontmatter fields for all review types
* [ ] Research YAML frontmatter best practices for LLM prompts

### Execution Steps

* [ ] Replace plain text metadata with YAML frontmatter in prompt construction
  > TEST: Verify YAML Format
  > Type: Format Validation
  > Assert: Generated prompts have valid YAML frontmatter
  > Command: head -10 prompt.md | yaml-lint
* [ ] Update all review focus areas (code/tests/docs) to use YAML headers
* [ ] Add session metadata fields (generated, target, focus, context, git_range)
  > TEST: Verify Metadata Completeness
  > Type: Content Validation
  > Assert: All required metadata fields are present
  > Command: grep -E '^(generated|target|focus|context):' prompt.md
* [ ] Test YAML frontmatter with different review scenarios

## Acceptance Criteria

* [ ] AC 1: All generated prompts include valid YAML frontmatter
* [ ] AC 2: Metadata fields are complete and consistently formatted
* [ ] AC 3: YAML frontmatter is machine-readable and parseable
* [ ] AC 4: Prompts remain compatible with existing LLM processing

## Out of Scope

* ❌ Adding YAML parsing to LLM query tools
* ❌ Creating metadata analysis scripts
* ❌ Modifying existing session files retroactively

## References

* Session feedback: "below part should be yaml frontmatter - meta defined"
* Current implementation in prompt.md with proper YAML structure
* YAML frontmatter standards for documentation systems
