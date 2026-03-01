---
id: 8no000
title: "Retro: ace-git Organism Test Stub Attempts"
type: conversation-analysis
tags: []
created_at: "2025-12-25 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8no000-ace-git-organism-test-stub-attempts.md
---
# Retro: ace-git Organism Test Stub Attempts

**Date**: 2025-12-25
**Context**: Attempted to speed up 3 slow organism tests in ace-git by stubbing config methods
**Author**: Development Session
**Type**: Conversation Analysis

## What Went Well

- **Clear root cause identified**: Tests slow due to `Ace::Git.config` → `ConfigResolver` filesystem search
- **Multiple stub approaches tried**: Minitest `stub`, `define_singleton_method`, method saving/restoring
- **User provided clear direction**: "we should stub our method that call ace git only"
- **Knew when to stop**: User correctly identified when approach was becoming too complex

## What Could Be Improved

- **Stubbing at wrong level**: Attempted to stub ace-git config methods, but ConfigResolver lives in ace-core
- **Complexity increased with each attempt**: Each new stub approach added more complexity without solving the problem
- **Time spent on ineffective solution**: Multiple iterations (module prepend, define_singleton_method, etc.) without success
- **Didn't consider cross-package dependency earlier**: Should have immediately recognized this requires ace-core changes

## Key Learnings

- **Cross-package dependencies can't be stubbed from downstream**: ace-git cannot effectively stub ace-core's ConfigResolver
- **Config caching complicates stubbing**: `@config` instance variable caches the result, making stubs ineffective
- **Some performance issues require architectural fixes**: Not all problems can be solved with test stubs
- **Accept "good enough" when fixes become too complex**: 7s test time (down from 18s) is acceptable for now

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Multiple stubbing attempts failed**
  - Occurrences: 5-6 different stub approaches (prepend module, define_singleton_method, Minitest stub, etc.)
  - Impact: Wasted time, increased complexity, no performance improvement
  - Root Cause: ConfigResolver is in ace-core, not ace-git - cannot be effectively stubbed from downstream package

- **User redirected approach early**
  - User insight: "but why do we need to stup ace-git?" and "we should stub our method that call ace git only"
  - This clarified the scope but didn't solve the underlying cross-package issue

#### Medium Impact Issues

- **Test helper modifications didn't help**
  - Attempted various test_helper.rb changes
  - None prevented ConfigResolver from being called

#### Low Impact Issues

- **Individual test stubs**
  - Adding stubs to specific tests had no effect
  - Config was already cached before stubs took effect

### Improvement Proposals

#### Process Improvements

- **Identify cross-package dependencies early**: Before attempting stubs, check if the slow code lives in a different package
- **Accept architectural limitations**: Some issues require changes in the dependency, not the consumer

#### Tool Enhancements

- **Task 156** (ace-core ConfigResolver test mode): This is the proper fix - add test mode to ConfigResolver itself

### Token Limit & Truncation Issues

- **No significant issues**: Conversation stayed focused on the technical problem

## Action Items

### Stop Doing

- Attempting to stub cross-package dependencies from consumer packages
- Adding complex stub mechanisms when simpler architectural fixes exist

### Continue Doing

- Using `ace-test --profile` to identify slow tests
- Accepting "good enough" performance when fixes become too complex
- Creating follow-up tasks for cross-package issues

### Start Doing

- Checking dependency chains before attempting stubs
- Identifying which package owns the code before planning fixes

## Technical Details

### Files Modified (All Reverted)

1. **ace-git/test/test_helper.rb** - Multiple attempted stub approaches (all reverted)
2. **ace-git/test/organisms/repo_status_loader_test.rb** - Added config stubs to 3 tests (reverted)

### Stub Approaches Tried

1. **Module prepend with `def self.user_config`** - Incorrect syntax
2. **Module prepend with `def user_config`** - Correct syntax but didn't work
3. **`define_singleton_method` before require** - Module reopens and replaces methods
4. **`class_eval` with class variables** - Didn't prevent ConfigResolver calls
5. **Minitest `stub` with `config` hash** - Cache returned before stub
6. **`define_singleton_method` in each test** - Saved/restored method, still slow
7. **`define_singleton_method` with begin/ensure** - Same issue

### Root Cause

```
RepoStatusLoader.load
  → Ace::Git.network_timeout
    → Ace::Git.config
      → user_config
        → Ace::Core::Organisms::ConfigResolver.new
          → ConfigFinder.new
            → DirectoryTraverser.new
              → Filesystem search (SLOW)
```

The ConfigResolver lives in **ace-support-core**, which ace-git depends on. Stubbing from ace-git cannot prevent ConfigResolver from being loaded and called.

## Additional Context

- **Branch**: `140-enhance-ace-context-with-dynamic-git-branch-and-pr-information`
- **Current test times**:
  - atoms: 22ms ✅
  - organisms: ~5.6s (80% of total time)
  - total: ~7.3s (60% faster than original 18s)
- **Proper fix**: Task 156 - add test mode to ace-core's ConfigResolver
- **Key User Insights**:
  - "we should stub our method that call ace git only"
  - "lets give up - we making it more complecated that it can be worth it"
  - "we keep it 7s for this package"
