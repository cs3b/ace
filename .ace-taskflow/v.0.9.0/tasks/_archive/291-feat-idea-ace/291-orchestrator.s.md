---
id: v.0.9.0+task.291
status: done
priority: high
estimate: TBD
subtasks:
- v.0.9.0+task.291.01
- v.0.9.0+task.291.02
- v.0.9.0+task.291.03
worktree:
  branch: 291-create-ace-idea-gem-with-b36ts-based-idea-management
  path: "../ace-task.291"
  created_at: '2026-02-28 01:42:21'
  updated_at: '2026-02-28 01:42:21'
  target_branch: main
---

# Create ace-idea Gem with B36TS-Based Idea Management

## Objective

Create a standalone `ace-idea` gem that manages ideas in `.ace-ideas/` using raw 6-char b36ts IDs, flat directory structure, and the same generic command pattern as ace-task (create, show, list, move, update). Replaces ace-taskflow's idea management, removing park/unpark/reschedule in favor of `move --to` and `update --set`.

Origin: idea `8ppq7w-taskflow-add` — "Refactor ace-taskflow: Simplify Release Model and Archive Structure"

## Behavioral Specification

### User Experience
- **Input**: Idea content/titles, shortcut references (`q7w`, `8ppq7w`), field updates, folder targets, clipboard content, LLM enhancement flag
- **Process**: Ideas stored in `.ace-ideas/` with raw b36ts IDs (no type marker). Same 5-command pattern as ace-task. Create supports clipboard capture and LLM enhancement from existing ace-taskflow patterns.
- **Output**: Idea spec files (`.idea.s.md`), formatted terminal output, confirmation messages

### Expected Behavior

Users manage ideas through 5 commands — create, show, list, move, update:

1. **Create**: Generates 6-char b36ts ID, creates `{id}-{slug}/` folder with `.idea.s.md` file. Supports `--clipboard` (paste from system clipboard), `--llm-enhance` (LLM improves raw idea), and `--move-to` (place in specific folder on creation).
2. **Show**: Resolves shortcut by scanning `.ace-ideas/`, shows idea with attachments list.
3. **List**: Recursively scans `.ace-ideas/` as flat list. Filters by `--status`, `--tags`, `--in` (special folder), `--root` (subpath).
4. **Move**: Physically relocates idea folder. Short names auto-map to `_` prefixed.
5. **Update**: Same `--set/--add/--remove` field modification as ace-task.

No more: park, unpark, reschedule, done (as dedicated commands), or --release flag.

### Interface Contract

```bash
# Create idea
ace-idea create "We should add dark mode support" [--title "Dark mode"] [--tags ux,design] [--move-to maybe] [--dry-run]
ace-idea create --clipboard                         # Capture from system clipboard
ace-idea create "raw idea text" --llm-enhance       # LLM enhances the idea

# Show idea
ace-idea show q7w [--path | --content]

# List ideas
ace-idea list [--status pending] [--tags ux] [--in maybe] [--root custom/path]

# Move idea
ace-idea move q7w --to archive
ace-idea move q7w --to next

# Update idea
ace-idea update q7w --set status=done --add tags=shipped
ace-idea update q7w --remove tags=wip
```

### Success Criteria

- [ ] `ace-idea create` generates raw b36ts ID and creates correct `.idea.s.md` file
- [ ] `--clipboard` captures system clipboard content (rich: RTF/HTML, plain text, images)
- [ ] `--llm-enhance` improves raw idea text via LLM with 3-Question Brief structure
- [ ] `--move-to` places idea in target folder on creation
- [ ] `ace-idea show` resolves all shortcut forms (full `8ppq7w`, suffix `q7w`)
- [ ] `ace-idea list` flat recursive scan with correct filtering
- [ ] `ace-idea move/update` work identically to ace-task equivalents
- [ ] No dependency on ace-taskflow — fully standalone
- [ ] All tests pass: `ace-test ace-idea`

### Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| Raw b36ts idea IDs | 291.01 | — | KEPT |
| IdeaScanner/Resolver/Loader | 291.01 | — | KEPT |
| IdeaCreator with clipboard+LLM | 291.01 | — | KEPT |
| 5 CLI commands | 291.02 | — | KEPT |
| park/unpark commands | — | 291.02 | REMOVED (replaced by move) |
| reschedule command | — | 291.02 | REMOVED (replaced by move) |
| Release-scoped ideas | — | 291.01 | REMOVED |

## Scope of Work

- **Gem**: `ace-idea` — idea-specific atoms/molecules/organisms/models + CLI
- **Handbook migration**: Idea workflows (3 files: `capture`, `capture-features`, `prioritize`) — move to ace-idea
- **Depends on**: ace-support-items (from task 290.01), ace-b36ts, ace-support-markdown, ace-llm
- **Out of scope**: Migration from ace-taskflow, ace-task gem (task 290), retrospectives, data migration

**Note**: ace-taskflow will be **deleted** after all domain extractions complete. ace-idea must be fully independent — own doctor, own config, own filtering. Shared utilities from ace-taskflow are duplicated rather than centralized.

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/_maybe/8ppq7w-taskflow-add/idea.idea.s.md`
- Plan: `/home/mc/.claude/plans/eventual-dazzling-pixel.md`
- Depends on: task 290.01 (ace-support-items must exist first)
- Reuse patterns from: `ace-taskflow/lib/ace/taskflow/organisms/idea_writer.rb` (clipboard, LLM enhance)