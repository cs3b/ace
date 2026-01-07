---
id: v.0.9.0+task.182
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Implement Descriptive Slugs for Idea Filenames

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-taskflow idea create "My feature idea"`
- **Process**: System generates slug, creates folder AND filename with slug
- **Output**: `{compact_id}-{slug}/{slug}.idea.s.md`

### Expected Behavior

Extend idea file naming to use `{slug}.idea.s.md` pattern. Currently only the folder has a slug - the filename is always `idea.s.md`.

**Current:** `.ace-taskflow/v.0.9.0/ideas/8o6jap-taskflow-add/idea.s.md`
**Desired:** `.ace-taskflow/v.0.9.0/ideas/8o6jap-taskflow-add/taskflow-add.idea.s.md`

This aligns idea naming with the task naming convention (e.g., `179-task-migrate-cli/179.01-foundation.s.md`).

### Interface Contract

```bash
# New behavior
ace-taskflow idea create "Implement user auth"
# Creates: .ace-taskflow/v.X.Y.Z/ideas/8o6xyz-user-auth/user-auth.idea.s.md

# Existing behavior (backward compat)
# Old ideas with idea.s.md continue to work
ace-taskflow idea list
# Displays both new and old format ideas correctly
```

**Error Handling:**
- Missing file_slug: Falls back to `idea.s.md`
- Multiple `.idea.s.md` files: Uses first found (alphabetically)

**Edge Cases:**
- Legacy `idea.s.md` files: Remain fully supported via fallback
- Mixed formats in same directory: New format takes priority

### Success Criteria

- [ ] **New ideas use slug filename**: Ideas created with `{slug}.idea.s.md` pattern
- [ ] **Backward compatibility**: Existing `idea.s.md` files remain resolvable
- [ ] **List command works**: `ace-taskflow idea list` correctly displays new format
- [ ] **Tests pass**: All existing tests pass with updated assertions

### Validation Questions

- [x] **Filename pattern**: Confirmed as `{slug}.idea.s.md` (slug first, `.idea.s.md` extension)
- [x] **Fallback behavior**: Falls back to `idea.s.md` when no slug available
- [x] **Migration**: No migration needed - backward compatible

## Objective

Improve idea path readability and discoverability by including descriptive slugs in filenames, matching the established task naming convention.

## Scope of Work

- **User Experience Scope**: Idea creation and listing workflows
- **System Behavior Scope**: File naming, file discovery, display formatting
- **Interface Scope**: `ace-taskflow idea create`, `ace-taskflow idea list`

### Deliverables

#### Behavioral Specifications
- Idea filename pattern: `{slug}.idea.s.md`
- File discovery priority: `.idea.s.md` > `.s.md` > `idea.s.md`
- Backward compatibility with existing ideas

#### Implementation Files
- `idea_writer.rb:113` - Change extension to `.idea.s.md`
- `idea_loader.rb:211-223` - Add `.idea.s.md` priority in discovery
- `ideas_command.rb` - Update display path resolution
- Test files - Update assertions for new pattern

## Out of Scope

- Migrating existing ideas to new format
- Changing task filename patterns
- Modifying the compact ID generation

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/8o6jap-taskflow-add/`
- Related: Task 149 (Base36 Compact ID implementation)
