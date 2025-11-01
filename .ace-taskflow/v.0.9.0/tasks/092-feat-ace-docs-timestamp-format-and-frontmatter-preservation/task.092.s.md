---
id: v.0.9.0+task.092
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Add hour:minute timestamps to ace-docs and fix frontmatter preservation

## Behavioral Specification

### User Experience

- **Input**: Documents and changelogs managed by ace-docs with timestamp and frontmatter data
- **Process**: When ace-docs updates document timestamps, it applies date+time format and preserves all frontmatter during writes
- **Output**: Documents with HH:MM timestamps, all frontmatter intact, consistent time-ordered changelog entries

### Expected Behavior

The ace-docs system should support timestamps with hour and minute precision (HH:MM) to enable ordering of multiple releases published on the same day. Currently the system uses date-only format (YYYY-MM-DD), which is insufficient when releasing multiple versions within a single calendar day. Additionally, the system must guarantee that all frontmatter is preserved during any document update operation.

Key behaviors:

- Accept and store timestamps in `YYYY-MM-DD HH:MM` format
- Special values like "today" and "now" generate current date+time (e.g., "2025-11-01 14:30")
- Changelog headers include time component: `## [VERSION] - YYYY-MM-DD HH:MM`
- All existing date-only timestamps remain unchanged (no migration of historical data)
- Document updates NEVER delete or lose YAML frontmatter
- Multiple releases on same day have distinct, orderable timestamps
- Support for custom timestamp values with HH:MM validation

### Interface Contract

```bash
# Update documentation with new timestamp format
ace-docs update README.md --set last-updated=now
# Output: last-updated: 2025-11-01 14:30

# Changelog format (new with time component)
## [0.9.100] - 2025-11-01 14:30
## [0.9.99] - 2025-11-01 09:15
## [0.9.98] - 2025-10-31 16:45

# Set explicit timestamp
ace-docs update CHANGELOG.md --set release-date="2025-11-01 14:30"

# Existing date-only format remains valid
## [0.9.97] - 2025-10-26
```

**Error Handling:**
- Invalid time format: "Error: Invalid timestamp format. Use YYYY-MM-DD HH:MM or special values: today, now"
- Missing frontmatter: No error (frontmatter preserved as-is)
- Update failure: Automatic backup created, no data loss

**Edge Cases:**
- Timestamp at midnight: `2025-11-01 00:00`
- Timestamp at end of day: `2025-11-01 23:59`
- Documents without frontmatter: Updated successfully with timestamps
- Multiple updates same document: Previous frontmatter preserved

### Success Criteria

- [ ] **Timestamp Format**: Timestamps stored and displayed as `YYYY-MM-DD HH:MM`
- [ ] **Special Values**: "now" and "today" generate current date+time with minutes precision
- [ ] **Changelog Support**: Changelog headers can include time component
- [ ] **Frontmatter Preservation**: Document updates never delete or lose frontmatter
- [ ] **Backward Compatibility**: Existing date-only timestamps remain unchanged
- [ ] **Time Validation**: Invalid HH:MM values rejected with helpful error message
- [ ] **Multiple Releases**: Same-day releases have distinct, properly ordered timestamps
- [ ] **No Data Loss**: Atomic writes with backup ensure no data loss on failure

### Validation Questions

- [ ] **Timezone Handling**: Should timezone be included in timestamps or assumed local?
- [ ] **Backward Reading**: Should system accept both old (date-only) and new (date+time) formats?
- [ ] **Frontmatter Formats**: Should all YAML frontmatter be preserved, or only known ace-docs fields?
- [ ] **Performance**: Are there performance implications for timestamp parsing with time component?
- [ ] **Migration Strategy**: Should existing date-only timestamps in active files be migrated or left as-is?

## Objective

Enable fine-grained timestamp tracking in ace-docs to support multiple releases per day while ensuring document integrity by never losing frontmatter during updates. This addresses a documented bug where frontmatter was deleted from ace-docs/README.md during document updates and improves the timestamp precision to match the temporal resolution of the development workflow.

## Scope of Work

### User Experience Scope
- CLI timestamp updates with new HH:MM format
- Changelog generation with time component
- Document frontmatter preservation during all updates
- Clear error messages for invalid timestamps

### System Behavior Scope
- Parse and validate `YYYY-MM-DD HH:MM` format
- Convert special values ("now", "today") to timestamped values
- Preserve all YAML frontmatter during document writes
- Atomic file operations with automatic backup
- Handle edge cases (midnight, end of day, missing frontmatter)

### Interface Scope
- ace-docs update command with new timestamp support
- Changelog header format changes
- Frontmatter manager atomic writes
- Document model timestamp handling

### Deliverables

#### Behavioral Specifications
- Timestamp format specification with examples
- Changelog header format documentation
- Frontmatter preservation guarantees
- Error handling specifications

#### User Experience Artifacts
- Migration guide for date-only to date+time (optional)
- Updated ace-docs README with new timestamp examples
- Error message specifications
- Common timestamp patterns documentation

#### Validation Artifacts
- Test cases for timestamp parsing and validation
- Frontmatter preservation test scenarios
- Edge case handling verification
- Multiple release per day ordering verification

## Out of Scope

- ❌ **Timezone Support**: Timezone inclusion or conversion (assume local time)
- ❌ **Historical Migration**: Bulk migration of existing date-only timestamps
- ❌ **Seconds Precision**: Sub-minute timestamps (HH:MM only, no seconds)
- ❌ **Custom Time Formats**: Support for formats other than YYYY-MM-DD HH:MM
- ❌ **Future Enhancements**: Scheduled releases, time-based triggers

## References

- Source Idea: `/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/done/20251015-002754-ace-docs-we-should-use-date-hourminute-for-any.md`
- Related Code: `ace-docs/lib/ace/docs/models/document.rb` (date parsing)
- Related Code: `ace-docs/lib/ace/docs/molecules/frontmatter_manager.rb` (updates)
- Bug Evidence: Commit bfc20caa (with frontmatter) → current (without frontmatter)
- Standard Reference: Keep a Changelog (note: this task diverges from standard for time support)

---

## Additional Context

### Why This Task is Needed

1. **Multiple Releases Per Day**: The project releases multiple versions on the same calendar day (e.g., 0.9.100, 0.9.99, 0.9.98 all on 2025-11-01), making date-only timestamps insufficient for ordering and tracking.

2. **Frontmatter Loss Bug**: Evidence shows that ace-docs/README.md previously had comprehensive YAML frontmatter that was deleted during a document update operation. This is a data loss issue that must be prevented.

3. **Timestamp Consistency**: Ideas and task files already use full timestamps (HH:MM:SS), so extending documentation timestamps to include hours and minutes creates consistency across the system.

### Breaking Changes

- Changelog format diverges slightly from Keep a Changelog standard (adding HH:MM component to dates)
- New validation stricter on timestamp format (must include HH:MM)
- This is acceptable as ace-docs is part of internal tooling, not a public standard

### Design Decisions

- **HH:MM not HH:MM:SS**: Simpler format for user input, sufficient for distinguishing same-day releases
- **No migration of existing dates**: Preserve historical accuracy; only new timestamps use new format
- **Atomic writes**: Use existing SafeFileWriter pattern with backup to prevent data loss
- **Flexible key support**: Any document field can use timestamp format, not just predefined fields
