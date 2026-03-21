---
doc-type: guide
title: Testing Philosophy
purpose: Testing philosophy and pyramid structure
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Testing Philosophy

## The Testing Pyramid

ACE follows a strict testing pyramid with clear IO boundaries:

| Layer | Location | IO Policy | Purpose |
|-------|----------|-----------|---------|
| **Unit (atoms)** | `test/atoms/` | **No IO** | Test pure logic in isolation |
| **Unit (molecules)** | `test/molecules/` | **No IO** | Test component composition |
| **Unit (organisms)** | `test/organisms/` | **Mocked IO** | Test business logic with stubbed boundaries |
| **Integration** | `test/integration/` | **Mocked IO** | Test CLI/API surface with stubbed externals |
| **E2E** | `test/e2e/TS-*/scenario.yml` | **Real IO** | Validate the real system works |

## IO Isolation Principle

**Default: No IO in unit tests.** This means:

- **No file system**: Use `MockGitRepo` or inline strings, not `File.read`
- **No network**: Use `WebMock` stubs, not real HTTP calls
- **No subprocesses**: Use method stubs, not `Open3.capture3`
- **No sleep**: Stub `Kernel.sleep` in retry logic

**Why?**
- Tests run in parallel safely
- Tests are fast (<10ms for atoms)
- Tests are deterministic (no flaky failures)
- CI doesn't need special setup

## When Real IO is Allowed

Real IO belongs in **E2E tests only** (`test/e2e/TS-*/`):

- Executed by an agent, not the test runner
- Verify the full system works end-to-end
- Run infrequently (on-demand, not every commit)
- Document real tool requirements (standardrb, rubocop, etc.)

See `/ace-e2e-run` workflow for execution.

## Core Principles

### 1. Test-Driven Development

Writing tests first drives design and ensures testability. Follow the Red-Green-Refactor cycle:

1. **Red**: Write a failing test that defines the desired outcome
2. **Green**: Write the minimum code to make the test pass
3. **Refactor**: Improve code design while keeping tests green

### 2. Isolation

- Unit tests should mock dependencies to test the unit in isolation
- Ensure tests clean up after themselves (reset state, delete created files/records)
- Tests must be independent and runnable in any order

### 3. Determinism

- Avoid flaky tests (tests that pass sometimes and fail others without code changes)
- Address sources of flakiness (timing issues, race conditions, external dependencies)
- Tests should produce the same result every run

### 4. Clarity

- Use descriptive names for test files, contexts, and individual tests
- Follow the Arrange-Act-Assert pattern
- Keep tests focused on a single behavior or requirement

## Related Guides

- [Test Organization](guide://test-organization) - Directory structure and naming
- [Mocking Patterns](guide://mocking-patterns) - How to isolate tests
- [Testing TDD Cycle](guide://testing-tdd-cycle) - Implementing the task cycle