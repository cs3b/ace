# Implementing Task Cycle: Meta (Documentation)

This details specific steps for the task cycle when the work involves modifying project documentation (guides, tasks,
research, etc.) within `dev-handbook/` or `dev-taskflow/`.

1. Draft or update task/guide/research markdown file(s).
2. Run `bin/lint` (which includes link checking) and address any reported issues.
3. Commit the documentation changes using the [conventional commit format](../version-control-system-message.g.md).
<rewrite_this>
4. Perform self-reflection on the documentation changes. Individual reflections can be captured using the [Create Reflection Note workflow](dev-handbook/workflow-instructions/create-reflection-note.wf.md).
</rewrite_this>
5. Commit any findings or documentation updates resulting from reflection.
6. If architecture changes were documented, run any scripts to update diagrams (e.g., `generate-blueprint` if applicable).
7. Push changes.
8. Mark the task as done.
