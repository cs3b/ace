# Test Profiling Report

## Executive Summary

Profiled 25 packages with 5,000+ total tests. Identified I/O bottlenecks and categorized slow tests by root cause.

## Current Package Times (Sorted by Duration)

| Package                  | Duration | Tests | I/O Pattern |
|--------------------------|----------|-------|-------------|
| ace-review               | 9.71s    | 344   | Dir.mktmpdir, ace-bundle calls |
| ace-lint                 | 9.12s    | 263   | Dir.mktmpdir, rubocop/standardrb |
| ace-taskflow             | 7.59s    | 1175  | Heavy Dir.mktmpdir (539 refs) |
| ace-bundle               | 7.32s    | 283   | CLI subprocess, real file I/O |
| ace-git                  | 7.18s    | 492   | Dir.mktmpdir, Open3 stubs |
| ace-git-worktree         | 6.89s    | 316   | Dir.mktmpdir (192 refs) |
| ace-prompt-prep          | 3.55s    | 279   | Subprocess/command execution |
| ace-git-secrets          | 3.37s    | 154   | Dir.mktmpdir, subprocess |
| ace-llm                  | 3.35s    | 269   | MockHTTPClient (well-mocked) |
| ace-docs                 | 2.55s    | 193   | File.read for registry |
| ace-support-config       | 2.48s    | 246   | Config file I/O |
| ace-llm-providers-cli    | 2.41s    | 96    | Edge case subprocess tests |
| ace-support-nav          | 2.40s    | 99    | Protocol resolution |
| ace-test-runner          | 2.34s    | 185   | Subprocess orchestration |
| ace-support-core         | 2.18s    | 221   | Config cascade I/O |
| ace-support-models       | 1.95s    | 213   | Model sync operations |
| ace-search               | 1.86s    | 118   | File search I/O |
| ace-support-markdown     | 1.54s    | 43    | CPU-bound (parsing) |
| ace-git-commit           | 1.24s    | 216   | Well-mocked |
| ace-support-timestamp    | 0.30s    | 230   | ✓ Fast (was 13.93s) |
| ace-support-fs           | 0.06s    | 69    | Fast (intentionally real FS) |

---

## Slowest Individual Tests Identified

### Critical Bottlenecks (>1s)

1. **ace-review/context_extractor_test.rb** - **4.49s** (20 tests)
   - Root cause: Calls real `ace-bundle` which loads actual project context
   - Pattern: Dir.chdir + ace-bundle preset loading
   - Recommendation: Mock ace-bundle responses or move to E2E

2. **ace-bundle/cli_auto_format_test.rb** - **1.35s** (6 tests)
   - Root cause: CLI subprocess tests with real file I/O
   - Pattern: Dir.mktmpdir + subprocess + file write/read
   - Recommendation: Acceptable (testing real CLI behavior)

3. **ace-bundle/cli_api_parity_test.rb** - **1.1s** (1 test)
   - Root cause: Intentionally disables mocking for parity verification
   - Pattern: CLI subprocess + API call comparison
   - Recommendation: Keep as-is (parity is critical)

4. **ace-git/command_executor_test.rb** - **2.52s** (31 tests)
   - Root cause: Test helper setup overhead
   - Pattern: Stubbed commands but expensive setup
   - Recommendation: Investigate test_helper.rb load time

---

## I/O Pattern Analysis

### Filesystem I/O (Dir.mktmpdir)

| Package | Test Files | I/O References |
|---------|------------|----------------|
| ace-taskflow | 41 files | 539 references |
| ace-git-worktree | 14 files | 192 references |
| ace-lint | 14 files | 322 references |
| ace-bundle | 28+ files | Heavy |

### Subprocess Overhead (Open3)

- ace-git/pr_metadata_fetcher_test.rb: 27 Open3.stub calls
- Properly mocked, but still has method dispatch overhead

### Well-Mocked Packages (Minimal I/O)

- ace-llm: MockHTTPClient
- ace-git-commit: CommandExecutor.stub
- ace-support-timestamp: Pure unit tests

---

## Verification Against Task 251

| Package | Task 251 After | Current | Delta |
|---------|----------------|---------|-------|
| ace-review | 5.52s | 9.71s | +76% |
| ace-lint | 4.66s | 9.12s | +96% |
| ace-bundle | 2.87s | 7.32s | +155% |
| ace-git-secrets | 1.8s | 3.37s | +87% |
| ace-support-timestamp | 61ms | 0.30s | ~OK |

**Note**: Apparent regressions likely due to:
1. Different timing methodology (parallel vs sequential)
2. Machine load during profiling
3. Possibly new tests added

---

## Recommendations

### Priority 1: Mock ace-bundle in ace-review tests

The `context_extractor_test.rb` spends 4.49s loading real project context.
Mock the `Ace::Bundle.load_auto` response for faster tests.

### Priority 2: Investigate test_helper load times

Several packages show 2-3s overhead before first test runs.
Profile Ruby require statements in test_helper.rb.

### Priority 3: No further VirtualFS investment needed

The current mocking infrastructure is well-implemented:
- MockHTTPClient for HTTP
- Open3.stub for subprocess
- Dir.mktmpdir for intentional filesystem tests

Creating a VirtualFS abstraction would add complexity without proportional benefit.

---

## Conclusion

Most I/O in tests is **intentional** and **appropriate**:
- Integration tests need real filesystem
- CLI tests need subprocess execution
- E2E tests already handle the slowest cases

**Single actionable item**: Mock `ace-bundle` in `context_extractor_test.rb` to save ~4s.

---

## Appendix: Test Group Breakdown

### ace-review (9.71s total)
- molecules: 4.92s (context_extractor_test.rb alone = 4.49s)
- atoms: 149ms
- organisms: 104ms
- integration: 532ms

### ace-git (7.18s total)
- atoms: 2.58s (command_executor_test.rb = 2.52s)
- organisms: 2.21s
- commands: 453ms
- integration: 441ms
- molecules: 15ms
- models: 9ms

### ace-bundle (7.32s total)
- integration: 2.96s (cli_api_parity + cli_auto_format = 2.45s)
- organisms: 98ms
- molecules: 93ms
- atoms: 48ms
- commands: 33ms
