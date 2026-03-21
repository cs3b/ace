---
doc-type: guide
title: "Implementing Task Cycle: Meta (Documentation)"
purpose: Documentation workflow
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Implementing Task Cycle: Meta (Documentation)

This details specific steps for the task cycle when the work involves modifying project documentation (guides, tasks,
research, etc.) within the ace-* packages.

1. Draft or update task/guide/research markdown file(s).
2. Run `bin/lint` (which includes link checking) and address any reported issues.
3. Commit the documentation changes using the [conventional commit format](../version-control-system-message.g.md).
4. Perform self-reflection on the documentation changes. Individual reflections can be captured using the [Create Reflection Note workflow](wfi://create-reflection-note). During this step:
   * Review the documentation for clarity, completeness, and accuracy
   * Consider if the documentation effectively communicates its intended purpose
   * Identify any gaps or areas that could be improved
   * Document insights or lessons learned during the documentation process
5. Commit any findings or documentation updates resulting from reflection.
6. If architecture changes were documented, run any scripts to update diagrams (e.g., `generate-blueprint` if applicable).
7. Push changes.
8. Mark the task as done.