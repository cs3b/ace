---
name: test-responsibility-map
description: Map behaviors to test layers to avoid redundant coverage
doc-type: guide
purpose: Test responsibility mapping
search_keywords:
  - test responsibility map
  - coverage matrix
  - behavior to layer
  - test pyramid mapping
  - redundancy reduction
  - risk-based coverage
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Test Responsibility Map

A test responsibility map assigns each behavior to the lowest test layer that can prove it. This reduces redundant coverage, keeps the fast loop fast, and preserves end-to-end confidence.

## Why Use This

- Prevents duplicate testing of the same behavior across layers
- Ensures high-risk behaviors get E2E coverage
- Keeps unit tests focused on fast, deterministic checks
- Makes it clear where gaps are and what to add

## Mapping Rules

1. **Start at the lowest layer** that can validate the behavior.
2. **Promote to higher layers** only when the lower layer cannot prove the behavior.
3. **Keep one E2E test per critical workflow**, not per flag or edge case.
4. **Record the source of truth** for inputs and outputs (fixtures, schema, APIs).

### Layer Decision Guide

| Behavior Type | Preferred Layer | Notes |
|--------------|-----------------|-------|
| Pure logic, parsing, mapping | Unit (atoms/molecules) | No IO, pure data
| Boundary logic with dependencies | Unit (organisms) | Stub boundaries
| CLI option parsing and validation | Unit or Integration (mocked) | Avoid subprocess
| External API contract | Contract test | Use provider test endpoint or recorded contract
| Full workflow with real tools | E2E | Real IO only here

## Build the Map

1. List behaviors by user workflow and subsystem.
2. Mark each behavior with **risk level** (high/medium/low).
3. Assign a **test layer** to each behavior.
4. Note **fixtures** or **contracts** needed.
5. Review for redundancy: if multiple tests cover the same behavior, keep the lowest layer only.

## Template (Copy/Paste)

```markdown
# Test Responsibility Map: {feature or package}

| Behavior | Risk | Layer | Test File / ID | Source of Truth | Notes |
|----------|------|-------|----------------|-----------------|-------|
| Example: CLI reports invalid config | High | E2E | MT-TOOL-001 | config parser | Real CLI path |
| Example: config validation rules | Medium | Unit (molecules) | config_validator_test.rb | schema | No IO |
| Example: retry backoff logic | Low | Unit (atoms) | backoff_test.rb | spec | Stub sleep |
```

## Review Questions

- Is each behavior tested at the lowest possible layer?
- Are critical workflows covered by at least one E2E?
- Are edge cases tested in fast loops, not E2E?
- Are there duplicate tests for the same behavior in multiple layers?
- Is the source of truth identified and consistent with real data?

## Common Pitfalls

- Using E2E tests to cover flag permutations or error cases
- Writing tests that only verify mock calls, not outputs
- Leaving behavior untested because it is "implicit" in a larger test
- Adding new tests without updating the responsibility map
