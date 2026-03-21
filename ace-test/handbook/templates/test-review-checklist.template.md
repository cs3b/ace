---
doc-type: template
title: Test Review Checklist
purpose: Test PR review checklist
ace-docs:
  last-updated: 2026-02-19
  last-checked: 2026-03-21
---

# Test Review Checklist

**PR**: #{{number}}
**Package**: {{package}}
**Reviewer**: {{name}}
**Date**: {{date}}

## Quick Summary

- [ ] Tests added/modified: {{count}}
- [ ] Test type: Unit / Integration / E2E
- [ ] Performance verified: Yes / No / N/A

---

## 1. Layer Appropriateness

Is each test at the correct layer?

| Test | Current Layer | Correct? | Notes |
|------|---------------|----------|-------|
| {{test}} | Unit/Integration/E2E | Yes/No | {{notes}} |

**Checklist**:
- [ ] Unit tests have NO real I/O (subprocess, network, filesystem)
- [ ] Integration tests stub external dependencies
- [ ] E2E tests are in `test/e2e/TS-*/` format (scenario.yml + TC-*.tc.md)
- [ ] No flag permutation tests in E2E (should be unit)
- [ ] ONE CLI parity test per integration file max

## 2. Stubbing Quality

Are mocks/stubs correctly implemented?

**Checklist**:
- [ ] Boundary methods stubbed (not just inner methods)
- [ ] `available?` checks stubbed if `run` is stubbed
- [ ] No zombie mocks (stub targets match actual code)
- [ ] Mock data is realistic (from snapshots or schemas)
- [ ] Composite helpers used where appropriate

**Red Flags**:
- [ ] Deep nesting (>3 levels) without composite helper
- [ ] Stubbing private methods
- [ ] Mock expectations without behavior assertions

## 3. Behavior vs Implementation

Do tests verify behavior, not implementation details?

**Checklist**:
- [ ] Tests assert on OUTPUT, not method calls
- [ ] Tests survive internal refactoring
- [ ] Mock expectations only for side-effect methods
- [ ] No testing of private method order

**Example Check**:
```ruby
# BAD: Tests implementation
mock.verify  # "Was X called?"

# GOOD: Tests behavior
assert_equal expected, result.output
```

## 4. Performance

Will tests run fast enough?

**Checklist**:
- [ ] Profiled with `ace-test --profile 5`
- [ ] Unit tests <100ms each
- [ ] No `sleep` calls without stubbing
- [ ] No subprocess calls without stubbing
- [ ] Cache pre-warming if needed

**Performance Check**:
```bash
ace-test {{package}} --profile 10
# Verify no new tests >100ms
```

## 5. Coverage Quality

Do tests actually catch bugs?

**Checklist**:
- [ ] Happy path tested
- [ ] Error cases tested
- [ ] Edge cases tested (nil, empty, boundaries)
- [ ] Test fails when code is broken (try breaking it)

**Negative Test Check**:
- [ ] At least one error scenario tested
- [ ] Invalid input handling verified
- [ ] Exception/error messages checked

## 6. E2E Specific (if applicable)

For E2E tests in TS-format (`TC-*.tc.md`):

**Checklist**:
- [ ] PASS/FAIL assertions are explicit
- [ ] File paths discovered at runtime, not hardcoded
- [ ] Error test cases included (not just happy path)
- [ ] Exit codes verified for error scenarios
- [ ] Cleanup documented
- [ ] Prerequisites listed

## 7. Test Organization

Is the test well-structured?

**Checklist**:
- [ ] Test file in correct directory (atoms/molecules/organisms/e2e)
- [ ] Test name describes behavior (`test_returns_error_for_invalid_input`)
- [ ] Arrange-Act-Assert pattern followed
- [ ] No test interdependencies
- [ ] Fixtures in `test/fixtures/` if shared

---

## Verdict

- [ ] **Approve**: Tests are well-designed and performant
- [ ] **Request Changes**: Issues identified above
- [ ] **Needs Discussion**: Architectural concerns

**Comments**:

{{reviewer_comments}}

---

## Quick Reference

### Performance Thresholds

| Layer | Target | Warning | Critical |
|-------|--------|---------|----------|
| Unit (atoms) | <10ms | >50ms | >100ms |
| Unit (molecules) | <50ms | >100ms | >200ms |
| Integration | <500ms | >1s | >2s |

### Stub the Boundary Pattern

```ruby
# Always stub availability check if stubbing execution
Runner.stub(:available?, true) do
  Runner.stub(:run, result) do
    subject.process
  end
end
```