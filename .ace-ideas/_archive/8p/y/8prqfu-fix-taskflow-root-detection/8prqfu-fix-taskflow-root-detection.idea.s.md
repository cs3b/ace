---
status: done
id: 8prqfu
title: Idea
tags: []
created_at: '2026-02-28 17:37:35'
---

# Idea

---
title: Fix ace-taskflow Project Root Detection
filename_suggestion: fix-taskflow-root-detection
enhanced_at: 2025-10-01 18:29:23
llm_model: gflash
---

## Problem
Currently, `ace-taskflow` fails to correctly locate its configuration directory (`.ace-taskflow/`) when executed from a subdirectory within an ACE project. This results in the tool reporting 'No tasks found' or similar errors, even when tasks exist. The tool only functions as expected when invoked directly from the project's root directory. This behavior is inconsistent with the ACE project's design principles for tools to operate reliably from any subdirectory.

## Solution
`ace-taskflow` should be enhanced to reliably detect the project's root directory using `ace-core`'s configuration discovery mechanisms. This will ensure that `ace-taskflow` consistently finds and operates on the `.ace-taskflow/` directory, regardless of the current working directory from which it is invoked.

## Implementation Approach
1.  **Leverage `ace-core`**: Integrate `Ace::Core::ConfigDiscovery.new.project_root` into `ace-taskflow`'s initialization to determine the definitive project root. This utility is designed for exactly this purpose within the ACE ecosystem.
2.  **Path Resolution**: All internal `ace-taskflow` operations (e.g., loading tasks, creating new tasks, reading release information) must construct paths to the `.ace-taskflow/` directory and its contents relative to the discovered project root.
3.  **ATOM Pattern**: This fix would likely involve modifications within `ace-taskflow/organisms/task_manager.rb` or `ace-taskflow/molecules/path_resolver.rb` to ensure all file operations correctly reference the project-root-relative `.ace-taskflow` directory. A dedicated `molecule` or `atom` might be introduced to abstract the root path discovery.
4.  **Configuration Loading**: Ensure `ace-taskflow`'s configuration loading (as per the `ace-gems.g.md` guide) correctly uses the `Ace::Core.config` cascade, which itself relies on project root detection for `.ace` directories.

## Considerations
-   **Backward Compatibility**: The change must not break existing `.ace-taskflow` directory structures or task definitions.
-   **Testing**: Comprehensive tests using `ace-test-support` (e.g., `AceTestCase` with `run_subprocess`) should be added to verify `ace-taskflow`'s behavior when run from various subdirectories.
-   **Error Handling**: Ensure clear error messages are provided if a `.ace-taskflow` directory is genuinely not found within the detected project root.

## Benefits
-   **Improved User Experience**: Developers can run `ace-taskflow` commands from anywhere within an ACE project, eliminating the need to `cd` to the root.
-   **Consistency**: Aligns `ace-taskflow` with the ACE project's standard for configuration discovery and project root detection, as provided by `ace-core`.
-   **Reliability**: Ensures `ace-taskflow` operates deterministically, which is crucial for AI agent execution.

---

## Original Idea

```
taskflow do not operate on the project root configured folder for e.g.: .ace-taskflow - it try to work on the folder you are actually in, and this is an error:
❯ ace-taskflow tasks
No tasks found for preset 'next'.

ace-meta/ace-git-commit on  main [!?⇡]
❯ cd ..

ace-meta on  main [!?⇡] via 💎 v3.4.6
❯ ace-taskflow tasks
v.0.9.0: 2/53 tasks • Mono-Repo Multiple Gems
Ideas: 💡 8 | ✅ 7 • 15 total
Tasks: ⚫ 9 | ⚪ 1 | 🟡 1 | 🟢 41 | 🔴 0 | ❓ 1 • 53 total • 77% complete
========================================
  v.0.9.0+task.057     ⚪ Improve ace-test-runner reporter output for Minitest
    .ace-taskflow/v.0.9.0/t/057-test-test-ace-test-runner-reporter-outpu/task.057.md
  v.0.9.0+task.055     🟡 Add critical edge case tests to ACE packages
    .ace-taskflow/v.0.9.0/t/055-test-packages-critical-edge-case-tests/task.055.md
    Estimate: 3-5 days|
```

---
Captured: 2025-10-01 18:29:09