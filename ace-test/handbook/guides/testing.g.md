---
doc-type: guide
title: Testing Guidelines
purpose: Testing guidelines overview
ace-docs:
  last-updated: 2026-02-24
  last-checked: 2026-03-21
---

# Testing Guidelines

## Goal

This guide defines the project's overall testing strategy, outlines best practices for writing effective
tests, and explains conventions for organizing and executing tests to ensure code quality and reliability.

This document outlines general testing strategies and best practices. Project-specific configurations or
conventions should be documented in `dev-taskflow/testing-guide.md` (if it exists).

## 1. Testing Strategy

1. **Public test categories:** ACE standardizes on three public categories:
    * **Fast:** isolated package tests under `test/fast/`; no real subprocess, network, or session IO.
    * **Feat:** deterministic feature tests under `test/feat/`; controlled local IO is allowed.
    * **E2E:** agent-driven workflows under `test/e2e/`; real sandboxed workflow validation.

2. **Directory Structure:** Organize tests around those three top-level folders.

    ```text
    project-root/
    └── test/
        ├── fast/
        │   ├── atoms/
        │   ├── molecules/
        │   ├── organisms/
        │   └── models/
        ├── feat/
        │   └── cli_contract_test.rb
        ├── e2e/
        │   └── TS-PACKAGE-001-scenario/
        │       └── scenario.yml
        ├── fixtures/
        ├── support/
        └── test_helper.rb
    ```

3. **Test Pyramid:** Aim for many `fast` tests, fewer `feat` tests, and the smallest number of `e2e` scenarios.

## 2. Writing Good Tests

### Designing for Testability (Especially with AI)

Writing testable code is even more important when using AI, as it simplifies verification and makes it
easier to guide the AI effectively.

* **Explicit Dependencies:** Pass dependencies (services, configurations, clients) into functions or
  classes rather than relying on global state or singletons. This makes mocking easier for unit tests.
* **Pure Functions:** Prefer functions that always return the same output for the same input and have
  no side effects. These are the easiest to test.
* **Separate Logic from I/O:** Isolate core business logic from operations that interact with external
  systems (files, network, databases). Test the logic separately from the I/O.
* **Clear Interfaces:** Define clear, well-documented public interfaces for modules and classes. This
  clarifies boundaries for testing and for AI interaction.
* **Stateless Components:** Where possible, favor stateless components or functions, as state
  management adds complexity to testing.

Following these principles makes it easier to write focused fast tests and provide clearer instructions
to an AI agent when generating or modifying code.

1. **Clarity:**
    * Use descriptive names for test files, contexts/describe blocks, and individual tests (`it "should..."`).
    * Follow the Arrange-Act-Assert (or Given-When-Then) pattern.
    * Keep tests focused on a single behavior or requirement.

2. **Isolation:**
    * Fast tests should mock or fake dependencies and stay in-process.
    * Feat tests may use controlled local IO when that is the behavior under test.
    * Ensure tests clean up after themselves (reset state, delete created files/records) to avoid
      interference. Use `before`/`after` hooks carefully.

3. **Reliability:**
    * Avoid flaky tests (tests that pass sometimes and fail others without code changes). Address
      sources of flakiness (e.g., timing issues, race conditions, reliance on unstable external
      factors).
    * Tests should be deterministic.

4. **Maintainability:**
    * Use test helpers, factories, or shared contexts to reduce duplication (DRY).
    * Keep tests updated as the code evolves. Delete tests for removed code.
    * Refactor tests just like production code.

## 3. Test Coverage

* **Goal:** Aim for meaningful coverage, not just high percentages. Ensure critical paths, complex
  logic, edge cases, and error handling are tested.
* **Tools:** Use code coverage tools suitable for your language/framework (e.g., SimpleCov for Ruby,
  `bun test --coverage` for Bun/TS) to identify untested code.
* **Review:** Analyze coverage reports to find gaps, but don't blindly chase 100%. Some code (e.g.,
  simple getters/setters, third-party library wrappers) may not require dedicated tests. Set
  reasonable project coverage targets.

## 4. Mocking & Stubbing

* Use mocking/stubbing libraries appropriate for your stack (e.g., `rspec-mocks`, `jest.fn()`) effectively.
* **Stubs:** Provide canned answers to method calls. Use when you need to control the return value of
  a dependency.
* **Mocks:** Set expectations on method calls (e.g., assert a method was called with specific
  arguments). Use sparingly, primarily when testing interactions/collaborations.
* **External Services:** Use relevant libraries (e.g., `WebMock`+`VCR` for Ruby HTTP requests, `msw`
  for JS) to stub external interactions in unit/integration tests, making them faster and more
  reliable.

## 5. Test Data Management

* Use test data factories (e.g., `FactoryBot` for Ruby, fixture libraries in other languages) or
  simple fixtures to create consistent and realistic test data.
* Use data generation libraries (e.g., `Faker`) to generate realistic-looking fake data.
* Store larger sets of test data in fixture files (e.g., YAML, JSON) within the test directory (e.g.,
  `tests/fixtures/`).

## 6. Running Tests

* To run the full suite use `bin/test`.
* Provide ways to run specific files or individual tests for faster feedback during development.
* Integrate tests into the CI/CD pipeline.

## 7. Performance & Thread Safety Testing (If Applicable)

* **Benchmarking:** Use benchmarking tools to measure the performance of critical code sections.
* **Load Testing:** Simulate concurrent users or operations to test system behavior under load.
* **Concurrency:** Write specific tests to verify thread safety if components are expected to be used
  concurrently (e.g., test shared resources under concurrent access using multiple threads).

## 8. Test Performance Optimization

For detailed patterns on test performance optimization including:
- Performance targets by test layer (Fast <10ms for atoms, Feat <500ms when practical, E2E slower by design)
- Composite test helpers (reduce deep nesting)
- E2E to feat migration when deterministic coverage is possible
- Subprocess stubbing patterns (Open3, DiffOrchestrator)
- Sleep stubbing for retry tests
- Zombie mocks detection and prevention

See: [Test Performance Guide](guide://test-performance)

## Related Documentation

* Technology-Specific Guides:
  * [Ruby (RSpec) Testing Guide](./testing/ruby-rspec.md)
  * [Ruby (RSpec) Configuration Examples](./testing/ruby-rspec-config-examples.md)
  * [Rust Testing Guide](./testing/rust.md)
  * [TypeScript (Bun) Testing Guide](./testing/typescript-bun.md)
* [Coding Standards Guide](guide://coding-standards.g)
* [Quality Assurance Guide](guide://quality-assurance.g) (Test Coverage, CI)
* [Performance Tuning Guide](guide://performance.g) (Performance Testing)

* [Troubleshooting Workflow](guide://debug-troubleshooting.g)
* Relevant Workflow Instructions: [`work-on-task.wf.md`](wfi://task/work) (includes testing
  guidance), [`analyze-failures.wf.md`](wfi://test/analyze-failures) (for classifying failing tests before changes), [`fix-tests.wf.md`](wfi://test/fix) (for applying fixes using analysis output)
