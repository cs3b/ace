---
id: v.0.9.0+task.129
status: pending
priority: medium
estimate: 1h
dependencies: []
---

# Consolidate test helper packages - merge ace-test-support into ace-support-test-helpers

## Behavioral Specification

### User Experience
- **Input**: User runs tests across ace-* packages
- **Process**: All tests use unified test helper package (ace-support-test-helpers)
- **Output**: Consistent test infrastructure, single source of truth for test utilities

### Expected Behavior
The codebase should have only ONE test helper package: `ace-support-test-helpers`. The old `ace-test-support` package should be removed. All ace-* packages should depend on and use `ace-support-test-helpers` for their test infrastructure.

### Interface Contract
```bash
# All test_helper.rb files require:
require "ace/test_support"

# All gemspecs should depend on:
spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
```

### Success Criteria
- [ ] `ace-test-support/` directory is deleted
- [ ] `ace-git-worktree` gemspec updated to use `ace-support-test-helpers`
- [ ] All tests pass via `ace-test-suite`
- [ ] `bundle install` completes without errors

## Objective

Eliminate duplicate test helper packages. The codebase currently has two nearly identical packages:
- `ace-support-test-helpers` (correct name, superset with coverage.rb, performance_helpers.rb)
- `ace-test-support` (old name, subset)

Only `ace-git-worktree` still depends on the old package.

## Scope of Work

### Analysis Summary

**ace-support-test-helpers** (KEEP):
- Version: 0.9.2
- Extras: `coverage.rb`, `performance_helpers.rb`, contract tests
- Status: Correct naming convention per ADR-015

**ace-test-support** (DELETE):
- Version: 0.9.2
- Missing: `coverage.rb`, `performance_helpers.rb`
- Status: Old naming, should have been deleted after rename

### Deliverables
- Updated gemspec for ace-git-worktree
- Updated comments in test_helper.rb files (hygiene)
- Deleted ace-test-support directory
- Regenerated Gemfile.lock

## Planning Steps

* [x] Analyze both packages structure and contents
* [x] Compare git history since rename commit (6e7e7753)
* [x] Identify all gemspec dependencies on each package
* [x] Verify ace-support-test-helpers is the superset

## Execution Steps

- [ ] Update `ace-git-worktree/ace-git-worktree.gemspec:48`
  - Change: `spec.add_development_dependency 'ace-test-support'`
  - To: `spec.add_development_dependency 'ace-support-test-helpers', '~> 0.9'`

- [ ] Update comments in test_helper.rb files (hygiene)
  - `ace-support-core/test/test_helper.rb:6`
  - `ace-context/test/test_helper.rb:7`
  - `ace-docs/test/test_helper.rb:6`
  - `ace-git-worktree/test/test_helper.rb:36,43,50`
  - `ace-review/test/test_helper.rb:44,62`

- [ ] Delete `ace-test-support/` directory
  ```bash
  rm -rf ace-test-support/
  ```

- [ ] Regenerate Gemfile.lock
  ```bash
  bundle install
  ```

- [ ] Run full test suite
  ```bash
  ace-test-suite
  ```

## Out of Scope

- No migration of code (ace-support-test-helpers already has everything)
- No changes to require paths (both use `require "ace/test_support"`)

## References

- Rename commit: `6e7e7753` (Nov 2, 2025) - feat(infrastructure-gem-naming)
- Sync commit: `b2cefe8b` - fix(ace-llm): Address review synthesis feedback
