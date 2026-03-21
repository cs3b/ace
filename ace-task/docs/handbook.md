---
doc-type: user
purpose: Handbooks index for ace-task workflows, guides, and task management structure
ace-docs:
  last-updated: '2026-03-21'
---

# ace-task Handbook Reference

Complete catalog of skills, workflows, guides, and templates shipped with ace-task.

The `handbook/` directory powers agent-assisted workflows. Skills are invoked by coding agents (Claude Code, Codex, etc.), workflows define the step-by-step processes behind each skill, and guides provide best-practice patterns.

## Skills

ace-task ships 12 skills for task and bug management. Each skill wraps a workflow instruction and can be invoked via `/as-<name>` in agent conversations.

### Task Lifecycle

| Skill | What it does |
|-------|-------------|
| `as-task-draft` | Draft a behavioral specification from a description or idea file (specs only, no code) |
| `as-task-review` | Review draft specs for completeness and promote to pending when ready |
| `as-task-plan` | Generate a just-in-time implementation plan without modifying the task file |
| `as-task-work` | Execute task implementation with context loading and incremental commits |
| `as-task-update` | Update task metadata, status, position, or location, including task hierarchy operations |
| `as-task-finder` | List, filter, and discover tasks across the project |
| `as-task-review-questions` | Review and answer clarifying questions about a task or implementation |
| `as-task-document-unplanned` | Document significant unplanned work completed outside the task system |

### Bug Handling

| Skill | What it does |
|-------|-------------|
| `as-bug-analyze` | Analyze bugs: identify root cause, verify reproduction, propose fix plan |
| `as-bug-fix` | Execute bug fix: apply changes, create regression tests, verify resolution |

## Workflow Instructions

Workflows are the step-by-step processes that skills invoke via the `wfi://` protocol. Load any workflow with `ace-bundle wfi://<path>`.

### Task Workflows

| Protocol Path | Description | Invoked by |
|--------------|-------------|------------|
| `wfi://task/draft` | Create behavior-first specifications with vertical slicing | `as-task-draft` |
| `wfi://task/review` | Validate draft specs and promote to pending | `as-task-review` |
| `wfi://task/plan` | Generate JIT implementation plans with caching | `as-task-plan` |
| `wfi://task/work` | Execute task against behavioral spec using pre-loaded plan | `as-task-work` |
| `wfi://task/update` | Handle lifecycle status transitions | `as-task-update` |
| `wfi://task/finder` | Task discovery and filtering | `as-task-finder` |
| `wfi://task/review-questions` | Surface and resolve critical validation questions | `as-task-review-questions` |
| `wfi://task/document-unplanned` | Post-hoc documentation of unplanned work | `as-task-document-unplanned` |
| `wfi://task/review-plan` | Adversarial quality gate for implementation plans | — |
| `wfi://task/review-work` | Adversarial quality gate for execution output | — |

### Bug Workflows

| Protocol Path | Description | Invoked by |
|--------------|-------------|------------|
| `wfi://bug/analyze` | Systematic bug analysis: root cause, reproduction, test proposals | `as-bug-analyze` |
| `wfi://bug/fix` | Execute fix: apply changes, regression tests, verify resolution | `as-bug-fix` |

## Guides

Development guides provide best-practice patterns and format specifications.

| Guide | Purpose |
|-------|---------|
| `task-definition.g.md` | Playbook for writing clear, actionable dev tasks — anatomy, templates, planning vs execution steps |

## Templates

Reusable templates in `handbook/templates/task/`, referenced via `tmpl://task/<name>` protocol.

| Template | Protocol | Purpose |
|----------|----------|---------|
| `draft.template.md` | `tmpl://task/draft` | Behavioral specification (WHAT): user experience, interface contract, success criteria, vertical slices |
| `technical-approach.template.md` | `tmpl://task/technical-approach` | Architecture pattern, technology stack, implementation strategy |
| `file-modification-checklist.template.md` | `tmpl://task/file-modification-checklist` | Create/Modify/Delete/Rename file changes with impact analysis |
