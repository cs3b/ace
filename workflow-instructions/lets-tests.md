# Let's Test Workflow Instruction

**Context:** This instruction details the "Test" phase of the overall development workflow described in the **[Implementing the Task Cycle Guide](../guides/task-cycle.md)**.

## Goal
Guide the developer through writing and running automated tests (unit, integration) following Test-Driven Development (TDD) principles.

## Prerequisites
- A specific feature or piece of functionality requires testing (often defined in a task `.md` file after completing the [Work on Task](./work-on-task.md) instruction).
- Development environment is set up with the testing framework configured.
- Understanding of the project's testing guidelines and conventions, including technology-specific details found in the **[Implementing the Task Cycle Guide](../guides/task-cycle.md)** sub-sections.

## Input
- Feature/task requirements and acceptance criteria (from the task `.md` file).
- Optional: Existing code that needs tests.

## Process Steps

1.  **Review Task & Plan Tests**:
    *   Revisit the selected task's `.md` file (`docs-project/current/{release_dir}/tasks/NN-*.md`).
    *   Focus on the `## Acceptance Criteria / Test Strategy` section.
    *   Plan specific tests covering:
        *   Core functionality (happy paths)
        *   Edge cases and known boundary conditions
        *   Error handling and expected failures
        *   Integration points (if applicable)

2.  **Write Failing Test First**:
    *   Create a new test file or locate the relevant existing one, following project conventions (e.g., naming, location).
    *   Write the simplest possible test case for a small piece of the required functionality according to your plan.
    *   **Ensure the test fails** for the *expected reason*. Run the test suite using the appropriate command for your project's tech stack.
        *   *(Example Action: `Execute test runner command`)*
        *   *(Refer to the technology-specific sub-guide in [Implementing the Task Cycle](../guides/task-cycle.md) for exact commands if unsure.)*

3.  **Write Code to Pass Test**:
    *   Write the minimum amount of application code necessary to make the failing test pass.
    *   Focus *only* on passing the current test; avoid adding extra functionality.

4.  **Run Tests & Verify**:
    *   Run the test suite again.
        *   *(Example Action: `Execute test runner command`)*
    *   Verify that the new test passes and no existing tests have broken.

5.  **Refactor (Optional but Recommended)**:
    *   With the safety net of passing tests, look for opportunities to improve the code you just wrote *and* the test code.
    *   Examples: Improve clarity, remove duplication, adhere to coding standards.
    *   Run tests again after refactoring to ensure nothing was broken.

6.  **Repeat:**
    *   Repeat steps 2-5 for the next piece of functionality identified in your test plan until all acceptance criteria are met by passing tests.

## Output / Success Criteria

*   A suite of automated tests exists for the implemented feature/fix.
*   All tests related to the completed functionality are passing.
*   The developer is ready to proceed to the "Commit" phase, detailed in the [Let's Commit](./lets-commit.md) instruction.

## Reference Documentation

*   **[Implementing the Task Cycle Guide](../guides/task-cycle.md)** (Overall workflow)
*   [Quality Assurance Guide](../guides/quality-assurance.md) (General testing principles)
*   Technology-specific sub-guides under `../guides/task-cycle/` (For specific commands and framework details)
