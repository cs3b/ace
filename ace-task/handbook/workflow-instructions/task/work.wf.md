---
name: task-work
description: Execute task implementation against behavioral spec using pre-loaded plan
assign:
  sub-steps:
    - onboard-base
    - task-load
    - plan-task
    - work-on-task
    - pre-commit-review
    - verify-test
    - release-minor
  context: fork
doc-type: workflow
purpose: Execute task implementation from plan with quality gates
ace-docs:
  last-updated: '2026-03-04'
---

# Work on Task

## Start State

You have context sources already loaded from prior sub-steps:
- **Project** (`project-base`) — vision, architecture, CLI tools, conventions, and repo-level onboarding context
- **Task** (`ace-bundle task://<ref>`) — behavioral spec, success criteria, interface contract
- **Plan** (`ace-task plan <ref> --content`) — implementation checklist with steps, file paths, verification commands
- **Pre-commit review** runs after implementation and before verification when enabled
- **Verification** runs in-tree per-package only via `verify-test` before subtree release; no full suite is executed at this level

If the plan is missing or stale: run `ace-task plan <ref> --content` and wait before proceeding.

## Primary Directive

Work through the plan checklist, step by step:
1. Mark task in-progress: `ace-task update <ref> --set status=in-progress`
2. For each plan step: implement → verify → commit → mark corresponding task checkbox done
   - Plan steps include `path:line` anchors to spec sections — when satisfied, mark the corresponding Success Criteria or Deliverables checkbox as `[x]`
3. Mark task done: `ace-task update <ref> --set status=done`

## Principles

**Spec adherence:**
- Success Criteria are acceptance tests — every criterion must pass before done
- Interface Contract defines inputs, outputs, and boundaries — don't invent outside it
- If the spec says X, implement X — don't gold-plate, don't simplify away requirements
- If spec and plan conflict, spec wins — the plan is a HOW, not a WHAT
- If the spec is ambiguous or incomplete: stop and ask, don't assume

**Execution discipline:**
- Commit incrementally — one logical step per commit, use `ace-git-commit`
- Test after every change — run `ace-test`; don't accumulate untested code
- If a test fails: fix it before moving to the next step
- If a test failure is undiagnosable after one attempt: stop and report

**Task lifecycle:**
- `draft` status: warn the user that the spec hasn't been reviewed, then continue only with explicit confirmation. In unattended/fork contexts where interactive confirmation is not possible, proceed after marking in-progress — the assignment creation layer is responsible for blocking draft tasks before they reach this point.
- Mark in-progress before first change, done after last verification
- Never modify task frontmatter directly — use `ace-task update <ref> --set key=value`

## Code Conventions

- Follow established project patterns — don't introduce new abstractions or styles
- 2-space indentation (Ruby); keep lines under 120 characters
- Write tests for all new logic; run `ace-test` before committing

## Task Folder

**Documents:** Task-specific docs (reports, findings, usage docs) go in the task folder — never in the project root.

**Codemods** (scripts that transform files): create in `{task-folder}/codemods/`, never in `bin/`

**Temporary files**: create in the system temp directory (`/tmp/`), never in the project root or task folder

## Done

All plan steps checked, all success criteria pass:

```bash
ace-task update <ref> --set status=done
```
