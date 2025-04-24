# Testing Guidelines

## Goal
This guide defines the project's overall testing strategy, outlines best practices for writing effective tests, and explains conventions for organizing and executing tests to ensure code quality and reliability.

# Testing Guidelines

This document outlines general testing strategies and best practices. Project-specific configurations or conventions should be documented in `docs-project/testing-guide.md` (if it exists).

## 1. Testing Strategy

1.  **Test Types:** Employ a mix of test types appropriate for the project:
    *   **Unit Tests:** Test individual classes or methods in isolation. Mock dependencies. Focus on logic correctness.
    *   **Integration Tests:** Test the interaction between two or more components (e.g., class and its dependency, module interactions, API client and service). May involve partial mocking or real dependencies in controlled environments.
    *   **End-to-End (E2E) / System Tests:** Test complete user flows or system functionalities, often interacting with real external dependencies or a fully deployed environment. These are typically slower and less frequent.
    *   **Performance Tests:** Measure response time, throughput, resource usage under specific conditions or load.
    *   **Security Tests:** Identify vulnerabilities (e.g., penetration testing, dependency scanning).

2.  **Directory Structure:** Organize tests logically, typically mirroring the source code structure.
    *(Example structure - adjust based on project)*
    ```
    project-root/
    └── tests/  # Or 'spec/'
        ├── unit/
        │   └── my_module/
        │       └── my_class_tests.ext # Use appropriate extension
        ├── integration/
        │   └── service_integration_tests.ext
        ├── e2e/
        │   └── user_workflow_tests.ext
        ├── performance/
        │   └── load_test.ext
        ├── fixtures/ # Test data files (e.g., YAML, JSON)
        ├── support/  # Test helpers, shared contexts, custom matchers
        │   └── helpers.ext
        └── test_helper.ext # Or 'spec_helper.ext' - Test configuration
    ```
    *(Refer to `docs-project/blueprint.md` for the project's actual structure)*

3.  **Test Pyramid:** Aim for a healthy test pyramid: many fast unit tests at the base, fewer integration tests, and even fewer slow E2E tests at the top.

## 2. Writing Good Tests
### Designing for Testability (Especially with AI)

Writing testable code is even more important when using AI, as it simplifies verification and makes it easier to guide the AI effectively.

- **Explicit Dependencies:** Pass dependencies (services, configurations, clients) into functions or classes rather than relying on global state or singletons. This makes mocking easier for unit tests.
- **Pure Functions:** Prefer functions that always return the same output for the same input and have no side effects. These are the easiest to test.
- **Separate Logic from I/O:** Isolate core business logic from operations that interact with external systems (files, network, databases). Test the logic separately from the I/O.
- **Clear Interfaces:** Define clear, well-documented public interfaces for modules and classes. This clarifies boundaries for testing and for AI interaction.
- **Stateless Components:** Where possible, favor stateless components or functions, as state management adds complexity to testing.

Following these principles makes it easier to write focused unit tests and provide clearer instructions to an AI agent when generating or modifying code.

1.  **Clarity:**
    *   Use descriptive names for test files, contexts/describe blocks, and individual tests (`it "should..."`).
    *   Follow the Arrange-Act-Assert (or Given-When-Then) pattern.
    *   Keep tests focused on a single behavior or requirement.

2.  **Isolation:**
    *   Unit tests should mock dependencies to test the unit in isolation.
    *   Ensure tests clean up after themselves (reset state, delete created files/records) to avoid interference. Use `before`/`after` hooks carefully.

3.  **Reliability:**
    *   Avoid flaky tests (tests that pass sometimes and fail others without code changes). Address sources of flakiness (e.g., timing issues, race conditions, reliance on unstable external factors).
    *   Tests should be deterministic.

4.  **Maintainability:**
    *   Use test helpers, factories, or shared contexts to reduce duplication (DRY).
    *   Keep tests updated as the code evolves. Delete tests for removed code.
    *   Refactor tests just like production code.

## 3. Test Coverage

- **Goal:** Aim for meaningful coverage, not just high percentages. Ensure critical paths, complex logic, edge cases, and error handling are tested.
- **Tools:** Use code coverage tools suitable for your language/framework (e.g., SimpleCov for Ruby, `bun test --coverage` for Bun/TS) to identify untested code.
- **Review:** Analyze coverage reports to find gaps, but don't blindly chase 100%. Some code (e.g., simple getters/setters, third-party library wrappers) may not require dedicated tests. Set reasonable project coverage targets.

## 4. Mocking & Stubbing

- Use mocking/stubbing libraries appropriate for your stack (e.g., `rspec-mocks`, `jest.fn()`) effectively.
- **Stubs:** Provide canned answers to method calls. Use when you need to control the return value of a dependency.
- **Mocks:** Set expectations on method calls (e.g., assert a method was called with specific arguments). Use sparingly, primarily when testing interactions/collaborations.
- **External Services:** Use relevant libraries (e.g., `WebMock`+`VCR` for Ruby HTTP requests, `msw` for JS) to stub external interactions in unit/integration tests, making them faster and more reliable.

## 5. Test Data Management

- Use test data factories (e.g., `FactoryBot` for Ruby, fixture libraries in other languages) or simple fixtures to create consistent and realistic test data.
- Use data generation libraries (e.g., `Faker`) to generate realistic-looking fake data.
- Store larger sets of test data in fixture files (e.g., YAML, JSON) within the test directory (e.g., `tests/fixtures/`).

## 6. Running Tests

- Configure a default task to run the full suite (e.g., `bundle exec rspec`, `npm test`, `cargo test`, `bun test`).
- Provide ways to run specific files or individual tests for faster feedback during development.
- Integrate tests into the CI/CD pipeline.

## 7. Performance & Thread Safety Testing (If Applicable)

- **Benchmarking:** Use benchmarking tools to measure the performance of critical code sections.
- **Load Testing:** Simulate concurrent users or operations to test system behavior under load.
- **Concurrency:** Write specific tests to verify thread safety if components are expected to be used concurrently (e.g., test shared resources under concurrent access using multiple threads).

## Related Documentation
- [Testing Framework Configuration Examples](docs-dev/guides/testing/ruby-rspec-config-examples.md) (Setup details for specific stacks)
- [Coding Standards Guide](docs-dev/guides/coding-standards.md)
- [Quality Assurance Guide](docs-dev/guides/quality-assurance.md) (Test Coverage, CI)
- [Performance Tuning Guide](docs-dev/guides/performance.md) (Performance Testing)
- [Writing Guides Guide](docs-dev/guides/writing-guides-guide.md)
- [Troubleshooting Workflow](docs-dev/guides/troubleshooting-workflow.md)
- Relevant Workflow Instructions: `docs-dev/workflow-instructions/lets-tests.md`, `docs-dev/workflow-instructions/lets-fix-tests.md`
