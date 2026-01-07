---
id: v.0.9.0+task.184
status: draft
priority: medium
estimate: 2h
dependencies: []
---

# Standardize ace-taskflow Retrospective Naming using ace-timestamp Base36 IDs

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-taskflow retro create "My Topic"`
- **Process**: System generates a 6-char Base36 ID using ace-timestamp, combines with slugified title
- **Output**: Creates retro file with format `{base36-id}-{slug}.md` (e.g., `i50jj3-my-topic.md`)

### Expected Behavior
When creating a retrospective, the system should:
1. Generate a globally unique, sortable Base36 compact ID using ace-timestamp
2. Combine this ID with the slugified title to form the filename
3. Create the retro file in the release's retros directory
4. Display the new file path to the user

Existing date-prefixed retros (e.g., `2025-01-06-topic.md`) should remain readable and navigable.

### Interface Contract
```bash
# CLI command (unchanged)
ace-taskflow retro create "Performance Analysis"

# Current output (BEFORE)
Created: .ace-taskflow/v.0.9.0/retros/2026-01-07-performance-analysis.md

# New output (AFTER)
Created: .ace-taskflow/v.0.9.0/retros/i50jj3-performance-analysis.md
```

**Error Handling:**
- Duplicate filename: Return error with existing file path
- Invalid release: Return error with release resolution failure message

**Edge Cases:**
- Empty title: Generate default slug (e.g., `{id}-retro.md`)
- Special characters in title: Sanitize to alphanumeric/hyphen slug

### Success Criteria
- [ ] New retros use 6-char Base36 ID prefix instead of YYYY-MM-DD date
- [ ] RetroLoader correctly parses both old (date) and new (Base36) formats
- [ ] CLI output displays new path format with Base36 ID
- [ ] All existing tests pass
- [ ] New tests cover Base36 ID generation for retros
- [ ] Template date field still shows human-readable date (not Base36 ID)

### Validation Questions
- [x] **Format confirmed**: Use `{base36-id}-{slug}.md` matching idea naming convention
- [x] **Backward compatibility**: RetroLoader already supports multiple formats via IdTitleExtractor
- [x] **ace-timestamp dependency**: Already present in ace-taskflow.gemspec

## Objective

Achieve consistency with Task 149's Base36 Compact ID standard across all ace-taskflow artifacts. Ideas already use Base36 IDs; retros should follow the same pattern for global uniqueness, sortability, and compactness.

## Scope of Work

- **User Experience Scope**: `ace-taskflow retro create` command output
- **System Behavior Scope**: Retro filename generation in RetroManager
- **Interface Scope**: CLI command (unchanged), file naming (changed)

### Deliverables

#### Code Changes
- Update `retro_manager.rb` to use `Ace::Timestamp.encode()` for ID generation
- Verify `retro_loader.rb` backward compatibility (likely no changes needed)

#### Test Updates
- Update `retro_command_test.rb` for new naming pattern
- Add Base36 ID generation tests to `retro_manager_test.rb`

## Out of Scope

- Migrating existing date-prefixed retros to Base36 format
- Changing the retro template content format
- Modifying RetroLoader parsing (already supports multiple formats)
- Any other ace-taskflow file naming changes (audit confirmed only retros need this)

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/8o6lu6-taskflow-add/idea.s.md`
- Task 149: Base36 Compact ID Format Implementation
- Pattern reference: `ace-taskflow/lib/ace/taskflow/molecules/file_namer.rb` (lines 37-41)

## Files to Modify

| File | Change |
|------|--------|
| `ace-taskflow/lib/ace/taskflow/organisms/retro_manager.rb` | Replace date-based naming with ace-timestamp (lines 140-142) |
| `ace-taskflow/test/commands/retro_command_test.rb` | Update test assertions for new naming pattern |
| `ace-taskflow/test/organisms/retro_manager_test.rb` | Add Base36 ID generation tests (if exists) |
