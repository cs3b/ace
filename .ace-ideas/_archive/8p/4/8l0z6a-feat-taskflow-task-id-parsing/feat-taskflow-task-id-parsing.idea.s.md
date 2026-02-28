---
status: done
completed_at: 2025-10-15 01:08:11.000000000 +01:00
id: 8l0z6a
title: Idea
tags: []
created_at: '2025-10-01 23:26:58'
---

# Idea

---
title: Enhance ace-taskflow to support 'v.X.Y.Z+task.NNN' as a valid task ID format
filename_suggestion: feat-taskflow-task-id-parsing
enhanced_at: 2025-10-02 00:27:25
location: active
llm_model: gflash
---

## Problem
The `ace-taskflow` gem currently supports various task ID formats like `018`, `task.018`, `v.0.9.0+task.018`, and `backlog+task.025`. However, it explicitly fails to parse task IDs that combine a version prefix with the `task.` keyword, such as `v.0.9.0+task.060`. This inconsistency in parsing limits user flexibility and deviates from an intuitive understanding of how versioned task identifiers might be constructed, even though `v.0.9.0+task.060` and `task.060` are individually recognized.

## Solution
Implement an enhancement to the `ace-taskflow` gem's task identifier parsing logic to correctly recognize and resolve task IDs formatted as `v.X.Y.Z+task.NNN`. This will involve updating the internal mechanisms responsible for extracting the version and task number from the provided string, ensuring that the explicit `task.` keyword is handled correctly when combined with a version prefix.

## Implementation Approach
1.  **Identify Parsing Logic:** Locate the relevant code within `ace-taskflow/lib/ace/taskflow/` that is responsible for parsing task identifiers. This is likely within an `atoms/` module (e.g., `task_id_parser.rb`) or a `models/` module (e.g., `task_id.rb`) that encapsulates the task ID structure and parsing.
2.  **Update Regular Expressions/Parsing Algorithm:** Modify the existing regular expressions or parsing functions to accommodate the `v.X.Y.Z+task.NNN` pattern. The logic should be able to extract the version (e.g., `v.0.9.0`) and the task number (e.g., `060`) while gracefully handling the `+task.` separator.
3.  **Leverage ace-core:** Ensure any file reading or path manipulation leverages `Ace::Core::Atoms::FileReader` or similar utilities if applicable for resolving paths.
4.  **Testing:** Add comprehensive test cases to `ace-taskflow/test/` using `AceTestCase` from `ace-test-support`. These tests should cover:
    *   Successful parsing of `v.X.Y.Z+task.NNN` IDs.
    *   Continued successful parsing of all existing valid formats (`060`, `task.060`, `v.0.9.0+task.060`, `backlog+task.025`).
    *   Appropriate error handling for genuinely invalid formats.

## Considerations
-   **Backward Compatibility:** The primary consideration is to ensure that all currently supported task ID formats continue to function correctly after the change.
-   **Robustness:** The parsing logic should be robust enough to handle various version and task number combinations without ambiguity.
-   **Readability:** The updated parsing code should remain clear and maintainable, adhering to the ATOM architecture pattern.
-   **Error Messaging:** Ensure that if an invalid format is provided, the error message remains informative and helpful.

## Benefits
-   **Enhanced User Experience:** Provides greater flexibility and consistency for users when referencing tasks, especially in versioned contexts.
-   **Improved Robustness:** Makes `ace-taskflow` more resilient to variations in how users might naturally specify task IDs.
-   **Code Consistency:** Aligns the parsing logic more closely with the intuitive structure of combined version and task identifiers.
-   **Agent Compatibility:** Ensures that AI agents can use a wider range of explicit task ID formats when interacting with `ace-taskflow`.

---

## Original Idea

```
Ensure we support v.0.9.0+task.060 as valid task id 

⏺ Now let me read the task file:

⏺ Bash(ace-taskflow task v.0.9.0+task.060 --path)
  ⎿  Error: Task 'v.0.9.0+task.060' not found.
     Valid formats: 018, task.018, v.0.9.0+task.018, backlog+task.025

⏺ Let me try with the correct format:

⏺ Bash(ace-taskflow task 060 --path)
  ⎿  .ace-taskflow/v.0.9.0/t/060-implement-sequential-group-execution-ace/task.060.md
```

---
Captured: 2025-10-02 00:27:11