---
id: 8o90e2
title: Dry-CLI Test Compatibility Fixes
type: conversation-analysis
tags: []
created_at: "2026-01-10 00:15:37"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8o90e2-dry-cli-test-compatibility-fixes.md
---
# Reflection: Dry-CLI Test Compatibility Fixes

**Date**: 2026-01-10
**Context**: Fixing CLI test failures across ace-prompt, ace-llm, ace-search, and ace-git-secrets packages after Thor to dry-cli migration
**Author**: Claude Agent
**Type**: Conversation Analysis | Self-Review

## What Went Well

- Systematic identification of root cause: dry-cli behavioral differences from Thor
- Pattern recognition across multiple packages with similar issues
- Shared helper fix in ace-support-test-helpers benefited multiple packages
- Tests now properly verify behavior via output instead of relying on exit codes

## What Could Be Improved

- Test assertions checking `CLI.start` return values should have been updated during the original Thor→dry-cli migration
- The `--help` flag causing `SystemExit` wasn't documented in migration guides
- Missing awareness that dry-cli outputs help to stderr, not stdout

## Key Learnings

- **dry-cli returns a `Set`, not exit codes**: `Dry::CLI.new(registry).call()` returns a Set object, not the command's return value. Tests expecting integer exit codes will fail.
- **dry-cli calls `exit(0)` for `--help`**: When `--help` is invoked, dry-cli calls `SystemExit` with status 0. Test helpers must catch this.
- **Help output goes to stderr**: dry-cli writes help/usage to stderr, not stdout. Tests checking output must combine `stdout + stderr`.
- **Known commands must be registered**: If a CLI has `--flag` as a command alias (like `--list-providers`), it must be in the `KNOWN_COMMANDS` set for routing to work correctly.

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Test Output Truncation**: Test runner output was getting truncated, making it difficult to see actual failure messages
  - Occurrences: Multiple times during debugging
  - Impact: Significant time spent running individual tests to see failures
  - Root Cause: ace-test wrapper has output buffering that doesn't play well with stuck tests

- **Incorrect Exit Code Assertions**: Tests asserting `assert_equal 0, result` failed with `#<Set: {}>`
  - Occurrences: 15+ tests across 4 packages
  - Impact: All command tests failing, blocking CI
  - Root Cause: Thor propagated exit codes, dry-cli does not

#### Medium Impact Issues

- **Help Goes to stderr**: Tests checking `stdout` for help output failed
  - Occurrences: 6 tests across 3 packages
  - Impact: Minor rework to use `stdout + stderr`
  - Root Cause: dry-cli uses stderr for help/usage messages

- **Missing Command Registration**: `--list-providers` not in `KNOWN_COMMANDS` caused routing issues
  - Occurrences: 1 instance in ace-llm
  - Impact: Command being treated as arg to default command
  - Root Cause: Incomplete registration during migration

#### Low Impact Issues

- **Test Helper Not Catching SystemExit**: Shared `invoke_cli` helper didn't handle exit calls
  - Occurrences: Multiple help tests hanging
  - Impact: Tests appearing to hang
  - Root Cause: dry-cli's `exit(0)` on help not anticipated

### Improvement Proposals

#### Process Improvements

- Add dry-cli behavior differences to migration documentation
- Create checklist for Thor→dry-cli migration covering: exit codes, help output location, SystemExit handling
- Include test verification step in migration process

#### Tool Enhancements

- Consider adding `--no-exit` option to ace-test for debugging stuck tests
- Add explicit dry-cli behavior notes to ace-support-test-helpers documentation
- Consider wrapper that captures exit codes for testing purposes

#### Communication Protocols

- Document dry-cli behavioral differences in package handbooks
- Create migration guide for future CLI framework changes

### Token Limit & Truncation Issues

- **Large Output Instances**: Test output frequently exceeded display limits
- **Truncation Impact**: Could not see full test failure messages
- **Mitigation Applied**: Ran individual tests with `-n test_name` to see full output
- **Prevention Strategy**: Use `bundle exec ruby -Ilib:test` directly for debugging, not ace-test

## Action Items

### Stop Doing

- Assuming CLI frameworks behave identically
- Checking exit codes directly when using dry-cli (it doesn't propagate them)

### Continue Doing

- Using shared test helpers (fix once, benefit everywhere)
- Running individual tests when debugging failures
- Checking both stdout and stderr for CLI output

### Start Doing

- Document CLI framework behavioral differences in migration guides
- Add SystemExit handling to all CLI test helpers by default
- Verify help output location (stdout vs stderr) when changing CLI frameworks

## Technical Details

**Key Pattern - SystemExit Handling in Test Helper:**
```ruby
def invoke_cli(cli_class, args)
  stdout, stderr = capture_io do
    begin
      @_cli_result = cli_class.start(args)
    rescue SystemExit => e
      @_cli_result = e.status
    end
  end
  { stdout: stdout, stderr: stderr, result: @_cli_result }
end
```

**Key Pattern - Checking Help Output:**
```ruby
def test_help_command
  result = invoke_cli(MyGem::CLI, ["--help"])
  # Help goes to stderr in dry-cli
  output = result[:stdout] + result[:stderr]
  assert_match(/Commands:/i, output)
end
```

## Additional Context

- PR #144: https://github.com/cs3b/ace-meta/pull/144
- Commits: `4dc4eec50`, `0196eadc7`
- Affected packages: ace-prompt, ace-llm, ace-search, ace-git-secrets, ace-support-test-helpers
