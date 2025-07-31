every task definition should have an example section

it should be part of drafting tasks (dev-handbook/workflow-instructions/draft-release.wf.md)

analyze the current draft task workflow instructions and ensure we have this section as part of this workflow

example should focus on the


## Example

how it example could look like ;-) can look like in context of: dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.001-create-ideas-manager-tool.md

### How we run it:

#### from simple text

```bash
ideas-manager capture "in context of task-manager - lets print a status on top (when doing any listing how many tasks are in certain state - in one line: draft: 2, panding: 5, done: 20, total: 27"
```

##### producing output

```bash
# => Created: dev-taskflow/backlog/ideas/20250730-1430-add-status-to-task-manager.md
```


#### from file

```bash
ideas-manager capture --file dev-taskflow/backlog/ideas/wf-create-reflection-note-feedback.md --commit
```

##### producing output

```bash
# => Created: dev-taskflow/backlog/ideas/20250730-1430-improve-reflection-note.md
```

#### from clipboad

```bash
ideas-manager capture -clipboard
```
##### producing output

```bash
# => Created: dev-taskflow/backlog/ideas/20250730-1430-task-example-section.md
```


### Example Ouput file cotent


<template path="dev-taskflow/backlog/ideas/20250730-1301-every-task-definition-should-have-an-example-section.md">
# Add --commit Flag to Git Commit Tool

## Intention

To automatically commit generated files by default when using the `git-commit` CLI tool, with the ability to disable this behavior during testing.

## Problem It Solves

**Observed Issues:**
- Users often create files and then need to manually commit them, adding an extra step to the workflow.
- Forgetting to commit generated files leads to uncommitted work and potential data loss or confusion.
- The current `git-commit` tool does not automatically stage and commit newly created files without explicit user action.

**Impact:**
- Increased manual effort for developers to stage and commit files.
- Higher likelihood of forgetting to commit important generated files.
- Inconsistent commit history if files are created but not committed promptly.
- A less seamless workflow for AI agents that generate and intend to commit files.

## Key Patterns from Reflections

- **CLI Tool Patterns**: The project has over 25 existing executables with consistent interfaces, suggesting that adding flags like `--commit` is a standard pattern. (docs/architecture-tools.md)
- **Git Operations**: The `dev-tools` gem already provides enhanced Git operations, including `git-commit`, indicating a focus on improving Git workflows. (docs/architecture-tools.md, docs/tools.md)
- **Testability**: The need to disable features like `--commit` during testing (e.g., by not committing files) aligns with the project's emphasis on robust testing and CI-aware configurations. (ADR-006)
- **Workflow Self-Containment**: Embedding functionality like automatic committing aligns with the principle of making workflows self-contained and reducing manual steps for AI agents. (ADR-001)

## Solution Direction

1. **Add `--commit` Flag**: Introduce a new `--commit` flag to the `git-commit` CLI tool that, when present, will automatically stage and commit the provided file path.
2. **Default Behavior**: Set the `--commit` flag to be enabled by default for interactive use, simplifying the common workflow of creating and committing a file.
3. **Test Environment Override**: Implement logic to automatically disable the `--commit` flag (or prevent actual commits) when the tool detects it's running in a test environment (e.g., via `ENV['CI']` or a specific test flag).

## Critical Questions

**Before proceeding, we need to answer:**
1. What is the precise default behavior for the `--commit` flag when used interactively (i.e., should it be on by default, or require explicit `--commit`)?
2. How will the `--commit` flag interact with other existing `git-commit` flags, such as `--intention` or `--message`?
3. What is the most robust and reliable way to detect a "test environment" to disable the commit functionality?

**Open Questions:**
- Should the `--commit` flag also implicitly stage the file if it's not already staged, or will it only commit if already staged?
- What should be the default commit message if one is not provided and the `--commit` flag is used?
- How should the tool provide feedback to the user when a commit is automatically performed or skipped in a test environment?

## Assumptions to Validate

**We assume that:**
- Users frequently create files and immediately want to commit them as part of their workflow. - *Needs validation through user feedback or observation.*
- Developers will appreciate the convenience of automatic committing for new files. - *Needs validation.*
- Disabling commits in test environments is a critical requirement for preventing unintended side effects. - *Needs validation.*

## Expected Benefits

- Streamlined workflow for creating and committing files.
- Increased developer productivity and reduced manual steps.
- More consistent and up-to-date commit history.
- Improved usability for AI agents performing file generation and commit tasks.
- Enhanced testability by providing a clear override for commit behavior.
</template>
