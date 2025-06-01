# Zed Editor Rule Mapping Guide

This document provides a mapping from old Zed editor custom rule names to the new workflow instruction filenames after the naming convention update (`.md` to `.wf.md` for workflows and `.g.md` for guides). It also includes general instructions for manually updating these rules in your Zed editor configuration.

**Important Note:** Due to limitations in programmatically accessing and modifying Zed editor's internal rule configurations or user-specific settings files, these updates **must be performed manually**.

## Rule Mapping

The following table maps the (assumed) old Zed rule names to their corresponding new workflow instruction filenames. Some rules might map to general workflows or involve referencing specific guides.

| Old Zed Rule Name           | New Workflow Instruction File / Guide                                  | Notes                                                                                                |
|-----------------------------|------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| `create-reflect-note`       | `docs-dev/workflow-instructions/create-reflection-note.wf.md`          | For creating reflection notes.                                                                       |
| `create-task(s)`            | `docs-dev/workflow-instructions/breakdown-notes-into-tasks.wf.md`      | Primary workflow for creating structured tasks from various inputs.                                  |
|                             | `docs-dev/workflow-instructions/draft-release.wf.md`                   | Task creation is also a step within the `draft-release` workflow.                                    |
| `initialize-project-structure`| `docs-dev/workflow-instructions/initialize-project-structure.wf.md`    | For setting up initial project directory structures.                                                 |
| `load-env`                  | `docs-dev/workflow-instructions/load-env.wf.md`                        | For loading project context, guides, and task information.                                           |
| `prepare-release`           | `docs-dev/workflow-instructions/draft-release.wf.md`                   | For drafting a new release.                                                                          |
| `review-next-task`          | `docs-dev/workflow-instructions/review-task.wf.md`                     | For reviewing and understanding a task before starting implementation.                               |
| `ship-current-release`      | `docs-dev/workflow-instructions/publish-release.wf.md`                 | For executing the process of publishing a release.                                                   |
| `update-changelog`          | `docs-dev/workflow-instructions/publish-release.wf.md`                 | Changelog updates are typically a step within the `publish-release` workflow.                        |
|                             | `docs-dev/guides/changelog.g.md`                                       | Refer to this guide for changelog content and formatting standards.                                    |
| `update-workflow-instruction`| `docs-dev/workflow-instructions/work-on-task.wf.md`                   | Use this workflow when the task involves modifying an existing workflow instruction file (e.g., `something.wf.md`). |
| `work-on-next-task`         | `docs-dev/workflow-instructions/work-on-task.wf.md`                    | The general workflow for implementing any given task.                                                |

## Manual Update Instructions for Zed Editor Rules

The exact steps to update your Zed editor rules will depend on how you've configured them (e.g., via `keymap.json`, `settings.json`, or a custom Zed package/extension). Below are general guidelines:

1.  **Locate Your Zed Configuration:**
    *   Open Zed.
    *   Go to `Zed` > `Settings` (or `Preferences`).
    *   You might find options to open `keymap.json` or `settings.json`.
    *   If you are using a custom package for these rules, you'll need to locate that package's files within your Zed configuration directory (often `~/.config/zed/`).

2.  **Identify the Rule Definition:**
    *   Search within your configuration files for the old rule names listed in the table above (e.g., search for `"create-task(s)"`).
    *   Rules might be defined as commands, keybindings, or actions that trigger a script or open a file.

3.  **Update the Rule:**
    *   **File Paths:** If the rule involves opening a specific workflow instruction file, update the old `.md` filepath to the new `.wf.md` filepath as per the mapping table.
        *   *Example (conceptual):*
            *   Old: `"command": "zed::OpenFile", "args": {"path": "docs-dev/workflow-instructions/load-env.md"}`
            *   New: `"command": "zed::OpenFile", "args": {"path": "docs-dev/workflow-instructions/load-env.wf.md"}`
    *   **Script Arguments:** If the rule triggers an external script that takes a workflow file as an argument, ensure the argument passed to the script reflects the new filename.
    *   **Associated Text/Labels:** If the rule has a display name or label in a command palette, update that as well if it mentioned the old filename.

4.  **Save and Test:**
    *   Save your configuration file(s).
    *   Restart Zed or reload the configuration if necessary.
    *   Test each updated rule to ensure it now points to the correct workflow instruction or performs the intended action with the new filenames.

**Example Scenario:**

Let's assume you had a Zed keybinding to open the `load-env.md` workflow:

*   In your `keymap.json` (or equivalent), you might have had:
    ```json
    // Old entry
    {
      "context": "Editor",
      "bindings": {
        "alt-l": ["zed_custom:open_workflow", {"name": "load-env.md"}]
      }
    }
    // Or perhaps directly opening a file
    {
      "context": "Editor",
      "bindings": {
        "alt-l": ["workspace::OpenFile", {"path": "docs-dev/workflow-instructions/load-env.md"}]
      }
    }
    ```

*   You would update this to:
    ```json
    // New entry
    {
      "context": "Editor",
      "bindings": {
        "alt-l": ["zed_custom:open_workflow", {"name": "load-env.wf.md"}]
      }
    }
    // Or
    {
      "context": "Editor",
      "bindings": {
        "alt-l": ["workspace::OpenFile", {"path": "docs-dev/workflow-instructions/load-env.wf.md"}]
      }
    }
    ```
    (The exact action like `zed_custom:open_workflow` or `workspace::OpenFile` depends on your specific Zed setup.)

If you encounter difficulties, refer to the Zed editor documentation on keybindings and custom commands, or review how you initially set up these rules.