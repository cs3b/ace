---
id: v.0.2.0+task.29
status: pending
priority: high
estimate: 3h
dependencies: []
---

# Create ADR for ATOM Architecture House Rules

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs/architecture | sed 's/^/    /'
```

_Result excerpt:_

```
    docs/architecture
    ├── ADR-001-CI-Aware-VCR-Configuration.md
    └── README.md
```

## Objective

Create a new Architecture Decision Record (ADR) to formalize the "house rules" for ATOM component classification. This ADR will clearly define the criteria for placing a class in `models/`, `molecules/`, or `organisms/`, using the `LlmModelInfo` refactoring as the primary example. This solidifies the project's architectural conventions and prevents future misclassification of components.

## Scope of Work

- Create a new ADR documenting ATOM architecture classification rules
- Define clear criteria for each component type (Models, Molecules, Organisms)
- Use LlmModelInfo refactoring as the primary example
- Provide decision rationale and consequences
- Include guidelines for future component classification

### Deliverables

#### Create

- docs/architecture/ADR-002-ATOM-Architecture-House-Rules.md

## Phases

1. Research ADR format and existing ADR-001 structure
2. Document the architectural decision context
3. Define classification criteria for each component type
4. Document the decision and its consequences
5. Add practical examples and guidelines

## Implementation Plan

### Planning Steps

* [ ] Review ADR-001 to understand the project's ADR format
  > TEST: ADR Format Understanding
  > Type: Pre-condition Check
  > Assert: ADR structure and sections are identified from ADR-001
  > Command: grep "^#" docs/architecture/ADR-001-CI-Aware-VCR-Configuration.md
* [ ] Analyze the LlmModelInfo refactoring context from code reviews
* [ ] Research best practices for ADR documentation

### Execution Steps

- [ ] Create ADR-002-ATOM-Architecture-House-Rules.md with proper ADR structure
- [ ] Write Context section explaining the need for clear component classification
  > TEST: Context Section Complete
  > Type: Action Validation
  > Assert: Context section explains the Model vs Molecule confusion issue
  > Command: grep -A5 "## Context" docs/architecture/ADR-002-ATOM-Architecture-House-Rules.md
- [ ] Document the Decision section with clear classification rules:
  - Models: Pure data carriers (POROs/Structs) with no behavior
  - Molecules: Behavior-oriented helpers with focused logic
  - Organisms: Complex components composing molecules/atoms
- [ ] Add Consequences section covering positive and negative impacts
- [ ] Include LlmModelInfo as the primary example of proper classification
  > TEST: LlmModelInfo Example Present
  > Type: Action Validation
  > Assert: LlmModelInfo refactoring is used as an example
  > Command: grep -B2 -A2 "LlmModelInfo" docs/architecture/ADR-002-ATOM-Architecture-House-Rules.md
- [ ] Add practical guidelines for developers making classification decisions
- [ ] Include references to updated architecture.md documentation

## Acceptance Criteria

- [ ] ADR follows the same format as ADR-001 (Title, Status, Context, Decision, Consequences)
- [ ] Clear, unambiguous criteria are defined for Models, Molecules, and Organisms
- [ ] The LlmModelInfo refactoring is used as the primary illustrative example
- [ ] Decision rationale explains why this classification matters
- [ ] Consequences section covers both benefits and potential challenges
- [ ] Practical guidelines help developers make correct classification decisions
- [ ] References to related documentation (architecture.md) are included
- [ ] The ADR is numbered correctly (ADR-002) and follows naming conventions

## Out of Scope

- ❌ Refactoring existing code to match the rules (this is implementation work)
- ❌ Creating automated tooling to enforce the rules
- ❌ Documenting other architectural decisions unrelated to ATOM classification
- ❌ Updating the ADR index/README (separate task if needed)

## References

- Documentation Review: docs-project/current/v.0.2.0-synapse/code-review/task-4/docs-review-gemini-2.5-pro.md
- Code Review Discussion: Highlighting Model vs Molecule classification confusion
- Example ADR format: docs/architecture/ADR-001-CI-Aware-VCR-Configuration.md
- Key principle: Models are data, Molecules are behavior, Organisms are complex compositions