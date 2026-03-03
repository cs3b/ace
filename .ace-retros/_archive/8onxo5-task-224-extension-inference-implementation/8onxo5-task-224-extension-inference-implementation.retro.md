---
id: 8onxo5
title: 'Retro: Task 224 - Extension Inference Implementation'
type: self-review
tags: []
created_at: '2026-01-24 22:26:49'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8onxo5-task-224-extension-inference-implementation.md"
---

# Retro: Task 224 - Extension Inference Implementation

**Date**: 2026-01-24
**Context**: Implementation of DWIM extension inference for ace-nav protocol resolution
**Author**: Claude Code Agent
**Type**: Self-Review

## What Went Well

- **ATOM Architecture Compliance**: Successfully created `ExtensionInferrer` as a pure atom with no side effects, making it easily testable and reusable
- **Test-Driven Approach**: Wrote comprehensive unit tests first (15 tests for ExtensionInferrer), which guided the implementation design
- **Configuration Cascade Integration**: Properly integrated with ADR-022 configuration cascade, allowing users to override inference settings via `.ace/nav/config.yml`
- **Backward Compatibility**: Ensured all existing tests pass and explicit extension matching continues to work exactly as before
- **Incremental Debugging**: Systematically fixed test failures by understanding the root cause (extension stripping logic, config merging in test helper)

## What Could Be Improved

- **Test Design Iterations**: Initial test design had incorrect assumptions about how extension inference should work, leading to 3-4 test iteration cycles
- **Integration Test Confusion**: Spent time debugging integration tests that were pre-existing failures (task protocol tests), unrelated to our changes
- **Version Test Update**: Forgot to update the version assertion test after bumping version, caught only during full test suite run

## Key Learnings

### Technical Insights

- **Extension Stripping Complexity**: The `create_resource_info` method needs to strip extensions from the relative path. Using both protocol extensions AND inferred extensions is necessary to handle compound extensions like `.cst.md`
- **Glob Pattern Wildcards**: For inference to work with files like `mydoc.cst.md` when searching for `mydoc`, the glob pattern needs to be `candidate + "*"` (not exact match), with additional basename validation
- **Config Merging**: The test helper's `create_test_protocol` function wasn't merging additional config keys (like `inferred_extensions`). Adding a simple `.merge(config)` fixed this

### Process Insights

- **Review Workflow Value**: The automated code review provided valuable medium-priority feedback (precise globbing pattern, documentation) that would be good to address but didn't block the feature
- **Skill Chaining**: Successfully executed the complete delivery workflow (implement → commit → release → create-pr → review → fix) by chaining `/ace:` skills

### Design Decisions

- **Inference Bailout for Nested Paths**: Explicitly disabled inference for patterns containing `/` to prevent performance issues and potential traversal - this was a sound security decision
- **First-Match Strategy**: Extension inference stops at the first successful match, which provides determinism and good performance characteristics

## Challenge Patterns Identified

### Medium Impact Issues

- **Test Mocking Complexity**: The `create_test_config_loader` uses monkey patching to inject `@test_dir` for protocol discovery. This works but is somewhat fragile and could be improved with a better testing abstraction
  - **Root Cause**: Need to test protocol scanning without using actual project directories
  - **Impact**: Required careful setup/teardown and could be brittle with code changes

- **Extension Stripping Order**: The order of extension stripping matters. For `mydoc.cst.md`, if `.md` is stripped first we get `mydoc.cst`, then `.cst` can be stripped. But this depends on iteration order.
  - **Root Cause**: Simple iteration through extensions list
  - **Mitigation**: Included compound extensions (`.cst.md`) in the `inferred_extensions` list to ensure proper stripping

### Low Impact Issues

- **Version Test Drift**: The version assertion test (`test_version_is_0_17_2`) becomes stale with every version bump
  - **Impact**: Minor - caught quickly during test runs
  - **Prevention**: Could use a dynamic version check or generate this test

## Improvement Proposals

### Process Improvements

- **Add Version Test to Release Workflow**: Automatically update or remove version-specific tests as part of the version bump workflow
- **Separate Integration Test Suites**: Run unit tests separately from integration tests to avoid confusion about which tests are failing

### Tool Enhancements

- **Better Test Config Loader**: Create a proper test double or factory for ConfigLoader that doesn't require monkey patching
- **Auto-Update Version Tests**: Have the bump-version workflow automatically update version-specific test assertions

### Code Quality

- **Refine Glob Pattern**: As suggested in review, consider using `candidate + "{,.*}"` for more precise matching instead of `candidate + "*"`

## Action Items

### Stop Doing

- Using monkey patching for test infrastructure when a proper test double would be cleaner
- Assuming tests understand compound extensions - explicitly add full compound extensions to `inferred_extensions` list

### Continue Doing

- Writing comprehensive tests before/alongside implementation
- Following ATOM architecture strictly for new code
- Running full test suite (`ace-test-suite`) before completing tasks

### Start Doing

- Considering extension stripping order when designing protocol configurations
- Running unit tests separately from integration tests during development
- Checking for version-specific tests after version bumps

## Technical Details

### Extension Inference Algorithm

```
1. Try exact match with protocol extensions (fast path)
2. If no match and inference enabled:
   a. Generate candidate patterns in fallback_order:
      - protocol_shorthand: .g, .wf
      - protocol_full: .g.md, .wf.md
      - generic_markdown: .md
      - bare: (no extension)
   b. For each candidate:
      - Glob: search_path/**/candidate*
      - Validate: basename.start_with?(pattern)
      - Return first match found
3. Return resources (empty if nothing found)
```

### Key Files Modified

- `lib/ace/support/nav/atoms/extension_inferrer.rb` (112 lines) - Pure extension inference logic
- `lib/ace/support/nav/molecules/protocol_scanner.rb` (+90 lines) - Integration of inference
- `test/atoms/extension_inferrer_test.rb` (197 lines) - Comprehensive unit tests
- `test/molecules/protocol_scanner_test.rb` (+183 lines) - Integration tests
- `.ace-defaults/nav/config.yml` - Added `extension_inference` configuration
- `.ace-defaults/nav/protocols/guide.yml` - Added `inferred_extensions`
- `.ace-defaults/nav/protocols/wfi.yml` - Added `inferred_extensions`

## Additional Context

- **Task**: v.0.9.0+task.224
- **PR**: #175
- **Version**: ace-support-nav 0.17.3
- **Commits**: 5 commits (implementation, version bump, CHANGELOG updates, test fix, task done)
- **Test Coverage**: 96 tests, 296 assertions (atoms + molecules + models + nav)
- **Review Result**: Approved as-is with 2 medium priority suggestions