---
id: v.0.9.0+task.150.35
status: done
priority: medium
estimate: 15m
dependencies:
- v.0.9.0+task.150.15
parent: v.0.9.0+task.150
---

# Verify: Full test suite & performance check

## Scope

Verify full test suite passes and performance is acceptable. If issues found, propose solution → get user approval → fix → re-verify.

## Verification Checklist

- [ ] All tests pass (no failures, no unexpected skips)
- [ ] Test counts correct (not "0 tests, 0 assertions")
- [ ] No tests exceed 1s (except integration tests)
- [ ] No zombie mocks (slow tests with ineffective stubs)

## Automatic Tests

```bash
# Full test suite across all packages
ace-test-suite

# Performance check - no tests >1s (except integration)
ace-test --profile 20
```

## Remediation Process

If any verification check fails:

1. **Document the issue**: What check failed and what the actual behavior is
2. **Propose solution**: Describe the fix needed
3. **Get user approval**: Present proposal and wait for approval
4. **Implement fix**: Make the code changes
5. **Re-verify**: Run tests and manual checks again

## Acceptance Criteria

- [ ] All verification checks pass
- [ ] All automatic tests pass
- [ ] Performance within acceptable limits
- [ ] No issues found OR all issues found and fixed