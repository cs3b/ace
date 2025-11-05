# Timestamp Format and Frontmatter Preservation - Usage Guide

## Overview

This feature extends ace-docs to support timestamps with hour and minute precision (`YYYY-MM-DD HH:MM`) alongside the existing date-only format (`YYYY-MM-DD`). This enables ordering of multiple releases published on the same day and provides finer-grained temporal tracking for documentation updates.

**Key Features:**
- Date+time timestamp format: `YYYY-MM-DD HH:MM`
- Special value "now" generates current date and time
- Backward compatible with existing date-only timestamps
- Guaranteed frontmatter preservation during all updates
- Atomic file operations with automatic backup

## Command Structure

### Basic Update Command

```bash
ace-docs update <file> --set <field>=<value>
```

**Parameters:**
- `<file>`: Path to markdown file with ace-docs frontmatter
- `<field>`: Frontmatter field to update (e.g., `last-updated`, `release-date`)
- `<value>`: Timestamp value (date-only, date+time, or special value)

## Timestamp Formats

### Supported Formats

| Format | Example | Use Case |
|--------|---------|----------|
| Date-only | `2025-11-01` | Legacy format, daily precision |
| Date+time | `2025-11-01 14:30` | New format, minute precision |
| Special: "today" | `today` → `2025-11-01` | Current date without time |
| Special: "now" | `now` → `2025-11-01 14:30` | Current date and time |

### Format Validation

**Valid Formats:**
- `YYYY-MM-DD` (date-only)
- `YYYY-MM-DD HH:MM` (date+time)

**Invalid Examples:**
- `2025-11-01 2:30pm` (AM/PM not supported)
- `2025-11-01 14:30:00` (seconds not supported)
- `11/01/2025 14:30` (wrong date format)
- `2025-11-01T14:30` (ISO 8601 T separator not supported)

## Usage Scenarios

### Scenario 1: Update Document with Current Date and Time

**Goal:** Mark a document as updated with the current timestamp including time.

**Command:**
```bash
ace-docs update README.md --set last-updated=now
```

**Before (frontmatter):**
```yaml
---
ace-docs:
  doc-type: guide
  purpose: Project overview
  last-updated: 2025-10-31
---
```

**After (frontmatter):**
```yaml
---
ace-docs:
  doc-type: guide
  purpose: Project overview
  last-updated: 2025-11-01 14:30
---
```

**Note:** All other frontmatter fields are preserved exactly as they were.

### Scenario 2: Set Explicit Date+Time Timestamp

**Goal:** Record a specific release time for a changelog entry.

**Command:**
```bash
ace-docs update CHANGELOG.md --set release-date="2025-11-01 09:15"
```

**Expected Output:**
```yaml
---
release-date: 2025-11-01 09:15
---

# Changelog

## [0.9.100] - 2025-11-01 09:15
...
```

**Use Case:** When releasing multiple versions on the same day, the time component enables proper ordering.

### Scenario 3: Backward Compatible Date-Only Update

**Goal:** Update a document using the legacy date-only format.

**Command:**
```bash
ace-docs update docs/architecture.md --set last-updated=today
```

**Result:**
```yaml
---
ace-docs:
  last-updated: 2025-11-01
---
```

**Behavior:** Existing behavior unchanged. Special value "today" still produces date-only format.

### Scenario 4: Multiple Releases Same Day

**Goal:** Track multiple releases published on the same calendar day.

**Changelog Format (with times):**
```markdown
## [0.9.100] - 2025-11-01 14:30

### Added
- New timestamp format support

## [0.9.99] - 2025-11-01 09:15

### Fixed
- Bug fixes

## [0.9.98] - 2025-10-31 16:45

### Changed
- Previous day release
```

**Ordering:** Releases are now distinguishable and properly ordered by timestamp.

### Scenario 5: Preserve Complex Frontmatter

**Goal:** Update timestamp while preserving all existing frontmatter.

**Before (complex frontmatter):**
```yaml
---
ace-docs:
  doc-type: reference
  purpose: API documentation
  subject:
    - code:
        diff:
          filters:
            - "lib/**/*.rb"
    - tests:
        diff:
          filters:
            - "test/**/*.rb"
  context:
    keywords: ["API", "endpoints", "authentication"]
  last-updated: 2025-10-31
metadata:
  version: 1.2.0
  author: Dev Team
custom-field: custom-value
---
```

**Command:**
```bash
ace-docs update docs/api.md --set last-updated=now
```

**After:**
```yaml
---
ace-docs:
  doc-type: reference
  purpose: API documentation
  subject:
    - code:
        diff:
          filters:
            - "lib/**/*.rb"
    - tests:
        diff:
          filters:
            - "test/**/*.rb"
  context:
    keywords: ["API", "endpoints", "authentication"]
  last-updated: 2025-11-01 14:30
metadata:
  version: 1.2.0
  author: Dev Team
custom-field: custom-value
---
```

**Guarantee:** All frontmatter structure and fields preserved, only `last-updated` changed.

### Scenario 6: Error Handling - Invalid Format

**Goal:** Understand error handling for invalid timestamp formats.

**Command:**
```bash
ace-docs update README.md --set last-updated="2025-11-01 2:30pm"
```

