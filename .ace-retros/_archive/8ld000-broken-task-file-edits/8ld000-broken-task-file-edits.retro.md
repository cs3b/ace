---
id: 8ld000
title: Broken Task File Edits - Frontmatter Corruption Pattern
type: conversation-analysis
tags: []
created_at: '2025-10-14 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8ld000-broken-task-file-edits.md"
---

# Reflection: Broken Task File Edits - Frontmatter Corruption Pattern

**Date**: 2025-10-14
**Context**: Analysis of recurring issue where task file edits, particularly frontmatter updates, result in corrupted or broken files
**Author**: Development Team
**Type**: Conversation Analysis

## What Went Well

- Quick recovery possible through git history when corruption detected
- User noticed the issue immediately and provided clear feedback
- Complete restoration achievable with `git show` commands to retrieve original content
- Task 071 successfully restored from 5 corrupted lines to full 1134 lines

## What Could Be Improved

- Edit tool's string matching for YAML frontmatter is fragile and error-prone
- Large file edits (1000+ lines) are prone to partial matches, truncation, or complete corruption
- No validation of YAML frontmatter structure after edits
- Mixing content updates with metadata updates in same operation creates risk
- No safety checks or backups before critical file modifications

## Key Learnings

- **YAML frontmatter is structurally fragile**: Multi-line values, special characters, and nested structures make it vulnerable to string-based edits
- **Edit tool limitations**: The string replacement approach doesn't handle edge cases well (line breaks, similar patterns, large contexts)
- **Task files are critical**: These are system files that track project state - corruption impacts project management
- **Separation of concerns needed**: Metadata (frontmatter) and content updates should be handled differently
- **Pattern recognition**: This issue has occurred multiple times, indicating a systemic problem rather than isolated incidents

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Frontmatter Corruption During Status Updates**:
  - Occurrences: Multiple times across different task files
  - Impact: Complete file corruption, reducing 1000+ line files to <10 lines
  - Root Cause: Edit tool's string matching fails on YAML blocks with special characters or when patterns repeat

- **Large File Edit Failures**:
  - Occurrences: Consistently on files >1000 lines
  - Impact: Partial or complete content loss requiring git recovery
  - Root Cause: Context size limitations or string matching algorithms failing on large content

#### Medium Impact Issues

- **Mixed Update Operations**:
  - Occurrences: When updating both frontmatter and content sections
  - Impact: Partial updates succeed while others fail silently
  - Root Cause: No transactional approach to multi-part file updates

#### Low Impact Issues

- **YAML Syntax Preservation**:
  - Occurrences: Indentation and formatting inconsistencies after edits
  - Impact: File remains readable but formatting degraded
  - Root Cause: String replacement doesn't understand YAML structure

### Improvement Proposals

#### Process Improvements

1. **Dedicated Frontmatter Update Method**:
   - Create `ace-taskflow task update-meta <task-id> --field=value`
   - Parse YAML properly, update fields, serialize back
   - Validate YAML structure before and after

2. **Backup Before Critical Edits**:
   - Auto-backup to `.ace-taskflow/.backups/` before task file modifications
   - Implement rollback capability for failed edits

3. **Two-Phase Update Strategy**:
   - Phase 1: Update frontmatter only (using YAML parser)
   - Phase 2: Update content sections (if needed)
   - Commit after each successful phase

#### Tool Enhancements

1. **YAML-Aware Edit Tool**:
   ```bash
   ace-taskflow task update-frontmatter <task-id> \
     --status=done \
     --completion-date=2025-10-14 \
     --version=0.3.0
   ```

2. **Safe Edit Mode**:
   - Implement `--safe` flag that creates backup before edit
   - Add `--validate` flag to check file integrity after edit
   - Return detailed error messages on failure

3. **Structured Task Operations**:
   ```bash
   # Instead of generic edits, use specific commands:
   ace-taskflow task done <task-id> [--version=X.Y.Z]
   ace-taskflow task reopen <task-id>
   ace-taskflow task update-meta <task-id> --field=value
   ```

#### Communication Protocols

- Clear warnings when editing large files (>500 lines)
- Prompt for confirmation on critical file modifications
- Better error messages showing what was attempted vs what failed
- Suggest recovery commands when corruption detected

### Token Limit & Truncation Issues

- **Large Output Instances**: Task files with 1000+ lines consistently problematic
- **Truncation Impact**: Complete loss of file content, requiring full recovery from git
- **Mitigation Applied**: Used git history to restore original content
- **Prevention Strategy**: Implement chunked editing for large files, use structured updates for frontmatter

## Action Items

### Stop Doing

- Using generic Edit tool for YAML frontmatter modifications
- Attempting to update entire large files in single operations
- Mixing metadata and content updates in same edit operation
- Relying on string matching for structured data updates

### Continue Doing

- Maintaining git history for recovery capability
- User providing immediate feedback on issues
- Using git commands for file recovery
- Documenting issues in retrospectives

### Start Doing

- **Implement dedicated frontmatter update commands** in ace-taskflow
- **Create backup mechanism** for task file modifications
- **Use YAML parser** for frontmatter updates instead of string replacement
- **Add validation step** after task file modifications
- **Implement size-aware editing** with different strategies for large files
- **Create `ace-taskflow task validate`** command to check file integrity
- **Add `--dry-run` option** for task updates to preview changes

## Technical Details

### Current Problem Pattern
```yaml
# Original frontmatter
---
id: v.0.9.0+task.071
status: in-progress
priority: high
---

# After failed edit attempt
* * *

id: v.0.9.0+task.071 status: done

# File truncated from 1105 lines to 5 lines
```

### Proposed Solution Architecture
```ruby
# ace-taskflow/lib/ace/taskflow/task_updater.rb
class TaskUpdater
  def update_frontmatter(task_file, updates)
    # 1. Backup original
    backup_file(task_file)

    # 2. Parse YAML frontmatter
    content = File.read(task_file)
    frontmatter, body = parse_frontmatter(content)

    # 3. Update fields
    updates.each do |key, value|
      frontmatter[key] = value
    end

    # 4. Validate YAML
    validate_yaml(frontmatter)

    # 5. Write back
    write_task_file(task_file, frontmatter, body)

    # 6. Verify integrity
    verify_file_integrity(task_file)
  end
end
```

## Additional Context

- Related issue: Task 071 corruption during completion (restored in commit a32aa12a)
- Pattern observed across multiple task completions in v.0.9.0 release
- Similar issues reported with other structured files (YAML configs, frontmatter docs)
- Consider this pattern when designing future file modification tools