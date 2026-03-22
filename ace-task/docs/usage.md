---
doc-type: user
purpose: CLI reference for ace-task commands and options
ace-docs:
  last-updated: '2026-03-21'
---

# ace-task CLI Reference

Complete command reference for `ace-task`.

## Installation

```bash
gem install ace-task
```

## Global Options

All commands support these flags:

| Flag | Description |
|------|-------------|
| `-q`, `--quiet` | Suppress non-essential output |
| `-v`, `--verbose` | Show verbose output |
| `-d`, `--debug` | Show debug output |
| `--help` | Show help for any command |

## Commands

### ace-task create TITLE

Create a new task with a B36TS-based ID.

| Option | Alias | Description |
|--------|-------|-------------|
| `--priority` | `-p` | Priority: critical, high, medium, low |
| `--tags` | `-T` | Tags (comma-separated) |
| `--status` | `-s` | Initial status: draft, pending, blocked, ... |
| `--estimate` | `-e` | Effort estimate (e.g. TBD, 2h, 1d) |
| `--child-of` | | Parent task reference (creates subtask) |
| `--in` | `-i` | Target folder (next, maybe) |
| `--dry-run` | `-n` | Preview without writing |
| `--gc` | | Auto-commit changes |

```bash
ace-task create "Fix login bug"
ace-task create "Fix auth" --priority high --tags auth,security
ace-task create "Setup DB" --child-of q7w
ace-task create "Quick task" --in maybe
ace-task create "Draft spec" --status draft --estimate TBD
ace-task create "Preview only" --dry-run
```

### ace-task show REF

Display task details by reference (full ID, short ref, or suffix).

| Option | Description |
|--------|-------------|
| `--path` | Print file path only |
| `--content` | Print raw markdown content |
| `--tree` | Show parent + subtask tree view |

```bash
ace-task show q7w
ace-task show q7w --tree
ace-task show q7w --content
ace-task show q7w --path
```

### ace-task list

List tasks with optional filtering by status, tags, or folder.

**Status legend:** `◇ draft` `○ pending` `▶ in-progress` `✓ done` `✗ blocked` `– skipped` `— cancelled`

**Priority:** `▲ critical` `▲ high` `▼ low` — Subtasks: `›N`

| Option | Alias | Description |
|--------|-------|-------------|
| `--status` | `-s` | Filter by status (pending, in-progress, done, blocked) |
| `--tags` | `-T` | Filter by tags (comma-separated, any match) |
| `--in` | `-i` | Folder: next (default), all, maybe, archive |
| `--root` | `-r` | Override root path (subpath within tasks root) |
| `--filter` | `-f` | Generic filter: key:value (repeatable, supports key:a\|b and key:!value) |
| `--sort` | `-S` | Sort: smart (default), id, priority, created |

```bash
ace-task list
ace-task list --status pending
ace-task list --in all
ace-task list --in maybe
ace-task list --tags ux,design
ace-task list --sort priority
ace-task list --filter status:pending --filter tags:ux|design
```

### ace-task update REF

Update task metadata, move to folders, or reparent tasks.

| Option | Alias | Description |
|--------|-------|-------------|
| `--set` | | Set field: key=value (repeatable) |
| `--add` | | Add to array field: key=value (repeatable) |
| `--remove` | | Remove from array field: key=value (repeatable) |
| `--move-to` | `-m` | Move to folder: archive, maybe, anytime, next |
| `--move-as-child-of` | | Reparent: \<ref\>, 'none' (promote), 'self' (orchestrator) |
| `--position` | `-p` | Set position: first, last, after:\<ref\>, before:\<ref\> |
| `--gc` | | Auto-commit changes |

```bash
ace-task update q7w --set status=done
ace-task update q7w --set status=done,priority=high
ace-task update q7w --add tags=shipped --remove tags=pending-review
ace-task update q7w --set status=done --move-to archive
ace-task update q7w --move-as-child-of abc
ace-task update q7w --move-as-child-of none       # Promote to standalone
ace-task update q7w --position first
ace-task update q7w --position after:abc
```

### ace-task status

Show task status overview with up-next tasks, summary stats, and recently completed.

| Option | Description |
|--------|-------------|
| `--up-next-limit` | Max up-next tasks to show |
| `--recently-done-limit` | Max recently-done tasks to show |

```bash
ace-task status
ace-task status --up-next-limit 5
ace-task status --recently-done-limit 3
```

### ace-task plan REF

Resolve or generate a task implementation plan. Reuses fresh cached plans when available.

| Option | Description |
|--------|-------------|
| `--refresh` | Force plan regeneration |
| `--content` | Print full plan content instead of path |
| `--model` | Provider:model override for plan generation |

```bash
ace-task plan q7w
ace-task plan q7w --refresh
ace-task plan q7w --content
ace-task plan q7w --model gemini:flash-latest
```

For automation, prefer `ace-task plan <ref>` (path output) and read the plan file directly.
Use `--content` only when inline output is needed. If `--content` appears stalled for ~3 minutes, cancel and rerun path mode.

### ace-task doctor

Run health checks on tasks. Validates frontmatter, file structure, and scope/status consistency.

| Option | Alias | Description |
|--------|-------|-------------|
| `--auto-fix` | `-f` | Auto-fix safe issues |
| `--auto-fix-with-agent` | | Auto-fix then launch agent for remaining |
| `--model` | | Provider:model for agent session |
| `--check` | | Run specific check: frontmatter, structure, scope |
| `--dry-run` | `-n` | Preview fixes without applying |
| `--json` | | Output in JSON format |
| `--errors-only` | | Show only errors, not warnings |
| `--no-color` | | Disable colored output |

```bash
ace-task doctor
ace-task doctor --auto-fix
ace-task doctor --auto-fix --dry-run
ace-task doctor --auto-fix-with-agent
ace-task doctor --check frontmatter
ace-task doctor --json
```

## Common Commands

Quick reference for everyday use:

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

## Runtime Help

```bash
ace-task --help
ace-task <command> --help
```
