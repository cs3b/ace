---
doc-type: guide
title: Test Responsibility Map Guide
purpose: Test responsibility mapping and risk-based coverage
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Test Responsibility Map Guide

## Goal

A Test Responsibility Map assigns each behavior to the **lowest test layer** that can prove it. This:
- Prevents duplicate testing across layers
- Keeps the fast loop fast
- Ensures critical workflows get E2E coverage
- Makes coverage gaps visible

## Core Principle

> Each behavior belongs to exactly ONE test layer. Test it at the lowest layer possible, promote only when necessary.

## The Mapping Process

### Step 1: List Behaviors

Identify all behaviors from requirements:

```markdown
## Behaviors for ConfigParser

1. Parse valid YAML file
2. Return defaults for missing keys
3. Raise error for malformed YAML
4. Handle empty file
5. Merge cascading configs
6. CLI reports config errors with exit code 1
```

### Step 2: Assign Risk Levels

| Risk Level | Criteria | Testing Intensity |
|------------|----------|-------------------|
| **High** | Security, data integrity, core business, user-facing errors | Must have unit + E2E |
| **Medium** | Important functionality, configuration, integrations | Unit required |
| **Low** | Logging, cosmetic, internal helpers | Unit if time permits |

### Step 3: Map to Layers

For each behavior, ask:

1. **Can a unit test prove this?** (No I/O needed) → Unit
2. **Does it need component interaction?** (Stubbed I/O) → Integration
3. **Does it require real I/O to prove?** (CLI, network, filesystem) → E2E

### Step 4: Build the Map

| Behavior | Risk | Layer | Test File | Source of Truth |
|----------|------|-------|-----------|-----------------|
| Parse valid YAML | Medium | Unit | config_parser_test.rb | YAML schema |
| Return defaults | Medium | Unit | config_parser_test.rb | defaults.yml |
| Malformed YAML error | High | Unit | config_parser_test.rb | Exception spec |
| Config cascade merge | Medium | Integration | config_resolver_test.rb | Merge rules |
| CLI exit code 1 | High | E2E | TS-CONFIG-001 | CLI spec |

## Layer Decision Rules

### Unit Test If:

- Pure logic with no side effects
- Data transformation or validation
- Error handling for invalid input
- Edge cases (nil, empty, boundaries)

**Stub everything**: filesystem, network, subprocess, git

### Integration Test If:

- Multiple components interact
- Data flows between modules
- Error propagation matters
- ONE CLI parity check needed

**Stub external dependencies**: APIs, subprocess calls

### E2E Test If:

- Complete user workflow
- Real tool interaction required
- Environment-specific behavior
- Cannot be proven without real I/O

**Use real I/O**: sandboxed, with cleanup

## Avoiding Redundancy

### Anti-Pattern: Testing Same Behavior at Multiple Layers

```markdown
# BAD: Same behavior tested 3 times
- Unit: test_config_parser_returns_defaults
- Integration: test_config_loader_uses_defaults
- E2E: TC-001 verifies defaults in CLI output
```

### Pattern: Test at Lowest Layer, Verify at Higher

```markdown
# GOOD: Behavior at lowest, workflow at highest
- Unit: test_config_parser_returns_defaults (proves logic)
- Integration: (skip - unit covers it)
- E2E: TC-001 verifies full config workflow (one test, not per feature)
```

## Risk-Based Coverage

### High Risk Behaviors

Must be tested thoroughly:

```markdown
| Behavior | Risk | Why High | Coverage |
|----------|------|----------|----------|
| Auth token validation | High | Security | Unit + E2E |
| Data persistence | High | Data integrity | Unit + Integration + E2E |
| Payment processing | High | Business critical | Unit + Integration + E2E |
```

### Low Risk Behaviors

Basic coverage sufficient:

```markdown
| Behavior | Risk | Why Low | Coverage |
|----------|------|---------|----------|
| Log formatting | Low | Cosmetic | Unit happy path |
| Debug output | Low | Internal | Skip or minimal |
```

## Template Usage

Use the template at `templates/test-responsibility-map.template.md` when:

- Starting a new feature
- Auditing existing coverage
- Planning test refactoring
- Reviewing PR test coverage

## Review Questions

When reviewing a responsibility map:

- [ ] Is each behavior at the lowest possible layer?
- [ ] Are high-risk behaviors covered by E2E?
- [ ] Are edge cases in unit tests, not E2E?
- [ ] Any duplicate coverage across layers?
- [ ] Source of truth identified for each behavior?

## Common Mistakes

### Mistake 1: E2E for Edge Cases

```markdown
# BAD: Testing every edge case in E2E
- E2E: TC-001 valid config
- E2E: TC-002 empty config
- E2E: TC-003 missing key
- E2E: TC-004 invalid YAML
- E2E: TC-005 circular reference

# GOOD: Edge cases in unit, workflow in E2E
- Unit: test_empty_config, test_missing_key, test_invalid_yaml, test_circular_ref
- E2E: TC-001 complete config workflow (happy + one error)
```

### Mistake 2: Missing High-Risk E2E

```markdown
# BAD: High-risk behavior only unit tested
- Unit: test_auth_token_validation ✓
- E2E: (none)

# GOOD: High-risk has E2E verification
- Unit: test_auth_token_validation ✓
- E2E: TC-001 authentication workflow ✓
```

### Mistake 3: No Source of Truth

```markdown
# BAD: Mock data invented
mock_response = { status: "ok" }  # Where does this come from?

# GOOD: Mock data from real source
mock_response = JSON.parse(File.read("fixtures/api_response.json"))
# fixtures/api_response.json is snapshot from real API
```

## Integration with Workflows

### With /ace-test-plan

1. Generate responsibility map
2. Identify gaps
3. Plan tests by layer
4. Output test plan

### With /ace-test-verify-suite

1. Check existing tests against map
2. Identify redundancies
3. Flag missing coverage
4. Suggest optimizations

## See Also

- [Test Layer Decision](guide://test-layer-decision) - Layer decision matrix
- [Test Mocking Patterns](guide://test-mocking-patterns) - How to stub
- [Test Suite Health](guide://test-suite-health) - Metrics and audits