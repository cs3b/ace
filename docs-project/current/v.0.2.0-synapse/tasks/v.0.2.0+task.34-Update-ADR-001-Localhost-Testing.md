---
id: v.0.2.0+task.34
status: pending
priority: high
estimate: 2h
dependencies: []
---

# Update ADR-001 with Localhost Testing Patterns

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

Update ADR-001-CI-Aware-VCR-Configuration.md to include a new section documenting best practices for handling localhost services like LM Studio in tests. This addresses the CI fragility issue identified in code reviews where direct Net::HTTP calls in test `before` blocks can cause failures when services are unavailable.

## Scope of Work

- Add a new section to ADR-001 covering localhost service testing
- Document the VCR-wrapped availability check pattern
- Provide the `lm_studio_available?` helper as an example
- Explain why this pattern prevents CI fragility
- Update the decision rationale to include localhost scenarios

### Deliverables

#### Modify

- docs/architecture/ADR-001-CI-Aware-VCR-Configuration.md

## Phases

1. Analyze current ADR-001 structure
2. Design the new localhost testing section
3. Document the pattern with examples
4. Update decision rationale
5. Review for consistency

## Implementation Plan

### Planning Steps

* [ ] Review current ADR-001 content and structure
  > TEST: ADR Structure Analysis
  > Type: Pre-condition Check
  > Assert: Current ADR sections and structure are understood
  > Command: grep "^##" docs/architecture/ADR-001-CI-Aware-VCR-Configuration.md
* [ ] Analyze the LM Studio testing implementation to extract best practices
* [ ] Design clear explanation of the CI fragility problem and solution

### Execution Steps

- [ ] Add new section "Handling Localhost Services" after existing VCR configuration
  > TEST: Localhost Section Added
  > Type: Action Validation
  > Assert: New section for localhost services exists
  > Command: grep -A2 "Localhost Services" docs/architecture/ADR-001-CI-Aware-VCR-Configuration.md
- [ ] Document the problem: direct Net::HTTP calls in before blocks cause CI failures
- [ ] Document the solution: VCR-wrapped availability check helpers
- [ ] Add code example of the `lm_studio_available?` helper pattern
  > TEST: Helper Example Present
  > Type: Action Validation
  > Assert: lm_studio_available? example is included
  > Command: grep -B2 -A5 "lm_studio_available?" docs/architecture/ADR-001-CI-Aware-VCR-Configuration.md
- [ ] Explain why this pattern works: VCR handles the network call gracefully
- [ ] Update the Decision section to mention localhost service handling
- [ ] Add to Consequences section about improved CI reliability
  > TEST: Consequences Updated
  > Type: Action Validation
  > Assert: Consequences mention CI reliability for localhost services
  > Command: grep -A5 "Consequences" docs/architecture/ADR-001-CI-Aware-VCR-Configuration.md | grep -i "localhost\|reliability"

## Acceptance Criteria

- [ ] ADR-001 includes a dedicated section for localhost service testing
- [ ] The CI fragility problem is clearly explained
- [ ] The VCR-wrapped probe pattern is documented with code examples
- [ ] The `lm_studio_available?` helper is shown as the recommended approach
- [ ] The rationale explains why this prevents CI failures
- [ ] The update maintains consistency with existing ADR content
- [ ] Cross-references to this pattern can be made from other documentation

## Out of Scope

- ❌ Implementing the actual helper methods
- ❌ Updating test files to use the pattern
- ❌ Creating new ADRs for other decisions
- ❌ Documenting non-localhost VCR patterns

## References

- Documentation Review: docs-project/current/v.0.2.0-synapse/code-review/task-4/docs-review-gemini-2.5-pro.md
- Code Review Insight: "The reviews identify a CI fragility issue with raw Net::HTTP calls in tests"
- Recommended pattern: "VCR-wrapped probe pattern for testing localhost service availability"
- Example helper: `lm_studio_available?` method that safely checks service availability