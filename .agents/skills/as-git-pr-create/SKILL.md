---
name: as-git-pr-create
description: Create an attempt-bound forge-neutral pull request
user-invocable: true
source: ace-git
allowed-tools:
- Bash(ace-assign:*)
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Read
assign:
  steps:
  - name: create-pr
    description: Create the exact assignment pull request
    produces:
    - pull-request
    consumes:
    - code-changes
    - execution-attempt
skill:
  kind: workflow
  execution:
    workflow: wfi://git/pr/create
---

Load and run `ace-bundle wfi://git/pr/create` in the current project, then execute its complete workflow. Use source `bin/ace-*` entrypoints inside the ACE repository.
