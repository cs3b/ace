---
:input_tokens: 45650
:output_tokens: 1202
:total_tokens: 46852
:took: 4.921
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-07-31T07:28:27Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45650
:cost:
  :input: 0.004565
  :output: 0.000481
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005046
  :currency: USD
---

# Enhance Task Manager with `task-create` Subcommand

## Intention

To improve the clarity and discoverability of creating new tasks within the `task-manager` CLI tool by introducing a dedicated `task-create` subcommand, migrating the functionality from the existing `create-path task-new` command.

## Problem It Solves

**Observed Issues:**
- The `create-path task-new` command is not intuitive for task creation, as `create-path` is primarily associated with file and directory generation, not task management.
- Task creation is a core function of the `task-manager` and should be directly accessible via its primary command.
- The current command structure leads to discoverability issues for users looking to create tasks.
- Inconsistency in command naming for related functionalities (e.g., `task-manager list` vs. `create-path task-new`).

**Impact:**
- Developers and AI agents may struggle to find or correctly use the command for creating new tasks, leading to missed functionalities or incorrect usage.
- The current structure creates cognitive overhead for users trying to understand the tool's capabilities.
- Potential for reduced adoption of task creation features due to unintuitive command naming.

## Key Patterns from Reflections

- **CLI Tool Patterns**: The project emphasizes consistent and discoverable command-line interfaces. Existing tools like `llm-query` and `code-review` have clear subcommands that directly reflect their functionality.
- **ATOM Architecture**: New features should be integrated logically within existing organisms or molecules. Task management logic resides within the `task-manager` executable, implying new subcommands should also be part of this executable.
- **User Experience**: Intuitive command naming and structure are crucial for developer productivity and AI agent reliability.
- **Refactoring for Clarity**: ADR-003 and ADR-005 highlight the importance of organizing files and standardizing naming for better maintainability and discoverability. This change aligns with that philosophy for CLI commands.

## Solution Direction

1. **Introduce `task-create` Subcommand**: Add a new subcommand `create` to the `task-manager` executable, which will handle the creation of new tasks.
2. **Migrate Functionality**: Re-implement the logic currently handled by `create-path task-new` under the new `task-manager create` command. This includes generating task IDs, setting up task files, and potentially incorporating initial metadata based on provided arguments.
3. **Deprecate `create-path task-new`**: Mark the old command as deprecated and provide clear guidance for users to migrate to the new `task-manager create` command. Eventually, `create-path task-new` can be removed to reduce maintenance.

## Critical Questions

**Before proceeding, we need to answer:**
1. What are the exact arguments and flags that `task-manager create` should accept, mirroring or improving upon `create-path task-new` (e.g., for title, priority, estimate)?
2. How will the new `task-manager create` command integrate with the existing task file structure and naming conventions (e.g., `task-id.md`)?
3. What is the strategy for deprecating `create-path task-new` to ensure a smooth transition for existing users and workflows?

**Open Questions:**
- Should `task-manager create` also support other `create-path` functionalities (e.g., creating project directories) if it becomes the primary creation command, or should it remain focused solely on task creation?
- How will the `task-manager create` command interact with the `nav-path` tool, if at all?
- What is the impact of this change on existing AI agent workflows that might be hardcoded to use `create-path task-new`?

## Assumptions to Validate

**We assume that:**
- The `task-manager` executable is the correct place to house the task creation functionality. - *Needs validation*
- Users and AI agents will benefit from a more direct command for task creation. - *Needs validation*
- The migration process can be managed effectively through deprecation warnings and clear documentation. - *Needs validation*

## Expected Benefits

- **Improved Discoverability**: Task creation is now directly accessible under the `task-manager` command.
- **Enhanced Clarity**: Command naming aligns better with the functionality being performed.
- **Consistent CLI Experience**: Adheres to the project's principle of having commands logically grouped under their primary executables.
- **Reduced Maintenance**: Consolidating creation logic into `task-manager` simplifies the codebase.
- **Smoother User Experience**: More intuitive command structure for both humans and AI agents.

## Big Unknowns

**Technical Unknowns:**
- The precise implementation details for handling task ID generation and file creation within the `task-manager` executable.
- The best approach for managing the deprecation lifecycle of `create-path task-new` within the `dev-tools` gem.

**User/Market Unknowns:**
- The extent to which existing AI agent workflows rely on the specific `create-path task-new` command, and the potential impact of its deprecation.
- User preference for command syntax (e.g., `create <task_title>` vs. `create --title <task_title>`).

**Implementation Unknowns:**
- The effort required to refactor the `create-path task-new` logic and integrate it into `task-manager`.
- The process for updating all relevant documentation (e.g., `docs/tools.md`, `dev-handbook/guides/`) to reflect the new command structure and deprecation.