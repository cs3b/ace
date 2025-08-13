---
:input_tokens: 45928
:output_tokens: 952
:total_tokens: 46880
:took: 6.06
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-13T23:24:28Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45928
:cost:
  :input: 0.004593
  :output: 0.000381
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.004974
  :currency: USD
---

```markdown
# Task Manager: Flexible Task Retrieval

## Intention

To enhance the `task-manager next` command to return a single pending task by default, or all pending tasks when a limit of zero is specified.

## Problem It Solves

**Observed Issues:**
- The `task-manager next` command currently only returns a single task, limiting its utility for users who need to view multiple ready tasks.
- There is no straightforward way to retrieve all pending tasks that are ready to be worked on without manually iterating or using less direct methods.
- Users lack control over the number of tasks returned by the `next` command.

**Impact:**
- Users cannot easily get an overview of all immediately actionable tasks without executing multiple commands or resorting to manual file parsing.
- The `next` command's functionality is restrictive, forcing users into a single-task workflow.
- Automation that requires fetching multiple ready tasks is cumbersome to implement.

## Key Patterns from Reflections

- **CLI Tool Patterns**: Existing executables in `dev-tools/exe/` follow consistent interfaces and argument parsing.
- **User Control**: Providing flags for granular control over command output (e.g., `--limit`, `--format`) is a common pattern.
- **Task Management**: The `dev-taskflow` repository structures tasks, implying that tools should interact with this structure.
- **Workflow Instructions**: AI agents rely on predictable command outputs for executing workflows.

## Solution Direction

1. **Modify `task-manager next` command**: Update the `next` command's logic to accept a `--limit` flag.
2. **Implement default behavior**: When `--limit` is not provided or is set to `1`, return only the single next pending task.
3. **Implement zero-limit behavior**: When `--limit 0` is specified, retrieve and return all pending tasks that are in a "ready" state.

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the exact definition of a "pending task ready to be worked on" in the context of the `dev-taskflow` structure? (e.g., status, specific fields)
2. How should multiple tasks be formatted and returned when `--limit 0` is used? (e.g., JSON array, newline-delimited, structured text)
3. What is the expected performance impact of retrieving all pending tasks, and are there any optimizations needed for very large task backlogs?

**Open Questions:**
- Should there be a maximum configurable limit if `--limit 0` is not truly "unlimited" but rather a very large number?
- How should tasks with dependencies that are not yet met be handled when `--limit 0` is used? Should they be excluded?
- What specific exit codes should be used for different scenarios (e.g., no tasks found vs. an error occurred)?

## Assumptions to Validate

**We assume that:**
- The `dev-taskflow` repository contains a consistent way to identify pending tasks ready for work. - *Needs validation*
- The current task retrieval mechanism within `task-manager` can be extended to handle multiple results efficiently. - *Needs validation*
- Users will benefit from the ability to view multiple ready tasks at once, especially for planning or batch processing. - *Needs validation*

## Expected Benefits

- **Increased Flexibility**: Users can choose to retrieve either a single next task or a batch of ready tasks.
- **Improved Workflow Efficiency**: AI agents and developers can more easily plan and execute tasks by seeing multiple options.
- **Enhanced Usability**: The `task-manager` becomes more versatile for different user needs and automation scenarios.
- **Standardized Output**: Consistent formatting for single vs. multiple task returns will improve predictability.

## Big Unknowns

**Technical Unknowns:**
- The precise implementation details for filtering tasks based on "readiness" and handling dependencies.
- The most suitable output format for returning multiple tasks that is both machine-readable and human-friendly.

**User/Market Unknowns:**
- How frequently will users utilize the `--limit 0` feature compared to the default single-task retrieval?
- Are there specific edge cases or task states that need to be explicitly excluded when returning "all pending tasks"?

**Implementation Unknowns:**
- The exact location and method within the `task-manager` codebase to implement this change.
- The effort required to update any existing documentation or examples that rely on the current single-task output.
```

> SOURCE

```text
task-manager next should return one task by default, but when we pass --limit 0 it shoould return all the pending tasks ready to be work on
```
