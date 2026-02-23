# Research: E2E Testing Best Practices for Agent-Driven Systems

## Context

Research findings informing Task 280 — E2E Test Levels, Grouping, and Goal-Based Execution.

## Tag-Based Test Filtering (Industry Standard)

### RSpec (Ruby)
- Tags via metadata: `it "works", :smoke do`
- CLI: `rspec --tag smoke`, `rspec --tag ~slow`
- Supports arbitrary key-value tags: `--tag type:integration`
- Filter at load time, not execution time

### pytest (Python)
- Markers: `@pytest.mark.smoke`
- CLI: `pytest -m "smoke and not slow"`
- Boolean expression filtering (AND, OR, NOT)
- Custom markers registered in pytest.ini

### JUnit 5 (Java)
- `@Tag("smoke")` annotation
- `includeTags`/`excludeTags` in test plan
- Supports tag expressions: `smoke & !slow`

### Common Patterns
- OR logic for inclusion (any matching tag runs)
- Exclude overrides include
- Untagged tests opt-out of tag-filtered runs
- Tags are free-form strings, conventions enforced by documentation

## Goal-Based Testing

### BDD/ATDD Influence
- Behavior-Driven Development: describe outcomes, not implementation
- Acceptance Test-Driven Development: criteria before code
- Both emphasize "what" over "how"

### Agent-Specific Considerations
- Procedural tests verify instruction-following ability
- Goal tests verify problem-solving ability
- Goal tests are more resilient to implementation changes
- Goal tests require clear, verifiable success criteria
- Risk: ambiguous criteria lead to false positives

### Success Criteria Design
- Must be objectively verifiable (file exists, output contains, exit code)
- Avoid subjective criteria ("output is well-formatted")
- Each criterion independently checkable
- Criteria should be necessary AND sufficient for the objective

## Test Grouping Strategies

### Cost-Based Tiers
- **Smoke**: Minimal cost, maximum signal-per-dollar
- **Standard**: Normal execution, expected workflow paths
- **Deep**: Expensive, edge cases, error recovery, multi-step

### Execution Context Tiers
- **Pre-commit**: <1 min, affected packages only, smoke tests
- **PR validation**: 5-10 min, full happy-path
- **Release gate**: Full suite, all tiers, optional verification
- **Investigation**: Targeted by use-case tags

### Grouping Anti-Patterns
- Too many groups → nobody remembers which to use
- Groups as folders → inflexible, tests belong to multiple groups
- Mandatory group membership → creates busywork for simple scenarios

## Dual-Agent Verification

### Rationale
- Agent self-assessment has confirmation bias
- Executor knows its own intent, may confuse "tried to" with "succeeded"
- Independent observer catches false positives

### Patterns from Software Testing
- Code review (separate reviewer from author)
- Mutation testing (independent validation of test quality)
- Formal verification (separate proof from implementation)

### Implementation Considerations
- Verifier must be truly independent (no shared context)
- Cost doubles per verified test — use selectively
- Most valuable for goal-mode tests (procedural tests have deterministic steps)
- Disagreement is signal, not failure — flags items for human review

## References

- RSpec metadata/tags: https://rspec.info/features/filtering/
- pytest markers: https://docs.pytest.org/en/stable/how-to/mark.html
- JUnit 5 tags: https://junit.org/junit5/docs/current/user-guide/#running-tests-tags
- BDD practices: https://cucumber.io/docs/bdd/
