---
id: v.0.9.0+task.292
status: draft
priority: high
estimate: TBD
dependencies:
  - v.0.9.0+task.290.01
subtasks:
  - v.0.9.0+task.292.01
  - v.0.9.0+task.292.02
---

# Create ace-retro Gem with B36TS-Based Retro Management

## Objective

Create a standalone `ace-retro` gem that manages retrospectives in `.ace-retros/` using raw 6-char b36ts IDs, folder-based storage, and the same generic command pattern as ace-task and ace-idea (create, show, list, move, update). Replaces ace-taskflow's release-scoped retro management with independent, standalone retro storage.

Origin: idea `8ppq7w-taskflow-add` — "Refactor ace-taskflow: Simplify Release Model and Archive Structure"

## Behavioral Specification

### User Experience
- **Input**: Retro content/titles, shortcut references (`q7w`, `8ppq7w`), field updates, folder targets, optional task references
- **Process**: Retros stored in `.ace-retros/` with raw b36ts IDs (no type marker, same as ideas). Each retro is a folder containing a `.retro.md` file. Only `_archive` as special folder. Archive uses chronological organization (year-month/week grouping).
- **Output**: Retro files (`.retro.md`), formatted terminal output, confirmation messages

### Expected Behavior

Users manage retros through 5 commands — create, show, list, move, update:

1. **Create**: Generates 6-char raw b36ts ID, creates `{id}-{slug}/` folder with `.retro.md` file. Supports `--type` (standard, conversation-analysis, self-review), `--task-ref` (link to task), and `--move-to` (place in specific folder on creation).
2. **Show**: Resolves shortcut by scanning `.ace-retros/`, shows retro with folder contents list.
3. **List**: Recursively scans `.ace-retros/` as flat list. Filters by `--status`, `--tags`, `--type`, `--in` (special folder), `--root` (subpath).
4. **Move**: Physically relocates retro folder. `archive` auto-maps to `_archive/` with chronological sub-path.
5. **Update**: Same `--set/--add/--remove` field modification as ace-task and ace-idea.

No more: release-scoped retros, release resolution, or release directory nesting.

### Interface Contract

```bash
# Create retro
ace-retro create "Sprint Review" [--type standard] [--tags sprint,team] [--task-ref q7w] [--move-to archive] [--dry-run]

# Show retro
ace-retro show q7w [--path | --content]

# List retros
ace-retro list [--status active] [--type standard] [--tags sprint] [--in archive] [--root custom/path]

# Move retro
ace-retro move q7w --to archive

# Update retro
ace-retro update q7w --set status=done --add tags=shipped
ace-retro update q7w --remove tags=wip
```

### Success Criteria

- [ ] `ace-retro create` generates raw b36ts ID and creates correct folder with `.retro.md` file
- [ ] `--type` sets retro type (standard, conversation-analysis, self-review)
- [ ] `--task-ref` links retro to a task ID
- [ ] `ace-retro show` resolves all shortcut forms (full `8ppq7w`, suffix `q7w`)
- [ ] `ace-retro list` flat recursive scan with correct filtering including `--type`
- [ ] `ace-retro move/update` work identically to ace-task/ace-idea equivalents
- [ ] `_archive` with chronological grouping (`_archive/2026-02/`)
- [ ] No dependency on ace-taskflow — fully standalone
- [ ] All tests pass: `ace-test ace-retro`

### Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| Raw b36ts retro IDs | 292.01 | — | KEPT |
| Retro folders (not flat files) | 292.01 | — | KEPT |
| RetroScanner/Resolver/Loader | 292.01 | — | KEPT |
| RetroCreator | 292.01 | — | KEPT |
| 5 CLI commands | 292.02 | — | KEPT |
| Only `_archive` special folder | 292.01 | — | KEPT |
| Retro types (standard, conversation-analysis, self-review) | 292.01 | — | KEPT |
| Release-scoped retros | — | 292.01 | REMOVED |
| Release directory resolution | — | 292.01 | REMOVED |

## Scope of Work

- **Gem**: `ace-retro` — retro-specific atoms/molecules/organisms/models + CLI
- **Handbook migration**: Retro workflows (2 files: `create`, `synthesize`), retro templates (3 files: `retro.template.md`, `synthesis-analytics.template.md`, `synthsize.system.prompt.md`)
- **Depends on**: ace-support-items (from task 290.01), ace-b36ts, ace-support-markdown, ace-support-config, ace-support-core
- **Out of scope**: Migration from ace-taskflow, ace-task gem (task 290), ace-idea gem (task 291), data migration

**Note**: ace-taskflow will be **deleted** after all domain extractions complete. ace-retro must be fully independent — own doctor, own config, own filtering. Shared utilities from ace-taskflow are duplicated rather than centralized.

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/_maybe/8ppq7w-taskflow-add/idea.idea.s.md`
- Depends on: task 290.01 (ace-support-items must exist first)
- Existing retro code: `ace-taskflow/lib/ace/taskflow/organisms/retro_manager.rb` (heavy rewrite needed)
- Existing retro code: `ace-taskflow/lib/ace/taskflow/molecules/retro_loader.rb` (simplify — remove release resolution)
- Workflow instructions: `ace-taskflow/handbook/workflow-instructions/retro/{create,synthesize}.wf.md`
