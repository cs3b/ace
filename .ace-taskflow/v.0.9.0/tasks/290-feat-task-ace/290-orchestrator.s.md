---
id: v.0.9.0+task.290
status: in-progress
priority: high
estimate: TBD
dependencies: []
subtasks:
- v.0.9.0+task.290.01
- v.0.9.0+task.290.02
- v.0.9.0+task.290.03
- v.0.9.0+task.290.04
worktree:
  branch: 290-create-ace-task-gem-with-b36ts-based-task-management
  path: "../ace-task.290"
  created_at: '2026-03-01 14:25:56'
  updated_at: '2026-03-01 14:25:56'
  target_branch: main
---

# Create ace-task Gem with B36TS-Based Task Management

## Objective

Replace ace-taskflow's task management with a standalone `ace-task` gem that uses globally-unique b36ts-based IDs, flat directory structure (no releases), and generic field update commands. This also creates the shared `ace-support-items` gem that both ace-task and ace-idea depend on.

Origin: idea `8ppq7w-taskflow-add` — "Refactor ace-taskflow: Simplify Release Model and Archive Structure"

## Behavioral Specification

### User Experience
- **Input**: Task titles, shortcut references (`q7w`, `t.q7w`, `8pp.t.q7w`), field updates (`--set status=done`), folder targets (`--to archive`)
- **Process**: Tasks stored in `.ace-tasks/` with b36ts split IDs (`xxx.t.yyy`). Five CLI commands replace all specialized commands. Recursive flat scanning treats any nesting as a single list.
- **Output**: Task spec files (`.s.md`), formatted terminal output for list/show, confirmation messages for create/move/update

### Expected Behavior

Users manage tasks through 5 commands — create, show, list, move, update — with no release scoping:

1. **Create**: Generates a 6-char b36ts ID, splits into `xxx.t.yyy` format, creates `{id}-{slug}/` folder with `.s.md` spec file. Subtasks created with `--child-of` get IDs like `xxx.t.yyy.a` (maximum of 36 subtasks per level: a-z, then 0-9).
2. **Show**: Resolves shortcut references by scanning all directories, picking the most recent match (by `mtime`), and warning about ambiguities via `stderr`.
3. **List**: Recursively scans `.ace-tasks/` treating all nested structures as a flat list. Filters by `--status`, `--priority`, `--tags`, `--in` (special folder), `--root` (subpath).
4. **Move**: Physically relocates task folder between special folders (`_archive`, `_maybe`, `_anytime`, `_next`) or any path. Short names auto-map to `_` prefixed folders. Automatically creates the target directory if it does not exist.
5. **Update**: Modifies frontmatter with `--set key=value` (replace), `--add key=value` (append to array), `--remove key=value` (remove from array). Supports nested keys via dot notation.

No more: done, undone, start, defer, park, unpark, reschedule, or --release flag.

### Interface Contract

```bash
# Create task
ace-task create "Fix login bug" [--priority high] [--tags auth,urgent] [--child-of t.q7w] [--in next] [--dry-run]
# Output: Created task 8pp.t.q7w
# Output: Path: .ace-tasks/8pp.t.q7w-fix-login/8pp.t.q7w-fix-login.s.md

# Show task (with shortcut resolution)
ace-task show q7w [--path | --content | --tree]
# Output: task details (formatted), or file path (--path), or raw content (--content)
# If ambiguous: "Note: 2 tasks match 'q7w'. Using 8pp.t.q7w (2026-02-26). Also: 7zz.t.q7w (2025-11-15)."

# List tasks
ace-task list [--status pending] [--priority high] [--tags auth] [--in maybe] [--root custom/path]
# Output: formatted list of matching tasks

# Move task
ace-task move q7w --to archive
# Output: Moved 8pp.t.q7w-fix-login to _archive/

# Update frontmatter
ace-task update q7w --set status=done --set priority=high
ace-task update q7w --add tags=shipped --add deps=8pp.t.abc
ace-task update q7w --remove deps=8pp.t.xyz
ace-task update q7w --set worktree.branch=my-branch    # Nested via dot notation
```

