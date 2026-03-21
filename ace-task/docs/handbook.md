# ace-task Handbook Reference

Complete catalog of skills, workflows, guides, and templates shipped with ace-task.

The `handbook/` directory powers agent-assisted workflows. Skills are invoked by coding agents (Claude Code, Codex, etc.), workflows define the step-by-step processes behind each skill, and guides provide best-practice patterns.

## Skills

ace-task ships 21 skills grouped by domain. Each skill wraps a workflow instruction and can be invoked via `/as-<name>` in agent conversations.

### Task Lifecycle

| Skill | What it does |
|-------|-------------|
| `as-task-draft` | Draft a behavioral specification from a description or idea file (specs only, no code) |
| `as-task-review` | Review draft specs for completeness and promote to pending when ready |
| `as-task-plan` | Generate a just-in-time implementation plan without modifying the task file |
| `as-task-work` | Execute task implementation with context loading and incremental commits |
| `as-task-manage-status` | Manage lifecycle transitions: start, done, undone |
| `as-task-finder` | List, filter, and discover tasks across the project |
| `as-task-reorganize` | Move tasks between folders, convert subtasks, promote to standalone |
| `as-task-review-questions` | Review and answer clarifying questions about a task or implementation |
| `as-task-improve-coverage` | Analyze test coverage gaps and create targeted test tasks |
| `as-task-document-unplanned` | Document significant unplanned work completed outside the task system |

### Bug Handling

| Skill | What it does |
|-------|-------------|
| `as-bug-analyze` | Analyze bugs: identify root cause, verify reproduction, propose fix plan |
| `as-bug-fix` | Execute bug fix: apply changes, create regression tests, verify resolution |

### Ideas

| Skill | What it does |
|-------|-------------|
| `as-idea-capture` | Capture a development idea to a structured idea file with tags |
| `as-idea-capture-features` | Capture application features as structured idea files |
| `as-idea-prioritize` | Prioritize and align ideas with project goals and roadmap |

### Testing

| Skill | What it does |
|-------|-------------|
| `as-test-create-cases` | Generate structured test cases for features and code changes |
| `as-test-fix` | Systematically fix failing automated tests |

### Documentation

| Skill | What it does |
|-------|-------------|
| `as-docs-update-roadmap` | Update project roadmap with current progress and milestones |
| `as-docs-update-usage` | Update usage documentation based on feedback or requirements |

### Retrospectives

| Skill | What it does |
|-------|-------------|
| `as-retro-create` | Create a task retrospective documenting learnings and improvements |
| `as-retro-synthesize` | Synthesize retrospectives into patterns and improvement recommendations |

## Workflow Instructions

Workflows are the step-by-step processes that skills invoke via the `wfi://` protocol. Load any workflow with `ace-bundle wfi://<path>`.

### Task Workflows

| Protocol Path | Description | Invoked by |
|--------------|-------------|------------|
| `wfi://task/draft` | Create behavior-first specifications with vertical slicing | `as-task-draft` |
| `wfi://task/review` | Validate draft specs and promote to pending | `as-task-review` |
| `wfi://task/plan` | Generate JIT implementation plans with caching | `as-task-plan` |
| `wfi://task/work` | Execute task against behavioral spec using pre-loaded plan | `as-task-work` |
| `wfi://task/manage-status` | Handle lifecycle status transitions | `as-task-manage-status` |
| `wfi://task/finder` | Task discovery and filtering | `as-task-finder` |
| `wfi://task/reorganize` | Restructure task hierarchy (promote, demote, convert) | `as-task-reorganize` |
| `wfi://task/review-questions` | Surface and resolve critical validation questions | `as-task-review-questions` |
| `wfi://task/improve-coverage` | Coverage analysis with quality-focused test task creation | `as-task-improve-coverage` |
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
| `roadmap-definition.g.md` | Format requirements and validation criteria for project roadmap documents |
| `project-management/release-codenames.g.md` | Philosophy, naming conventions, and selection process for release codenames |

## Templates

Reusable templates for task creation and planning.

### Task Templates

| Template | Purpose |
|----------|---------|
| `task.draft.template.md` | Behavioral specification (WHAT): user experience, interface contract, success criteria, vertical slices |
| `task.pending.template.md` | Implementation planning (HOW): behavioral context, planning steps, execution steps |

### Planning Templates

| Template | Purpose |
|----------|---------|
| `task.technical-approach.template.md` | Architecture pattern, technology stack, implementation strategy |
| `task.file-modification-checklist.template.md` | Create/Modify/Delete/Rename file changes with impact analysis |
| `task.risk-assessment.template.md` | Risk identification and mitigation planning |
| `task.next-steps.template.md` | Follow-up actions after task completion |
| `task.tool-selection-matrix.template.md` | Tool evaluation and selection criteria |

### Other

| Template | Purpose |
|----------|---------|
| `sample-auth-task.md` | Complete example task for reference |
| `impact-note.template.md` | Impact assessment for changes |
