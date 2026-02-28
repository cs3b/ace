---
title: Integrate ace-review reports directly into ace-taskflow task directories
filename_suggestion: feat-review-task-report-storage
enhanced_at: 2025-11-07 12:54:56.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2025-11-16 14:03:56.000000000 +00:00
id: 8m6jcl
tags: []
created_at: '2025-11-07 12:53:58'
---

# Integrate ace-review reports directly into ace-taskflow task directories

## Problem
Currently, `ace-review` reports are often generated and displayed, but their persistent storage and association with specific development tasks are not standardized. This makes it challenging for both human developers and AI agents to easily retrieve, reference, and incorporate historical review feedback directly related to an `ace-taskflow` task. Without a clear storage pattern, review context can be lost or difficult to discover, hindering continuous improvement and informed decision-making within a task's lifecycle.

## Solution
Implement a feature in `ace-review` to automatically save generated review reports within the corresponding `ace-taskflow` task directory. This would involve creating a dedicated `reviews/` subdirectory inside the active task's folder (e.g., `.ace-taskflow/v.0.9.0/tasks/047-my-task/reviews/`) and storing each report with a deterministic, timestamped filename that includes the provider (e.g., `YYYYMMDDHHMMSS-provider-report.md`). This ensures review reports become an integral, discoverable part of the task's artifacts.

## Implementation Approach
- **`ace-review` gem:**
  - **Task Context Resolution (Molecule/Organism):** Enhance `ace-review` to detect the currently active `ace-taskflow` task. This could involve querying `ace-taskflow` via its CLI (e.g., `ace-taskflow task current --path`) or an internal API if `ace-review` has a direct dependency on `ace-taskflow`.
  - **Report Persistence (Organism):** Introduce a new `Organism` (e.g., `Ace::Review::Organisms::TaskReportPersister`) responsible for constructing the target path within the identified task directory and writing the review report content to a new file.
  - **Filename Generation (Atom):** Develop an `Atom` (e.g., `Ace::Review::Atoms::ReportFilenameGenerator`) to create standardized, unique filenames for review reports, incorporating a timestamp and the LLM provider used (e.g., `20251107123000-claude-pr-review.md`).
  - **CLI Integration:** Add an option to `ace-review` (e.g., `--save-to-task` or `--auto-save`) to explicitly or implicitly trigger this behavior when a task is active.
- **`ace-taskflow` gem (potential enhancements):**
  - While `ace-taskflow` doesn't strictly need changes for `ace-review` to write files, future enhancements could include `ace-taskflow` commands to list or navigate to associated review reports within a task's directory, similar to how it handles task files.
- **Configuration:** Utilize `Ace::Core.config.get('ace', 'review')` to allow users to configure default behavior, such as the `reviews/` subdirectory name or whether auto-saving to tasks is enabled by default.
- **ATOM Architecture:** The `Ace::Review` gem would leverage its `Organisms` layer for orchestrating the review process and report saving, `Molecules` for interacting with `ace-taskflow` context, and `Atoms` for pure functions like path and filename generation.

## Considerations
- **Dependency Management:** `ace-review` will need to be aware of `ace-taskflow`'s task directory structure and potentially its CLI/API. This might introduce a soft or hard dependency.
- **User Experience:** The CLI interface should be intuitive, allowing users to easily opt-in or out of saving reports to tasks.
- **Report Format:** Ensure reports are saved in a machine-readable yet human-friendly format, preferably Markdown, to facilitate AI processing and human review.
- **Error Handling:** Robust error handling is needed if a task directory cannot be found or written to.
- **Context Awareness:** How `ace-review` determines the 'current' task needs to be deterministic and reliable (e.g., via `ACE_TASK_ID` environment variable, or `ace-taskflow`'s `current` command).

## Benefits
- **Enhanced Traceability:** Review reports are directly linked to the specific task they address, providing a clear audit trail.
- **Improved AI Context:** AI agents working on a task can automatically discover and incorporate past review feedback and decisions, leading to more informed and consistent outputs.
- **Standardized Artifacts:** Establishes a consistent and predictable location for all review-related artifacts across the project.
- **Simplified Navigation:** Human developers can easily find all relevant information for a task, including its review history, within a single, well-defined directory structure.
- **Seamless Workflow Integration:** Deepens the integration between `ace-review` and `ace-taskflow`, making the overall ACE development workflow more cohesive and powerful.

---

## Original Idea

```
ace-review - the report should be part of the task if we work on the task e.g.: task-dir/reviews/timestamp-report-provider.md
```