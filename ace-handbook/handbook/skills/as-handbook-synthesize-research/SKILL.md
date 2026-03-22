---
name: as-handbook-synthesize-research
description: Synthesize parallel agent research outputs into unified result
# bundle: wfi://handbook/synthesize-research
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Glob
argument-hint: "[research_folder]"
last_modified: 2026-01-31
source: ace-handbook
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/synthesize-research
---

Load and run `ace-bundle wfi://handbook/synthesize-research` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
