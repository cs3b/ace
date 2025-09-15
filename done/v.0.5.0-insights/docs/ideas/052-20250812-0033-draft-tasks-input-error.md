---
:input_tokens: 46346
:output_tokens: 1229
:total_tokens: 47575
:took: 5.331
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-11T23:34:04Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 46346
:cost:
  :input: 0.004635
  :output: 0.000492
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005126
  :currency: USD
---

# Enhance `/draft-tasks` Command to Handle Idea and Task Files

## Intention

To enhance the `/draft-tasks` command to intelligently detect whether it's processing raw idea files or already-completed task specifications, and to adapt its workflow accordingly for creating or registering tasks.

## Problem It Solves

**Observed Issues:**
- The `/draft-tasks` command currently expects "idea" files (brief concepts/proposals) as input.
- It fails when provided with already-completed task files that have full behavioral specifications, as its workflow is designed to transform ideas into draft tasks using `task-manager create`.
- The command does not distinguish between input types, leading to incorrect processing when complete task files are provided.
- Users must manually determine whether to use `/draft-tasks` or a manual loop with `task-manager create` and file content copying for already-completed tasks.

**Impact:**
- Users cannot efficiently register existing, fully specified task files using the `/draft-tasks` command.
- The command's current workflow is not robust enough to handle different input file types, leading to user confusion and errors.
- Manual workarounds are required for common scenarios, reducing automation efficiency.
- The distinction between "ideas" and "tasks" in the input processing is not clear, leading to incorrect usage.

## Key Patterns from Reflections

- **CLI Tool Patterns**: The need to create a more robust and user-friendly CLI interface that can handle varied input types and adapt its behavior. (Referenced in `docs/architecture-tools.md` about 25+ existing executables with consistent interfaces).
- **Workflow Instructions**: The concept of transforming input into a structured output (ideas to draft tasks) is a core workflow pattern. (Referenced in `docs/architecture.md` about AI workflow instructions).
- **ATOM Architecture**: The `task-manager` is likely an `Organism` or `Ecosystem` component, and this enhancement would involve modifying its behavior or adding a new `Molecule` to handle input detection. (Referenced in `docs/architecture-tools.md` about ATOM architecture).
- **Error Handling**: The current failure indicates a need for better error reporting and input validation, potentially leveraging `ADR-009: Centralized CLI Error Reporting Strategy`.

## Solution Direction

1. **Input Type Detection**: Implement logic within the `/draft-tasks` command to analyze input files and determine if they represent raw ideas or complete task specifications.
2. **Conditional Workflow Execution**: Based on the detected input type, the command will execute one of two distinct workflows:
    - **Idea Files**: Proceed with the existing `/draft-tasks` logic (transform ideas → create draft tasks via `task-manager create`).
    - **Completed Task Files**: Execute a new workflow that registers the existing task files with `task-manager create` and preserves their content.
3. **User Guidance and Feedback**: Provide clear feedback to the user about the detected input type and the action being taken. If an error occurs due to incorrect input, provide specific guidance on how to use the command or what input is expected.

## Critical Questions

**Before proceeding, we need to answer:**
1. What specific criteria will be used to reliably distinguish between an "idea file" and a "completed task file" (e.g., presence of specific keywords, structured fields, file naming conventions)?
2. How should the command handle files that do not clearly fit either category?
3. What is the precise behavior required for registering "completed task files" – should it update existing tasks, create new ones with specific statuses, or both?

**Open Questions:**
- Should the command attempt to automatically extract the task title and other metadata from completed task files, or rely on the user to provide this information?
- How should the command interact with the `task-manager` to ensure idempotency if a task file is processed multiple times?
- What level of detail should be provided in the user feedback for detected input types and executed actions?

## Assumptions to Validate

**We assume that:**
- "Idea files" typically contain brief descriptions or proposals, lacking the detailed structure of a completed task. - *Needs validation*
- "Completed task files" will have a discernible structure or content that allows for programmatic identification (e.g., specific YAML front matter, headings, or keywords). - *Needs validation*
- Users expect the command to automatically handle the registration of existing task files when provided, rather than requiring them to manually loop and call `task-manager create`. - *Needs validation*

## Expected Benefits

- **Improved User Experience**: The command becomes more versatile and forgiving, handling different input scenarios gracefully.
- **Increased Automation**: Eliminates the need for manual looping and content copying for registering existing task files.
- **Reduced Errors**: Prevents incorrect processing when users provide completed tasks instead of ideas.
- **Clearer Command Intent**: The command's behavior is more predictable and aligned with user expectations for different input types.

## Big Unknowns

**Technical Unknowns:**
- The exact heuristic or set of rules to accurately differentiate between "idea" files and "completed task" files across various potential user inputs.
- Potential edge cases or variations in how "completed task files" might be structured, which could affect metadata extraction or registration.

**User/Market Unknowns:**
- How frequently users will attempt to use `/draft-tasks` with already-completed task files.
- What specific metadata (beyond title) users might expect to be extracted and used when registering completed task files.

**Implementation Unknowns:**
- The specific `task-manager` commands and options required to robustly register existing task files while preserving their content and status.
- The best approach for providing feedback to the user regarding the detected file type and the subsequent action taken.

> SOURCE

```text
I see the issue now! The /draft-tasks command is designed to work with idea files (from dev-taskflow/backlog/ideas/), not with already-completed task files. You provided it with task files that were already fully drafted with complete specifications.

  Here's what went wrong:

  The Problem:

  1. Wrong Input Type:
    - /draft-tasks expects idea files (brief concepts/proposals)
    - You gave it completed task files with full behavioral specifications
  2. Wrong Workflow:
    - /draft-tasks is meant to transform ideas → draft tasks using task-manager create
    - Your files were already complete tasks that just needed to be moved/registered

  What Should Have Happened:

  Option 1: If Starting from Ideas

  # If you had idea files:
  /draft-tasks dev-taskflow/backlog/ideas/vue-component-storage.md
  This would have:
  - Read the idea file
  - Used task-manager create to generate tasks in the current release
  - Created proper task files with draft status

  Option 2: For Already-Complete Tasks (Your Case)

  You should have used a different approach since you already had complete task files:

  # Loop through existing task files and register them:
  for task in dev-taskflow/backlog/tasks/vue-component-storage-*.md; do
    # Extract title from the file
    title=$(grep "^# " "$task" | head -1 | sed 's/^# //')

    # Use task-manager create
    task-manager create --title "$title" --status draft --priority high

    # Then copy content from backlog task to newly created file
  done

  The Solution Going Forward:

  The /draft-tasks command should be enhanced to:
  1. Detect input type - Check if files are ideas or already-complete tasks
  2. Handle both cases:
    - Ideas → Create new draft tasks from scratch
    - Complete tasks → Register them with task-manager and preserve content
```
