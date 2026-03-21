---
doc-type: guide
title: Test Review Checklist Guide
purpose: Test PR review checklist
ace-docs:
  last-updated: 2026-02-19
  last-checked: 2026-03-21
---

# Test Review Checklist Guide

## Goal

Quick checklist for reviewing PRs that add or modify tests. Ensures tests are:
- At the correct layer
- Properly stubbed
- Testing behavior (not implementation)
- Fast enough
- Actually catching bugs

## The Quick Check (30 seconds)

Before deep review, check:

1. **Layer**: Is test in correct directory? (atoms/molecules/organisms/e2e)
2. **Speed**: Run `ace-test <package> --profile 5` - any >100ms?
3. **I/O**: Search for `Open3`, `system(`, `File.` in new test code

If any fail → detailed review needed.

## Detailed Checklist

### 1. Layer Appropriateness

| Check | Pass | Fail |
|-------|------|------|
| Unit tests have NO real I/O | ✓ | Subprocess, network, or filesystem calls |
| Integration tests stub external deps | ✓ | Real API or subprocess calls |
| E2E tests are in `test/e2e/TS-*/` | ✓ | E2E behavior in unit test file |
| No flag permutations in E2E | ✓ | Multiple E2E tests for CLI flags |
| Max ONE CLI parity test per integration file | ✓ | Multiple subprocess tests |

**Red Flag**: Test name says "unit" but takes >100ms

### 2. Stubbing Quality

| Check | Pass | Fail |
|-------|------|------|
| Boundary methods stubbed | ✓ `available?` stubbed | Only `run` stubbed |
| No zombie mocks | ✓ Stub targets exist | Stub target renamed/removed |
| Mock data is realistic | ✓ From snapshot/schema | Invented data |
| Composite helpers used | ✓ Single helper | >3 levels of nesting |

**Red Flag**: Deep nesting without composite helper

```ruby
# BAD: 5 levels of nesting
mock_a do
  mock_b do
    mock_c do
      mock_d do
        test_code
      end
    end
  end
end

# GOOD: Composite helper
with_mock_context(a: x, b: y) do
  test_code
end
```

### 3. Behavior vs Implementation

| Check | Pass | Fail |
|-------|------|------|
| Tests assert on OUTPUT | ✓ `assert_equal expected, result` | Only `mock.verify` |
| Tests survive refactoring | ✓ Tests behavior | Tests method names |
| Mock expectations only for side-effects | ✓ `Git.commit` | `Parser.parse` |

**Red Flag**: Test only has `mock.verify` without output assertions

```ruby
# BAD: Only verifies mock was called
mock.expect(:process, true, [data])
subject.call(data)
mock.verify  # What was the result?

# GOOD: Verifies actual behavior
result = subject.call(data)
assert_equal expected_output, result.output
assert result.success?
```

### 4. Performance

| Check | Pass | Fail |
|-------|------|------|
| Unit tests <100ms | ✓ All fast | Any >100ms |
| No unstubbed `sleep` | ✓ `Kernel.stub :sleep` | Real sleep in retry tests |
| No real subprocess | ✓ Stubbed | `Open3.capture3` without stub |
| Cache pre-warming if needed | ✓ In test_helper | Cache miss on every test |

**Quick Check**:
```bash
ace-test <package> --profile 10
# All unit tests should be <100ms
```

### 5. Coverage Quality

| Check | Pass | Fail |
|-------|------|------|
| Happy path tested | ✓ | Missing |
| Error cases tested | ✓ At least one | None |
| Edge cases tested | ✓ nil, empty, boundaries | Only happy path |
| Test actually fails when broken | ✓ Try breaking it | Always passes |

**Verification**: Temporarily break the code, test should fail.

### 6. Test Base Class Check

- [ ] All tests in `test/molecules/` inherit from `<Package>Test` base class
- [ ] NOT directly from `Minitest::Test`

**Red Flag**: Test using `Minitest::Test` without access to package helpers

```ruby
# BAD: Missing package helpers (stub_prompt_path, shared temp dir, etc.)
class FeedbackExtractorTest < Minitest::Test
  # No access to stub_prompt_path, must manually stub
end

# GOOD: Has access to all package test helpers
class FeedbackExtractorTest < AceReviewTest
  # Can use stub_prompt_path(@extractor), shared temp dir, etc.
end
```

### 7. E2E Specific

For tests in `test/e2e/TS-*/`:

| Check | Pass | Fail |
|-------|------|------|
| Explicit PASS/FAIL assertions | ✓ `&& echo PASS \|\| echo FAIL` | Implicit success |
| Paths discovered at runtime | ✓ `find`, `ls` | Hardcoded paths |
| Error test cases included | ✓ Wrong args, missing files | Only happy path |
| Exit codes verified | ✓ `[ $? -eq 1 ]` | Exit code ignored |
| Cleanup documented | ✓ Cleanup section | No cleanup |

## Common Review Comments

### Performance Issues

> "This test takes 150ms. Please stub the availability check:
> ```ruby
> Runner.stub(:available?, true) do
>   # existing test code
> end
> ```"

### Wrong Layer

> "This test uses real subprocess calls but is in `test/atoms/`. Either:
> - Stub the subprocess and keep in atoms
> - Move to `test/e2e/` as an E2E test"

### Implementation Testing

> "This test only verifies the mock was called. Please add assertion on the actual result:
> ```ruby
> result = subject.call(input)
> assert_equal expected_output, result.value
> ```"

### Missing Error Cases

> "Please add at least one error case test. For example:
> ```ruby
> def test_raises_on_invalid_input
>   assert_raises(ValidationError) { subject.call(nil) }
> end
> ```"

## Quick Reference Card

### Performance Thresholds

| Layer | Target | Warning | Critical |
|-------|--------|---------|----------|
| Unit (atoms) | <10ms | >50ms | >100ms |
| Unit (molecules) | <50ms | >100ms | >200ms |
| Integration | <500ms | >1s | >2s |

### Stub the Boundary

```ruby
# Always stub availability if stubbing execution
Runner.stub(:available?, true) do
  Runner.stub(:run, result) do
    subject.process
  end
end
```

### Behavior Assertion Pattern

```ruby
# Arrange
input = build_test_input

# Act
result = subject.call(input)

# Assert (behavior, not implementation)
assert result.success?
assert_equal expected_output, result.value
assert_nil result.error
```

## Template

Use `templates/test-review-checklist.template.md` for formal PR reviews.

## See Also

- [Test Layer Decision](guide://test-layer-decision)
- [Test Mocking Patterns](guide://test-mocking-patterns)
- [Test Performance](guide://test-performance)