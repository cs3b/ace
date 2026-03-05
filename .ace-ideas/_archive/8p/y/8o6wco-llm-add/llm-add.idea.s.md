---
title: Fix incorrect file path resolution and reporting in ace-test suite execution
filename_suggestion: fix-test-path-resolution
enhanced_at: 2026-01-07 21:34:05.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2026-01-07 22:51:52.000000000 +00:00
id: 8o6wco
tags: []
created_at: '2026-01-07 21:34:04'
---

# Fix incorrect file path resolution and reporting in ace-test suite execution

## Problem
The `ace-test` gem, or its underlying infrastructure in `ace-test-support`, suffers from a critical bug where test failure reports or discovery logs point to incorrect file paths. This usually occurs when the path resolution logic fails to account for the mono-repo structure, resulting in paths relative to an incorrect working directory or pointing to temporary runner files instead of the actual source file (e.g., `test/atoms/my_atom_test.rb`). This non-deterministic and inaccurate reporting severely hinders the ability of AI agents and human developers to quickly navigate to and fix test failures, breaking the core principle of reliable autonomous execution.

## Solution
Refactor the path resolution and reporting components within `ace-test` and `ace-test-support` to ensure all reported file paths are correctly normalized and relative to the ACE mono-repo root or the specific gem's root directory. This involves auditing the `Molecule` or `Atom` responsible for path handling during test execution and failure aggregation.

## Implementation Approach
1. **Identify the Component**: Locate the `Atom` or `Molecule` within `ace-test-support` responsible for normalizing file paths in test results (e.g., a `TestResultModel` constructor or a path utility). 
2. **Path Normalization**: Implement robust path normalization using Ruby's `Pathname` or similar utilities, ensuring paths are correctly resolved relative to the project root, regardless of whether the test is executed via `Rake` or the `bin/ace-test` binstub.
3. **Test Coverage**: Add specific integration tests to `ace-test-support` that simulate running tests from different directories and verify that the reported file paths in failure output are consistently correct.

## Considerations
- **Mono-Repo Context**: The fix must correctly handle paths when running tests across multiple gems from the root `Gemfile` environment.
- **CLI Output**: Ensure the fix maintains deterministic, parseable output for agents, allowing tools like `ace-nav` to correctly locate the failing file using the reported path.
- **Integration**: Verify that the updated path reporting integrates seamlessly with existing test runners (like MiniTest or RSpec if used) without introducing performance overhead.

## Benefits
- Restores deterministic and reliable error reporting for the ACE testing ecosystem.
- Significantly improves the debugging workflow for both human developers and AI agents.
- Ensures that `ace-nav` and context-loading tools can accurately locate source files referenced in test reports.

---

## Original Idea

```
ace-test-runner > ace-test-suite > point to wrong file (see screenshoots)
```

## Attached Files

- [clipboard-image-1.tiff](./clipboard-image-1.tiff)