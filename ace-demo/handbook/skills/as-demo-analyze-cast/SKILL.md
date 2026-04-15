---
name: as-demo-analyze-cast
description: Analyze failed demo casts and route them to scenario, product, or verifier fixes
# bundle: wfi://demo/analyze-cast
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-demo:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "<cast-file> --tape <tape-ref-or-path> [--sandbox-path <path>]"
last_modified: 2026-04-15
source: ace-demo
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
skill:
  kind: workflow
  execution:
    workflow: wfi://demo/analyze-cast
---

Load and run `ace-bundle wfi://demo/analyze-cast` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
