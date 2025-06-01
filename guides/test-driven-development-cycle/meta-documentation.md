# Implementing Task Cycle: Meta (Documentation)

This details specific steps for the task cycle when the work involves modifying project documentation (guides, tasks,
research, etc.) within `docs-dev/` or `docs-project/`.

1. Draft or update task/guide/research markdown file(s).
2. Run `bin/lint` (which includes link checking) and address any reported issues.
3. Commit the documentation changes using the [conventional commit format](../version-control-system.g.md).
4. Perform self-reflection on the documentation changes. Individual reflections can be captured and later used as input
   for the [Create Retrospective Document workflow](../../workflow-instructions/create-retrospective-document.wf.md).
5. Commit any findings or documentation updates resulting from reflection.
6. If architecture changes were documented, run any scripts to update diagrams (e.g., `generate-blueprint` if applicable).
7. Push changes.
8. Mark the task as done.
