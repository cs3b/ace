---
name: as-git-pr-update
description: Update an attempt-bound forge-neutral pull request
user-invocable: true
source: ace-git
allowed-tools:
  - Bash(ace-assign:*)
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
assign:
  steps:
    - name: update-pr-desc
      description: Update the exact assignment pull request
      produces: [pull-request]
      consumes: [code-changes, execution-attempt]
skill:
  kind: workflow
  execution:
    workflow: wfi://git/pr/update
---

Load and run `ace-bundle wfi://git/pr/update` in the current project, then execute its complete workflow. Use source `bin/ace-*` entrypoints inside the ACE repository.
