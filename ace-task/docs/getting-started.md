---
doc-type: user
purpose: Quickstart guide for installing and using ace-task workflows
ace-docs:
  last-updated: '2026-03-21'
---

# Getting Started with ace-task

End-to-end tutorial from installation to productive task management.

## Prerequisites

- Ruby installed
- `gem install ace-task`

## 1) Create your first task

```bash
ace-task create "Rewrite onboarding docs"
```

This creates a markdown task spec with a compact B36TS ID (e.g. `8q4.t.abc`), stored in your `.ace-tasks/` directory.

Add options to set priority, tags, and target folder:

```bash
ace-task create "Fix auth flow" --priority high --tags auth,security
ace-task create "Backlog idea" --in maybe
```

Create subtasks to break work into slices:

```bash
ace-task create "Draft quick-start outline" --child-of abc
```

## 2) List and find tasks

```bash
ace-task list
```

Shows active tasks in the root folder. Filter by status or folder:

```bash
ace-task list --status pending
ace-task list --in all                   # Include archive, maybe
ace-task list --in maybe
ace-task list --tags ux,design
ace-task list --sort priority
```

**Status legend:** `◇ draft` `○ pending` `▶ in-progress` `✓ done` `✗ blocked` `– skipped` `— cancelled`

## 3) View a task

```bash
ace-task show abc
```

See the full task spec with metadata. Use flags for different views:

```bash
ace-task show abc --tree              # Parent + subtask tree
ace-task show abc --content           # Raw markdown content
ace-task show abc --path              # File path only
```

## 4) Update task metadata

Use `--set` for scalar fields and `--add`/`--remove` for array fields:

```bash
ace-task update abc --set status=in-progress
ace-task update abc --set priority=high --add tags=docs
ace-task update abc --set status=done --move-to archive
```

Move tasks between folders or reparent them:

```bash
ace-task update abc --move-to maybe
ace-task update abc.1 --move-as-child-of none    # Promote to standalone
ace-task update abc --position first              # Pin to top of list
```

## 5) Generate an implementation plan

```bash
ace-task plan abc
```

Converts the behavioral spec into an implementation checklist using an LLM. Plans are cached and reused when fresh:

```bash
ace-task plan abc --refresh            # Force regeneration
ace-task plan abc --content            # Print full plan inline
```

## 6) Keep task health in check

```bash
ace-task doctor
```

Validates frontmatter, file structure, and scope/status consistency. Auto-fix safe issues:

```bash
ace-task doctor --auto-fix
ace-task doctor --auto-fix --dry-run   # Preview without applying
```

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-task create "..."` | Create a new task |
| `ace-task show <ref> --tree` | View task with subtask tree |
| `ace-task list --status pending` | Filter tasks by status |
| `ace-task update <ref> --set status=done` | Mark a task done |
| `ace-task update <ref> --move-to archive` | Archive a completed task |
| `ace-task status` | Dashboard: up-next + recent completions |
| `ace-task plan <ref>` | Generate implementation plan |
| `ace-task doctor` | Run health checks |

## What to try next

- [Usage Guide](usage.md) — full command reference with all options
- [Handbook Reference](handbook.md) — skills, workflows, guides, and templates
- Runtime help: `ace-task --help` / `ace-task <command> --help`
