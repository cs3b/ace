---
doc-type: template
title: Problem
purpose: Documentation for ace-git/handbook/templates/pr/bugfix.template.md
ace-docs:
  last-updated: 2025-11-13
  last-checked: 2026-03-21
---

## Problem

[Clear description of the bug]

### Symptoms
- [What users experience]
- [Error messages]
- [Unexpected behavior]

### Root Cause
[Technical explanation of why the bug occurs]

### Impact
- Severity: [Critical/High/Medium/Low]
- Users affected: [All/Specific use case/Edge case]
- Frequency: [Always/Often/Rare]

## Solution

[Explanation of how the fix addresses the root cause]

### Changes Made
- [File/module] - [Specific fix applied]
- [File/module] - [Specific fix applied]

### Why This Approach
- [Reasoning for chosen solution]
- [Alternatives considered and why rejected]

## Testing

### Reproduction Steps (Before Fix)
1. [Step to reproduce bug]
2. [Another step]
3. [Observe error/unexpected behavior]

### Verification (After Fix)
1. [Step to verify fix]
2. [Another step]
3. [Observe correct behavior]

### Test Coverage
- [New tests added to prevent regression]
- [Existing tests modified]
- [Coverage percentage]

### Test Commands
```bash
# Run tests
bundle exec rake test

# Run specific test for this fix
bundle exec rake test:bug_fix
```

## Regression Prevention

- [ ] Added test to prevent future regression
- [ ] Updated validation/error handling
- [ ] Added documentation about edge case
- [ ] Improved error messages

## Documentation

- [ ] Code comments added explaining fix
- [ ] README updated if behavior changed
- [ ] CHANGELOG.md updated
- [ ] Known issues list updated

## Checklist

- [ ] Tests pass locally
- [ ] Root cause identified and documented
- [ ] Fix verified with reproduction steps
- [ ] No breaking changes
- [ ] CHANGELOG.md updated
- [ ] Regression test added

## Breaking Changes

[Breaking changes should be rare in bugfixes. If present, describe them. Otherwise, state "None"]

## Related Issues

Fixes #[issue-number]
Related to #[related-issue]

## Additional Context

[Any additional information, logs, stack traces, or context]

```
# Error logs or stack traces if relevant
```
