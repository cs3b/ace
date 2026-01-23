# ace-test Package Usage Guide

## Overview

The `ace-test` package consolidates testing knowledge into a single, discoverable location. It provides:

- **Guides**: Testing philosophy, patterns, and best practices (6 core guides + technology-specific)
- **Workflow Instructions**: `create-test-cases` and `fix-tests` workflows
- **Agents**: `test`, `mock`, and `profile-tests` for AI-assisted testing
- **Templates**: Test case templates

This is a **pure workflow package** (like ace-handbook) - no CLI binary, only handbook content.

## Protocol Discovery

### Discovering Testing Guides

```bash
# List all testing guides
ace-nav guide:// | grep testing

# Expected output:
# guide://testing-philosophy
# guide://test-organization
# guide://mocking-patterns
# guide://test-performance
# guide://testable-code-patterns
# guide://testing-tdd-cycle
# guide://embedded-testing-guide
# guide://quick-reference
# guide://testing
```

### Loading a Specific Guide

```bash
# Load testing philosophy guide into context
ace-bundle guide://testing-philosophy

# Load mocking patterns for reference
ace-bundle guide://mocking-patterns
```

### Discovering Testing Workflows

```bash
# List testing workflows
ace-nav wfi:// | grep test

# Expected output:
# wfi://create-test-cases
# wfi://fix-tests
```

### Discovering Testing Agents

```bash
# List testing agents
ace-nav agent:// | grep test

# Expected output:
# agent://test
# agent://mock
# agent://profile-tests
```

## Usage Scenarios

### Scenario 1: Creating Test Cases for a New Feature

**Goal**: Generate structured test cases for a feature implementation.

**Steps**:

```bash
# In Claude Code conversation
/ace:create-test-cases

# Agent will:
# 1. Analyze the feature requirements
# 2. Identify testable components
# 3. Generate test case matrix (unit, integration, e2e)
# 4. Save test cases to task directory
```

**Expected Output**: Test case file in `.ace-taskflow/v.X.X/tasks/<task>/test-cases.md`

### Scenario 2: Fixing Failing Tests

**Goal**: Systematically diagnose and fix test failures.

**Steps**:

```bash
# In Claude Code conversation
/ace:fix-tests

# Agent will:
# 1. Run the test suite to identify failures
# 2. Analyze failure patterns
# 3. Apply fixes based on testing-patterns guides
# 4. Verify fixes
```

### Scenario 3: Profiling Slow Tests

**Goal**: Identify and optimize slow tests.

**Steps**:

```bash
# In Claude Code conversation (using profile-tests agent)
/ace:profile-tests

# Or via CLI
ace-test --profile 10

# Agent will:
# 1. Run tests with profiling
# 2. Identify slowest tests
# 3. Reference test-performance.g.md patterns
# 4. Suggest optimizations
```

### Scenario 4: Learning Testing Best Practices

**Goal**: Understand ACE testing patterns before writing tests.

**Steps**:

```bash
# Load the quick reference
ace-bundle guide://quick-reference

# For detailed philosophy
ace-bundle guide://testing-philosophy

# For mocking patterns (most common need)
ace-bundle guide://mocking-patterns
```

### Scenario 5: Technology-Specific Testing

**Goal**: Get testing setup for a specific technology stack.

**Steps**:

```bash
# For Ruby with RSpec
ace-bundle guide://testing/ruby-rspec

# For TypeScript with Bun
ace-bundle guide://testing/typescript-bun

# For Vue with Vitest
ace-bundle guide://testing/vue-vitest

# For Rust
ace-bundle guide://testing/rust
```

## Guide Reference

### Core Guides (from testing-patterns.md)

| Guide | Purpose | Key Topics |
|-------|---------|------------|
| `quick-reference.g.md` | TL;DR | Command reference, essential patterns |
| `testing-philosophy.g.md` | Philosophy | Testing pyramid, IO isolation principle |
| `test-organization.g.md` | Structure | Flat directory structure, naming conventions |
| `mocking-patterns.g.md` | Mocking | Git, HTTP, subprocess, ENV patterns |
| `test-performance.g.md` | Performance | Targets, zombie mocks, optimization |
| `testable-code-patterns.g.md` | Code Design | Status codes, exceptions, exit handling |

### Additional Guides (from other packages)

| Guide | Origin | Purpose |
|-------|--------|---------|
| `testing-tdd-cycle.g.md` | ace-test-runner | Red-Green-Refactor cycle |
| `embedded-testing-guide.g.md` | ace-docs | AI workflow testing |
| `testing.g.md` | ace-test-runner | General testing overview |

### Technology-Specific Guides

Located in `handbook/guides/testing/`:

- `ruby-rspec.md` - RSpec configuration and patterns
- `ruby-rspec-config-examples.md` - Detailed RSpec config
- `typescript-bun.md` - Bun test runner
- `vue-vitest.md` - Vue.js with Vitest
- `vue-firebase-auth.md` - Firebase auth testing
- `rust.md` - Rust testing patterns
- `test-maintenance.md` - Keeping tests healthy

## Workflow Commands

### Claude Code Commands (Chat)

| Command | Description |
|---------|-------------|
| `/ace:create-test-cases` | Generate test cases for a feature |
| `/ace:fix-tests` | Diagnose and fix failing tests |

### CLI Commands (Terminal)

| Command | Description |
|---------|-------------|
| `ace-test` | Run tests (from ace-test-runner) |
| `ace-test --profile 10` | Profile slowest 10 tests |
| `ace-test atoms` | Run atom tests only |

## Tips and Best Practices

### Test Organization
- Use flat structure: `test/atoms/`, `test/molecules/`
- Suffix files with `_test.rb`, not `test_*.rb`
- Mirror ATOM architecture layers

### Performance
- Target <10ms for atom tests
- Target <50ms for molecule tests
- Use MockGitRepo instead of real git init (~150ms savings)
- Stub `Kernel.sleep` in retry tests

### Mocking Strategy
- Stub at the boundary closest to your test subject
- Use `with_empty_git_diff` for git-dependent tests
- Use WebMock for HTTP API calls
- Watch for "zombie mocks" - stubs that don't match code paths

### Common Pitfalls
- Avoid subprocess spawning in unit tests
- Never call `exit` in testable code - return status codes
- Don't nest stubs deeply - use composite helpers

## Migration Notes

### Before (scattered docs)
```
docs/testing-patterns.md          # 1104 lines in bundle
ace-taskflow/...create-test-cases # Workflow in wrong package
ace-taskflow/...fix-tests         # Workflow in wrong package
ace-test-runner/guides/testing/*  # Guides in runner package
ace-docs/guides/embedded-testing* # Guide in docs package
```

### After (consolidated)
```
ace-test/handbook/
├── guides/                      # All testing guides
├── workflow-instructions/       # Both testing workflows
└── agents/                      # All testing agents
```

### Key Differences
- Single source of truth for testing knowledge
- Bundle size reduced from 2137 to ~1100 lines
- Protocol discovery for all testing resources
- Clear package ownership (ace-test owns testing, ace-test-runner owns CLI)
