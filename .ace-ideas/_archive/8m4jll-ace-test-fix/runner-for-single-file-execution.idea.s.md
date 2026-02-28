---
title: Fix ace-test Runner for Single File/Line Execution
filename_suggestion: fix-test-runner-file-filter
enhanced_at: 2025-11-05 13:04:48.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2025-11-05 13:10:32.000000000 +00:00
id: 8m4jll
tags: []
created_at: '2025-11-05 13:03:58'
---

# Fix ace-test Runner for Single File/Line Execution

## Problem
Currently, when `ace-test` is invoked with a specific test file path (e.g., `ace-test test/atoms/path_expander_test.rb`), the runner executes all configured test suites (e.g., 'smoke', 'atoms') instead of limiting execution to only the specified file. The provided example output clearly demonstrates this, showing 'Running smoke (2 files)...' and 'Running atoms (2 files)...' even when a single file from the 'atoms' group was targeted. This behavior leads to inefficient test cycles, slows down the feedback loop for developers and AI agents, and makes it difficult to focus on isolated test failures or new test development.

## Solution
Enhance the `ace-test` gem to accurately filter and execute only the tests contained within the specified file path, or even a specific line number or test method within that file. The runner should respect the provided CLI arguments for granular test selection, bypassing other test groups or files that are not explicitly targeted.

## Implementation Approach
This fix will primarily reside within the `ace-test` gem.

### ATOM Architecture Considerations:
- **Atoms**: Introduce new atoms for parsing CLI arguments related to test file paths, line numbers, or test method names. These atoms would be responsible for extracting precise filtering criteria.
- **Molecules**: A new molecule, e.g., `TestFilterBuilder`, would combine these parsing atoms to construct a robust filter object. This molecule would then interact with the underlying test framework (e.g., Minitest's runner) to apply the generated filters, ensuring only relevant tests are selected for execution.
- **Organisms**: The main `TestRunner` organism in `ace-test` would be updated to orchestrate the `TestFilterBuilder` molecule. It would receive the CLI arguments, apply the filters, and then initiate the test execution with the narrowed scope.

### CLI Interface Design:
- The `ace-test` CLI (`lib/ace/test/cli.rb`) will need to correctly parse arguments like `ace-test <file_path>`, `ace-test <file_path>:<line_number>`, or potentially `ace-test <file_path> --name <test_method_regex>`.
- The output should clearly indicate which specific tests or files are being run, confirming the applied filtering.

### Configuration:
- Review if any `.ace/test/config.yml` settings could influence or override this behavior, ensuring the CLI arguments take precedence for explicit filtering.

## Considerations
- **Integration with existing `ace-test` groups**: Ensure that explicit file/line filtering overrides any default test grouping or suite definitions.
- **Performance**: The filtering mechanism itself should be efficient and not introduce noticeable overhead.
- **Error Handling**: Provide clear error messages if a specified file, line, or test method cannot be found.
- **Deterministic Output**: The output should remain deterministic and parseable, indicating exactly which tests were executed based on the filter.

## Benefits
- **Faster Feedback Loop**: Significantly reduces test execution time during focused development or debugging, improving developer and agent efficiency.
- **Enhanced Developer Experience**: Allows developers and AI agents to quickly run and verify changes to specific components without running the entire test suite.
- **Improved AI Agent Workflow**: Enables AI agents to run highly targeted tests after making code modifications, leading to more precise validation and faster iteration cycles.
- **Aligned with ACE Principles**: Reinforces the ACE project's commitment to deterministic, focused, and efficient CLI tools.

---

## Original Idea

```
ace-test -> fix the one file runner, if we select single file or line of test we have to run all the tests without filters and groupping (not like in example when we pass single file and all the suite is running

ace-meta/ace-git-worktree on  main [!⇡] via 💎 v3.4.6
❯ ace-test test/atoms/path_expander_test.rb

Running smoke (2 files)...
......
✓ smoke complete (53.84ms, 6 tests, 0 failures)



Running atoms (2 files)...
✗ atoms complete (26.11ms, 48 tests, 5 failures)

Details: ./test-reports/20251105-130337/
❌ 54 tests, 113 assertions, 5 failures, 0 errors (79.96ms)

FAILURES (5):

STOPPED: Group 'atoms' failed (--fail-fast enabled)
```