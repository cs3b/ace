---
name: as-overseer-configure-project
description: Adapt project delivery supervision presets, workflows, and decision guidance
  without replacing local policy
user-invocable: true
allowed-tools:
- Bash(ace-nav:*)
- Bash(ace-bundle:*)
- Read
- Write
- Edit
- Glob
argument-hint: "[project-root]"
last_modified: '2026-10-11'
source: ace-overseer
skill:
  kind: workflow
  execution:
    workflow: wfi://overseer/configure-project
---

Load and run `ace-bundle wfi://overseer/configure-project` in the target project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
