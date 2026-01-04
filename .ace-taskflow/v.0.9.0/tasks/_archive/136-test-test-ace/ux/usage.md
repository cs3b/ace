# ace-test Package Argument Usage

## Overview

This feature enhances `ace-test` to allow running tests for any package in the mono-repo from any directory by specifying the package name or path as an argument.

## Command Types

### Bash CLI Commands

All commands are executed in a terminal using the `ace-test` command.

## Command Structure

```bash
ace-test [package] [target] [options] [files...]
```

Where:
- `package` - Optional package name or path (e.g., `ace-context`, `./ace-search`, `/full/path/to/ace-lint`)
- `target` - Optional test group target (e.g., `atoms`, `molecules`, `unit`, `all`)
- `options` - Standard ace-test options (e.g., `--profile`, `--fail-fast`)
- `files` - Specific test files relative to the package

## Usage Scenarios

### Scenario 1: Run all tests for a package by name

**Goal**: Run all tests in the `ace-context` package from the mono-repo root or any subdirectory.

```bash
# From mono-repo root
ace-test ace-context

# From any subdirectory (e.g., inside ace-search)
cd ace-search
ace-test ace-context
```

**Expected Output**:
```
Running tests in ace-context...
...

Finished in 1.234s
15 tests, 42 assertions, 0 failures, 0 errors, 0 skips
```

### Scenario 2: Run a specific test group for a package

**Goal**: Run only the atoms tests in the `ace-nav` package.

```bash
ace-test ace-nav atoms
```

**Expected Output**:
```
Running tests in ace-nav...
Group: atoms
...

Finished in 0.456s
5 tests, 12 assertions, 0 failures, 0 errors, 0 skips
```

### Scenario 3: Run tests with profiling enabled

**Goal**: Profile the slowest tests in `ace-taskflow`.

```bash
ace-test ace-taskflow --profile 10
```

**Expected Output**:
```
Running tests in ace-taskflow...
...

============================================================
Slowest Tests (Top 10)
============================================================
 1. test_complex_task_resolution                              0.234s
    test/organisms/task_resolver_test.rb:42
...
```

### Scenario 4: Use relative path to package

**Goal**: Run tests using a relative path when you know the exact location.

```bash
ace-test ./ace-search
ace-test ../ace-lint
```

### Scenario 5: Use absolute path to package

**Goal**: Run tests for a package using its absolute path.

```bash
ace-test /Users/mc/Ps/ace-meta/ace-docs
```

### Scenario 6: Run specific test file within a package

**Goal**: Run a specific test file in a package without navigating to it.

```bash
ace-test ace-nav test/atoms/protocol_parser_test.rb
```

### Scenario 7: Invalid package name handling

**Goal**: Understand error messages when package is not found.

```bash
ace-test nonexistent-package
```

**Expected Error**:
```
Error: Package not found: nonexistent-package
Available packages: ace-context, ace-core, ace-docs, ace-git, ...
Hint: Make sure you're in the ace-meta mono-repo or specify the full path.
```

### Scenario 8: Package without tests

**Goal**: Understand behavior when a package has no test directory.

```bash
ace-test ace-support-mac-clipboard
```

**Expected Error**:
```
Error: No test directory found in ace-support-mac-clipboard
Expected: ace-support-mac-clipboard/test/
```

## Command Reference

### Package Resolution

When a first argument is provided that is not a known target or existing file:

1. **By package name**: Searches for `ace-{name}` or `{name}` directories in mono-repo root
2. **By relative path**: Resolves `./path` or `../path` from current directory
3. **By absolute path**: Uses the path directly if it starts with `/`

### Test Execution

Once the package is resolved:
- Working directory is set to the package root
- Configuration is loaded from the package's `.ace/test/runner.yml`
- Test reports are saved to the package's `test-reports/` directory

### Internal Implementation

The package argument triggers:
1. Package resolution via `PackageResolver` atom
2. Directory change to package root
3. Standard test orchestration with package-local config

## Tips and Best Practices

1. **Use package names** for convenience: `ace-test ace-search` is shorter than `ace-test ./ace-search`
2. **Combine with targets**: `ace-test ace-lint atoms` runs only atoms tests
3. **Profile specific packages**: Use `--profile` to identify slow tests in a package
4. **Fail fast during development**: `ace-test ace-nav --fail-fast` stops on first failure

## Migration Notes

### Current Behavior (Before)

```bash
# Must navigate to package first
cd ace-context
ace-test

# Or run from mono-repo root with full path
ace-test ace-context/test/atoms/foo_test.rb
```

### New Behavior (After)

```bash
# Run from anywhere
ace-test ace-context

# Run with targets
ace-test ace-context atoms
```

### Key Differences

| Aspect | Before | After |
|--------|--------|-------|
| Working directory | Must be in package | Any directory |
| Package specification | Not supported | Package name or path |
| Config loading | Current directory | Package directory |
| Report location | Current directory | Package directory |
