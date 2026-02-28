---
title: Fix ace-taskflow status to accurately report recently completed tasks
filename_suggestion: fix-taskflow-status-recent
enhanced_at: 2025-12-29 23:19:00.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2026-01-05 23:24:24.000000000 +00:00
id: 8nsyz3
tags: []
created_at: '2025-12-29 23:18:58'
---

# Fix ace-taskflow status to accurately report recently completed tasks

## Problem
The `ace-taskflow status` command is failing to accurately report recently completed tasks in the "Recently Done" section. For example, tasks like 159 (Extract ace-support-fs gem), which was recently merged (4 minutes ago per `ace-git status`), are not appearing in the taskflow report, which currently only lists tasks completed 16 days ago or earlier.

This lack of real-time visibility hinders the ability of AI agents and human developers to track rapid progress and understand the current state of the release cycle.

## Solution
Refactor the task loading and filtering mechanism within `ace-taskflow` to ensure that the most recent task completions are correctly identified and displayed. This requires updating the logic that determines the completion date and the time window for 'Recently Done' tasks.

## Implementation Approach
1. **Configuration Update:** Define a new configuration setting in `ace-taskflow/.ace.example/taskflow/config.yml` (following ADR-022) to control the lookback period (e.g., `status.recent_days: 7`) or the maximum number of tasks to display.
2. **Task Loading Molecule:** Update the relevant Molecule (e.g., `Ace::Taskflow::Molecules::TaskLoader`) to reliably read the completion timestamp from task metadata files within `.ace-taskflow/done/`.
3. **Status Organism:** Modify `Ace::Taskflow::Organisms::StatusReporter` to use the configured lookback period to filter the list of completed tasks, ensuring that tasks completed within the last few hours or days are prioritized.
4. **Verification:** Ensure the fix correctly identifies and displays tasks corresponding to recent merges confirmed by `ace-git status`.

## Considerations
- **Performance:** The solution must efficiently traverse the `.ace-taskflow/done/` directory without causing significant latency, especially as the number of completed tasks grows.
- **Deterministic Output:** The output format must remain stable to ensure reliable parsing by AI agents.
- **Time Zones:** Ensure consistent handling of timestamps and time zone conversions when calculating the 'recently done' window.

## Benefits
- Provides accurate, real-time progress tracking for developers and AI agents.
- Improves the reliability and utility of the core `ace-taskflow` command.
- Adheres to the ACE principle of providing deterministic and up-to-date CLI output.

---

## Original Idea

```
ace-taskflow status doesn't show properly recenlty done it should show task 160 161

## Task Activity

### Recently Done
- 159: Extract ace-support-fs gem (PathExpander, ProjectRootFinder, DirectoryTraverser) (done 2m ago)
- 155: Add fix-bug and analyze-bug workflows to ace-taskflow (done 1d ago)
- 154.01: Add parse_move_args_with_optparse to TaskArgParser (done 1d ago)

### In Progress
No other tasks in progress

### Up Next
- 158: Fix ace-taskflow task move --backlog command bug
- 163: Add MIT licenses to all ACE packages and mono-repo
- 157.07: Update ace-support-core to Use ace-config
```