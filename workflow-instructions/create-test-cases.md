# Create Test Cases Workflow Instruction

## Goal

Generate a structured list of test cases (unit, integration, performance, etc.) for a specific feature,
task, or code change based on requirements and project testing guidelines.

## Prerequisites

- A clear understanding of the feature/task requirements (e.g., from a task `.md` file, FRD, or PR
  description).
- Access to project testing guidelines (`dev-docs/guides/testing.md`).

## Process Steps

1. **Analyze Requirements:** Review the feature/task description, implementation notes, and acceptance criteria
   (likely found in a task `.md` file within `docs-project`).
2. **Identify Scenarios:** Brainstorm potential usage scenarios:
    - **Happy Path:** Standard, expected usage.
    - **Edge Cases:** Boundary conditions, unusual inputs, empty/null values.
    - **Error Conditions:** Invalid inputs, failures of dependencies, exception handling.
    - **Integration Points:** Interactions with other modules or external systems.
    - **Performance/Security (if applicable):** Scenarios related to load, concurrency, or potential
      vulnerabilities.
3. **Categorize Tests:** Group the identified scenarios into test types (Unit, Integration, E2E,
   Performance, Security) based on `docs-dev/guides/testing.md`.
4. **Draft Test Cases:** For each scenario, describe the test case including:
    - **Test ID/Name:** A unique identifier.
    - **Description:** What the test aims to verify.
    - **Prerequisites/Setup:** Any required initial state or data.
    - **Steps:** Actions to perform.
    - **Expected Result:** The anticipated outcome or verification point.
5. **Structure Output:** Format the test cases clearly, potentially using a table or list structure.
   Use the template `docs-dev/guides/prepare-release/v.x.x.x/test-cases/_template.md` as a reference
   for structure.
6. **Save (Optional):** Save the generated test cases to the appropriate location, often within the
   release directory (e.g., `docs-project/current/{release_dir}/test-cases/feature-x-tests.md`).

## Input

- Feature/task requirements (description, acceptance criteria).
- Optional: Specific code changes being tested.

## Output / Success Criteria

- A structured list of test cases covering the specified feature/task is generated.
- Test cases cover happy path, edge cases, and error conditions.
- Test cases are categorized appropriately (Unit, Integration, etc.).
- Each test case includes a description, steps, and expected results.
- Generated tests align with principles in `docs-dev/guides/testing.md`.

## Reference Documentation

- [Testing Guidelines Guide](docs-dev/guides/testing.md)
- [Test Cases Template](docs-dev/guides/prepare-release/v.x.x.x/test-cases/_template.md)
