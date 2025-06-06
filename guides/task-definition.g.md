<!-- markdownlint-disable -->
# 📑 Writing Clear, Actionable Dev Tasks

## A playbook for documentation‑oriented tickets, with a complete worked example

## Introduction & Goal

This guide provides a structured approach and template for writing effective development tasks, particularly those
focused on documentation changes within this toolkit. Following these steps ensures tasks are clear, scoped correctly,
actionable, and easily understood by both human developers and AI agents contributing to the project. The goal is to
minimize ambiguity and streamline the process of defining and executing documentation work.

---

## 0. Directory Audit Step ✅

**Always start by discovering what actually exists in the repo.**

1. Run a tree or ls command (exclude `node_modules`, `vendor`, etc.).
2. Copy the relevant excerpt into the ticket.
3. From that listing, build the deliverable manifest.

> **Tip:**
> • If you don’t have repo access, create a tiny *pre‑ticket* titled “Generate Guide‑Audit Manifest”.
> • Commit the tree output as a comment or markdown file, then reference it in the main ticket.

Example audit snippet to embed:

```bash
tree -L 2 docs-dev/guides | sed 's/^/    /'

guides
├── coding-standards.md
├── error-handling.md
├── performance.md
├── testing.md
└── ...
```

---

## 1. Anatomy of a Great Task

| Section | Purpose | Key Questions |
|---------|---------|---------------|
| **Front‑matter** | Helps tooling & humans filter | id (use `bin/tnid` to generate), status, priority, estimate, dependencies |
| **Objective / Problem** | *Why* are we doing this? | What pain are we fixing? |
| **Directory Audit (0)** | Source‑of‑truth for scope | Did we include the current tree? |
| **Scope of Work** | *What* to touch | Which guides/folders? |
| **Deliverables / Manifest** | Exact files to create / modify / delete | Could a newcomer do it with just this? |
| **Phases** | Bite‑sized plan | Audit → Extract → Refactor → Index |
| **Implementation Plan** | Divided into Planning Steps (`* [ ]`) for analysis/design and Execution Steps (`- [ ]`) for implementation actions. Consider embedding automated test/verification steps directly. | |
| **Acceptance Criteria** | Definition of Done | Check‑list style `[ ]`. **Can include references to automated checks defined in the Implementation Plan's Planning and Execution sections or be high-level checks themselves.** |
| **Out of Scope** | Prevent scope creep | What must *not* be touched? |
| **References & Risks** | Links to style guides, ADRs, **testing standards (like [Embedding Tests Guide](docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md))**; mitigations | Any scripts to run? **Use links relative to the project root (e.g., `docs-dev/guides/some-guide.md`), not relative to the current file (`../guides/some-guide.md`)** |

---

## 2. Task Template

A re-usable Markdown template for tasks is available at:
[`docs-dev/guides/draft-release/v.x.x.x/tasks/_template.md`](./draft-release/v.x.x.x/tasks/_template.md)

This template includes all the standard sections discussed in "Anatomy of a Great Task". You should copy this template and fill it out for each new task. Remember to use `bin/tnid` to generate the task ID.

### Planning vs. Execution Steps

The template's Implementation Plan section is divided into two subsections to support different phases of task work:

- **Planning Steps (`* [ ]`)**: Optional but recommended for complex tasks. Use asterisk markers for research, analysis, and design activities that help clarify the approach before implementation begins. These steps are typically worked on during task review or initial planning phases.

- **Execution Steps (`- [ ]`)**: Required section. Use hyphen markers for concrete implementation actions that modify code, create files, or change the system state. These steps are the actual work performed when implementing the task.

This distinction supports workflow separation where review/planning phases focus on Planning Steps, while implementation phases focus on Execution Steps. Both sections can include embedded tests as guardrails.

> **Tip: Generating Task IDs with `bin/tnid`**
> Always use the `bin/tnid` command (run from the project root)
> to generate the task ID for the `id` field in the front-matter.
> This script ensures the ID is unique, correctly formatted, and uses the next sequential
> number for the current release, as per the conventions in
> `docs-dev/guides/project-management.md#task-id-convention`.

---

## 3. **Full Worked Example**

A full worked example of a task, "Tailor Guides to Tech Stack," has been moved to a separate file:
[`docs-dev/guides/draft-release/v.x.x.x/tasks/_example.md`](./draft-release/v.x.x.x/tasks/_example.md)

This example demonstrates how to fill out the template for a real-world scenario.

---

### 4. Planning vs. Execution Examples

#### Simple Task (Execution Steps Only)

For straightforward tasks that don't require research or design, you can skip Planning Steps:

```markdown
## Implementation Plan

### Execution Steps
- [ ] Update the configuration file with new API endpoint
- [ ] Test the connection to verify it works
  > TEST: API Connection Check
  >   Type: Action Validation
  >   Assert: The new API endpoint responds with status 200
  >   Command: bin/test --check-api-connection
- [ ] Update documentation with the new endpoint URL
```

#### Complex Task (Both Planning and Execution)

For complex tasks requiring analysis or design decisions, include both sections:

```markdown
## Implementation Plan

### Planning Steps
* [ ] Research existing authentication patterns in the codebase
  > TEST: Pattern Analysis Complete
  >   Type: Pre-condition Check
  >   Assert: Current auth patterns are documented and understood
  >   Command: bin/test --check-analysis-exists auth-patterns.md
* [ ] Design new OAuth integration approach considering security requirements
* [ ] Plan database schema changes needed for user sessions

### Execution Steps
- [ ] Create new OAuth service class
- [ ] Implement session management database tables
  > TEST: Schema Migration
  >   Type: Action Validation
  >   Assert: Database migration runs successfully
  >   Command: bin/test --check-migration-success
- [ ] Update user authentication flow
- [ ] Add comprehensive tests for OAuth integration
```

### 5. Quick Checklist 🚦

1. Is the **Directory Audit** present?
2. Could a newcomer complete the work using only the manifest?
3. Do the Acceptance Criteria read like QA steps?
4. Is scope creep prevented by an **Out of Scope** section?
5. Are references & scripts one click away?
6. Are Planning Steps used for complex tasks requiring analysis/design?
7. Do visual markers distinguish planning (`* [ ]`) from execution (`- [ ]`) steps?

Tick them all → merge the ticket.
