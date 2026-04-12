---
name: as-retro-synthesize
description: Synthesize retrospectives into ranked, repo-validated learnings and unresolved improvement themes
# bundle: wfi://retro/synthesize
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-retro:*)
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Grep
argument-hint: "[retro-ref ...] [--oldest N]"
last_modified: 2026-04-12
source: ace-retro
skill:
  kind: workflow
  execution:
    workflow: wfi://retro/synthesize

---

## Arguments

Use the skill `argument-hint` values as the explicit inputs for this skill.

## Variables

- ARGUMENTS

## Execution

- You are working in the current project.
- Run `ace-bundle wfi://retro/synthesize` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this project.
- Follow the workflow as the source of truth.
- If explicit retro refs are provided, synthesize exactly those refs.
- If no refs are provided, default to the oldest active retros using the workflow's deterministic ordering rules.
- When inputs include older synthesis retros, dedupe evidence by original source retro IDs rather than double-counting nested syntheses.
- Validate major themes against the current repo so the synthesis distinguishes `addressed`, `partial`, and `open` findings.
- Always produce a new synthesis retro; do not stop at a chat-only summary.
- Archive only the successfully processed source retros after the new synthesis is complete.
