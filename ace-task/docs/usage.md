---
doc-type: user
purpose: CLI reference for ace-task commands and options
ace-docs:
  last-updated: '2026-04-13'
  last-checked: '2026-04-13'
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

## Linked Issues

Local tasks work without a forge configuration, binary, credentials, or network.
When a task is linked, its frontmatter stores one exact named-server issue
identity. Task status drives the linked issue's open or closed state.

Create a linked task with `--issue NUMBER_OR_URL`. Select a named server with
`--server NAME`, use `--default-server`, or let ACE match the configured Git
remote. A URL must match exactly one configured server and cannot contradict
an explicit selection. Existing links always replay against their stored
server identity, even if the configured default changes.

Example task frontmatter pattern:

```yaml
remote_issue:
  server_name: forgejo-lab
  provider: forgejo
  repository_url: https://forge.example.com/owner/repo
  number: 276
  url: https://forge.example.com/owner/repo/issues/276
issue_sync_pending: true
```

`issue_sync_pending` appears when a linked change or clear has not completed.
For a failed clear, `issue_sync_operation: clear` records the operation so
`issue-sync --pending` resumes cleanup. The exact `remote_issue` identity
remains available for replay.

### ace-task create TITLE

Create a new task with a B36TS-based ID.

The task title can be provided as the positional `TITLE` argument or with
`--title TITLE`. Provide only one title form.

If the generated task ID collides with an existing persisted task, `ace-task create`
automatically retries with a new ID. If it cannot obtain a unique ID within the retry
budget, the command fails cleanly without leaving behind a partial task artifact.

| Option | Alias | Description |
|--------|-------|-------------|
| `--title` | | Task title (alternative to positional `TITLE`) |
| `--priority` | `-p` | Priority: critical, high, medium, low |
| `--tags` | `-T` | Tags (comma-separated) |
| `--status` | `-s` | Initial status: draft, pending, blocked, ... |
| `--estimate` | `-e` | Effort estimate (e.g. TBD, 2h, 1d) |
| `--issue` | | Issue number or URL to link |
| `--server` | | Named forge server for the issue |
| `--default-server` | | Select the configured default forge server |
| `--child-of` | | Parent task reference (creates subtask) |
| `--in` | `-i` | Target folder (next, maybe) |
| `--dry-run` | `-n` | Preview without writing |
| `--gc` | | Auto-commit changes |

```bash
ace-task create "Fix login bug"
ace-task create --title "Fix login bug"
ace-task create "Fix auth" --priority high --tags auth,security
ace-task create "Setup DB" --child-of q7w
ace-task create "Quick task" --in maybe
ace-task create "Draft spec" --status draft --estimate TBD
ace-task create "Track issue" --issue 276 --default-server
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

**Priority:** `▲ critical` `▲ high` `▼ low` -- Subtasks: `›N`

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
| `--timeout` | LLM request timeout in seconds for plan generation |

```bash
ace-task plan q7w
ace-task plan q7w --refresh
ace-task plan q7w --content
ace-task plan q7w --timeout 30
ace-task plan q7w --model gemini:flash-latest
```

By default, `ace-task plan` uses `role:planner`. Override with `--model` when you need a specific provider/model.

For automation, prefer `ace-task plan <ref>` (path output) and read the plan file directly.
For E2E validation, path mode is the recommended contract because it verifies
real plan artifact creation without depending on inline LLM output rendering.
Use `--content` only when inline output is needed. If `--content` appears stalled for ~3 minutes, cancel and rerun path mode.

### ace-task issue-link REF

Link one existing task to an authoritative issue or clear its current link.
Explicit linking checks that the issue is reachable and not owned by another
ACE task before changing local metadata. Repeating the same link succeeds;
replacing it requires a successful clear first. Clear removes ACE tracking
content and label without changing the issue state. If cleanup fails, the link
and pending flag remain for recovery.

```bash
ace-task issue-link q7w --issue 42 --server forgejo-lab
# Linked 8pp.t.q7w to https://forge.example.com/owner/repo/issues/42
ace-task issue-link q7w --clear
# Cleared issue link for 8pp.t.q7w
```

### ace-task issue-sync REF|--all|--pending

Synchronize the stored exact issue identity. `--all` and `--pending` cannot
combine with each other or a reference. Bulk sync continues independent tasks;
any failure or unresolved pending result returns nonzero with per-task identity
and error. An empty pending set succeeds with zero counts.

| Option | Description |
|--------|-------------|
| `--all` | Sync every linked task |
| `--pending` | Replay tasks with deferred synchronization |

```bash
ace-task issue-sync q7w
# Issue sync: synced 1, failed 0, pending 0, skipped 0
ace-task issue-sync --pending
# Issue sync: synced 0, failed 0, pending 0, skipped 0
```

If sync reports a changed server identity, restore the original server
configuration or explicitly clear the link after remote cleanup succeeds.
ACE never switches to the new default as a fallback.

### ace-task doctor

Run health checks on tasks. Validates frontmatter, file structure, and scope/status consistency.

Duplicate persisted task IDs are reported as errors, including subtask collisions.
`ace-task doctor --check frontmatter` also fails when duplicate IDs are present in
task frontmatter.

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
