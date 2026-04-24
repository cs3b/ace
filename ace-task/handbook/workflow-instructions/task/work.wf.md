---
name: task-work
description: Execute task implementation against behavioral spec using pre-loaded
  plan
allowed-tools: Bash, Read, Write
assign:
  sub-steps:
  - onboard-base
  - task-load
  - plan-task
  - work-on-task
  - pre-commit-review
  - verify-test
  - release-minor
  - create-retro
  context: fork
doc-type: workflow
purpose: Execute task implementation from plan with quality gates
ace-docs:
  last-updated: '2026-04-24'
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

### Plan Retrieval Guard

To avoid known `--content` stalls in some environments:
1. Prefer `ace-task plan <ref>` first and read the returned plan path.
2. Use `ace-task plan <ref> --content` only when inline output is explicitly required.
3. If `--content` shows no progress after about 3 minutes, stop it and fall back to:
   - `ace-task plan <ref>` (path mode, reuse cached plan when available)
   - The most recent plan artifact plus current task spec, documented in the step report
4. If stalls repeat, add a follow-up fix task and capture evidence in the retrospective.
5. If implementation reveals the spec or spike contract is materially wrong, stale, or missing an adoption path, stop and either update the spec or add a follow-up task before continuing.

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
- If runtime work materially changes a public contract promised by a spike (flags, naming, fallback behavior, proof surface, ownership boundary), do not silently drift. Update the task/spec or create a follow-up task before release or demo cleanup.
- If implementation reveals the plan targets only a symptom/consumer package for a shared primitive, stop and re-plan at the owner layer before editing. The owner layer is the package that creates, names, persists, routes, or navigates the primitive; adapters and consumers should reuse owner APIs instead of duplicating policy.

**Prior implementation awareness:**
- Before creating new modules, search for existing implementations of the same concern — especially spike or prototype code from prior subtasks
- If a sibling task (same parent, earlier sequence) produced spike code: refactor and promote it rather than creating parallel "production" versions
- Check dependency task reports and the task folder for prior work artifacts (concept inventories, spike reports)
- When plan file paths point to locations where code already exists, integrate rather than duplicate

**Execution discipline:**
- Commit incrementally — one logical step per commit, use `ace-git-commit`
- Test after every change — run `ace-test`; don't accumulate untested code
- If a test fails: fix it before moving to the next step
- If a test failure is undiagnosable after one attempt: stop and report

**Task lifecycle:**
- `draft` status: warn the user that the spec hasn't been reviewed, then continue only with explicit confirmation. In unattended/fork contexts where interactive confirmation is not possible, proceed after marking in-progress -- the assignment creation layer is responsible for blocking draft tasks before they reach this point.
- Mark in-progress before first change, done after last verification
- Never modify task frontmatter directly -- use `ace-task update <ref> --set key=value`
- If the task implements a spike outcome, verify before marking done that deferred gaps and adoption follow-ups are explicit rather than left implicit in release notes or retrospectives.
- If the task is a spike, treat the spec's **Spike Completion Contract** as mandatory. Before marking the spike done, update the parent sync target, update all declared related artifact sync targets, and rerun `as-task-review` on the declared parent task.
- Do not mark a spike done while the parent task or directly affected sibling/public docs still describe the pre-spike contract.

## Code Conventions

- Follow established project patterns -- don't introduce new abstractions or styles
- 2-space indentation (Ruby); keep lines under 120 characters
- Write tests for all new logic; run `ace-test` before committing

## Task Folder

**Documents:** Task-specific docs (reports, findings, usage docs) go in the task folder -- never in the project root.

**Codemods** (scripts that transform files): create in `{task-folder}/codemods/`, never in `bin/`

**Temporary files**: create in the system temp directory (`/tmp/`), never in the project root or task folder

## Done

All plan steps checked, all success criteria pass:

1. **Verify working tree is clean** -- no uncommitted changes:
   ```bash
   git status --short
   ```
   If dirty, commit remaining changes with `ace-git-commit` before proceeding.

2. Mark task done:
   ```bash
   ace-task update <ref> --set status=done
   ```

### Spike-Specific Done Gate

Before a spike task is marked done:
1. Update the spike file with the final outcome, concept inventory, and adopted/rejected/deferred decisions.
2. Update the declared parent/orchestrator task so its contract matches the spike outcome.
3. Update every declared related artifact sync target whose written contract changed:
   - sibling task specs
   - task-local `ux/usage.md`
   - public package docs
4. Run the declared final review command, normally `as-task-review <parent-ref>`.
5. Reflect that parent-review outcome in the task tree before `status=done`.

If any of those steps remain undone, the spike is still in progress even if the analytical work is finished.
