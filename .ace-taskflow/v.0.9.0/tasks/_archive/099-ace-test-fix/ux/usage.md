# ace-test Explicit File Execution - Usage Guide

## Overview

The `ace-test` command now correctly respects explicit file path arguments, allowing developers and AI agents to run focused tests on specific files rather than the entire test suite. This dramatically improves the feedback loop during development and debugging.

## Key Features

- **Single file execution**: Run tests from a specific file only
- **Line number filtering**: Run a specific test at a given line number
- **Multiple file execution**: Run tests from multiple specific files
- **Configuration override**: Explicit files always override group configurations
- **Clear output**: Shows exactly which files are being executed

## Command Types

### CLI Commands (bash/terminal)
These commands are executed directly in your terminal or by AI agents via the Bash tool.

## Command Structure

```bash
ace-test [options] [files...]
```

Where:
- `[options]` - Optional flags like `--verbose`, `--fail-fast`, etc.
- `[files...]` - One or more test file paths (absolute or relative)

## Usage Scenarios

### Scenario 1: Running a Single Test File
**Goal**: Execute tests from only one specific file for fast feedback during development.

```bash
# Run a specific atom test file
$ ace-test test/atoms/path_expander_test.rb
Running test/atoms/path_expander_test.rb...
✓ Complete (45.2ms, 12 tests, 0 failures)

# Run with verbose output for debugging
$ ace-test test/atoms/path_expander_test.rb --verbose
Running test/atoms/path_expander_test.rb...
Run options: --verbose

# test_expands_home_directory_correctly
Started with run options...
12 runs, 24 assertions, 0 failures, 0 errors, 0 skips
✓ Complete (48.1ms, 12 tests, 0 failures)
```

**Expected output**: Only the specified file is executed, not the entire test group.

### Scenario 2: Running a Test at a Specific Line
**Goal**: Execute only the test method at a specific line number for ultra-focused debugging.

```bash
# Run the test at line 42 of the file
$ ace-test test/atoms/path_expander_test.rb:42
Running test/atoms/path_expander_test.rb:42...
✓ Complete (8.1ms, 1 test, 0 failures)

# With fail-fast to stop immediately on failure
$ ace-test test/atoms/path_expander_test.rb:42 --fail-fast
Running test/atoms/path_expander_test.rb:42...
✓ Complete (7.9ms, 1 test, 0 failures)
```

**Expected output**: Only the single test method at that line is executed.

### Scenario 3: Running Multiple Specific Files
**Goal**: Execute tests from multiple files without running unrelated tests.

```bash
# Run two specific test files
$ ace-test test/atoms/path_expander_test.rb test/molecules/config_loader_test.rb
Running 2 files...
  test/atoms/path_expander_test.rb
  test/molecules/config_loader_test.rb
✓ Complete (67.3ms, 24 tests, 0 failures)

# Run multiple files with progress display
$ ace-test test/atoms/foo_test.rb test/atoms/bar_test.rb test/molecules/baz_test.rb --format progress
Running 3 files...
.............................
✓ Complete (102.5ms, 29 tests, 0 failures)
```

**Expected output**: Only the specified files are executed in the order provided.

### Scenario 4: Error Handling - File Not Found
**Goal**: Provide clear error messages when specified files don't exist.

```bash
# Attempt to run a non-existent file
$ ace-test test/atoms/nonexistent_test.rb
Error: File not found: test/atoms/nonexistent_test.rb

# Attempt with invalid line number
$ ace-test test/atoms/path_expander_test.rb:999
Running test/atoms/path_expander_test.rb:999...
No tests found at line 999
✓ Complete (5.2ms, 0 tests, 0 failures)
```

**Expected output**: Clear error message indicating the issue.

### Scenario 5: Mixed Arguments (Precedence)
**Goal**: Demonstrate that explicit files take precedence over group targets.

```bash
# File takes precedence over group
$ ace-test atoms test/molecules/config_loader_test.rb
Running test/molecules/config_loader_test.rb...
✓ Complete (31.2ms, 8 tests, 0 failures)
# Note: Only the explicit file runs, 'atoms' group is ignored

# Multiple files with group - files win
$ ace-test test/atoms/foo_test.rb unit test/molecules/bar_test.rb
Running 2 files...
  test/atoms/foo_test.rb
  test/molecules/bar_test.rb
✓ Complete (54.8ms, 16 tests, 0 failures)
# Note: 'unit' group is ignored, only specified files run
```

**Expected output**: Only explicit files are executed; groups are ignored.

### Scenario 6: Default Behavior (No Files Specified)
**Goal**: Show that normal group execution continues to work when no files are specified.

```bash
# Run default test groups (no change to existing behavior)
$ ace-test
Running smoke (2 files)...
✓ smoke complete (53.8ms, 6 tests, 0 failures)
Running atoms (12 files)...
✓ atoms complete (241.5ms, 48 tests, 0 failures)
Running molecules (8 files)...
✓ molecules complete (183.2ms, 32 tests, 0 failures)

# Run specific group (existing behavior preserved)
$ ace-test unit
Running unit tests...
  atoms (12 files)
  molecules (8 files)
  organisms (4 files)
✓ Complete (512.3ms, 96 tests, 0 failures)
```

**Expected output**: Normal group-based execution when no explicit files provided.

## Command Reference

### Basic Syntax
```bash
ace-test [file_path]                    # Run single file
ace-test [file_path:line_number]        # Run test at specific line
ace-test [file1] [file2] ...           # Run multiple files
```

### Parameters
- `file_path`: Path to test file (relative or absolute)
- `line_number`: Specific line number in the file (Minitest will find the test method)
- Multiple files can be specified separated by spaces

### Common Options
- `--verbose`: Show detailed test execution output
- `--fail-fast`: Stop on first test failure
- `--format progress`: Show progress dots during execution
- `--profile N`: Show N slowest tests after completion

### Internal Implementation
The fix modifies the `should_execute_sequentially?` method in `TestOrchestrator` to check for explicit files first, bypassing group execution when files are provided via the CLI.

## Tips and Best Practices

1. **Use relative paths**: Makes commands shorter and more portable
   ```bash
   ace-test test/atoms/foo_test.rb  # Good
   ace-test /Users/me/project/test/atoms/foo_test.rb  # Works but verbose
   ```

2. **Line numbers for focused debugging**: When a specific test fails, use line numbers
   ```bash
   ace-test test/atoms/validator_test.rb:58 --verbose
   ```

3. **Combine with --fail-fast**: Stop immediately on first failure for faster feedback
   ```bash
   ace-test test/atoms/*.rb --fail-fast
   ```

4. **Profile slow tests**: Identify performance bottlenecks
   ```bash
   ace-test test/integration/heavy_test.rb --profile 5
   ```

## Migration Notes

If you've been working around the bug by using other methods:

### Previous Workaround → New Command
```bash
# Old workaround (didn't work correctly)
$ cd test/atoms && ruby path_expander_test.rb

# New (works correctly)
$ ace-test test/atoms/path_expander_test.rb
```

### Key Differences
- No need to change directories
- Proper test runner configuration applied
- Reports saved in correct location
- Exit codes handled properly

## Troubleshooting

**Issue**: "File not found" error
- **Solution**: Check file path exists with `ls <file_path>`

**Issue**: "No tests found at line X"
- **Solution**: Verify a test method exists near that line number

**Issue**: Tests still running entire group
- **Solution**: Ensure you're using the updated ace-test-runner gem version

**Issue**: Different behavior between development and CI
- **Solution**: Explicit file paths ensure consistent behavior everywhere