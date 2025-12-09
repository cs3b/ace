# Idea

---
title: Extend `ace-taskflow` reschedule functionality to ideas and releases
filename_suggestion: feat-taskflow-reschedule-ideas-releases
enhanced_at: 2025-09-25 01:11:20
location: active
llm_model: gflash
---

## Problem
The `ace-taskflow` gem currently provides a `tasks reschedule` command that allows for overwriting the priority, status, or scheduled date of individual tasks. This capability is crucial for dynamic project management, especially for AI agents. However, this 'reschedule' functionality is missing for ideas and releases, leading to an inconsistent and less flexible management experience across different project artifacts within ACE.

## Solution
Implement `reschedule` subcommands for both `ace-taskflow idea` and `ace-taskflow release`, mirroring the existing functionality of `ace-taskflow tasks reschedule`. This will enable both human developers and AI agents to programmatically update the priority, status, or other relevant metadata (e.g., target date, category) of ideas and releases, bringing consistency and enhanced control to the entire `ace-taskflow` ecosystem.

## Implementation Approach
This enhancement will primarily be implemented within the `ace-taskflow` gem, leveraging its ATOM architecture patterns.

1.  **CLI Command Extension**: Add `reschedule` subcommands to the `idea` and `release` commands within `ace-taskflow/lib/ace/taskflow/commands/`.
    *   These subcommands will accept options (e.g., `--priority <value>`, `--status <value>`, `--date <YYYY-MM-DD>`) to specify the new metadata. Input validation will be crucial.
2.  **Organisms (Business Logic)**:
    *   Extend `Ace::Taskflow::Organisms::IdeaWriter` or introduce a new `IdeaScheduler` organism to encapsulate the business logic for updating an `Idea`'s metadata. This organism will be responsible for loading the idea, applying the changes, and persisting the updated `Idea` model.
    *   Similarly, for releases, an existing `ReleaseWriter` or a new `ReleaseScheduler` organism will handle the updates to `Release` models.
    *   These organisms will ensure data integrity and follow the existing patterns for task manipulation.
3.  **Models (Data Structures)**:
    *   Ensure `Ace::Taskflow::Models::Idea` and `Ace::Taskflow::Models::Release` can correctly represent and be updated with the new priority, status, or date attributes.
4.  **Molecules (Composed Operations)**:
    *   Leverage existing molecules for loading and saving ideas and releases (e.g., `Ace::Taskflow::Molecules::IdeaLoader`, `Ace::Taskflow::Molecules::IdeaWriter`) to facilitate the update process.
5.  **Deterministic Output**: The `reschedule` commands should provide clear, parseable output, indicating the success or failure of the operation and the new state of the idea or release.

## Considerations
-   **Consistency**: Ensure the CLI interface, option names, and behavior are highly consistent with `ace-taskflow tasks reschedule` to maintain a predictable user and agent experience.
-   **Configuration Cascade**: Consider if default priorities, valid statuses, or scheduling rules for ideas and releases should be configurable via the `.ace/` configuration cascade (ADR-015, Configuration Cascade).
-   **Error Handling**: All errors encountered during validation or persistence should be routed through the centralized `ErrorReporter` (ADR-009).
-   **Impact on Workflows**: Evaluate how rescheduling an idea might influence its conversion into a task, and if any automatic adjustments are needed.

## Benefits
-   **Unified Workflow**: Provides a consistent and predictable management experience across all `ace-taskflow` artifacts (tasks, ideas, releases).
-   **Enhanced Agent Capabilities**: Empowers AI agents to dynamically adjust the prioritization and scheduling of ideas and releases, improving their autonomous planning and execution capabilities.
-   **Improved Project Management**: Offers greater flexibility and control for both human developers and agents to manage project progress and adapt to changing priorities.
-   **Reduced Manual Intervention**: Automates updates that would otherwise require manual file editing, increasing efficiency.

---

## Original Idea

```
similar to feature in ace-taskflow tasks reschedule -> we should copy this ability to ideas - so we overwrite priorities, and also for releases
```

---
Captured: 2025-09-25 01:11:04