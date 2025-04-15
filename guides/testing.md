# General Testing Guidelines

This document outlines general testing strategies and best practices. Project-specific configurations or conventions should be documented in `docs-dev/project/testing-guide.md` (if it exists).

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
    └── spec/  # Or 'tests/'
        ├── unit/
        │   └── my_module/
        │       └── my_class_spec.rb
        ├── integration/
        │   └── service_integration_spec.rb
        ├── e2e/
        │   └── user_workflow_spec.rb
        ├── performance/
        │   └── load_test.rb
        ├── fixtures/ # Test data files (e.g., YAML, JSON)
        ├── support/  # Test helpers, shared contexts, custom matchers
        │   └── helpers.rb
        └── spec_helper.rb # Or 'test_helper.rb' - Test configuration
    ```
    *(Refer to `docs-dev/project/blueprint.md` for the project's actual structure)*

3.  **Test Pyramid:** Aim for a healthy test pyramid: many fast unit tests at the base, fewer integration tests, and even fewer slow E2E tests at the top.

## 2. Writing Good Tests

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
- **Tools:** Use coverage tools (e.g., SimpleCov for Ruby) to identify untested code.
- **Review:** Analyze coverage reports to find gaps, but don't blindly chase 100%. Some code (e.g., simple getters/setters, third-party library wrappers) may not require dedicated tests. Set reasonable project coverage targets.

## 4. Mocking & Stubbing

- Use mocking/stubbing libraries (e.g., `rspec-mocks`, `WebMock`, `VCR` for Ruby) effectively.
- **Stubs:** Provide canned answers to method calls. Use when you need to control the return value of a dependency.
- **Mocks:** Set expectations on method calls (e.g., assert a method was called with specific arguments). Use sparingly, primarily when testing interactions/collaborations.
- **External Services:** Use libraries like `WebMock` or `VCR` to stub HTTP requests in unit/integration tests, making them faster and more reliable.

## 5. Test Data Management

- Use test data factories (e.g., `FactoryBot` for Ruby) or fixtures to create consistent and realistic test data.
- Use libraries like `Faker` to generate realistic-looking fake data.
- Store larger sets of test data in fixture files (e.g., YAML, JSON) within the test directory.

## 6. Running Tests

- Configure a default task to run the full suite (e.g., `bin/rspec`).
- Provide ways to run specific files or individual tests for faster feedback during development.
- Integrate tests into the CI/CD pipeline.

## 7. Performance & Thread Safety Testing (If Applicable)

- **Benchmarking:** Use benchmarking tools to measure the performance of critical code sections.
- **Load Testing:** Simulate concurrent users or operations to test system behavior under load.
- **Concurrency:** Write specific tests to verify thread safety if components are expected to be used concurrently (e.g., test shared resources under concurrent access using multiple threads).
