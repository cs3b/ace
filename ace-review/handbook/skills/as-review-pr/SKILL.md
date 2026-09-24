---
name: as-review-pr
description: Review PR through verified findings and converging rounds
# bundle: wfi://review/pr
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-review:*)
  - Bash(ace-bundle:*)
  - Read
  - TodoWrite
argument-hint: "[#]"
last_modified: 2026-01-10
source: ace-review
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
assign:
  steps:
    - name: review-pr
      description: Review and resolve PR feedback through converging rounds
      prerequisites:
        - name: create-pr
          strength: required
          reason: "Must have a PR to review"
      produces: [review-feedback]
      consumes: [pull-request]
      when_to_skip:
        - "No PR exists yet"
      effort: medium
      tags: [review, quality]
skill:
  kind: workflow
  execution:
    workflow: wfi://review/pr
---

Load and run `ace-bundle wfi://review/pr` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
