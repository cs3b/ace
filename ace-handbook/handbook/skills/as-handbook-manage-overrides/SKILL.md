---
name: as-handbook-manage-overrides
description: Manage project-local overrides of ace-managed docs (workflows, cookbooks, guides) and verify resolution precedence
# bundle: wfi://handbook/manage-overrides
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-nav:*)
  - Bash(ace-handbook:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - Glob
  - LS
argument-hint: "[surface|uri] [action: plan|verify]"
last_modified: 2026-09-20
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
    workflow: wfi://handbook/manage-overrides
---

Load and run `ace-bundle wfi://handbook/manage-overrides` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