**Expected Error:**
```
Error: Invalid timestamp format. Use YYYY-MM-DD HH:MM or special values: today, now
Examples:
  - 2025-11-01 14:30
  - 2025-11-01
  - now
  - today
```

**Recovery:** No changes made to file. Original frontmatter intact.

## Command Reference

### ace-docs update

**Syntax:**
```bash
ace-docs update <file> --set <field>=<value>
```

**Parameters:**
- `<file>` (required): Path to markdown file
- `--set <field>=<value>` (required): Field and value to update

**Timestamp Values:**
- Date-only: `YYYY-MM-DD` format
- Date+time: `YYYY-MM-DD HH:MM` format
- Special: `today` (current date)
- Special: `now` (current date and time)

**Internal Implementation:**
- Uses `Ace::Docs::Molecules::FrontmatterManager` for updates
- Delegates to `Ace::Support::Markdown::Organisms::DocumentEditor` for atomic writes
- Creates `.bak` backup before writing
- Validates timestamp format before applying

**Exit Codes:**
- `0`: Success
- `1`: Error (invalid format, file not found, write failure)

## Tips and Best Practices

### When to Use Date+Time Format

**Use date+time (`YYYY-MM-DD HH:MM`) when:**
- Publishing multiple releases per day
- Tracking fine-grained documentation updates
- Ordering events within a single day
- Synchronizing with git commit timestamps

**Use date-only (`YYYY-MM-DD`) when:**
- Daily update frequency is sufficient
- Maintaining consistency with external systems (e.g., Keep a Changelog)
- Historical data uses date-only format

### Frontmatter Preservation

**Best Practices:**
- Always review backup file (`.bak`) after updates
- Test updates on non-critical documents first
- Use version control to track frontmatter changes
- Report any frontmatter loss immediately (should never happen)

**Safety Guarantees:**
- Atomic writes: File written to temp location, then renamed
- Automatic backup: `.bak` file created before write
- Rollback support: `DocumentEditor.rollback` available
- Validation: Frontmatter structure validated before write

### Performance Considerations

**Timestamp Parsing:**
- Ruby `Time.parse` is fast (<1ms per operation)
- No observable performance impact for typical use
- Atomic writes add minimal overhead (~5-10ms per file)

**Bulk Updates:**
```bash
# Update multiple documents
for file in docs/**/*.md; do
  ace-docs update "$file" --set last-updated=now
done
```

**Note:** Each update creates a backup file. Clean up `.bak` files after verification.

## Migration Notes

### From Date-Only to Date+Time (Optional)

**No Forced Migration:**
- Existing date-only timestamps remain valid
- System accepts both formats indefinitely
- Migrate only if you need time precision

**Selective Migration Approach:**
```bash
# Migrate specific files to date+time
ace-docs update CHANGELOG.md --set release-date=now
ace-docs update README.md --set last-updated=now

# Keep others as date-only
ace-docs update docs/architecture.md --set last-updated=today
```

### Backward Compatibility

**Reading:**
- Date-only strings parsed as `Date` objects
- Date+time strings parsed as `Time` objects
- Both work with all ace-docs commands

**Writing:**
- "today" → date-only format (existing behavior)
- "now" → date+time format (new behavior)
- Explicit strings validated and written as-is

### Changelog Format Considerations

**Standard Keep a Changelog:**
```markdown
## [1.0.0] - 2025-11-01
```

**Extended with Time (ace-docs):**
```markdown
## [1.0.0] - 2025-11-01 14:30
```

**Note:** This diverges from Keep a Changelog standard but is acceptable for internal tooling. External changelogs can continue using date-only format.

## Troubleshooting

### Frontmatter Not Preserved

**Symptom:** Frontmatter fields lost after update.

**Diagnosis:**
1. Check for `.bak` file in same directory
2. Compare original (`.bak`) with updated file
3. Verify ace-support-markdown version (requires >= 0.4.0)

**Resolution:**
- Restore from `.bak` file
- Report bug with file examples
- Verify DocumentEditor integration

### Invalid Timestamp Format Error

**Symptom:** Error message about invalid format.

**Diagnosis:**
- Check timestamp string format
- Verify HH:MM uses 24-hour format (00-23)
- Ensure no AM/PM or seconds

**Resolution:**
- Use `YYYY-MM-DD HH:MM` format
- Use special values: `now` or `today`
- Remove seconds if present (`:00`)

### Backup Files Accumulating

**Symptom:** Many `.bak` files in document directories.

**Diagnosis:** Normal behavior - each update creates backup.

**Resolution:**
```bash
# Clean up backups after verification
find docs -name "*.md.bak" -delete

# Or review before deletion
find docs -name "*.md.bak" -exec ls -l {} \;
```

**Best Practice:** Commit changes to git, then clean up backups.

## Examples Summary

```bash
# Current date and time
ace-docs update README.md --set last-updated=now

# Current date only
ace-docs update README.md --set last-updated=today

# Explicit date+time
ace-docs update CHANGELOG.md --set release-date="2025-11-01 14:30"

# Explicit date only
ace-docs update docs/guide.md --set last-updated="2025-11-01"

# Multiple fields (run separately)
ace-docs update README.md --set last-updated=now
ace-docs update README.md --set version=1.0.0
```

## Related Documentation

- ace-docs README: General usage and configuration
- ace-docs/docs/usage.md: Complete command reference
- ace-support-markdown: DocumentEditor API and safety guarantees