**Error Handling:**
- Unknown reference: `Error: No task matching 'xyz'. Run 'ace-task list' to see available tasks.`
- Ambiguous reference: Show all matches, use most recent by `mtime`, proceed with warning to `stderr`
- Move target doesn't exist: Create target folder automatically
- Invalid field update: `Error: Cannot --remove from non-array field 'status'`
- Subtask limit exceeded: `Error: Maximum of 36 subtasks reached for this parent. Cannot allocate beyond '9'.`

**Edge Cases:**
- Empty `.ace-tasks/`: `ace-task list` returns empty, `ace-task create` creates root dir
- Deeply nested user folders: Scanner finds tasks at any depth
- Subtask of subtask attempt: Error — only one level of nesting allowed

### Success Criteria

- [ ] `ace-task create` generates valid b36ts split ID (`xxx.t.yyy`) and creates correct folder/file structure
- [ ] `ace-task show` resolves all shortcut forms: full ID, `t.yyy`, suffix `yyy`
- [ ] `ace-task list` recursively scans all nesting depths as flat list with correct filtering
- [ ] `ace-task move` physically relocates folders, auto-maps short names to `_` prefixed folders, and creates missing dirs
- [ ] `ace-task update` correctly handles `--set` (scalar), `--add` (array append), `--remove` (array remove), and nested dot keys
- [ ] Subtask creation (`--child-of`) allocates single base36 char (a-z then 0-9, max 36) and places file in parent folder
- [ ] Subtask limit enforced: error raised on 37th subtask attempt
- [ ] All tests pass: `ace-test ace-support-items && ace-test ace-task`
- [ ] No dependency on ace-taskflow — fully standalone

### Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| b36ts split ID (xxx.t.yyy) | 290.01 | — | KEPT |
| ace-support-items gem | 290.01 | — | KEPT |
| ItemIdFormatter/Parser | 290.01 | — | KEPT |
| DirectoryScanner + ShortcutResolver | 290.01 | — | KEPT |
| FieldUpdater (--set/--add/--remove) | 290.02 | — | KEPT |
| FolderMover | 290.02 | — | KEPT |
| TaskManager organism | 290.02 | — | KEPT |
| 5 CLI commands | 290.03 | — | KEPT |
| TaskDoctor (health checks + auto-fix) | 290.04 | — | KEPT |
| Sequential numeric IDs | — | 290.01 | REMOVED (from ace-taskflow) |
| Release-scoped directories | — | 290.01 | REMOVED |
| done/undone/start/defer commands | — | 290.03 | REMOVED |

## Scope of Work

- **Gem 1**: `ace-support-items` — shared ID formatting, directory scanning, shortcut resolution, field updates, folder moves
- **Gem 2**: `ace-task` — task-specific atoms/molecules/organisms/models + CLI
- **Handbook migration**: Task workflows (16 files), bug workflows (2 files), task templates (9 files), guides (3 files) — all move to ace-task
- **Out of scope**: Migration from ace-taskflow, ace-idea gem (separate task 291), retrospectives, reviews

**Note**: ace-taskflow will be **deleted** after all domain extractions complete (tasks 290, 291, 292). Each extracted gem must be fully independent — own doctor, own config loading, own filtering. Shared utilities from ace-taskflow are duplicated into each gem rather than centralized.

## Implementation Guidance (from task 291 retro)

### Pre-implementation validation
Run `ace-sim validate-task` on 290.01 before starting implementation. If simulation surfaces upstream bugs, fix first and document in retro. (Lesson from 291: ace-sim session found ace-llm coercion bug that blocked progress.)

### Migration warning
From 291.04 retro: migration is always more complex than expected. Task migration (future task 293) will face 625+ files, ID format conversion, and orchestrator/subtask relationship re-encoding. Do NOT design TaskManager API to accommodate migration — migration is 293's problem as a codemod script.

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/_maybe/8ppq7w-taskflow-add/idea.idea.s.md`
- Plan: `/home/mc/.claude/plans/eventual-dazzling-pixel.md`
- Key deps: ace-b36ts, ace-support-config, ace-support-core, ace-support-markdown
- Reuse: `ace-taskflow/lib/ace/taskflow/molecules/field_argument_parser.rb` (git-move)
- Reuse: `ace-taskflow/lib/ace/taskflow/atoms/slug_sanitizer.rb` (git-move)
- Reuse: `ace-taskflow/lib/ace/taskflow/molecules/llm_slug_generator.rb` (git-move)