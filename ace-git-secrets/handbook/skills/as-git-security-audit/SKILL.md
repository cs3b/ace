---
name: as-git-security-audit
description: Perform security audits to detect leaked authentication tokens
# bundle: wfi://git/security-audit
# context: no-fork
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git-secrets:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[scan|check-release] [--since=SINCE] [--confidence=LEVEL] [options]"
last_modified: 2026-01-09
source: ace-git-secrets
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
    workflow: wfi://git/security-audit
---

read and run `ace-bundle wfi://git/security-audit`
