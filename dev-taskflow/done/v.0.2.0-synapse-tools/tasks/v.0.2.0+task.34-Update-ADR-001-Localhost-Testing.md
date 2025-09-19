---
id: v.0.2.0+task.34
status: done
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

* [x] Review current ADR-001 content and structure
  > TEST: ADR Structure Analysis
  > Type: Pre-condition Check
  > Assert: Current ADR sections and structure are understood
  > Command: grep "^##" docs-project/current/v.0.2.0-synapse/decisions/ADR-001-CI-Aware-VCR-Configuration.md
  > Result: ✅ PASS - ADR structure analyzed: Status, Context, Decision, Consequences (Positive/Negative/Neutral), Alternatives Considered, Related Decisions, References
* [x] Analyze the LM Studio testing implementation to extract best practices
  > Result: ✅ PASS - Found VCR-wrapped `lm_studio_available?` helper pattern in docs/DEVELOPMENT.md that prevents CI fragility by avoiding direct Net::HTTP calls in test before blocks
* [x] Design clear explanation of the CI fragility problem and solution
  > Result: ✅ PASS - Problem: Direct Net::HTTP calls in test before blocks fail in CI when localhost services unavailable. Solution: VCR-wrapped availability helpers that record/replay network interactions deterministically.

### Execution Steps

- [x] Add new section "Handling Localhost Services" after existing VCR configuration
  > TEST: Localhost Section Added
  > Type: Action Validation
  > Assert: New section for localhost services exists
  > Command: grep -A2 "Localhost Services" docs-project/current/v.0.2.0-synapse/decisions/ADR-001-CI-Aware-VCR-Configuration.md
  > Result: ✅ PASS - Section "## Handling Localhost Services" added with subsections for CI fragility problem and VCR-wrapped probe solution
- [x] Document the problem: direct Net::HTTP calls in before blocks cause CI failures
  > Result: ✅ PASS - Problem documented in "The CI Fragility Problem" subsection with clear explanation and anti-pattern example
- [x] Document the solution: VCR-wrapped availability check helpers
  > Result: ✅ PASS - Solution documented in "The VCR-Wrapped Probe Solution" subsection with recommended pattern and implementation guidelines
- [x] Add code example of the `lm_studio_available?` helper pattern
  > TEST: Helper Example Present
  > Type: Action Validation
  > Assert: lm_studio_available? example is included
  > Command: grep -B2 -A5 "lm_studio_available?" docs-project/current/v.0.2.0-synapse/decisions/ADR-001-CI-Aware-VCR-Configuration.md
  > Result: ✅ PASS - Helper example included with VCR-wrapped availability check pattern and usage in test before blocks
- [x] Explain why this pattern works: VCR handles the network call gracefully
  > Result: ✅ PASS - Explanation included in "Why This Pattern Works" subsection with 5 key benefits: VCR handles network calls gracefully, deterministic behavior, proper separation, maintainable, and CI-safe
- [x] Update the Decision section to mention localhost service handling
  > Result: ✅ PASS - Added paragraph to Decision section explaining localhost service testing pattern
- [x] Add to Consequences section about improved CI reliability
  > TEST: Consequences Updated
  > Type: Action Validation
  > Assert: Consequences mention CI reliability for localhost services
  > Command: grep -A15 "Consequences" docs-project/current/v.0.2.0-synapse/decisions/ADR-001-CI-Aware-VCR-Configuration.md | grep -i "localhost\|reliability"
  > Result: ✅ PASS - Added "Localhost Service Reliability" and "Deterministic Testing" benefits to Positive consequences

## Acceptance Criteria

- [x] ADR-001 includes a dedicated section for localhost service testing
- [x] The CI fragility problem is clearly explained
- [x] The VCR-wrapped probe pattern is documented with code examples
- [x] The `lm_studio_available?` helper is shown as the recommended approach
- [x] The rationale explains why this prevents CI failures
- [x] The update maintains consistency with existing ADR content
- [x] Cross-references to this pattern can be made from other documentation

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