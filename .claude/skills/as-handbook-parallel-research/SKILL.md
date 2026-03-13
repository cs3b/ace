---
name: as-handbook-parallel-research
description: Set up and run parallel agent research
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Write
- Glob
argument-hint: "[topic] --agents claude,gemini,codex"
last_modified: 2026-01-31
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/parallel-research
---

Load and run `mise exec -- ace-bundle wfi://handbook/parallel-research` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
