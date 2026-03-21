---
doc-type: guide
title: "Testing Strategy: The Fast and Slow Loops"
purpose: Define the ACE testing strategy with fast loop (unit/integration) and slow loop (E2E)
ace-docs:
  last-updated: 2026-02-19
  last-checked: 2026-03-21
---

# Testing Strategy: The Fast and Slow Loops

This guide defines the ACE strategy for maintaining a high-performance, high-confidence test suite. We divide testing into two distinct loops: the **Fast Loop** (immediate feedback) and the **Slow Loop** (comprehensive validation).

## Core Philosophy

1.  **Fast Loop must be FAST (< 10s total)**: If unit tests are slow, developers stop running them.
2.  **Slow Loop must be SAFE**: E2E tests run real commands and modify state; they must be sandboxed.
3.  **Stub the Boundary**: Never let a unit test leak a subprocess call or file I/O.
4.  **Test Behavior, Not Mocks**: Verify the *outcome* of logic, not just that a method was called.

## The Test Pyramid

| Layer | Scope | Target Speed | I/O | Strategy |
|-------|-------|--------------|-----|----------|
| **Unit** (Atoms) | Single Method/Class | < 10ms / test | **Forbidden** | Pure functions. Mock *all* collaborators. |
| **Integration** (Molecules) | Component Interaction | < 100ms / test | **Stubbed** | Test wiring. Stub APIs/Shell/FS. |
| **E2E** (Systems) | Full Workflow | Seconds/Minutes | **Real** | Real CLI execution. Sandboxed FS. |

> **Note**: Target speeds are ideal goals. The `verify-test-suite` workflow uses relaxed thresholds for warnings (atoms >50ms, molecules >100ms) to catch tests drifting toward I/O leaks before they become critical.

---

## 1. The Fast Loop (Unit & Integration)

**Goal**: Validate logic correctness instantly.

### Rules of Engagement
-   **No Subprocesses**: Never call `system`, `Open3`, or backticks.
-   **No Network**: Never make HTTP requests.
-   **In-Memory FS**: Use `FakeFS` or temporary directories only if absolutely necessary (prefer mocking `File`).

### Effective Mocking: "Stub the Boundary"
Don't just stub the inner implementation; stub the *check* that leads to it.

**Bad** (Still triggers subprocess):
```ruby
# The code checks `if runner.available?` before calling `run`
Runner.stub(:run, result) do
  # Code calls `available?` -> triggers `system("cmd --version")` -> SLOW!
  subject.process
end
```

**Good** (Fast):
```ruby
Runner.stub(:available?, true) do # Bypass the check
  Runner.stub(:run, result) do    # Return canned result
    subject.process
  end
end
```

### Avoiding "Testing the Mock"
-   **Stub for Data**: When you need a value to proceed (e.g., configuration, file content), use stubs.
-   **Mock for Side Effects**: Only use `Minitest::Mock` (expectations) when the *purpose* of the method is the side effect (e.g., `Git.commit`).
-   **Don't over-specify**: If your test breaks every time you rename a private helper, you are testing implementation, not behavior.

### Maintainable Stubbing (Composite Helpers)
Avoid deeply nested stub blocks. Use composite helpers to wrap common environmental setups.

**Bad (Deep Nesting):**
```ruby
def test_workflow
  mock_config do
    mock_git do
      mock_llm do
        # Actual test code is buried
      end
    end
  end
end
```

**Good (Composite Helper):**
```ruby
def test_workflow
  with_mock_environment(git: true, llm: true) do
    # Clear test focus
  end
end
```

### Mock Hygiene (Avoiding Drift)
Mocks simulate reality, but reality changes.
-   **Rule**: Whenever you change behavior covered by an E2E test (reality), you MUST verify and update the corresponding Unit Test mocks (simulation).
-   **Risk**: "Mock Drift" leads to green unit tests that fail in production.

---

## 2. The Slow Loop (E2E)

**Goal**: Validate system coherence and real-world functionality.

### Rules of Engagement
-   **Real Binaries**: Execute the actual `ace-*` CLI tools.
-   **Sandboxing**: Run in a temporary directory. Clean up after yourself.
-   **Critical Paths**: Focus on happy paths and critical error cases. Don't test every edge case (leave that to unit tests).

### E2E Test Structure (TS-format)
We use directory-based test scenarios with `scenario.yml` and `TC-*.tc.md` files for E2E to ensure they double as documentation.

```
TS-FEATURE-001-task-creation/
    scenario.yml          # Metadata + setup
    TC-001-create.tc.md   # Test case with steps + assertions
    fixtures/             # Shared test data
```

---

## 3. The "Test Planner" & "Test Writer" Roles

When creating tests, separate the concerns:

### 🎩 The Test Planner
Decides **WHAT** and **WHERE** to test.
-   *"This logic handles a git conflict. It's complex logic -> **Unit Test** with mocked git output."*
-   *"This command wires up the search tool to the LLM. -> **Integration Test** with stubbed LLM."*
-   *"This workflow creates a PR and comments on it. -> **E2E Test**."*

### ✍️ The Test Writer
Implements the test efficiently.
-   Uses `ace-test --profile` to ensure speed.
-   Writes proper setup/teardown.
-   Ensures assertions are meaningful.

---

## 4. Maintenance & Profiling

### The 100ms Rule
Any unit/integration test taking > 100ms is a bug.
-   **Cause**: Likely a hidden I/O call (subprocess, file system).
-   **Fix**: Profile, find the leak, and **Stub the Boundary**.

### Periodic Verification
Run the suite with profiling regularly:
```bash
ace-test --profile 10
```
If "fast" tests appear in the top 10 slow list, investigate immediately.