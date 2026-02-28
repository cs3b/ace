# ace-task Usage

Task management CLI using globally-unique b36ts-based IDs and flat directory structure.

## Commands

### create

Create a new task.

```bash
ace-task create "Fix login bug"
# Created task 8pp.t.q7w
# Path: .ace-tasks/8pp.t.q7w-fix-login/8pp.t.q7w-fix-login.s.md

ace-task create "Fix auth bug" --priority high --tags auth,security --in next
ace-task create "Setup DB" --child-of t.q7w      # Subtask (becomes 8pp.t.q7w.a)
ace-task create "Preview only" --dry-run          # Show without writing
```

**Options:**
- `--priority` — `critical`, `high`, `medium` (default), `low`
- `--tags` — comma-separated list
- `--child-of REF` — create as subtask of parent (max 36 subtasks per parent: a–z, then 0–9)
- `--in FOLDER` — place in special folder (e.g. `--in next` → `_next/`)
- `--dry-run` — preview what would be created without writing

**Output:** `Created task 8pp.t.q7w`

---

### show

Display a task by ID or shortcut.

```bash
ace-task show q7w             # Formatted display
ace-task show q7w --path      # Output file path only
ace-task show q7w --content   # Raw markdown content
ace-task show q7w --tree      # Parent + subtask tree view
```

**Shortcut forms accepted:**
- Full ID: `8pp.t.q7w`
- Short prefix: `t.q7w`
- Suffix only: `q7w`
- Subtask: `8pp.t.q7w.a`

**Ambiguity:** If multiple tasks share a suffix, the most recent (by `mtime`) is used and a warning is printed to `stderr`:
```
Note: 2 tasks match 'q7w'. Using 8pp.t.q7w (2026-02-26). Also: 7zz.t.q7w (2025-11-15).
```

---

### list

List tasks with optional filters.

```bash
ace-task list                       # All tasks (flat, recursive)
ace-task list --status pending
ace-task list --priority high
ace-task list --tags urgent
ace-task list --in maybe            # Tasks inside _maybe/
ace-task list --root sprint-3       # Tasks under custom subpath
```

**Options:**
- `--status` — `pending`, `in-progress`, `done`, `blocked`, `draft`, `skipped`, `cancelled`
- `--priority` — `critical`, `high`, `medium`, `low`
- `--tags` — filter by tag
- `--in FOLDER` — filter by special folder
- `--root PATH` — scan a subpath of `.ace-tasks/`

Scans `.ace-tasks/` recursively at any depth, treating all nesting as a flat list.

---

### move

Move a task to a different folder.

```bash
ace-task move q7w --to archive      # → .ace-tasks/_archive/
ace-task move q7w --to maybe        # → .ace-tasks/_maybe/
ace-task move q7w --to sprint-3     # → .ace-tasks/sprint-3/ (created if missing)
```

Short names are auto-mapped to `_`-prefixed special folders:
`archive` → `_archive`, `maybe` → `_maybe`, `anytime` → `_anytime`, `next` → `_next`

Custom paths are created automatically if they don't exist.

---

### update

Modify task frontmatter fields.

```bash
ace-task update q7w --set status=done
ace-task update q7w --set status=done --set priority=high   # Multiple --set
ace-task update q7w --add tags=shipped                       # Append to array
ace-task update q7w --add tags=a --add tags=b               # Multiple --add
ace-task update q7w --remove deps=8pp.t.xyz                 # Remove from array
ace-task update q7w --set worktree.branch=my-branch         # Nested key (dot notation)
```

**Operations:**
- `--set K=V` — replace scalar value or create nested path
- `--add K=V` — append to array (creates array if field was scalar)
- `--remove K=V` — remove value from array

**Errors:**
- `Error: Cannot --remove from non-array field 'status'`

---

## ID Format

Tasks use a split b36ts ID: `xxx.t.yyy` (e.g. `8pp.t.q7w`)

Subtasks append a single base36 char: `8pp.t.q7w.a`, `.b`, `.c` … `.z`, `.0` … `.9`
Maximum **36 subtasks** per parent. Exceeding this raises:
```
Error: Maximum of 36 subtasks reached for this parent. Cannot allocate beyond '9'.
```

---

## Directory Structure

```
.ace-tasks/
  8pp.t.q7w-fix-login/
    8pp.t.q7w-fix-login.s.md        # Task spec file
    8pp.t.q7w.a-setup-database.s.md # Subtask (co-located in parent folder)
  _archive/
    ...
  _maybe/
    ...
  sprint-3/
    ...
```

---

## Frontmatter Schema

```yaml
---
id: 8pp.t.q7w
status: pending          # pending | in-progress | done | blocked | draft | skipped | cancelled
priority: medium         # critical | high | medium | low
created_at: 2026-02-26 19:15:00
estimate:
dependencies: []
tags: []
---
```

Subtasks add `parent: 8pp.t.q7w`.
Orchestrators add `subtasks: [8pp.t.q7w.a, 8pp.t.q7w.b]`.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (see message) |
| 130 | Interrupted (SIGINT) |

---

## Error Reference

| Error | Cause |
|-------|-------|
| `No task matching 'xyz'` | Reference not found — run `ace-task list` |
| `Cannot --remove from non-array field` | Field is scalar, not array |
| `Maximum of 36 subtasks reached` | Parent already has 36 subtasks |
| `Only one level of subtask nesting allowed` | Subtask-of-subtask attempted |
