---
id: v.0.2.0+task.31
status: done
priority: medium
estimate: 3h
dependencies: [v.0.2.0+task.29]
---

# Create ATOM House Rules Developer Guide

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs-dev/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    docs-dev/guides
    ├── coding-standards.md
    ├── draft-release
    │   └── v.x.x.x
    ├── error-handling.md
    ├── performance.md
    ├── project-management.md
    ├── task-definition.g.md
    └── testing.md
```

## Objective

Create a developer guide that formalizes the ATOM component classification rules in a practical, easy-to-reference format. This guide will serve as the go-to resource for contributors when deciding where to place new classes and how to structure components according to the project's architectural patterns.

## Scope of Work

- Create a comprehensive guide explaining ATOM classification rules
- Provide clear decision trees or flowcharts for component placement
- Include practical examples from the codebase
- Offer troubleshooting for common classification mistakes
- Suggest future enforcement mechanisms

### Deliverables

#### Create

- docs-dev/guides/atom-house-rules.md

## Phases

1. Structure guide outline based on developer needs
2. Document classification rules with examples
3. Create decision-making aids (flowcharts/checklists)
4. Add troubleshooting section
5. Include enforcement suggestions

## Implementation Plan

### Planning Steps

* [x] Review the ADR-002 content (once created) for official rules
  > TEST: ADR Content Review
  > Type: Pre-condition Check
  > Assert: ADR-002 exists or draft content is available
  > Command: test -f docs/architecture/ADR-002-ATOM-Architecture-House-Rules.md || echo "Using draft content"
* [x] Analyze existing code organization patterns in lib/coding_agent_tools/
* [x] Design practical decision aids for developers

### Execution Steps

- [x] Create atom-house-rules.md with clear introduction explaining purpose
- [x] Document Models classification rules with examples
  > TEST: Models Rules Documented
  > Type: Action Validation
  > Assert: Models section includes criteria and examples
  > Command: grep -A10 "## Models" docs-dev/guides/atom-house-rules.md | grep -E "data carrier|PORO|Struct"
- [x] Document Molecules classification rules with examples
- [x] Document Organisms classification rules with examples
- [x] Create decision flowchart or checklist for component placement
  > TEST: Decision Aid Present
  > Type: Action Validation
  > Assert: A flowchart or checklist section exists
  > Command: grep -E "Flowchart|Checklist|Decision" docs-dev/guides/atom-house-rules.md
- [x] Add "Common Mistakes" section with LlmModelInfo as cautionary example
- [x] Include code examples showing proper vs improper classification
  > TEST: Code Examples Included
  > Type: Action Validation
  > Assert: Both good and bad examples are present
  > Command: grep -B2 -A5 "```ruby" docs-dev/guides/atom-house-rules.md | grep -E "Good:|Bad:|Correct:|Incorrect:"
- [x] Add section on future enforcement (RuboCop rules, CI checks)
- [x] Create cross-references to architecture.md and ADR-002

## Acceptance Criteria

- [x] Guide provides clear, actionable rules for each component type
- [x] Decision aids (flowchart/checklist) make classification decisions straightforward
- [x] Real codebase examples illustrate each rule
- [x] Common mistakes section helps prevent misclassification
- [x] LlmModelInfo refactoring is used as a teaching example
- [x] Future enforcement mechanisms are suggested
- [x] Guide is written in accessible, developer-friendly language
- [x] Cross-references to related documentation are included

## Out of Scope

- ❌ Implementing automated enforcement tools
- ❌ Refactoring existing code to match rules
- ❌ Creating video tutorials or interactive guides
- ❌ Documenting non-ATOM architectural patterns

## References

- Documentation Review: docs-project/current/v.0.2.0-synapse/code-review/task-4/docs-review-gemini-2.5-pro.md
- Related ADR: ADR-002-ATOM-Architecture-House-Rules (to be created)
- Architecture Documentation: docs-project/architecture.md
- Key Examples:
  - LlmModelInfo: Example of data object incorrectly placed in molecules/
  - ExecutableWrapper: Example of behavior-oriented molecule
  - LMStudioClient: Example of properly structured organism