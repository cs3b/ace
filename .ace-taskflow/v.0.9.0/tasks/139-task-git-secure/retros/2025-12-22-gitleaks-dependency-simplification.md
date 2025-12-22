# Reflection: Gitleaks Dependency Simplification

**Date**: 2025-12-22
**Context**: Simplifying ace-git-secrets by making gitleaks a required dependency and removing ~1800 lines of Ruby pattern matching code
**Author**: Claude Code
**Type**: Self-Review

## What Went Well

- **Clear decision framework**: Objectively analyzed gitleaks (100+ patterns, Go speed) vs Ruby fallback (15 patterns) to surface the core tradeoff
- **User involvement at decision points**: Asked user about gitleaks requirement and branch filtering before implementing, avoiding rework
- **Systematic refactoring**: Followed ATOM architecture - deleted atoms before updating molecules/organisms that depended on them
- **Incremental testing**: Running tests after each major change caught cascading issues early (parameter mismatches, missing skips)
- **Comprehensive commit message**: Used `BREAKING CHANGE:` notation for the gitleaks requirement

## What Could Be Improved

- **Test token entropy awareness**: Low-entropy test tokens (`ghp_1234567890abcdefghijklmnopqrstuvwxyzAB`) weren't detected by gitleaks - required high-entropy patterns (`ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4`)
- **Multi-file parameter cascading**: Missed several files still passing old parameters (`:patterns`, `:use_gitleaks`, `:thread_count`) after deleting the atoms that consumed them
- **Integration test isolation**: Some tests were testing multiple concerns (scan AND revoke), making failures harder to diagnose
- **Config method removal**: Forgot to remove `.patterns` method from config tests when removing pattern support

## Key Learnings

- **Gitleaks requires entropy**: Token patterns must have sufficient entropy to avoid false positives - sequential characters won't trigger detection
- **Simplify by responsibility**: ace-git-secrets' value is in remediation (revoke, rewrite, report), not detection - detection is gitleaks' job
- **External tools > internal duplication**: 100+ actively maintained patterns in Go beat 15 static Ruby patterns we'd need to maintain
- **grep for deleted parameter names**: When removing a feature, grep for its parameter names across all files to find all callers
- **Breaking changes need visibility**: Adding `BREAKING CHANGE:` to commit message helps future readers understand the impact

## Action Items

### Stop Doing

- Duplicating functionality that external tools do better (detection patterns)
- Using low-entropy test data for security tools that detect based on entropy
- Testing multiple concerns in single integration tests

### Continue Doing

- Using plan mode to analyze design decisions before implementing
- Asking user at key decision points (require dependency? remove feature?)
- Running tests incrementally during large refactors
- Following ATOM architecture for deletion order (atoms → molecules → organisms)

### Start Doing

- Grep for parameter names when removing features: `grep -r ':parameter_name' .`
- Document entropy requirements for test tokens in test helpers
- Add gitleaks skip guards in all security scanning tests

## Technical Details

**Files Changed**: 29 files
**Lines Removed**: 2,230
**Lines Added**: 427
**Net Reduction**: ~1,800 lines

**Deleted Files**:
- `atoms/token_pattern_matcher.rb` (255 lines of regex patterns)
- `atoms/git_blob_reader.rb` (351 lines of batch blob reading)
- `atoms/thread_safe_blob_cache.rb` (84 lines of caching)
- Related test files

**Key API Changes**:
- `GitleaksRunner.ensure_available!` - new method for early validation
- Removed `--no-gitleaks`, `--branch` CLI options
- Removed `:patterns`, `:use_gitleaks`, `:thread_count` parameters

## Additional Context

- Commit: `b0513bb9 refactor(detection): Require gitleaks for scanning; remove internal detection logic`
- Branch: `139-secure-git-history-remove-and-revoke-authentication-tokens`
- All 144 tests pass (1 skipped for git-filter-repo)
